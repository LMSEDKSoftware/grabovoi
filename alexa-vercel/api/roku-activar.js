'use strict';

// Página que se abre al escanear el QR de la TV (también accesible
// tecleando la dirección corta /tv). El usuario ve el código que tiene
// enfrente en la pantalla, entra con su cuenta ManiGraB, y con eso la
// televisión que estaba haciendo polling recibe su sesión.
//
// Emite exactamente el mismo token opaco que roku-login.js y lo guarda
// en la misma tabla (roku_account_links): para el resto de los endpoints
// del canal, una TV vinculada por QR y una que entró con el teclado son
// indistinguibles.

const { createClient } = require('@supabase/supabase-js');

const ACCESS_TOKEN_TTL_SECONDS = 90 * 24 * 60 * 60; // 90 días, igual que roku-login

function randomToken() {
  return require('crypto').randomUUID().replace(/-/g, '') + require('crypto').randomUUID().replace(/-/g, '');
}

function readFormBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', (chunk) => { data += chunk; });
    req.on('end', () => {
      try {
        resolve(Object.fromEntries(new URLSearchParams(data)));
      } catch (e) {
        reject(e);
      }
    });
    req.on('error', reject);
  });
}

function esc(valor) {
  return String(valor == null ? '' : valor)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function pagina(cuerpo) {
  return `<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>Activar ManiGraB TV</title>
<style>
  :root { color-scheme: dark; }
  * { box-sizing: border-box; }
  body {
    margin: 0; min-height: 100vh; padding: 32px 20px 48px;
    background: radial-gradient(120% 90% at 50% 0%, #14284d 0%, #071226 62%);
    color: #F4F1E8;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    display: flex; justify-content: center;
  }
  .caja { width: 100%; max-width: 420px; }
  .marca { font-size: 26px; font-weight: 800; letter-spacing: .5px; color: #FFD83D; margin: 0 0 4px; }
  .marca span { color: #F4F1E8; font-weight: 600; }
  .lema { margin: 0 0 28px; color: #B9C4D8; font-size: 14px; }
  h1 { font-size: 21px; margin: 0 0 8px; }
  p.ayuda { color: #B9C4D8; font-size: 14px; line-height: 1.5; margin: 0 0 22px; }
  label { display: block; font-size: 13px; color: #B9C4D8; margin: 0 0 6px; }
  input {
    width: 100%; padding: 14px 16px; margin: 0 0 18px; font-size: 16px;
    border-radius: 12px; border: 1px solid #24365c; background: #0C1830; color: #F4F1E8;
  }
  input:focus { outline: none; border-color: #FFD83D; }
  input.codigo { font-size: 30px; font-weight: 700; letter-spacing: 10px; text-align: center; color: #FFD83D; }
  button {
    width: 100%; padding: 16px; font-size: 16px; font-weight: 700; cursor: pointer;
    border: none; border-radius: 12px; background: #FFD83D; color: #071226;
  }
  .aviso {
    margin: 24px 0 0; padding: 14px 16px; border-radius: 12px;
    background: rgba(255, 216, 61, .08); border: 1px solid rgba(255, 216, 61, .28);
    color: #E4D9B0; font-size: 13px; line-height: 1.5;
  }
  .error {
    margin: 0 0 20px; padding: 14px 16px; border-radius: 12px;
    background: rgba(255, 119, 119, .12); border: 1px solid rgba(255, 119, 119, .4);
    color: #FFB4B4; font-size: 14px;
  }
  .listo { font-size: 56px; line-height: 1; margin: 0 0 16px; }
</style>
</head>
<body>
  <main class="caja">
    <p class="marca">ManiGraB <span>TV</span></p>
    <p class="lema">Secuencias Grabovoi</p>
    ${cuerpo}
  </main>
</body>
</html>`;
}

function formulario({ codigo, error }) {
  return pagina(`
    <h1>Activa tu televisión</h1>
    <p class="ayuda">Escribe el número que aparece en la pantalla de tu TV y entra con tu cuenta de ManiGraB.</p>
    ${error ? `<div class="error">${esc(error)}</div>` : ''}
    <form method="POST" action="/tv">
      <label for="codigo">Código de la TV</label>
      <input class="codigo" id="codigo" name="codigo" inputmode="numeric" pattern="[0-9]{6}"
             maxlength="6" autocomplete="off" required value="${esc(codigo)}" placeholder="000000">
      <label for="email">Correo electrónico</label>
      <input id="email" name="email" type="email" autocomplete="email" required>
      <label for="password">Contraseña</label>
      <input id="password" name="password" type="password" autocomplete="current-password" required>
      <button type="submit">Vincular televisión</button>
    </form>
    <p class="aviso">Solo escribe un código si lo estás viendo en tu propia televisión. Nadie de ManiGraB va a pedirte este número por teléfono, correo ni mensaje.</p>
  `);
}

async function handler(req, res) {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Cache-Control', 'no-store');

  if (req.method === 'GET') {
    const c = String((req.query && req.query.c) || '').trim();
    res.status(200).end(formulario({ codigo: /^\d{6}$/.test(c) ? c : '', error: '' }));
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).end(pagina('<h1>Método no permitido</h1>'));
    return;
  }

  let body;
  try {
    body = await readFormBody(req);
  } catch (_e) {
    res.status(400).end(formulario({ codigo: '', error: 'No se pudo leer el formulario.' }));
    return;
  }

  const codigo = String(body.codigo || '').trim();
  const email = String(body.email || '').trim().toLowerCase();
  const password = String(body.password || '');

  if (!/^\d{6}$/.test(codigo)) {
    res.status(400).end(formulario({ codigo: '', error: 'El código son 6 dígitos.' }));
    return;
  }
  if (!email || !password) {
    res.status(400).end(formulario({ codigo, error: 'Escribe tu correo y tu contraseña.' }));
    return;
  }

  const admin = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

  const { data: fila, error: selectError } = await admin
    .from('roku_device_codes')
    .select('id, status, expires_at')
    .eq('code', codigo)
    .maybeSingle();

  if (selectError) {
    console.error('roku-activar: select falló', selectError);
    res.status(500).end(formulario({ codigo, error: 'Algo falló de nuestro lado. Intenta de nuevo.' }));
    return;
  }

  // Se valida el código ANTES de tocar las credenciales: así un código
  // inventado no sirve ni siquiera para probar contraseñas.
  if (!fila || fila.status !== 'pending' || new Date(fila.expires_at).getTime() < Date.now()) {
    res.status(400).end(formulario({
      codigo: '',
      error: 'Ese código ya no es válido. Genera uno nuevo desde tu televisión.',
    }));
    return;
  }

  const anon = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);
  const { data: sesion, error: authError } = await anon.auth.signInWithPassword({ email, password });

  if (authError || !sesion.user) {
    res.status(401).end(formulario({ codigo, error: 'Correo o contraseña incorrectos.' }));
    return;
  }

  const accessToken = randomToken();
  const expiresAt = new Date(Date.now() + ACCESS_TOKEN_TTL_SECONDS * 1000).toISOString();

  const { error: upsertError } = await admin
    .from('roku_account_links')
    .upsert(
      {
        user_id: sesion.user.id,
        access_token: accessToken,
        access_token_expires_at: expiresAt,
        updated_at: new Date().toISOString(),
      },
      { onConflict: 'user_id' },
    );

  if (upsertError) {
    console.error('roku-activar: upsert de roku_account_links falló', upsertError);
    res.status(500).end(formulario({ codigo, error: 'Algo falló de nuestro lado. Intenta de nuevo.' }));
    return;
  }

  // El filtro por status 'pending' es lo que hace que dos envíos
  // simultáneos del mismo código no puedan vincular dos veces.
  const { data: actualizada, error: updateError } = await admin
    .from('roku_device_codes')
    .update({
      status: 'linked',
      user_id: sesion.user.id,
      access_token: accessToken,
      access_token_expires_at: expiresAt,
      linked_at: new Date().toISOString(),
    })
    .eq('id', fila.id)
    .eq('status', 'pending')
    .select('id');

  if (updateError || !actualizada || actualizada.length === 0) {
    console.error('roku-activar: update del código falló', updateError);
    res.status(400).end(formulario({
      codigo: '',
      error: 'Ese código ya no es válido. Genera uno nuevo desde tu televisión.',
    }));
    return;
  }

  res.status(200).end(pagina(`
    <p class="listo">✅</p>
    <h1>¡Listo!</h1>
    <p class="ayuda">Tu televisión ya está vinculada a la cuenta <strong>${esc(email)}</strong>.
    En unos segundos vas a ver tu portal en la pantalla. Ya puedes cerrar esta página.</p>
    <p class="aviso">Si quieres desvincularla, vuelve a entrar aquí desde otra TV o cierra sesión desde el menú del canal.</p>
  `));
}

module.exports = handler;
