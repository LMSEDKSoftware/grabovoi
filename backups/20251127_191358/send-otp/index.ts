// deno-lint-ignore-file no-explicit-any
import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

function generateOtp(length = 6): string {
  const min = Math.pow(10, length - 1)
  const max = Math.pow(10, length) - 1
  return Math.floor(Math.random() * (max - min + 1) + min).toString()
}

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
      function_name: 'send-otp',
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
  console.log('🚀 Función send-otp invocada')
  console.log('📥 Método:', req.method)
  console.log('📥 URL:', req.url)
  
  let supabase: any = null
  let requestEmail: string = ''
  
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Content-Type': 'application/json',
  }

  if (req.method === 'OPTIONS') {
    console.log('✅ Respondiendo a OPTIONS (CORS)')
    return new Response(null, { status: 204, headers: corsHeaders })
  }
  if (req.method !== 'POST') {
    console.error('❌ Método no permitido:', req.method)
    return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers: corsHeaders })
  }

  console.log('📧 Procesando solicitud POST...')
  const { email } = await req.json().catch(() => ({}))
  console.log('📧 Email recibido:', email)
  if (!email || typeof email !== 'string') {
    return new Response(JSON.stringify({ error: 'email requerido' }), { status: 400, headers: corsHeaders })
  }

  const SUPABASE_URL = Deno.env.get('SB_URL')!
  const SERVICE_ROLE_KEY = Deno.env.get('SB_SERVICE_ROLE_KEY')!
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
    return new Response(JSON.stringify({ error: 'Faltan variables de entorno' }), { status: 500, headers: corsHeaders })
  }

  supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)
  requestEmail = email.toLowerCase().trim()

  // Guardar log inicial
  await saveLog(supabase, requestEmail, 'otp_request_received', `Solicitud de OTP recibida para ${requestEmail}`, 'info', {
    method: req.method,
    url: req.url
  })

  // Verificar que el usuario exista en auth
  // Nota: listUsers no soporta filtro por email directamente, necesitamos listar y filtrar
  console.log('🔍 Buscando usuario en auth...')
  await saveLog(supabase, requestEmail, 'user_lookup_started', `Iniciando búsqueda de usuario en auth`, 'debug')
  const { data: usersData, error: usersErr } = await supabase.auth.admin.listUsers({
    page: 1,
    perPage: 1000, // Aumentar para buscar en más usuarios
  } as any)
  
  if (usersErr) {
    console.error('❌ Error listando usuarios:', usersErr)
    await saveLog(supabase, requestEmail, 'user_lookup_error', `Error buscando usuario: ${usersErr.message}`, 'error', {}, undefined, undefined, {
      error: usersErr.message,
      code: usersErr.status
    })
    return new Response(JSON.stringify({ error: 'Error validando usuario' }), { status: 500, headers: corsHeaders })
  }
  
  // Filtrar por email (case-insensitive)
  const normalizedEmail = email.toLowerCase().trim()
  const foundUser = usersData?.users?.find((u: any) => {
    const userEmail = u.email?.toLowerCase().trim()
    return userEmail === normalizedEmail
  })
  const userExists = !!foundUser
  
  console.log('👤 Usuario existe en auth:', userExists)
  console.log('📧 Email buscado:', normalizedEmail)
  
  await saveLog(supabase, requestEmail, 'user_lookup_completed', `Usuario ${userExists ? 'encontrado' : 'NO encontrado'} en auth`, userExists ? 'info' : 'warning', {
    total_users_searched: usersData?.users?.length || 0,
    user_exists: userExists,
    user_id: foundUser?.id || null
  }, undefined, foundUser?.id)
  
  if (usersData?.users && usersData.users.length > 0) {
    console.log('📊 Total usuarios encontrados:', usersData.users.length)
    // Log de los primeros 3 emails para debugging
    const sampleEmails = usersData.users.slice(0, 3).map((u: any) => u.email?.toLowerCase().trim())
    console.log('📋 Primeros emails en auth:', sampleEmails)
  }
  
  if (!userExists) {
    // Para no filtrar emails válidos, responder 200 siempre
    console.log('⚠️ Usuario no existe, pero respondiendo OK por seguridad')
    await saveLog(supabase, requestEmail, 'otp_request_rejected', `Usuario no existe, respondiendo OK por seguridad`, 'warning', {
      reason: 'user_not_found'
    })
    return new Response(JSON.stringify({ ok: true }), { status: 200, headers: corsHeaders })
  }

  // MÉTODO OFICIAL: Generar token de recuperación de Supabase
  console.log('🔑 Generando token de recuperación oficial de Supabase...')
  await saveLog(supabase, requestEmail, 'supabase_token_generation_started', `Iniciando generación de token de recuperación de Supabase`, 'debug', {}, undefined, foundUser.id)
  
  const redirectTo = Deno.env.get('APP_URL') || 'https://manigrab.app/auth/callback'
  const { data: linkData, error: linkError } = await supabase.auth.admin.generateLink({
    type: 'recovery',
    email: requestEmail,
    options: {
      redirectTo: redirectTo,
    },
  } as any)
  
  if (linkError || !linkData?.properties?.action_link) {
    console.error('❌ Error generando token de recuperación de Supabase:', linkError)
    await saveLog(supabase, requestEmail, 'supabase_token_generation_error', `Error generando token de Supabase: ${linkError?.message}`, 'error', {}, undefined, foundUser.id, {
      error: linkError?.message || 'Error desconocido',
      code: linkError?.code
    })
    return new Response(JSON.stringify({ 
      error: 'No se pudo generar token de recuperación',
      details: linkError?.message || 'Error desconocido'
    }), { status: 500, headers: corsHeaders })
  }
  
  const recoveryLink = linkData.properties.action_link
  console.log('✅ Link de recuperación generado exitosamente')
  console.log(`   Link: ${recoveryLink.substring(0, 80)}...`)
  
  // Extraer el token del link
  const tokenMatch = recoveryLink.match(/token=([^&]+)/)
  if (!tokenMatch) {
    console.error('❌ No se pudo extraer token del link')
    await saveLog(supabase, requestEmail, 'token_extraction_error', `No se pudo extraer token del link de recuperación`, 'error', {}, undefined, foundUser.id)
    return new Response(JSON.stringify({ 
      error: 'Error procesando token de recuperación'
    }), { status: 500, headers: corsHeaders })
  }
  
  const recoveryToken = tokenMatch[1]
  console.log(`✅ Token de Supabase extraído: ${recoveryToken.substring(0, 20)}...`)
  
  // Generar un código corto de 6 dígitos para mostrar al usuario
  const userFriendlyCode = generateOtp(6)
  const expiresAt = new Date(Date.now() + 60 * 60 * 1000).toISOString() // 1 hora (igual que Supabase)
  
  console.log(`🔑 Código para usuario: ${userFriendlyCode}`)
  console.log(`   Token completo guardado (últimos 8 chars): ...${recoveryToken.slice(-8)}`)
  
  await saveLog(supabase, requestEmail, 'supabase_token_generated', `Token de Supabase generado exitosamente`, 'info', {
    user_code: userFriendlyCode,
    token_length: recoveryToken.length,
    expires_at: expiresAt
  }, undefined, foundUser.id)

  console.log('💾 Guardando token de Supabase en base de datos...')
  // Guardar el código corto y el token completo de Supabase
  const { data: insertedOtp, error: insErr } = await supabase.from('password_reset_otps').insert({
    email: requestEmail,
    otp_code: userFriendlyCode, // Código corto de 6 dígitos para el usuario
    recovery_token: recoveryToken, // Token completo de Supabase
    expires_at: expiresAt,
  }).select().single()
  
  if (insErr) {
    console.error('❌ Error guardando OTP:', insErr)
    await saveLog(supabase, requestEmail, 'otp_save_error', `Error guardando OTP en BD: ${insErr.message}`, 'error', {}, undefined, foundUser.id, {
      error: insErr.message,
      code: insErr.code
    })
    return new Response(JSON.stringify({ error: 'Error guardando OTP' }), { status: 500, headers: corsHeaders })
  }
  
  console.log('✅ Token guardado en base de datos')
  
  await saveLog(supabase, requestEmail, 'otp_saved', `Token de Supabase guardado en base de datos exitosamente`, 'info', {
    otp_id: insertedOtp.id,
    user_code: userFriendlyCode,
    expires_at: expiresAt
  }, insertedOtp.id, foundUser.id)

  // Determinar si estamos en producción
  const isProd = (Deno.env.get('ENV') || '').toLowerCase() === 'production'

  // Configuración de envío de email
  // Opción 1: Usar servidor propio con IP estática (recomendado para whitelist)
  const EMAIL_SERVER_URL = Deno.env.get('EMAIL_SERVER_URL') // ej: https://manigrab.app/api/send-email
  const EMAIL_SERVER_SECRET = Deno.env.get('EMAIL_SERVER_SECRET') // Token secreto para autenticación
  
  // Opción 2: Enviar directamente desde Supabase (requiere IP en whitelist)
  const SENDGRID_API_KEY = Deno.env.get('SENDGRID_API_KEY')
  const SENDGRID_FROM_EMAIL = Deno.env.get('SENDGRID_FROM_EMAIL') || 'hola@em6490.manigrab.app'
  const SENDGRID_FROM_NAME = Deno.env.get('SENDGRID_FROM_NAME') || 'ManiGrab'
  
  console.log('🔍 Verificando configuración de envío de email...')
  console.log('   Email Server URL:', EMAIL_SERVER_URL || 'No configurado')
  console.log('   Email Server Secret:', EMAIL_SERVER_SECRET ? 'Configurado' : 'No configurado')
  console.log('   SendGrid API Key:', SENDGRID_API_KEY ? 'Configurado' : 'No configurado')
  console.log('   From Email:', SENDGRID_FROM_EMAIL)
  console.log('   From Name:', SENDGRID_FROM_NAME)
  console.log('   Entorno:', isProd ? 'production' : 'development')
  
  // Preparar HTML del email con el código corto
  const emailHtml = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #FFD700 0%, #FFA500 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .otp-code { font-size: 32px; font-weight: bold; color: #FFD700; text-align: center; padding: 20px; background: #1C2541; border-radius: 8px; margin: 20px 0; letter-spacing: 5px; }
        .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1 style="color: #1C2541; margin: 0;">ManiGrab</h1>
          <p style="color: #1C2541; margin: 10px 0 0 0;">Manifestaciones Cuánticas Grabovoi</p>
        </div>
        <div class="content">
          <h2 style="color: #1C2541;">Código de Verificación</h2>
          <p>Hemos recibido una solicitud para restablecer tu contraseña. Utiliza el siguiente código de verificación:</p>
          <div class="otp-code">${userFriendlyCode}</div>
          <p>Este código expirará en 1 hora.</p>
          <p>Si no solicitaste este código, puedes ignorar este mensaje de forma segura.</p>
          <div class="footer">
            <p>© ${new Date().getFullYear()} ManiGrab. Todos los derechos reservados.</p>
          </div>
        </div>
      </div>
    </body>
    </html>
  `
  
  // OPCIÓN 1: Usar servidor propio con IP estática (recomendado)
  if (EMAIL_SERVER_URL && EMAIL_SERVER_SECRET) {
    try {
      console.log('📧 Enviando email a través del servidor propio (IP estática)...')
      console.log('   Servidor:', EMAIL_SERVER_URL)
      
      const serverResponse = await fetch(EMAIL_SERVER_URL, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${EMAIL_SERVER_SECRET}`,
          'Content-Type': 'application/json'
        },
          body: JSON.stringify({
            to: requestEmail,
            subject: 'Código de verificación - Recuperación de contraseña',
            html: emailHtml,
            text: `Tu código de verificación es: ${userFriendlyCode}. Este código expirará en 1 hora.`
          })
      })
      
      if (!serverResponse.ok) {
        const errorText = await serverResponse.text()
        console.error('❌ Error enviando email a través del servidor')
        console.error('   Status:', serverResponse.status)
        console.error('   Error:', errorText)
        await saveLog(supabase, requestEmail, 'email_send_error', `Error enviando email vía servidor: ${serverResponse.status}`, 'error', {
          server_url: EMAIL_SERVER_URL,
          status: serverResponse.status
        }, insertedOtp.id, foundUser.id, {
          error: errorText,
          status: serverResponse.status
        })
        // Fallback a envío directo si el servidor falla
        console.log('⚠️ Intentando envío directo como fallback...')
      } else {
        const result = await serverResponse.json()
        console.log('✅ Email enviado correctamente a través del servidor')
        console.log('   Destino:', requestEmail)
        console.log('   Código enviado:', userFriendlyCode)
        await saveLog(supabase, requestEmail, 'otp_email_sent', `Email con código de verificación enviado exitosamente vía servidor propio`, 'info', {
          method: 'server_proxy',
          server_url: EMAIL_SERVER_URL,
          user_code: userFriendlyCode
        }, insertedOtp.id, foundUser.id)
        // Retornar éxito
        const response = {
          ok: true,
          dev_code: isProd ? undefined : userFriendlyCode // En desarrollo, retornar el código para pruebas
        }
        console.log('✅ Función completada exitosamente. Código generado:', userFriendlyCode)
        return new Response(JSON.stringify(response), { status: 200, headers: corsHeaders })
      }
    } catch (serverError: any) {
      console.error('❌ Error en envío a través del servidor:', serverError)
      console.log('⚠️ Intentando envío directo como fallback...')
      // Continuar con envío directo como fallback
    }
  }
  
  // OPCIÓN 2: Envío directo desde Supabase (requiere IP en whitelist)
  if (SENDGRID_API_KEY) {
    try {
      console.log('📧 Enviando email directamente desde Supabase...')
      const emailBody = {
        personalizations: [{
          to: [{ email: email }],
          subject: 'Código de verificación - Recuperación de contraseña'
        }],
        from: {
          email: SENDGRID_FROM_EMAIL,
          name: SENDGRID_FROM_NAME
        },
        content: [{
          type: 'text/html',
          value: emailHtml
        }]
      }

      const sendGridResponse = await fetch('https://api.sendgrid.com/v3/mail/send', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${SENDGRID_API_KEY}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(emailBody)
      })

      if (!sendGridResponse.ok) {
        const errorText = await sendGridResponse.text()
        console.error('❌ Error enviando email con SendGrid')
        console.error('   Status:', sendGridResponse.status)
        console.error('   Status Text:', sendGridResponse.statusText)
        console.error('   Error completo:', errorText)
        let errorJson: any = null
        try {
          errorJson = JSON.parse(errorText)
          console.error('   Errores detallados:', JSON.stringify(errorJson, null, 2))
        } catch (_) {
          console.error('   Error como texto:', errorText)
        }
        await saveLog(supabase, requestEmail, 'email_send_error', `Error enviando email con SendGrid: ${sendGridResponse.status}`, 'error', {
          method: 'sendgrid_direct',
          from_email: SENDGRID_FROM_EMAIL
        }, insertedOtp.id, foundUser.id, {
          error: errorText,
          status: sendGridResponse.status,
          status_text: sendGridResponse.statusText,
          error_json: errorJson
        })
      // Retornar error para que el cliente sepa que hubo un problema
      return new Response(JSON.stringify({ 
        ok: false, 
        error: `Error enviando email: ${sendGridResponse.status} - ${errorText}`,
        dev_code: isProd ? undefined : userFriendlyCode // Aún retornar código en dev para pruebas
      }), { status: 500, headers: corsHeaders })
      } else {
        console.log('✅ Email enviado correctamente con SendGrid')
        console.log('   Destino:', requestEmail)
        console.log('   Remitente:', SENDGRID_FROM_EMAIL)
        console.log('   Código enviado:', userFriendlyCode)
        await saveLog(supabase, requestEmail, 'otp_email_sent', `Email con código de verificación enviado exitosamente con SendGrid`, 'info', {
          method: 'sendgrid_direct',
          from_email: SENDGRID_FROM_EMAIL,
          user_code: userFriendlyCode
        }, insertedOtp.id, foundUser.id)
      }
    } catch (emailError: any) {
      console.error('❌ Error en envío de email:', emailError)
      console.error('   Tipo de error:', emailError?.constructor?.name)
      console.error('   Mensaje:', emailError?.message)
      console.error('   Stack:', emailError?.stack)
      await saveLog(supabase, requestEmail, 'email_send_exception', `Excepción al enviar email: ${emailError?.message}`, 'error', {
        method: 'sendgrid_direct'
      }, insertedOtp.id, foundUser.id, {
        error_message: emailError?.message,
        error_type: emailError?.constructor?.name,
        stack: emailError?.stack
      })
      // Retornar error para que el cliente sepa que hubo un problema
      return new Response(JSON.stringify({ 
        ok: false, 
        error: `Error en envío de email: ${emailError?.message || 'Error desconocido'}`,
        dev_code: isProd ? undefined : userFriendlyCode // Aún retornar código en dev para pruebas
      }), { status: 500, headers: corsHeaders })
    }
  } else {
    console.warn('⚠️ SENDGRID_API_KEY no configurada, email no enviado')
    console.warn('⚠️ Variables disponibles:', {
      hasKey: !!Deno.env.get('SENDGRID_API_KEY'),
      fromEmail: Deno.env.get('SENDGRID_FROM_EMAIL'),
      fromName: Deno.env.get('SENDGRID_FROM_NAME')
    })
    await saveLog(supabase, requestEmail, 'email_config_error', `SENDGRID_API_KEY no configurada`, 'error', {
      has_key: !!Deno.env.get('SENDGRID_API_KEY'),
      from_email: Deno.env.get('SENDGRID_FROM_EMAIL'),
      from_name: Deno.env.get('SENDGRID_FROM_NAME')
    }, insertedOtp.id, foundUser.id)
    // Retornar error si no hay API key configurada
    return new Response(JSON.stringify({ 
      ok: false, 
      error: 'SENDGRID_API_KEY no configurada en las variables de entorno de Supabase',
      dev_code: isProd ? undefined : userFriendlyCode // Aún retornar código en dev para pruebas
    }), { status: 500, headers: corsHeaders })
  }

  // Retornar éxito si llegamos aquí (el email se envió correctamente)
  // En desarrollo, también retornar el código para facilitar pruebas
  const response = {
    ok: true,
    dev_code: isProd ? undefined : userFriendlyCode
  }
  
  await saveLog(supabase, requestEmail, 'otp_process_completed', `Proceso OTP completado exitosamente`, 'info', {
    final_status: 'success',
    user_code: userFriendlyCode
  }, insertedOtp.id, foundUser.id)
  
  console.log('✅ Función completada exitosamente. Código generado:', userFriendlyCode)
  return new Response(JSON.stringify(response), { status: 200, headers: corsHeaders })
})
