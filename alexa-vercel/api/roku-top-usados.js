'use strict';

// Top 10 secuencias más repetidas por el usuario (user_code_history.
// usage_count) para la pantalla "Top ten más usados" del sidebar de
// Roku. Mismo shape que /roku-catalog ({ secuencias: [...] }) para
// reusar SequenceListScreen -- ver endpointUri en
// SequenceListScreen.xml/.brs.

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

  const { data: historial, error: errorHistorial } = await admin
    .from('user_code_history')
    .select('code_id, usage_count')
    .eq('user_id', userId)
    .order('usage_count', { ascending: false })
    .limit(10);

  if (errorHistorial) {
    console.error('roku-top-usados: historial falló', errorHistorial);
    res.status(500).json({ error: 'server_error' });
    return;
  }

  if (!historial || historial.length === 0) {
    res.status(200).json({ secuencias: [] });
    return;
  }

  const ids = historial.map((h) => h.code_id);
  const { data: secuenciasDb, error: errorSecuencias } = await admin
    .from('codigos_grabovoi')
    .select('id, codigo, nombre, descripcion, categoria, color, imagen_url')
    .in('id', ids);

  if (errorSecuencias) {
    console.error('roku-top-usados: secuencias falló', errorSecuencias);
    res.status(500).json({ error: 'server_error' });
    return;
  }

  // .in() no preserva el orden por usage_count -- se reordena aqui
  // siguiendo el orden de "historial" (ya viene ordenado desc).
  const porId = new Map((secuenciasDb || []).map((s) => [s.id, s]));
  const secuencias = ids.map((id) => porId.get(id)).filter(Boolean);

  res.status(200).json({ secuencias });
}

module.exports = handler;
