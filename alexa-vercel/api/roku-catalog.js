'use strict';

// Catálogo para ManiGraB TV: categorías y búsqueda sobre codigos_grabovoi
// (biblioteca abierta). No requiere sesión — es lectura pública, igual
// que en la app. A diferencia del filtro por voz de Alexa (que excluye
// nombres clínicos porque Alexa los LEE en voz alta sin contexto), aquí
// Roku muestra el nombre como texto en pantalla con su descripción,
// igual que la app — no hace falta filtrar nada, sería inconsistente
// con lo que el usuario ya ve en el móvil.

const { createClient } = require('@supabase/supabase-js');

async function handler(req, res) {
  if (req.method !== 'GET') {
    res.status(405).json({ error: 'method_not_allowed' });
    return;
  }

  const admin = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
  const q = String(req.query.q || '').trim();
  const categoria = String(req.query.categoria || '').trim();
  // Supabase/PostgREST tiene un tope por defecto de 1000 filas por
  // consulta (el proyecto ya tiene 1191 en codigos_grabovoi) -- 1000
  // cubre con margen la categoria mas grande de hoy (Salud, 627), y no
  // tiene sentido pedir mas de lo que el propio Supabase va a devolver.
  const limit = Math.min(Number.parseInt(req.query.limit, 10) || 50, 1000);
  const offset = Math.max(Number.parseInt(req.query.offset, 10) || 0, 0);

  if (!q && !categoria) {
    // Sin filtros: lista de categorias con conteo, para "explorar por
    // categoria". Antes esto traia TODAS las filas de codigos_grabovoi
    // al cliente y contaba por categoria en JS -- con el tope de 1000
    // filas de Supabase y ya 1191 filas en la tabla, el conteo salia mal
    // para TODAS las categorias (ej. "Salud: 504" en vez de 627, bug
    // reportado). roku_categorias_resumen() agrega con GROUP BY del
    // lado del servidor, exacto sin importar cuantas filas tenga la
    // tabla -- ver supabase/migrations/20260815090000_roku_categorias_resumen.sql.
    const { data, error } = await admin.rpc('roku_categorias_resumen');
    if (error) {
      console.error('roku-catalog: categorias falló', error);
      res.status(500).json({ error: 'server_error' });
      return;
    }
    const categorias = (data || []).map((row) => ({
      nombre: row.categoria,
      total: row.total,
      color: row.color || '#FFD700',
      imagen_url: row.imagen_url || null,
    }));
    res.status(200).json({ categorias });
    return;
  }

  let query = admin
    .from('codigos_grabovoi')
    .select('id, codigo, nombre, descripcion, categoria, color, imagen_url')
    .not('nombre', 'is', null)
    .order('nombre', { ascending: true })
    .range(offset, offset + limit - 1);

  if (categoria) query = query.eq('categoria', categoria);
  if (q) {
    // Mismos 3 campos que busca la app (supabase_service.dart) para que
    // Roku encuentre lo mismo que el celular. Se quitan "," "(" ")" del
    // termino: son caracteres con significado especial en la sintaxis de
    // filtros de PostgREST y romperian el .or() si vinieran en la
    // busqueda del usuario.
    const termino = q.replace(/[,()]/g, ' ').trim();
    query = query.or(`nombre.ilike.%${termino}%,descripcion.ilike.%${termino}%,codigo.ilike.%${termino}%`);
  }

  const { data, error } = await query;
  if (error) {
    console.error('roku-catalog: búsqueda falló', error);
    res.status(500).json({ error: 'server_error' });
    return;
  }

  res.status(200).json({ secuencias: data });
}

module.exports = handler;
