'use strict';

// Pantalla de inicio de ManiGraB TV: secuencia del día, progreso,
// favoritos, y "continuar" (reutiliza user_code_history, que ya existía
// en el schema pero nadie lo llenaba — ver docs/ROKU_TV_PLAN.md).
// Requiere sesión de Roku (Authorization: Bearer <token> de /roku/login).

const { createClient } = require('@supabase/supabase-js');

async function resolverUsuario(admin, authHeader) {
  if (!authHeader?.startsWith('Bearer ')) return null;
  const token = authHeader.slice('Bearer '.length);
  const { data: link } = await admin
    .from('roku_account_links')
    .select('user_id, voice_gender, access_token_expires_at')
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
    { data: codigoDia },
    { data: progreso },
    { data: rewards },
    { data: favoritos },
    { data: continuar },
  ] = await Promise.all([
    admin.rpc('obtener_codigo_del_dia'),
    admin.from('usuario_progreso').select('dias_consecutivos, total_pilotajes, nivel_energetico').eq('user_id', userId).maybeSingle(),
    admin.from('user_rewards').select('cristales_energia, luz_cuantica').eq('user_id', userId).maybeSingle(),
    admin
      .from('usuario_favoritos')
      .select('codigo_id, codigos_grabovoi(id, codigo, nombre, categoria)')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(12),
    admin
      .from('user_code_history')
      .select('code_id, code_name, usage_count, last_used, total_time_minutes')
      .eq('user_id', userId)
      .order('last_used', { ascending: false })
      .limit(12),
  ]);

  // obtener_codigo_del_dia() solo devuelve codigo+nombre, sin el id de
  // codigos_grabovoi que necesita el reproductor de Roku (/roku-sequence
  // busca por id). Se resuelve con una segunda consulta.
  let secuenciaDelDia = codigoDia?.[0] || null;
  if (secuenciaDelDia) {
    const { data: fila } = await admin
      .from('codigos_grabovoi')
      .select('id')
      .eq('codigo', secuenciaDelDia.codigo)
      .limit(1)
      .maybeSingle();
    if (fila) secuenciaDelDia = { ...secuenciaDelDia, id: fila.id };
  }

  res.status(200).json({
    secuencia_del_dia: secuenciaDelDia,
    progreso: {
      dias_consecutivos: progreso?.dias_consecutivos ?? 0,
      total_pilotajes: progreso?.total_pilotajes ?? 0,
      nivel_energetico: progreso?.nivel_energetico ?? 0,
      cristales_energia: rewards?.cristales_energia ?? 0,
      luz_cuantica: rewards?.luz_cuantica ?? 0,
      voice_gender: link.voice_gender || 'female',
    },
    favoritos: (favoritos || []).map((f) => f.codigos_grabovoi).filter(Boolean),
    continuar: continuar || [],
  });
}

module.exports = handler;
