'use strict';

// Lista completa de favoritos del usuario para la pantalla "Mis
// favoritos" del sidebar de Roku. Mismo shape que /roku-catalog
// ({ secuencias: [...] }) para poder reusar SequenceListScreen tal
// cual, solo apuntando a este endpoint en vez de armar la URL desde una
// categoria -- ver endpointUri en SequenceListScreen.xml/.brs.

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

  const { data, error } = await admin
    .from('usuario_favoritos')
    .select('codigos_grabovoi(id, codigo, nombre, descripcion, categoria, color, imagen_url)')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(100);

  if (error) {
    console.error('roku-favoritos: consulta falló', error);
    res.status(500).json({ error: 'server_error' });
    return;
  }

  const secuencias = (data || []).map((f) => f.codigos_grabovoi).filter(Boolean);
  res.status(200).json({ secuencias });
}

module.exports = handler;
