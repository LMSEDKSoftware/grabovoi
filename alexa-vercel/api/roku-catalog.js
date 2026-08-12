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
  const limit = Math.min(Number.parseInt(req.query.limit, 10) || 50, 200);
  const offset = Math.max(Number.parseInt(req.query.offset, 10) || 0, 0);

  if (!q && !categoria) {
    // Sin filtros: devolver la lista de categorías con conteo, para la
    // pantalla de "explorar por categoría".
    const { data, error } = await admin
      .from('codigos_grabovoi')
      .select('categoria', { count: 'exact', head: false });
    if (error) {
      console.error('roku-catalog: categorias falló', error);
      res.status(500).json({ error: 'server_error' });
      return;
    }
    const conteo = {};
    for (const row of data) {
      const c = row.categoria || 'Otros';
      conteo[c] = (conteo[c] || 0) + 1;
    }
    const categorias = Object.entries(conteo)
      .map(([nombre, total]) => ({ nombre, total }))
      .sort((a, b) => b.total - a.total);
    res.status(200).json({ categorias });
    return;
  }

  let query = admin
    .from('codigos_grabovoi')
    .select('id, codigo, nombre, descripcion, categoria, color')
    .not('nombre', 'is', null)
    .order('nombre', { ascending: true })
    .range(offset, offset + limit - 1);

  if (categoria) query = query.eq('categoria', categoria);
  if (q) query = query.ilike('nombre', `%${q}%`);

  const { data, error } = await query;
  if (error) {
    console.error('roku-catalog: búsqueda falló', error);
    res.status(500).json({ error: 'server_error' });
    return;
  }

  res.status(200).json({ secuencias: data });
}

module.exports = handler;
