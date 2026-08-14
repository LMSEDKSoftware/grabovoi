'use strict';

// Detalle de una secuencia + manifiesto de audio para que BrightScript
// arme la cola de reproducción dígito por dígito, replicando
// NumbersVoiceService exactamente (mismos clips, mismos tiempos). No
// requiere sesión para leer el detalle.
//
// Roku solo usa la voz femenina (decisión de producto: se eliminaron las
// voces male/male 2 del canal). Antes esto leía roku_account_links.
// voice_gender por usuario; ya no hace falta esa consulta ni esa
// independencia de voz por cuenta, así que queda fijo aquí.

const { createClient } = require('@supabase/supabase-js');

const BASE_VOCES = 'https://whtiazgcxdnemrrgjjqf.supabase.co/storage/v1/object/public/roku/voces';
const BASE_VIDEOS_NARRADOS = 'https://whtiazgcxdnemrrgjjqf.supabase.co/storage/v1/object/public/roku/videos_narrados';
const VOZ_SLUG = 'female';

const GAP_DIGITOS_MS = 280;
const SILENCIO_ESPACIO_MS = 100;
const PAUSA_NUEVAMENTE_MS = 1800;

function clipsDeVoz(vozSlug) {
  const base = `${BASE_VOCES}/${vozSlug}`;
  const clips = { espacio: `${base}/espacio.mp3`, nuevamente: `${base}/nuevamente.mp3` };
  for (let d = 0; d <= 9; d++) clips[String(d)] = `${base}/${d}.mp3`;
  return clips;
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
    .select('id, codigo, nombre, descripcion, categoria, color, imagen_url, video_loop_url, fuente_titulo, fuente_url')
    .eq('id', id)
    .maybeSingle();

  if (error || !secuencia) {
    res.status(404).json({ error: 'not_found' });
    return;
  }

  const tokens = String(secuencia.codigo)
    .split('')
    .filter((c) => (c >= '0' && c <= '9') || c === '_');

  res.status(200).json({
    ...secuencia,
    // Video con la voz ya integrada (generado por
    // scripts/generar_video_narrado.py) -- URL predecible por convención,
    // igual que los clips de voz sueltos; puede no existir todavía para
    // esta secuencia (la biblioteca se está narrando por partes). El
    // cliente lo intenta primero y cae al modo dígito-por-dígito con
    // Audio si el Video falla al cargar, sin necesidad de que el server
    // confirme de antemano que el archivo existe.
    video_narrado_url: `${BASE_VIDEOS_NARRADOS}/${VOZ_SLUG}/${secuencia.codigo}.mp4`,
    audio: {
      voz: VOZ_SLUG,
      tokens,
      clips: clipsDeVoz(VOZ_SLUG),
      gaps_ms: {
        digito: GAP_DIGITOS_MS,
        espacio: SILENCIO_ESPACIO_MS,
        nuevamente: PAUSA_NUEVAMENTE_MS,
      },
    },
  });
}

module.exports = handler;
