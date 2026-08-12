'use strict';

// Cambia la voz exclusiva de ManiGraB TV (roku_account_links.voice_gender).
// Nunca toca user_rewards — independiente de la app/Alexa a propósito.

const { createClient } = require('@supabase/supabase-js');

const VOCES_VALIDAS = ['female', 'male', 'male 2'];

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

  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'invalid_session' });
    return;
  }
  const token = authHeader.slice('Bearer '.length);

  let body;
  try {
    body = await readJsonBody(req);
  } catch (_e) {
    res.status(400).json({ error: 'invalid_json' });
    return;
  }

  const voz = String(body.voz || '');
  if (!VOCES_VALIDAS.includes(voz)) {
    res.status(400).json({ error: 'invalid_voice' });
    return;
  }

  const admin = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
  const { data: link } = await admin
    .from('roku_account_links')
    .select('user_id, access_token_expires_at')
    .eq('access_token', token)
    .maybeSingle();

  if (!link || new Date(link.access_token_expires_at) <= new Date()) {
    res.status(401).json({ error: 'invalid_session' });
    return;
  }

  const { error } = await admin
    .from('roku_account_links')
    .update({ voice_gender: voz, updated_at: new Date().toISOString() })
    .eq('user_id', link.user_id);

  if (error) {
    console.error('roku-voice: update falló', error);
    res.status(500).json({ error: 'server_error' });
    return;
  }

  res.status(200).json({ voz });
}

module.exports = handler;
