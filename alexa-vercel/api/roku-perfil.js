'use strict';

// "Lo mío" de ManiGraB TV: perfil, progreso, rutinas guardadas y cerrar
// sesión. Todo lo que pertenece a la cuenta del usuario y ninguna otra
// pantalla comparte.
//
// Van juntos en un archivo porque el plan Hobby de Vercel solo admite 12
// funciones por despliegue y ya estamos en el tope; se separan por método
// y por parámetro, no por archivo:
//
//   GET                      -> perfil + progreso (pantallas Perfil y Evolución)
//   GET  ?rutinas=1          -> mis rutinas, con cuántas secuencias tiene cada una
//   GET  ?rutina=<uuid>      -> una rutina con sus secuencias en orden
//   POST {action:"logout"}   -> cierra ESTA sesión
//   POST {action:"rutina_crear",  nombre, codigo_ids}
//   POST {action:"rutina_agregar", id, codigo_ids}   añade al final
//   POST {action:"rutina_borrar", id}

const { createClient } = require('@supabase/supabase-js');

const MAX_ITEMS_RUTINA = 30;

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

function tokenDe(req) {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) return null;
  return authHeader.slice('Bearer '.length);
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
  return link.user_id;
}

// Hasta ahora "Cerrar sesión" solo borraba el token del registro del
// propio Roku: la fila seguía viva y el token seguía sirviendo los 90
// días completos. Si el aparato se vendía o se devolvía, esa sesión se
// iba con él.
async function cerrarSesion(req, res, admin) {
  const token = tokenDe(req);
  if (!token) {
    res.status(401).json({ error: 'invalid_session' });
    return;
  }

  // Se borra por token, no por user_id: así una TV solo puede cerrar su
  // propia sesión, nunca la de otro aparato de la misma cuenta.
  const { error } = await admin
    .from('roku_account_links')
    .delete()
    .eq('access_token', token);

  if (error) {
    console.error('roku-perfil: no se pudo borrar el vínculo', error);
    res.status(500).json({ error: 'server_error' });
    return;
  }

  // 200 aunque el token ya no existiera: para el canal el resultado es el
  // mismo (esta sesión ya no vale) y no hay nada que reintentar.
  res.status(200).json({ ok: true });
}

async function listarRutinas(res, admin, userId) {
  const { data, error } = await admin
    .from('rutinas')
    .select('id, nombre, created_at, rutina_items(count)')
    .eq('user_id', userId)
    .order('created_at', { ascending: false });

  if (error) {
    console.error('roku-perfil: listar rutinas falló', error);
    res.status(500).json({ error: 'server_error' });
    return;
  }

  res.status(200).json({
    rutinas: (data || []).map((r) => ({
      id: r.id,
      nombre: r.nombre,
      total: r.rutina_items?.[0]?.count ?? 0,
    })),
  });
}

async function detalleRutina(res, admin, userId, rutinaId) {
  // El filtro por user_id es lo que impide que un id ajeno devuelva la
  // rutina de otra cuenta (esta ruta usa service_role, así que las
  // políticas RLS de la tabla no aplican aquí).
  const { data: rutina, error: errorRutina } = await admin
    .from('rutinas')
    .select('id, nombre')
    .eq('id', rutinaId)
    .eq('user_id', userId)
    .maybeSingle();

  if (errorRutina) {
    console.error('roku-perfil: detalle de rutina falló', errorRutina);
    res.status(500).json({ error: 'server_error' });
    return;
  }
  if (!rutina) {
    res.status(404).json({ error: 'not_found' });
    return;
  }

  const { data: items, error: errorItems } = await admin
    .from('rutina_items')
    .select('orden, codigos_grabovoi(id, codigo, nombre, categoria, color, imagen_url)')
    .eq('rutina_id', rutinaId)
    .order('orden', { ascending: true });

  if (errorItems) {
    console.error('roku-perfil: items de rutina falló', errorItems);
    res.status(500).json({ error: 'server_error' });
    return;
  }

  res.status(200).json({
    id: rutina.id,
    nombre: rutina.nombre,
    secuencias: (items || []).map((i) => i.codigos_grabovoi).filter(Boolean),
  });
}

async function crearRutina(res, admin, userId, body) {
  const nombre = String(body.nombre || '').trim().slice(0, 80);
  const codigoIds = Array.isArray(body.codigo_ids) ? body.codigo_ids : [];

  if (!nombre) {
    res.status(400).json({ error: 'missing_nombre', message: 'Ponle un nombre a tu rutina.' });
    return;
  }
  if (codigoIds.length === 0) {
    res.status(400).json({ error: 'empty', message: 'Una rutina necesita al menos una secuencia.' });
    return;
  }

  // Se recorta en vez de rechazar: el usuario está armando esto con un
  // control remoto y no tiene por qué pelearse con un límite.
  const ids = codigoIds.slice(0, MAX_ITEMS_RUTINA).map(String);

  const { data: rutina, error } = await admin
    .from('rutinas')
    .insert({ user_id: userId, nombre })
    .select('id, nombre')
    .single();

  if (error || !rutina) {
    console.error('roku-perfil: crear rutina falló', error);
    res.status(500).json({ error: 'server_error' });
    return;
  }

  const filas = ids.map((codigoId, i) => ({
    rutina_id: rutina.id,
    codigo_id: codigoId,
    orden: i,
  }));

  const { error: errorItems } = await admin.from('rutina_items').insert(filas);

  if (errorItems) {
    // Sin los items la rutina queda vacía y sin sentido: se deshace para
    // no dejar basura en la lista del usuario.
    console.error('roku-perfil: items de rutina nueva fallaron, deshaciendo', errorItems);
    await admin.from('rutinas').delete().eq('id', rutina.id);
    res.status(500).json({ error: 'server_error' });
    return;
  }

  res.status(200).json({ id: rutina.id, nombre: rutina.nombre, total: ids.length });
}

// Agregar secuencias a una combinación que ya existe. Se añaden al final,
// respetando el orden que ya tenía: una combinación es una secuencia de
// pasos, no un conjunto, y reordenarla al vuelo cambiaría lo que el
// usuario armó.
async function agregarARutina(res, admin, userId, body) {
  const rutinaId = String(body.id || '').trim();
  const codigoIds = Array.isArray(body.codigo_ids) ? body.codigo_ids.map(String) : [];

  if (!rutinaId) {
    res.status(400).json({ error: 'missing_id' });
    return;
  }
  if (codigoIds.length === 0) {
    res.status(400).json({ error: 'empty', message: 'No elegiste ninguna secuencia.' });
    return;
  }

  // El filtro por user_id es lo que impide agregar a una combinación
  // ajena: esta ruta usa service_role y las políticas RLS no aplican.
  const { data: rutina, error: errorRutina } = await admin
    .from('rutinas')
    .select('id, nombre')
    .eq('id', rutinaId)
    .eq('user_id', userId)
    .maybeSingle();

  if (errorRutina) {
    console.error('roku-perfil: buscar rutina falló', errorRutina);
    res.status(500).json({ error: 'server_error' });
    return;
  }
  if (!rutina) {
    res.status(404).json({ error: 'not_found' });
    return;
  }

  const { data: actuales, error: errorItems } = await admin
    .from('rutina_items')
    .select('codigo_id, orden')
    .eq('rutina_id', rutinaId)
    .order('orden', { ascending: false });

  if (errorItems) {
    console.error('roku-perfil: leer items falló', errorItems);
    res.status(500).json({ error: 'server_error' });
    return;
  }

  const yaEstan = new Set((actuales || []).map((i) => i.codigo_id));
  const siguienteOrden = (actuales || []).length ? (actuales[0].orden ?? 0) + 1 : 0;
  const espacio = Math.max(0, MAX_ITEMS_RUTINA - (actuales || []).length);

  // Se ignoran en silencio las que ya estaban: el usuario las marcó sin
  // acordarse, y fallar por eso sería castigarlo por algo irrelevante.
  const nuevas = codigoIds.filter((id) => !yaEstan.has(id)).slice(0, espacio);

  if (nuevas.length === 0) {
    res.status(200).json({
      id: rutina.id,
      nombre: rutina.nombre,
      agregadas: 0,
      total: (actuales || []).length,
      lleno: espacio === 0,
    });
    return;
  }

  const filas = nuevas.map((codigoId, i) => ({
    rutina_id: rutinaId,
    codigo_id: codigoId,
    orden: siguienteOrden + i,
  }));

  const { error: errorInsert } = await admin.from('rutina_items').insert(filas);
  if (errorInsert) {
    console.error('roku-perfil: agregar items falló', errorInsert);
    res.status(500).json({ error: 'server_error' });
    return;
  }

  res.status(200).json({
    id: rutina.id,
    nombre: rutina.nombre,
    agregadas: nuevas.length,
    total: (actuales || []).length + nuevas.length,
    lleno: false,
  });
}

async function borrarRutina(res, admin, userId, body) {
  const id = String(body.id || '').trim();
  if (!id) {
    res.status(400).json({ error: 'missing_id' });
    return;
  }

  // rutina_items se va sola por el ON DELETE CASCADE de la migración.
  const { error } = await admin
    .from('rutinas')
    .delete()
    .eq('id', id)
    .eq('user_id', userId);

  if (error) {
    console.error('roku-perfil: borrar rutina falló', error);
    res.status(500).json({ error: 'server_error' });
    return;
  }

  res.status(200).json({ ok: true });
}

async function handler(req, res) {
  const admin = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

  if (req.method === 'POST') {
    let body;
    try {
      body = await readJsonBody(req);
    } catch (_e) {
      res.status(400).json({ error: 'invalid_json' });
      return;
    }

    const action = String(body.action || '').trim();

    // Cerrar sesión es el único que no necesita resolver al usuario: le
    // basta el token, y de hecho tiene que funcionar aunque el vínculo ya
    // esté medio roto.
    if (action === 'logout') {
      await cerrarSesion(req, res, admin);
      return;
    }

    const userId = await resolverUsuario(admin, req.headers.authorization);
    if (!userId) {
      res.status(401).json({ error: 'invalid_session' });
      return;
    }

    if (action === 'rutina_crear') {
      await crearRutina(res, admin, userId, body);
    } else if (action === 'rutina_agregar') {
      await agregarARutina(res, admin, userId, body);
    } else if (action === 'rutina_borrar') {
      await borrarRutina(res, admin, userId, body);
    } else {
      res.status(400).json({ error: 'invalid_action' });
    }
    return;
  }

  if (req.method !== 'GET') {
    res.status(405).json({ error: 'method_not_allowed' });
    return;
  }

  const userId = await resolverUsuario(admin, req.headers.authorization);
  if (!userId) {
    res.status(401).json({ error: 'invalid_session' });
    return;
  }

  if (String(req.query.rutinas || '') === '1') {
    await listarRutinas(res, admin, userId);
    return;
  }

  const rutinaId = String(req.query.rutina || '').trim();
  if (rutinaId) {
    await detalleRutina(res, admin, userId, rutinaId);
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
