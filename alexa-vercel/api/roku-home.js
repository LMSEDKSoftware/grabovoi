'use strict';

// Pantalla de inicio de ManiGraB TV: secuencia del día, progreso,
// favoritos, y "continuar" (reutiliza user_code_history, que ya existía
// en el schema pero nadie lo llenaba — ver docs/ROKU_TV_PLAN.md).
// Requiere sesión de Roku (Authorization: Bearer <token> de /roku/login).

const { createClient } = require('@supabase/supabase-js');

// Mismo calculo que MensajesDiariosService._obtenerDiaDelAnio() en la
// app movil (lib/services/mensajes_diarios_service.dart), para que Roku
// muestre la misma frase del dia que el celular: dia 1-365 del año.
function diaDelAnio() {
  const ahora = new Date();
  const inicioAnio = new Date(ahora.getFullYear(), 0, 1);
  const dias = Math.floor((ahora - inicioAnio) / 86400000) + 1;
  return Math.min(Math.max(dias, 1), 365);
}

// El Label de Roku no tiene fuente con emoji (glifo en blanco/tofu, ver
// conversacion) -- se recorta cualquier emoji inicial antes de mandarlo,
// el texto en si no se toca.
function sinEmojiInicial(texto) {
  if (!texto) return texto;
  return texto.replace(/^[\p{Extended_Pictographic}\s]+/u, '').trim();
}

async function resolverUsuario(admin, authHeader) {
  if (!authHeader?.startsWith('Bearer ')) return null;
  const token = authHeader.slice('Bearer '.length);
  const { data: link } = await admin
    .from('roku_account_links')
    .select('user_id, access_token_expires_at')
    .eq('access_token', token)
    .maybeSingle();
  if (!link || new Date(link.access_token_expires_at) <= new Date()) return null;
  return link;
}

async function handler(req, res) {
  if (req.method !== 'GET') {
    res.status(405).json({ error: 'method_not_allowed' });
    return;
  }

  const admin = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
  const link = await resolverUsuario(admin, req.headers.authorization);
  if (!link) {
    res.status(401).json({ error: 'invalid_session' });
    return;
  }
  const userId = link.user_id;

  const [
    { data: usuarioAuth },
    { data: codigoDia },
    { data: progreso },
    { data: rewards },
    { data: favoritos },
    { data: continuar },
    { data: mensajeDia },
  ] = await Promise.all([
    // Solo para mostrar en pantalla que cuenta esta conectada. Del perfil
    // de auth se usa unicamente el correo; nada mas de esa ficha sale de
    // aqui.
    admin.auth.admin.getUserById(userId),
    admin.rpc('obtener_codigo_del_dia'),
    admin.from('usuario_progreso').select('dias_consecutivos, total_pilotajes, nivel_energetico').eq('user_id', userId).maybeSingle(),
    admin.from('user_rewards').select('cristales_energia, luz_cuantica').eq('user_id', userId).maybeSingle(),
    admin
      .from('usuario_favoritos')
      .select('codigo_id, codigos_grabovoi(id, codigo, nombre, categoria, color, imagen_url)')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(12),
    admin
      .from('user_code_history')
      .select('code_id, code_name, usage_count, last_used, total_time_minutes')
      .eq('user_id', userId)
      .order('last_used', { ascending: false })
      .limit(12),
    admin.from('mensajes_diarios').select('mensaje').eq('dia', diaDelAnio()).maybeSingle(),
  ]);

  const fraseDelDia = sinEmojiInicial(mensajeDia?.mensaje) || 'La energía fluye contigo. Cada día es más poderoso.';

  // obtener_codigo_del_dia() solo devuelve codigo+nombre, sin el id de
  // codigos_grabovoi que necesita el reproductor de Roku (/roku-sequence
  // busca por id). Se resuelve con una segunda consulta.
  let secuenciaDelDia = codigoDia?.[0] || null;
  if (secuenciaDelDia) {
    const { data: fila } = await admin
      .from('codigos_grabovoi')
      .select('id, color, imagen_url')
      .eq('codigo', secuenciaDelDia.codigo)
      .limit(1)
      .maybeSingle();
    if (fila) secuenciaDelDia = { ...secuenciaDelDia, ...fila };
  }

  // user_code_history.code_id no tiene foreign key declarada hacia
  // codigos_grabovoi (a diferencia de usuario_favoritos.codigo_id, que
  // si la tiene y por eso puede pedirse con el select anidado de arriba)
  // -- se resuelve el codigo/color/imagen a mano con una segunda
  // consulta, para que las tarjetas de "Recientes" se vean igual de
  // completas que las de "Tus favoritas".
  let continuarConDatos = continuar || [];
  if (continuarConDatos.length > 0) {
    const ids = continuarConDatos.map((c) => c.code_id).filter(Boolean);
    const { data: filas } = await admin
      .from('codigos_grabovoi')
      .select('id, codigo, color, imagen_url')
      .in('id', ids);
    const porId = new Map((filas || []).map((f) => [f.id, f]));
    continuarConDatos = continuarConDatos.map((c) => ({ ...c, ...(porId.get(c.code_id) || {}) }));
  }

  res.status(200).json({
    email: usuarioAuth?.user?.email ?? null,
    secuencia_del_dia: secuenciaDelDia,
    frase_del_dia: fraseDelDia,
    progreso: {
      dias_consecutivos: progreso?.dias_consecutivos ?? 0,
      total_pilotajes: progreso?.total_pilotajes ?? 0,
      nivel_energetico: progreso?.nivel_energetico ?? 0,
      cristales_energia: rewards?.cristales_energia ?? 0,
      luz_cuantica: rewards?.luz_cuantica ?? 0,
    },
    favoritos: (favoritos || []).map((f) => f.codigos_grabovoi).filter(Boolean),
    continuar: continuarConDatos,
  });
}

module.exports = handler;
