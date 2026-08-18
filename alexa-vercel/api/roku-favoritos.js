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

// Marcar favoritos desde la TV. Hasta ahora el canal solo LEÍA la lista:
// había que ir al celular a marcar y volver a la televisión, que es justo
// lo que rompe el flujo cuando estás armando una combinación.
//
// Ojo con la llave: usuario_favoritos.codigo_id referencia
// codigos_grabovoi.CODIGO (texto), no el id. Mandar el uuid aquí falla
// con un error de tipo.
async function agregarFavoritos(req, res, admin, userId, body) {
  const codigos = Array.isArray(body.codigos)
    ? body.codigos.map(String).filter(Boolean).slice(0, 30)
    : [];
  if (!codigos.length) {
    res.status(400).json({ error: 'empty' });
    return;
  }

  const { data: existentes } = await admin
    .from('usuario_favoritos')
    .select('codigo_id')
    .eq('user_id', userId)
    .in('codigo_id', codigos);

  const yaEstan = new Set((existentes || []).map((f) => f.codigo_id));
  const nuevos = codigos.filter((c) => !yaEstan.has(c));

  if (!nuevos.length) {
    res.status(200).json({ agregados: 0, ya_estaban: codigos.length });
    return;
  }

  const { error } = await admin
    .from('usuario_favoritos')
    .insert(nuevos.map((codigo) => ({ user_id: userId, codigo_id: codigo })));

  if (error) {
    console.error('roku-favoritos: insertar falló', error);
    res.status(500).json({ error: 'server_error' });
    return;
  }

  res.status(200).json({ agregados: nuevos.length, ya_estaban: codigos.length - nuevos.length });
}

async function handler(req, res) {
  const admin = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
  const userId = await resolverUsuario(admin, req.headers.authorization);
  if (!userId) {
    res.status(401).json({ error: 'invalid_session' });
    return;
  }

  if (req.method === 'POST') {
    let body;
    try {
      body = await readJsonBody(req);
    } catch (_e) {
      res.status(400).json({ error: 'invalid_json' });
      return;
    }
    await agregarFavoritos(req, res, admin, userId, body);
    return;
  }

  if (req.method !== 'GET') {
    res.status(405).json({ error: 'method_not_allowed' });
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
