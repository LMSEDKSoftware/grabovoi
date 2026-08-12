'use strict';

// Login del canal de Roku de ManiGraB. Roku prohíbe explícitamente el
// patrón "código en pantalla, actívalo en tu teléfono" para apps
// públicas (lo llaman "rendezvous", deprecado) — el login tiene que
// pasar enteramente dentro del canal, con el teclado en pantalla
// nativo de Roku. Por eso esto es un simple POST con email+password
// (capturados en BrightScript), no un flujo OAuth como el de Alexa.
// Ver docs/ROKU_TV_PLAN.md.

const { createClient } = require('@supabase/supabase-js');

const ACCESS_TOKEN_TTL_SECONDS = 90 * 24 * 60 * 60; // 90 días, igual que Alexa

function randomToken() {
  return require('crypto').randomUUID().replace(/-/g, '') + require('crypto').randomUUID().replace(/-/g, '');
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

  let body;
  try {
    body = await readJsonBody(req);
  } catch (_e) {
    res.status(400).json({ error: 'invalid_json' });
    return;
  }

  const email = String(body.email || '').trim();
  const password = String(body.password || '');
  if (!email || !password) {
    res.status(400).json({ error: 'missing_credentials', message: 'Correo o contraseña vacíos.' });
    return;
  }

  const anon = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);
  const { data, error } = await anon.auth.signInWithPassword({ email, password });

  if (error || !data.user) {
    res.status(401).json({ error: 'invalid_credentials', message: 'Correo o contraseña incorrectos.' });
    return;
  }

  const admin = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
  const accessToken = randomToken();
  const expiresAt = new Date(Date.now() + ACCESS_TOKEN_TTL_SECONDS * 1000).toISOString();

  const { error: upsertError } = await admin
    .from('roku_account_links')
    .upsert(
      {
        user_id: data.user.id,
        access_token: accessToken,
        access_token_expires_at: expiresAt,
        updated_at: new Date().toISOString(),
      },
      { onConflict: 'user_id' },
    );

  if (upsertError) {
    console.error('roku-login: upsert falló', upsertError);
    res.status(500).json({ error: 'server_error' });
    return;
  }

  res.status(200).json({
    access_token: accessToken,
    expires_in: ACCESS_TOKEN_TTL_SECONDS,
    user_id: data.user.id,
  });
}

module.exports = handler;
