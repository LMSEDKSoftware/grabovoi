'use strict';

// Atajo de vinculación por QR para ManiGraB TV, lado televisión.
//
// Los tres pasos que le tocan al Roku viven en un solo archivo a
// propósito: el plan Hobby de Vercel solo admite 12 funciones por
// despliegue, y con un archivo por endpoint nos pasábamos. Se separan
// por acción, no por archivo:
//
//   POST {action:"create", device_id}        -> genera el código de 6 dígitos
//   POST {action:"poll", code, device_id}    -> ¿ya lo confirmaron desde el teléfono?
//   GET  ?qr=123456                          -> PNG del código QR
//
// El paso que le toca al usuario (entrar con su cuenta) está en
// roku-activar.js, que es la página que abre el QR.
//
// Nada de esto reemplaza a roku-login.js: Roku exige que el canal
// siempre permita iniciar sesión sin salir del dispositivo, así que el
// login con teclado sigue visible en la misma pantalla. Esto es solo
// comodidad, igual que lo hace Gaia.

const crypto = require('crypto');
const QRCode = require('qrcode');
const { createClient } = require('@supabase/supabase-js');

const CODE_TTL_SECONDS = 15 * 60;
const POLL_INTERVAL_SECONDS = 5;
const MAX_INTENTOS_CODIGO = 8;

function readJsonBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', (chunk) => { data += chunk; });
    req.on('end', () => {
      try {
        resolve(data ? JSON.parse(data) : {});
      } catch (e) {
        reject(e);
      }
    });
    req.on('error', reject);
  });
}

// 6 dígitos, siempre con el primero distinto de cero: así el número que
// se lee en la TV y el que se teclea en el teléfono tienen exactamente
// la misma longitud, sin ceros a la izquierda que se pierdan al copiar.
function nuevoCodigo() {
  return String(crypto.randomInt(100000, 1000000));
}

function baseUrl(req) {
  const host = req.headers['x-forwarded-host'] || req.headers.host;
  const proto = String(req.headers['x-forwarded-proto'] || 'https').split(',')[0];
  return `${proto}://${host}`;
}

function admin() {
  return createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
}

// GET ?qr=123456 -> imagen. Roku no sabe generar códigos QR (el nodo
// Poster solo carga imágenes por URL), así que la imagen viene hecha de
// aquí. A propósito no se acepta texto libre para codificar, solo el
// código: si aceptara cualquier URL, esto sería un generador de QR
// gratuito apuntando a donde sea, bajo nuestro dominio.
async function responderQr(req, res, code) {
  if (!/^\d{6}$/.test(code)) {
    res.status(400).json({ error: 'invalid_code' });
    return;
  }
  try {
    const png = await QRCode.toBuffer(`${baseUrl(req)}/tv?c=${code}`, {
      type: 'png',
      // 'M' aguanta reflejos y fotos torcidas de una pantalla de TV sin
      // engordar demasiado la cuadrícula.
      errorCorrectionLevel: 'M',
      margin: 2,
      width: 420,
      color: { dark: '#071226ff', light: '#ffffffff' },
    });
    res.setHeader('Content-Type', 'image/png');
    res.setHeader('Content-Length', png.length);
    // El código vive 15 minutos; que la caché no lo sobreviva.
    res.setHeader('Cache-Control', 'public, max-age=600');
    res.status(200).end(png);
  } catch (e) {
    console.error('roku-device: no se pudo generar el PNG', e);
    res.status(500).json({ error: 'server_error' });
  }
}

async function crearCodigo(req, res, body) {
  const deviceId = String(body.device_id || '').trim().slice(0, 128);
  if (!deviceId) {
    res.status(400).json({ error: 'missing_device_id' });
    return;
  }

  const db = admin();

  // Barrido de basura oportunista. Si falla no importa: los códigos
  // caducan por expires_at, esto solo evita que la tabla crezca.
  db.rpc('roku_purgar_codigos_vencidos').then(() => {}, () => {});

  // Si esta TV ya tenía un código pendiente (por ejemplo se reinició el
  // canal), se descarta: solo debe haber un código vivo por dispositivo,
  // o el usuario podría estar mirando un número que ya nadie escucha.
  await db
    .from('roku_device_codes')
    .delete()
    .eq('device_id', deviceId)
    .eq('status', 'pending');

  const expiresAt = new Date(Date.now() + CODE_TTL_SECONDS * 1000).toISOString();

  let fila = null;
  for (let intento = 0; intento < MAX_INTENTOS_CODIGO; intento += 1) {
    const code = nuevoCodigo();
    const { data, error } = await db
      .from('roku_device_codes')
      .insert({ code, device_id: deviceId, status: 'pending', expires_at: expiresAt })
      .select('code')
      .single();

    if (!error && data) {
      fila = data;
      break;
    }
    // 23505 = unique_violation: el código ya estaba tomado, se reintenta
    // con otro. Cualquier otro error sí es real.
    if (error && error.code !== '23505') {
      console.error('roku-device: insert falló', error);
      res.status(500).json({ error: 'server_error' });
      return;
    }
  }

  if (!fila) {
    console.error('roku-device: no se consiguió un código libre');
    res.status(500).json({ error: 'server_error' });
    return;
  }

  const base = baseUrl(req);
  res.status(200).json({
    code: fila.code,
    expires_in: CODE_TTL_SECONDS,
    poll_interval: POLL_INTERVAL_SECONDS,
    activate_url: `${base}/tv?c=${fila.code}`,
    // Versión corta y sin protocolo, para dictarla en la pantalla del
    // televisor sin que ocupe dos renglones.
    activate_label: `${base.replace(/^https?:\/\//, '')}/tv`,
    qr_url: `${base}/api/roku-device?qr=${fila.code}`,
  });
}

// Siempre 200 con un "status" ('pending' | 'linked' | 'expired') en vez
// de códigos HTTP distintos: del lado de Roku es un solo camino de
// lectura, sin ramas por código de respuesta.
async function consultarCodigo(req, res, body) {
  const code = String(body.code || '').trim();
  const deviceId = String(body.device_id || '').trim();
  if (!/^\d{6}$/.test(code) || !deviceId) {
    res.status(400).json({ error: 'invalid_request' });
    return;
  }

  const db = admin();

  const { data: fila, error } = await db
    .from('roku_device_codes')
    .select('id, device_id, status, access_token, access_token_expires_at, expires_at')
    .eq('code', code)
    .maybeSingle();

  if (error) {
    console.error('roku-device: select falló', error);
    res.status(500).json({ error: 'server_error' });
    return;
  }

  // Código inexistente, ya reclamado, de otra televisión, o caducado:
  // todos se responden igual a propósito, para no confirmarle a nadie
  // que un número existe.
  if (!fila
    || fila.device_id !== deviceId
    || fila.status === 'claimed'
    || new Date(fila.expires_at).getTime() < Date.now()) {
    res.status(200).json({ status: 'expired' });
    return;
  }

  if (fila.status !== 'linked' || !fila.access_token) {
    res.status(200).json({ status: 'pending' });
    return;
  }

  const token = fila.access_token;
  const expiresIn = Math.max(
    0,
    Math.floor((new Date(fila.access_token_expires_at).getTime() - Date.now()) / 1000),
  );

  // Un solo uso: se marca reclamado y se borra el token de la fila para
  // que no quede una copia viva en una tabla de códigos temporales.
  const { error: updateError } = await db
    .from('roku_device_codes')
    .update({ status: 'claimed', access_token: null })
    .eq('id', fila.id)
    .eq('status', 'linked');

  if (updateError) {
    console.error('roku-device: update falló', updateError);
    res.status(500).json({ error: 'server_error' });
    return;
  }

  res.status(200).json({ status: 'linked', access_token: token, expires_in: expiresIn });
}

// ¿Ese correo tiene cuenta de ManiGraB? Se usa después de que el usuario
// acepta compartir el correo de su cuenta Roku (ChannelStore getUserData,
// exigido por el criterio RP 2.1).
//
// A propósito NO devuelve un token: eso sería autenticar solo con el
// correo, y este endpoint no puede comprobar que la petición venga de
// verdad del sistema Roku con el consentimiento del dueño. Cualquiera
// podría pedir el token de una cuenta ajena sabiendo su correo. Solo
// dice si existe, para decidir entre pedir la contraseña o mandar a
// registrarse; entrar sigue exigiendo la contraseña o el QR.
async function verificarCorreo(res, admin, body) {
  const email = String(body.email || '').trim().toLowerCase();
  const deviceId = String(body.device_id || '').trim();
  if (!email || !deviceId) {
    res.status(400).json({ error: 'invalid_request' });
    return;
  }

  // Vía función SQL y no supabase-js: auth.users no está expuesta por
  // PostgREST, y el cliente no tiene getUserByEmail. La función devuelve
  // solo un booleano, nunca datos de la cuenta.
  const { data, error } = await admin.rpc('existe_correo', { p_email: email });
  if (error) {
    console.error('roku-device: verificar correo falló', error);
    res.status(500).json({ error: 'server_error' });
    return;
  }

  res.status(200).json({ existe: data === true });
}

async function handler(req, res) {
  if (req.method === 'GET') {
    await responderQr(req, res, String((req.query && req.query.qr) || '').trim());
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'method_not_allowed' });
    return;
  }

  let body;
  try {
    body = await readJsonBody(req);
  } catch (_e) {
    res.status(400).json({ error: 'invalid_json' });
    return;
  }

  const action = String(body.action || '').trim();
  if (action === 'create') {
    await crearCodigo(req, res, body);
  } else if (action === 'poll') {
    await consultarCodigo(req, res, body);
  } else if (action === 'verificar_correo') {
    await verificarCorreo(res, admin(), body);
  } else {
    res.status(400).json({ error: 'invalid_action' });
  }
}

module.exports = handler;
