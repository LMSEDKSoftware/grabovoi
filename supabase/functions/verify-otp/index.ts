// deno-lint-ignore-file no-explicit-any
import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

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

  const { email, otp_code, new_password } = await req.json().catch(() => ({}))
  if (!email || !otp_code || !new_password) {
    return new Response(JSON.stringify({ error: 'email, otp_code y new_password requeridos' }), { status: 400, headers: corsHeaders })
  }

  const SUPABASE_URL = Deno.env.get('SB_URL')!
  const SERVICE_ROLE_KEY = Deno.env.get('SB_SERVICE_ROLE_KEY')!
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
    return new Response(JSON.stringify({ error: 'Faltan variables de entorno' }), { status: 500, headers: corsHeaders })
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  // Buscar OTP válido
  const now = new Date().toISOString()
  const { data: rows, error: selErr } = await supabase
    .from('password_reset_otps')
    .select('*')
    .eq('email', email)
    .eq('used', false)
    .gte('expires_at', now)
    .order('created_at', { ascending: false })
    .limit(1)

  if (selErr || !rows || rows.length === 0) {
    return new Response(JSON.stringify({ error: 'OTP inválido o expirado' }), { status: 400, headers: corsHeaders })
  }

  const otpRow = rows[0]
  if (String(otpRow.otp_code) !== String(otp_code)) {
    return new Response(JSON.stringify({ error: 'OTP inválido' }), { status: 400 })
  }

  // Obtener usuario por email
  const { data: users, error: usersErr } = await supabase.auth.admin.listUsers({
    page: 1,
    perPage: 1,
    email
  } as any)
  if (usersErr || !users?.users?.length) {
    return new Response(JSON.stringify({ error: 'Usuario no encontrado' }), { status: 400, headers: corsHeaders })
  }

  const user = users.users[0]

  // Actualizar password usando Admin API
  const { error: updErr } = await supabase.auth.admin.updateUserById(user.id, {
    password: new_password,
  } as any)
  if (updErr) {
    return new Response(JSON.stringify({ error: 'No se pudo actualizar la contraseña' }), { status: 500, headers: corsHeaders })
  }

  // Marcar OTP como usado
  const { error: updOtpErr } = await supabase
    .from('password_reset_otps')
    .update({ used: true })
    .eq('id', otpRow.id)

  if (updOtpErr) {
    // No bloquear por este error, pero reportar
    console.error('No se pudo marcar OTP como usado', updOtpErr)
  }

  return new Response(JSON.stringify({ ok: true }), { status: 200, headers: corsHeaders })
})
