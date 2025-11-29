// deno-lint-ignore-file no-explicit-any
import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Helper function para guardar logs en la base de datos
async function saveLog(
  supabase: any,
  email: string,
  action: string,
  message: string,
  logLevel: 'debug' | 'info' | 'warning' | 'error' = 'info',
  metadata?: Record<string, any>,
  otpId?: string,
  userId?: string,
  errorDetails?: Record<string, any>
) {
  try {
    const logData: any = {
      email,
      function_name: 'verify-otp',
      action,
      message,
      log_level: logLevel,
      metadata: metadata || {},
    }
    
    if (otpId) logData.otp_id = otpId
    if (userId) logData.user_id = userId
    if (errorDetails) logData.error_details = errorDetails
    
    const { error } = await supabase
      .from('otp_transaction_logs')
      .insert(logData)
    
    if (error) {
      console.error('⚠️ Error guardando log en BD:', error)
    }
  } catch (err) {
    console.error('⚠️ Error en función saveLog:', err)
  }
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

  const { email, otp_code } = await req.json().catch(() => ({}))
  const requestEmail = email ? (email as string).toLowerCase().trim() : ''
  
  const SUPABASE_URL = Deno.env.get('SB_URL')!
  const SERVICE_ROLE_KEY = Deno.env.get('SB_SERVICE_ROLE_KEY')!
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
    await saveLog(createClient(SUPABASE_URL, SERVICE_ROLE_KEY), requestEmail || 'unknown', 'config_error', 'Faltan variables de entorno', 'error')
    return new Response(JSON.stringify({ error: 'Faltan variables de entorno' }), { status: 500, headers: corsHeaders })
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)
  
  // Guardar log inicial
  if (requestEmail) {
    await saveLog(supabase, requestEmail, 'otp_verification_requested', `Solicitud de verificación OTP recibida`, 'info', {
      method: req.method,
      url: req.url,
      otp_code_length: otp_code ? String(otp_code).length : 0
    })
  }
  
  if (!email || !otp_code) {
    await saveLog(supabase, requestEmail || 'unknown', 'validation_error', 'Faltan parámetros requeridos', 'error', {
      has_email: !!email,
      has_otp_code: !!otp_code
    })
    return new Response(JSON.stringify({ error: 'email y otp_code requeridos' }), { status: 400, headers: corsHeaders })
  }

  // Buscar OTP válido
  const now = new Date().toISOString()
  await saveLog(supabase, requestEmail, 'otp_lookup_started', `Buscando OTP válido en base de datos`, 'debug', {
    email_search: requestEmail,
    current_time: now
  })
  
  const { data: rows, error: selErr } = await supabase
    .from('password_reset_otps')
    .select('*')
    .eq('email', requestEmail)
    .eq('used', false)
    .gte('expires_at', now)
    .order('created_at', { ascending: false })
    .limit(1)

  if (selErr || !rows || rows.length === 0) {
    await saveLog(supabase, requestEmail, 'otp_not_found', `OTP inválido o expirado`, 'warning', {
      error: selErr?.message,
      rows_found: rows?.length || 0
    }, undefined, undefined, {
      error: selErr?.message || 'No se encontraron OTPs válidos',
      code: selErr?.code
    })
    return new Response(JSON.stringify({ error: 'OTP inválido o expirado' }), { status: 400, headers: corsHeaders })
  }

  const otpRow = rows[0]
  await saveLog(supabase, requestEmail, 'otp_found', `OTP encontrado en base de datos`, 'info', {
    otp_id: otpRow.id,
    expires_at: otpRow.expires_at,
    created_at: otpRow.created_at,
    has_recovery_link: !!otpRow.recovery_link
  }, otpRow.id)
  
  // Verificar que el código corto coincida
  if (String(otpRow.otp_code) !== String(otp_code)) {
    await saveLog(supabase, requestEmail, 'otp_mismatch', `Código OTP no coincide`, 'warning', {
      otp_id: otpRow.id,
      provided_code: String(otp_code).substring(0, 2) + '***',
      expected_code: String(otpRow.otp_code).substring(0, 2) + '***'
    }, otpRow.id)
    return new Response(JSON.stringify({ error: 'OTP incorrecto' }), { status: 400, headers: corsHeaders })
  }
  
  // Verificar que tenemos el recovery_link de Supabase
  if (!otpRow.recovery_link) {
    await saveLog(supabase, requestEmail, 'recovery_link_missing', `Recovery link de Supabase no encontrado en el registro`, 'error', {
      otp_id: otpRow.id
    }, otpRow.id)
    return new Response(JSON.stringify({ error: 'Recovery link no disponible' }), { status: 500, headers: corsHeaders })
  }
  
  await saveLog(supabase, requestEmail, 'otp_verified', `Código OTP verificado correctamente`, 'info', {
    otp_id: otpRow.id,
    recovery_link_length: otpRow.recovery_link.length
  }, otpRow.id)

  // Obtener usuario para tener su ID
  // Nota: listUsers no tiene filtro directo por email, necesitamos listar y buscar
  const { data: users, error: usersErr } = await supabase.auth.admin.listUsers({
    page: 1,
    perPage: 1000, // Aumentar para buscar en más usuarios
  } as any)
  
  let userId: string | undefined = undefined
  if (!usersErr && users?.users?.length) {
    const user = users.users.find((u: any) => u.email?.toLowerCase() === requestEmail)
    if (user) {
      userId = user.id
      await saveLog(supabase, requestEmail, 'user_id_found', `User ID obtenido para sesión de reset`, 'debug', {
        user_id: userId
      }, otpRow.id, userId)
    }
  }
  
  if (!userId) {
    await saveLog(supabase, requestEmail, 'user_id_not_found', `No se encontró user_id para sesión de reset`, 'warning', {
      otp_id: otpRow.id
    }, otpRow.id)
  }

  // Marcar OTP como usado
  const { error: updOtpErr } = await supabase
    .from('password_reset_otps')
    .update({ used: true })
    .eq('id', otpRow.id)

  if (updOtpErr) {
    console.error('⚠️ No se pudo marcar OTP como usado:', updOtpErr)
    await saveLog(supabase, requestEmail, 'otp_mark_used_error', `Error marcando OTP como usado: ${updOtpErr.message}`, 'warning', {
      otp_id: otpRow.id
    }, otpRow.id, {
      error: updOtpErr.message
    })
  } else {
    await saveLog(supabase, requestEmail, 'otp_marked_used', `OTP marcado como usado exitosamente`, 'info', {
      otp_id: otpRow.id
    }, otpRow.id)
  }

  // SOLUCIÓN IVO: Ya NO creamos sesión en password_reset_sessions
  // El OTP marcado como used=true es suficiente como prueba de verificación
  const APP_URL = Deno.env.get('APP_URL') || 'https://manigrab.app'
  
  await saveLog(supabase, requestEmail, 'otp_marked_used_success', `OTP marcado como usado - verificación completada`, 'info', {
    otp_id: otpRow.id,
    user_id: userId
  }, otpRow.id, userId)
  
  await saveLog(supabase, requestEmail, 'continue_url_returned', `Continue URL devuelto al cliente`, 'info', {
    otp_id: otpRow.id,
    continue_url: `${APP_URL}/reset-password.php?email=${encodeURIComponent(requestEmail)}`
  }, otpRow.id)
  
  await saveLog(supabase, requestEmail, 'otp_process_completed', `Proceso de verificación OTP completado exitosamente`, 'info', {
    final_status: 'success',
    otp_id: otpRow.id
  }, otpRow.id)
  
  // Regresar URL a la página PHP donde cambiará la contraseña
  console.log('✅ OTP verificado y marcado como usado, devolviendo continue_url')
  return new Response(JSON.stringify({ 
    ok: true,
    continue_url: `${APP_URL}/reset-password.php?email=${encodeURIComponent(requestEmail)}`,
  }), { status: 200, headers: corsHeaders })
})
