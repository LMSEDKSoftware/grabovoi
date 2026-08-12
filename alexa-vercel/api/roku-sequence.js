'use strict';

// Detalle de una secuencia + manifiesto de audio para que BrightScript
// arme la cola de reproducción dígito por dígito, replicando
// NumbersVoiceService exactamente (mismos clips, mismos tiempos). No
// requiere sesión para leer el detalle; si viene el token de Roku,
// se usa la voz elegida en roku_account_links.voice_gender — INDEPENDIENTE
// de user_rewards.voice_gender (app/Alexa). Cambiar la voz en Roku nunca
// debe tocar esa fila compartida; ver docs/ROKU_TV_PLAN.md.

const { createClient } = require('@supabase/supabase-js');

const BASE_VOCES = 'https://whtiazgcxdnemrrgjjqf.supabase.co/storage/v1/object/public/roku/voces';
const VOCES_VALIDAS = { female: 'female', male: 'male', 'male 2': 'male2' };

const GAP_DIGITOS_MS = 280;
const SILENCIO_ESPACIO_MS = 100;
const PAUSA_NUEVAMENTE_MS = 1800;

function clipsDeVoz(vozSlug) {
  const base = `${BASE_VOCES}/${vozSlug}`;
  const clips = { espacio: `${base}/espacio.mp3`, nuevamente: `${base}/nuevamente.mp3` };
  for (let d = 0; d <= 9; d++) clips[String(d)] = `${base}/${d}.mp3`;
  return clips;
}

async function vozDelUsuario(admin, authHeader) {
  if (!authHeader?.startsWith('Bearer ')) return 'female';
  const token = authHeader.slice('Bearer '.length);
  const { data: link } = await admin
    .from('roku_account_links')
    .select('voice_gender, access_token_expires_at')
    .eq('access_token', token)
    .maybeSingle();
  if (!link || new Date(link.access_token_expires_at) <= new Date()) return 'female';
  return link.voice_gender || 'female';
}

async function handler(req, res) {
  if (req.method !== 'GET') {
    res.status(405).json({ error: 'method_not_allowed' });
    return;
  }
  const id = String(req.query.id || '').trim();
  if (!id) {
    res.status(400).json({ error: 'missing_id' });
    return;
  }

  const admin = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
  const { data: secuencia, error } = await admin
    .from('codigos_grabovoi')
    .select('id, codigo, nombre, descripcion, categoria, color, fuente_titulo, fuente_url')
    .eq('id', id)
    .maybeSingle();

  if (error || !secuencia) {
    res.status(404).json({ error: 'not_found' });
    return;
  }

  const vozElegida = await vozDelUsuario(admin, req.headers.authorization);
  const vozSlug = VOCES_VALIDAS[vozElegida] || 'female';

  const tokens = String(secuencia.codigo)
    .split('')
    .filter((c) => (c >= '0' && c <= '9') || c === '_');

  res.status(200).json({
    ...secuencia,
    audio: {
      voz: vozElegida,
      tokens,
      clips: clipsDeVoz(vozSlug),
      gaps_ms: {
        digito: GAP_DIGITOS_MS,
        espacio: SILENCIO_ESPACIO_MS,
        nuevamente: PAUSA_NUEVAMENTE_MS,
      },
    },
  });
}

module.exports = handler;
