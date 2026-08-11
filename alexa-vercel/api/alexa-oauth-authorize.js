'use strict';

// Servidor OAuth2 (Authorization Code Grant) propio para el account linking
// del skill de Alexa. Alexa nunca ve la contraseña del usuario: este
// endpoint sirve un formulario de login, valida contra Supabase Auth (el
// mismo usuario/contraseña que ya usa en la app), y si es correcto emite
// un "authorization code" de un solo uso que Alexa intercambia por un
// access_token en alexa-oauth-token (ese se queda en Supabase, ahí no hay
// problema porque solo devuelve JSON).
//
// Migrado desde Supabase Edge Functions a Vercel porque Supabase fuerza
// Content-Type: text/plain + CSP sandbox en cualquier respuesta que no
// sea JSON (política de la plataforma, no un bug de nuestro código) — la
// app de Alexa mostraba el HTML crudo como texto en vez de renderizarlo.

const { createClient } = require('@supabase/supabase-js');

const CLIENT_ID = process.env.ALEXA_OAUTH_CLIENT_ID || '';

// Dominios reales de account linking que Amazon dio en la consola de Alexa
// (NA, EU, Japón). Sin esto, redirect_uri sería un open redirect.
const ALLOWED_REDIRECT_HOSTS = ['pitangui.amazon.com', 'layla.amazon.com', 'alexa.amazon.co.jp'];

function isAllowedRedirectUri(redirectUri) {
  try {
    const parsed = new URL(redirectUri);
    return parsed.protocol === 'https:' && ALLOWED_REDIRECT_HOSTS.includes(parsed.hostname);
  } catch (_e) {
    return false;
  }
}

function escapeHtml(s) {
  return String(s)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function renderForm({ clientId, redirectUri, state, responseType, error }) {
  const errorHtml = error ? `<p style="color:#ff6b6b;margin:0 0 16px;">${escapeHtml(error)}</p>` : '';
  return `<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Conectar ManiGraB con Alexa</title>
<style>
  body { font-family: -apple-system, system-ui, sans-serif; background:#0B132B; color:#fff; display:flex; align-items:center; justify-content:center; min-height:100vh; margin:0; }
  .card { background:#1C2541; border:1px solid rgba(255,215,0,0.3); border-radius:16px; padding:32px; width:100%; max-width:360px; }
  h1 { color:#FFD700; font-size:20px; margin:0 0 8px; }
  p.sub { color:rgba(255,255,255,0.7); font-size:14px; margin:0 0 24px; }
  label { display:block; font-size:13px; color:rgba(255,255,255,0.7); margin-bottom:6px; }
  input { width:100%; box-sizing:border-box; padding:12px; margin-bottom:16px; border-radius:8px; border:1px solid rgba(255,255,255,0.2); background:rgba(255,255,255,0.06); color:#fff; font-size:15px; }
  button { width:100%; padding:14px; border-radius:30px; border:none; background:#FFD700; color:#0B132B; font-weight:700; font-size:15px; cursor:pointer; }
</style>
</head>
<body>
  <div class="card">
    <h1>Conectar ManiGraB con Alexa</h1>
    <p class="sub">Inicia sesión con tu cuenta de ManiGraB para que Alexa pueda repetir tu código del día.</p>
    ${errorHtml}
    <form method="POST">
      <input type="hidden" name="client_id" value="${escapeHtml(clientId)}">
      <input type="hidden" name="redirect_uri" value="${escapeHtml(redirectUri)}">
      <input type="hidden" name="state" value="${escapeHtml(state)}">
      <input type="hidden" name="response_type" value="${escapeHtml(responseType)}">
      <label for="email">Correo</label>
      <input type="email" id="email" name="email" required autocomplete="email">
      <label for="password">Contraseña</label>
      <input type="password" id="password" name="password" required autocomplete="current-password">
      <button type="submit">Conectar</button>
    </form>
  </div>
</body>
</html>`;
}

function randomCode() {
  return (
    require('crypto').randomUUID().replace(/-/g, '') + require('crypto').randomUUID().replace(/-/g, '')
  );
}

function readRawBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', (chunk) => { data += chunk; });
    req.on('end', () => resolve(data));
    req.on('error', reject);
  });
}

async function handler(req, res) {
  const SUPABASE_URL = process.env.SUPABASE_URL;
  const ANON_KEY = process.env.SUPABASE_ANON_KEY;
  const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (req.method === 'GET') {
    const url = new URL(req.url, `https://${req.headers.host}`);
    const clientId = url.searchParams.get('client_id') || '';
    const redirectUri = url.searchParams.get('redirect_uri') || '';
    const state = url.searchParams.get('state') || '';
    const responseType = url.searchParams.get('response_type') || 'code';

    if (!redirectUri || clientId !== CLIENT_ID || !isAllowedRedirectUri(redirectUri)) {
      res.status(400).send('Solicitud de vinculación inválida.');
      return;
    }

    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.status(200).send(renderForm({ clientId, redirectUri, state, responseType }));
    return;
  }

  if (req.method === 'POST') {
    const rawBody = await readRawBody(req);
    const form = new URLSearchParams(rawBody);
    const email = form.get('email') || '';
    const password = form.get('password') || '';
    const clientId = form.get('client_id') || '';
    const redirectUri = form.get('redirect_uri') || '';
    const state = form.get('state') || '';
    const responseType = form.get('response_type') || 'code';

    if (!redirectUri || clientId !== CLIENT_ID || !isAllowedRedirectUri(redirectUri)) {
      res.status(400).send('Solicitud de vinculación inválida.');
      return;
    }

    const anon = createClient(SUPABASE_URL, ANON_KEY);
    const { data, error } = await anon.auth.signInWithPassword({ email, password });

    if (error || !data.user) {
      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      res.status(200).send(
        renderForm({
          clientId,
          redirectUri,
          state,
          responseType,
          error: 'Correo o contraseña incorrectos. Intenta de nuevo.',
        }),
      );
      return;
    }

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
    const code = randomCode();
    const { error: insertError } = await admin.from('alexa_auth_codes').insert({
      code,
      user_id: data.user.id,
      redirect_uri: redirectUri,
    });
    if (insertError) {
      res.status(500).send('Error interno generando el código de autorización.');
      return;
    }

    const redirectTo = new URL(redirectUri);
    redirectTo.searchParams.set('state', state);
    redirectTo.searchParams.set('code', code);

    res.writeHead(302, { Location: redirectTo.toString() });
    res.end();
    return;
  }

  res.status(405).send('Método no permitido');
}

handler.config = { api: { bodyParser: false } };
module.exports = handler;
