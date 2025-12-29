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

  const { email, otp_code, new_password } = await req.json().catch(() => ({}))
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
      otp_code_length: otp_code ? String(otp_code).length : 0,
      new_password_length: new_password ? String(new_password).length : 0
    })
  }
  
  if (!email || !otp_code || !new_password) {
    await saveLog(supabase, requestEmail || 'unknown', 'validation_error', 'Faltan parámetros requeridos', 'error', {
      has_email: !!email,
      has_otp_code: !!otp_code,
      has_new_password: !!new_password
    })
    return new Response(JSON.stringify({ error: 'email, otp_code y new_password requeridos' }), { status: 400, headers: corsHeaders })
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
    has_recovery_token: !!otpRow.recovery_token
  }, otpRow.id)
  
  // Verificar que el código corto coincida
  if (String(otpRow.otp_code) !== String(otp_code)) {
    await saveLog(supabase, requestEmail, 'otp_mismatch', `Código OTP no coincide`, 'warning', {
      otp_id: otpRow.id,
      provided_code: String(otp_code).substring(0, 2) + '***',
      expected_code: String(otpRow.otp_code).substring(0, 2) + '***'
    }, otpRow.id)
    return new Response(JSON.stringify({ error: 'OTP inválido' }), { status: 400, headers: corsHeaders })
  }
  
  // Verificar que tenemos el token de recuperación de Supabase
  if (!otpRow.recovery_token) {
    await saveLog(supabase, requestEmail, 'recovery_token_missing', `Token de recuperación de Supabase no encontrado en el registro`, 'error', {
      otp_id: otpRow.id
    }, otpRow.id)
    return new Response(JSON.stringify({ error: 'Token de recuperación no encontrado. Solicita un nuevo código.' }), { status: 400, headers: corsHeaders })
  }
  
  const recoveryToken = otpRow.recovery_token
  
  await saveLog(supabase, requestEmail, 'otp_verified', `Código OTP verificado correctamente, usando token de Supabase`, 'info', {
    otp_id: otpRow.id,
    recovery_token_length: recoveryToken.length
  }, otpRow.id)

  // Obtener usuario por email
  await saveLog(supabase, requestEmail, 'user_lookup_started', `Buscando usuario en auth`, 'debug', {
    email: requestEmail
  }, otpRow.id)
  
  const { data: users, error: usersErr } = await supabase.auth.admin.listUsers({
    page: 1,
    perPage: 1,
    email: requestEmail
  } as any)
  
  if (usersErr || !users?.users?.length) {
    await saveLog(supabase, requestEmail, 'user_not_found', `Usuario no encontrado en auth`, 'error', {}, otpRow.id, undefined, {
      error: usersErr?.message || 'Usuario no encontrado',
      code: usersErr?.code
    })
    return new Response(JSON.stringify({ error: 'Usuario no encontrado' }), { status: 400, headers: corsHeaders })
  }

  const user = users.users[0]
  
  await saveLog(supabase, requestEmail, 'user_found', `Usuario encontrado en auth`, 'info', {
    user_id: user.id,
    email: user.email
  }, otpRow.id, user.id)
  
  console.log(`🔐 Código verificado correctamente para usuario: ${user.id} (${user.email})`)
  console.log(`   Nueva contraseña recibida: ${new_password.length} caracteres`)
  console.log(`   Token de Supabase disponible: ${recoveryToken.substring(0, 20)}...`)
  
  // NUEVA ESTRATEGIA: Usar el recovery token para crear sesión y luego updateUser()
  // Este es el método que Supabase espera para tokens de recuperación
  console.log('🔑 Intentando método alternativo: Usar recovery token para sesión...')
  await saveLog(supabase, requestEmail, 'password_update_started', `Iniciando actualización usando recovery token`, 'info', {
    user_id: user.id,
    password_length: String(new_password).length,
    method: 'Recovery token -> Session -> updateUser()'
  }, otpRow.id, user.id)
  
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY') || Deno.env.get('SB_ANON_KEY') || ''
  let updateSuccess = false
  let lastError: any = null
  
  // INTENTO 1: Usar recovery token directamente en exchangeCodeForSession (puede que funcione si lo hacemos correctamente)
  try {
    const tempSupabase = createClient(SUPABASE_URL, anonKey)
    
    // Construir el tipo correcto para el exchange
    // El recovery token necesita ser usado con el tipo correcto
    const exchangeResponse = await tempSupabase.auth.exchangeCodeForSession({
      auth_code: recoveryToken,
      type: 'recovery',
    } as any)
    
    if (!exchangeResponse.error && exchangeResponse.data.session) {
      console.log('✅ Sesión creada exitosamente con recovery token')
      
      // Ahora actualizar usando updateUser() desde la sesión
      const updateResponse = await tempSupabase.auth.updateUser({
        password: new_password,
      })
      
      if (!updateResponse.error && updateResponse.data.user) {
        console.log('✅ Contraseña actualizada exitosamente usando updateUser()')
        await saveLog(supabase, requestEmail, 'password_updated', `Contraseña actualizada usando recovery token -> session -> updateUser()`, 'info', {
          user_id: user.id,
          method: 'Recovery token -> updateUser()',
          updated_user_id: updateResponse.data.user.id
        }, otpRow.id, user.id)
        
        // Confirmar email también
        await supabase.auth.admin.updateUserById(user.id, {
          email_confirm: true,
        } as any)
        
        await tempSupabase.auth.signOut()
        updateSuccess = true
      } else {
        lastError = updateResponse.error
        await tempSupabase.auth.signOut()
      }
    } else {
      lastError = exchangeResponse.error
    }
  } catch (exchangeErr: any) {
    console.log('⚠️ Método 1 falló, intentando método alternativo...')
    lastError = exchangeErr
  }
  
  // INTENTO 2: Usar API REST directa de Supabase (bypass del SDK)
  if (!updateSuccess) {
    console.log('🔑 Intentando método alternativo: API REST directa de Supabase...')
    
    try {
      const authUrl = `${SUPABASE_URL}/auth/v1/admin/users/${user.id}`
      console.log(`   📡 Llamando: PUT ${authUrl}`)
      
      const restResponse = await fetch(authUrl, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
          'apikey': SERVICE_ROLE_KEY,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          password: new_password,
          email_confirm: true,
        }),
      })
      
      const restData = await restResponse.json()
      
      if (restResponse.ok) {
        console.log('✅ Contraseña actualizada usando API REST directa')
        await saveLog(supabase, requestEmail, 'password_updated', `Contraseña actualizada usando API REST directa`, 'info', {
          user_id: user.id,
          method: 'API REST directa (PUT /auth/v1/admin/users/{id})',
          updated_user_id: user.id
        }, otpRow.id, user.id)
        updateSuccess = true
      } else {
        console.error('❌ Error en API REST:', restData)
        lastError = restData
      }
    } catch (restErr: any) {
      console.error('❌ Error en llamada REST:', restErr)
      lastError = restErr
    }
  }
  
  // INTENTO 3: Como último recurso, usar admin.updateUserById() del SDK
  if (!updateSuccess) {
    console.log('🔑 Intentando método final: admin.updateUserById() del SDK...')
    
    const updateResult = await supabase.auth.admin.updateUserById(user.id, {
      password: new_password,
      email_confirm: true,
    } as any)
    
    if (!updateResult.error) {
      console.log('✅ Contraseña actualizada usando admin.updateUserById() del SDK')
      await saveLog(supabase, requestEmail, 'password_updated', `Contraseña actualizada usando admin.updateUserById() del SDK`, 'info', {
        user_id: user.id,
        method: 'admin.updateUserById (SDK fallback)',
        updated_user_id: updateResult.data?.user?.id || user.id
      }, otpRow.id, user.id)
      updateSuccess = true
    } else {
      lastError = updateResult.error
    }
  }
  
  if (!updateSuccess) {
    console.error('❌ Error actualizando contraseña con ambos métodos:', lastError)
    await saveLog(supabase, requestEmail, 'password_update_error', `Error actualizando contraseña: ${lastError?.message}`, 'error', {
      user_id: user.id,
      method: 'Both methods failed'
    }, otpRow.id, user.id, {
      error: lastError?.message,
      status: lastError?.status
    })
    return new Response(JSON.stringify({ 
      error: 'No se pudo actualizar la contraseña',
      details: lastError?.message || 'Error desconocido'
    }), { status: 500, headers: corsHeaders })
  }
  
  // Esperar un momento para asegurar propagación de cambios
  await new Promise(resolve => setTimeout(resolve, 1500))
  
  // PASO 3: Verificar que la contraseña funciona haciendo login
  console.log('🔐 Verificando que la nueva contraseña funciona (intentando login)...')
  await saveLog(supabase, requestEmail, 'password_verification_started', `Iniciando verificación de contraseña con login`, 'debug', {
    user_id: user.id
  }, otpRow.id, user.id)
  
  try {
    // Crear un cliente nuevo sin autenticación para probar el login
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY') || Deno.env.get('SB_ANON_KEY') || ''
    const testSupabase = createClient(SUPABASE_URL, anonKey)
    const testLogin = await testSupabase.auth.signInWithPassword({
      email: requestEmail,
      password: new_password,
    })
    
    if (testLogin.error || !testLogin.data.session) {
      console.error('⚠️ ADVERTENCIA: La verificación de contraseña falló')
      console.error('   Error:', testLogin.error?.message)
      console.error('   Status:', testLogin.error?.status)
      await saveLog(supabase, requestEmail, 'password_verification_failed', `La nueva contraseña NO funciona para login`, 'error', {
        user_id: user.id,
        login_error_message: testLogin.error?.message,
        login_error_status: testLogin.error?.status
      }, otpRow.id, user.id, {
        error: testLogin.error?.message,
        status: testLogin.error?.status,
        code: testLogin.error?.code
      })
    } else {
      console.log('✅ Verificación exitosa: La contraseña funciona correctamente')
      await saveLog(supabase, requestEmail, 'password_verification_success', `La nueva contraseña funciona correctamente para login`, 'info', {
        user_id: user.id,
        session_created: true,
        session_user_id: testLogin.data.session.user.id
      }, otpRow.id, user.id)
      // Cerrar sesión de prueba
      await testSupabase.auth.signOut()
    }
  } catch (verifyErr: any) {
    console.error('⚠️ Error en verificación de contraseña:', verifyErr)
    await saveLog(supabase, requestEmail, 'password_verification_exception', `Excepción al verificar contraseña: ${verifyErr?.message}`, 'error', {
      user_id: user.id
    }, otpRow.id, user.id, {
      error_message: verifyErr?.message,
      error_type: verifyErr?.constructor?.name
    })
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
    }, otpRow.id, user.id, {
      error: updOtpErr.message
    })
  } else {
    await saveLog(supabase, requestEmail, 'otp_marked_used', `OTP marcado como usado exitosamente`, 'info', {
      otp_id: otpRow.id
    }, otpRow.id, user.id)
  }
  
  await saveLog(supabase, requestEmail, 'otp_process_completed', `Proceso de verificación OTP completado`, 'info', {
    user_id: user.id,
    final_status: 'success'
  }, otpRow.id, user.id)
  
  return new Response(JSON.stringify({ 
    ok: true,
    message: 'Contraseña actualizada exitosamente'
  }), { status: 200, headers: corsHeaders })
})
