'use strict';

// Se llama cuando el reproductor de Roku termina una secuencia: acredita
// cristales (mismo RPC que usa Alexa) y actualiza user_code_history —
// la tabla de "continuar viendo" que ya existía en el schema pero
// ningún cliente escribía. Ver docs/ROKU_TV_PLAN.md.

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

async function handler(req, res) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'method_not_allowed' });
    return;
  }

  const admin = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
  const userId = await resolverUsuario(admin, req.headers.authorization);
  if (!userId) {
    res.status(401).json({ error: 'invalid_session' });
    return;
  }

  let body;
  try {
    body = await readJsonBody(req);
  } catch (_e) {
    res.status(400).json({ error: 'invalid_json' });
    return;
  }

  const codigoId = String(body.codigo_id || '').trim();
  const codigo = String(body.codigo || '').trim();
  const nombre = body.nombre ? String(body.nombre) : null;
  const categoria = body.categoria ? String(body.categoria) : '';
  const minutos = Number.isFinite(body.minutos) ? body.minutos : 0;
  if (!codigoId || !codigo) {
    res.status(400).json({ error: 'missing_fields' });
    return;
  }

  const { data: recompensa, error: recompensaError } = await admin.rpc('otorgar_recompensa_repeticion', {
    p_user_id: userId,
    p_codigo: codigo,
    p_codigo_nombre: nombre ?? codigo,
    p_origen: 'roku',
  });
  if (recompensaError) {
    console.error('roku-complete: otorgar_recompensa_repeticion falló', recompensaError);
  }

  // user_code_history no tiene upsert por (user_id, code_id) con
  // incremento atómico vía REST, así que se lee y escribe en dos pasos.
  const { data: existente } = await admin
    .from('user_code_history')
    .select('id, usage_count, total_time_minutes')
    .eq('user_id', userId)
    .eq('code_id', codigoId)
    .maybeSingle();

  if (existente) {
    await admin
      .from('user_code_history')
      .update({
        usage_count: (existente.usage_count || 0) + 1,
        total_time_minutes: (existente.total_time_minutes || 0) + minutos,
        last_used: new Date().toISOString(),
        code_name: nombre ?? undefined,
        updated_at: new Date().toISOString(),
      })
      .eq('id', existente.id);
  } else {
    await admin.from('user_code_history').insert({
      user_id: userId,
      code_id: codigoId,
      code_name: nombre ?? codigo,
      usage_count: 1,
      total_time_minutes: minutos,
      last_used: new Date().toISOString(),
    });
  }

  // Mismas "secuencias sincrónicas" que sugiere la app al terminar una
  // sesión (SequenciaActivadaModal -> _getSincronicosForCurrentCode):
  // categorias_sincronicas mapea la categoria de lo que se acaba de
  // completar a hasta N categorias recomendadas (por peso), y de ahi se
  // toman hasta 2 codigos. Sin categoria no hay nada que sugerir.
  let sincronicos = [];
  if (categoria) {
    const { data: catRows } = await admin
      .from('categorias_sincronicas')
      .select('categoria_recomendada')
      .eq('categoria_principal', categoria)
      .order('peso', { ascending: false });

    const categoriasRecomendadas = (catRows || []).map((r) => r.categoria_recomendada);
    if (categoriasRecomendadas.length) {
      const { data: secRows } = await admin
        .from('codigos_grabovoi')
        .select('id, codigo, nombre, categoria')
        .in('categoria', categoriasRecomendadas)
        .limit(2);
      sincronicos = secRows || [];
    }
  }

  res.status(200).json({
    ya_otorgada: recompensa?.ya_otorgada ?? null,
    cristales_ganados: recompensa?.cristales_ganados ?? null,
    dias_consecutivos: recompensa?.dias_consecutivos ?? null,
    sincronicos,
  });
}

module.exports = handler;
