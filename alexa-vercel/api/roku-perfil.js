'use strict';

// Datos de cuenta + progreso para las pantallas "Perfil" y "Evolución"
// del sidebar de Roku. Un solo endpoint para las dos: comparten casi
// todos los datos (progreso/cristales), cada pantalla en Roku solo
// decide qué campos destacar.

const { createClient } = require('@supabase/supabase-js');

async function resolverUsuario(admin, authHeader) {
  if (!authHeader?.startsWith('Bearer ')) return null;
  const token = authHeader.slice('Bearer '.length);
  const { data: link } = await admin
    .from('roku_account_links')
    .select('user_id, access_token_expires_at')
    .eq('access_token', token)
    .maybeSingle();
  if (!link || new Date(link.access_token_expires_at) <= new Date()) return null;
  return link.user_id;
}

async function handler(req, res) {
  if (req.method !== 'GET') {
    res.status(405).json({ error: 'method_not_allowed' });
    return;
  }

  const admin = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
  const userId = await resolverUsuario(admin, req.headers.authorization);
  if (!userId) {
    res.status(401).json({ error: 'invalid_session' });
    return;
  }

  const [{ data: usuarioAuth }, { data: progreso }, { data: rewards }, { data: estadisticas }] = await Promise.all([
    admin.auth.admin.getUserById(userId),
    admin.from('usuario_progreso').select('dias_consecutivos, total_pilotajes, nivel_energetico').eq('user_id', userId).maybeSingle(),
    admin.from('user_rewards').select('cristales_energia, luz_cuantica').eq('user_id', userId).maybeSingle(),
    // Mismo calculo que la app movil (user_progress_service.dart,
    // sobre user_actions) -- ver
    // supabase/migrations/20260815200000_roku_estadisticas_evolucion.sql.
    admin.rpc('roku_estadisticas_evolucion', { p_user_id: userId }).maybeSingle(),
  ]);

  res.status(200).json({
    email: usuarioAuth?.user?.email ?? null,
    miembro_desde: usuarioAuth?.user?.created_at ?? null,
    progreso: {
      dias_consecutivos: progreso?.dias_consecutivos ?? 0,
      total_pilotajes: progreso?.total_pilotajes ?? 0,
      nivel_energetico: progreso?.nivel_energetico ?? 0,
      cristales_energia: rewards?.cristales_energia ?? 0,
      luz_cuantica: rewards?.luz_cuantica ?? 0,
      total_sesiones: estadisticas?.total_sesiones ?? 0,
      total_minutos: estadisticas?.total_minutos ?? 0,
      secuencias_usadas: estadisticas?.secuencias_usadas ?? 0,
    },
  });
}

module.exports = handler;
