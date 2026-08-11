import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Segundo paso del account linking: Alexa intercambia el "code" que emitió
// alexa-oauth-authorize (o un refresh_token viejo) por un access_token
// opaco de larga duración. Ese token es lo que Alexa manda en
// request.session.user.accessToken en cada llamada al skill
// (alexa-skill), y es como resolvemos qué usuario de ManiGraB está
// hablando. Ver docs/ALEXA_SKILL_PLAN.md.

const CLIENT_ID = Deno.env.get('ALEXA_OAUTH_CLIENT_ID') ?? ''
const CLIENT_SECRET = Deno.env.get('ALEXA_OAUTH_CLIENT_SECRET') ?? ''
// 90 días. Empezamos con 1 hora y estaba mal: Alexa no refrescaba el token
// de forma fiable (se comprobó en vivo — la cuenta seguía "Vinculada" en la
// app de Alexa pero updated_at nunca se movía, así que el skill recibía un
// token caducado y trataba al usuario como si no tuviera cuenta). El
// refresh_token sigue funcionando como respaldo si Alexa decide usarlo;
// esto solo evita depender de que lo haga. Es un token opaco nuestro, no un
// JWT de Supabase, así que su duración la decidimos nosotros.
const ACCESS_TOKEN_TTL_SECONDS = 90 * 24 * 60 * 60 // 90 días
const AUTH_CODE_MAX_AGE_MS = 10 * 60 * 1000 // 10 minutos

function randomToken(): string {
  return crypto.randomUUID().replace(/-/g, '') + crypto.randomUUID().replace(/-/g, '')
}

function extractClientCredentials(req: Request, body: URLSearchParams): { clientId: string; clientSecret: string } {
  const authHeader = req.headers.get('Authorization')
  if (authHeader?.startsWith('Basic ')) {
    try {
      const decoded = atob(authHeader.slice('Basic '.length))
      const idx = decoded.indexOf(':')
      if (idx >= 0) {
        return { clientId: decoded.slice(0, idx), clientSecret: decoded.slice(idx + 1) }
      }
    } catch (_) {
      // sigue al fallback de body params
    }
  }
  return {
    clientId: body.get('client_id') ?? '',
    clientSecret: body.get('client_secret') ?? '',
  }
}

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-store',
      'Pragma': 'no-cache',
    },
  })
}

serve(async (req) => {
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'invalid_request', error_description: 'Método no permitido' }, 405)
  }

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
  const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  const contentType = req.headers.get('Content-Type') ?? ''
  let body: URLSearchParams
  if (contentType.includes('application/json')) {
    const json = await req.json().catch(() => ({}))
    body = new URLSearchParams(Object.entries(json).map(([k, v]) => [k, String(v)]))
  } else {
    body = new URLSearchParams(await req.text())
  }

  const { clientId, clientSecret } = extractClientCredentials(req, body)
  if (clientId !== CLIENT_ID || clientSecret !== CLIENT_SECRET) {
    return jsonResponse({ error: 'invalid_client' }, 401)
  }

  const grantType = body.get('grant_type')

  if (grantType === 'authorization_code') {
    const code = body.get('code') ?? ''
    const { data: authCode, error } = await admin
      .from('alexa_auth_codes')
      .select('code, user_id, redirect_uri, created_at, used')
      .eq('code', code)
      .maybeSingle()

    if (error || !authCode || authCode.used) {
      return jsonResponse({ error: 'invalid_grant', error_description: 'Código inválido o ya usado' }, 400)
    }
    const ageMs = Date.now() - new Date(authCode.created_at).getTime()
    if (ageMs > AUTH_CODE_MAX_AGE_MS) {
      return jsonResponse({ error: 'invalid_grant', error_description: 'Código expirado' }, 400)
    }

    await admin.from('alexa_auth_codes').update({ used: true }).eq('code', code)

    const accessToken = randomToken()
    const refreshToken = randomToken()
    const expiresAt = new Date(Date.now() + ACCESS_TOKEN_TTL_SECONDS * 1000).toISOString()

    const { error: linkError } = await admin.from('alexa_account_links').upsert(
      {
        user_id: authCode.user_id,
        access_token: accessToken,
        refresh_token: refreshToken,
        access_token_expires_at: expiresAt,
        updated_at: new Date().toISOString(),
      },
      { onConflict: 'user_id' },
    )
    if (linkError) {
      return jsonResponse({ error: 'server_error' }, 500)
    }

    return jsonResponse({
      access_token: accessToken,
      token_type: 'bearer',
      expires_in: ACCESS_TOKEN_TTL_SECONDS,
      refresh_token: refreshToken,
    })
  }

  if (grantType === 'refresh_token') {
    const refreshToken = body.get('refresh_token') ?? ''
    const { data: link, error } = await admin
      .from('alexa_account_links')
      .select('user_id, refresh_token')
      .eq('refresh_token', refreshToken)
      .maybeSingle()

    if (error || !link) {
      return jsonResponse({ error: 'invalid_grant', error_description: 'refresh_token inválido' }, 400)
    }

    const accessToken = randomToken()
    const expiresAt = new Date(Date.now() + ACCESS_TOKEN_TTL_SECONDS * 1000).toISOString()

    const { error: updateError } = await admin
      .from('alexa_account_links')
      .update({ access_token: accessToken, access_token_expires_at: expiresAt, updated_at: new Date().toISOString() })
      .eq('refresh_token', refreshToken)
    if (updateError) {
      return jsonResponse({ error: 'server_error' }, 500)
    }

    return jsonResponse({
      access_token: accessToken,
      token_type: 'bearer',
      expires_in: ACCESS_TOKEN_TTL_SECONDS,
      refresh_token: refreshToken,
    })
  }

  return jsonResponse({ error: 'unsupported_grant_type' }, 400)
})
