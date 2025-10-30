// deno-lint-ignore-file no-explicit-any
import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

function generateOtp(length = 6): string {
  const min = Math.pow(10, length - 1)
  const max = Math.pow(10, length) - 1
  return Math.floor(Math.random() * (max - min + 1) + min).toString()
}

Deno.serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Content-Type': 'application/json',
  }

  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders })
  }
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers: corsHeaders })
  }

  const { email } = await req.json().catch(() => ({}))
  if (!email || typeof email !== 'string') {
    return new Response(JSON.stringify({ error: 'email requerido' }), { status: 400, headers: corsHeaders })
  }

  const SUPABASE_URL = Deno.env.get('SB_URL')!
  const SERVICE_ROLE_KEY = Deno.env.get('SB_SERVICE_ROLE_KEY')!
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
    return new Response(JSON.stringify({ error: 'Faltan variables de entorno' }), { status: 500, headers: corsHeaders })
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  // Verificar que el usuario exista en auth
  const { data: users, error: usersErr } = await supabase.auth.admin.listUsers({
    page: 1,
    perPage: 1,
    email
  } as any)
  if (usersErr) {
    return new Response(JSON.stringify({ error: 'Error validando usuario' }), { status: 500, headers: corsHeaders })
  }
  const userExists = users?.users?.some((u: any) => u.email?.toLowerCase() === email.toLowerCase())
  if (!userExists) {
    // Para no filtrar emails válidos, responder 200 siempre
    return new Response(JSON.stringify({ ok: true }), { status: 200, headers: corsHeaders })
  }

  const otp = generateOtp(6)
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString() // 10 min

  const { error: insErr } = await supabase.from('password_reset_otps').insert({
    email,
    otp_code: otp,
    expires_at: expiresAt,
  })
  if (insErr) {
    return new Response(JSON.stringify({ error: 'Error guardando OTP' }), { status: 500, headers: corsHeaders })
  }

  // En producción: aquí integrar envío por email/SMS (Twilio, Resend, etc.)
  // Por ahora, retornamos el OTP sólo en desarrollo
  const isProd = (Deno.env.get('ENV') || '').toLowerCase() === 'production'
  return new Response(JSON.stringify({ ok: true, dev_otp: isProd ? undefined : otp }), { status: 200, headers: corsHeaders })
})
