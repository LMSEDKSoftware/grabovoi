// deno-lint-ignore-file no-explicit-any
import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Función generateOtp eliminada - ya no necesitamos código OTP personalizado
// Usamos directamente el recovery link oficial de Supabase

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
  const { email, redirectTo: clientRedirectTo } = await req.json().catch(() => ({}))
  console.log('📧 Email recibido:', email)
  console.log('📧 RedirectTo del cliente:', clientRedirectTo || 'no proporcionado')
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
  
  // GENERAR CÓDIGO OTP DE 6 DÍGITOS
  const otpCode = String(Math.floor(100000 + Math.random() * 900000)) // Código de 6 dígitos
  console.log(`   ✅ Código OTP generado: ${otpCode}`)
  
  // CONSTRUIR LINK DIRECTO A reset-password.php (según solución IVO)
  // Este link va directo a manigrab.app, NO pasa por Supabase
  // Solo funcionará si el usuario verifica el OTP primero en la app
  const baseUrl = Deno.env.get('APP_URL') || 'https://manigrab.app'
  const finalRecoveryUrl = `${baseUrl}/reset-password.php?email=${encodeURIComponent(requestEmail)}`
  
  console.log(`   ✅ Link directo a reset-password.php construido`)
  console.log(`   URL final a enviar: ${finalRecoveryUrl}`)
  
  // Calcular fecha de expiración (1 hora como Supabase)
  const expiresAt = new Date(Date.now() + 60 * 60 * 1000).toISOString()
  console.log(`   Expira en: ${expiresAt}`)
  
  await saveLog(supabase, requestEmail, 'otp_generated', `Código OTP generado correctamente`, 'info', {
    otp_code_length: otpCode.length,
    recovery_link_length: finalRecoveryUrl.length,
    expires_at: expiresAt
  }, undefined, foundUser.id)

  console.log('💾 Guardando OTP y recovery link en base de datos...')
  // Guardar el OTP y recovery_link en la base de datos
  let insertedOtp: any = null
  try {
    const { data, error: insErr } = await supabase.from('password_reset_otps').insert({
      email: requestEmail,
      otp_code: otpCode, // ⚠️ IMPORTANTE: Código OTP de 6 dígitos
      recovery_link: finalRecoveryUrl, // URL de recuperación
      expires_at: expiresAt,
      used: false,
    }).select().single()
    
    if (insErr) {
      console.warn('⚠️ Error guardando recovery link en BD (no crítico):', insErr.message)
      // Continuar de todas formas - el link ya está generado y podemos enviarlo
    } else {
      insertedOtp = data
      console.log('✅ Recovery link guardado en base de datos')
      await saveLog(supabase, requestEmail, 'recovery_link_saved', `Recovery link guardado en base de datos exitosamente`, 'info', {
        otp_id: insertedOtp.id,
        expires_at: expiresAt
      }, insertedOtp.id, foundUser.id)
    }
  } catch (dbError: any) {
    console.warn('⚠️ Error guardando en BD (continuando):', dbError.message)
    // Continuar de todas formas
  }

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
  const SENDGRID_TEMPLATE_RECOVERY = Deno.env.get('SENDGRID_TEMPLATE_RECOVERY') || 'd-971362da419640f7be3c3cb7fae9881d' // Template ID de SendGrid para recovery
  
  console.log('🔍 Verificando configuración de envío de email...')
  console.log('   Email Server URL:', EMAIL_SERVER_URL || 'No configurado')
  console.log('   Email Server Secret:', EMAIL_SERVER_SECRET ? 'Configurado' : 'No configurado')
  console.log('   SendGrid API Key:', SENDGRID_API_KEY ? 'Configurado' : 'No configurado')
  console.log('   SendGrid Template Recovery:', SENDGRID_TEMPLATE_RECOVERY || 'No configurado')
  console.log('   From Email:', SENDGRID_FROM_EMAIL)
  console.log('   From Name:', SENDGRID_FROM_NAME)
  console.log('   Entorno:', isProd ? 'production' : 'development')
  
  // Obtener nombre del usuario para el email
  const userName = foundUser.user_metadata?.full_name || foundUser.user_metadata?.name || foundUser.email?.split('@')[0] || 'Usuario'
  
  // Preparar HTML del email con OTP y link de recuperación
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
        .otp-code { font-size: 36px; font-weight: bold; color: #FFD700; text-align: center; padding: 20px; background: #1C2541; border-radius: 8px; margin: 20px 0; letter-spacing: 8px; }
        .button { display: inline-block; padding: 15px 30px; background: #FFD700; color: #1C2541; text-decoration: none; border-radius: 8px; font-weight: bold; margin: 20px 0; }
        .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
        .link { word-break: break-all; color: #0066cc; }
        .steps { background: #e3f2fd; padding: 15px; border-radius: 8px; margin: 20px 0; }
        .steps ol { margin: 10px 0; padding-left: 20px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1 style="color: #1C2541; margin: 0;">ManiGrab</h1>
          <p style="color: #1C2541; margin: 10px 0 0 0;">Secuencias Numéricas</p>
        </div>
        <div class="content">
          <h2 style="color: #1C2541;">Recuperación de Contraseña</h2>
          <p>Hola ${userName},</p>
          <p>Hemos recibido una solicitud para restablecer tu contraseña.</p>
          
          <p><strong>Tu código de verificación es:</strong></p>
          <div class="otp-code">${otpCode}</div>
          
          <div class="steps">
            <p><strong>Sigue estos pasos:</strong></p>
            <ol>
              <li>Ingresa el código ${otpCode} en la app</li>
              <li>Después de verificar el código, podrás cambiar tu contraseña</li>
            </ol>
          </div>
          
          <p>O también puedes hacer clic en el siguiente enlace después de verificar tu código:</p>
          <div style="text-align: center;">
            <a href="${finalRecoveryUrl}" class="button">Restablecer Contraseña</a>
          </div>
          <p style="font-size: 12px; color: #666; word-break: break-all;">${finalRecoveryUrl}</p>
          
          <p><strong>⚠️ Importante:</strong> Este código expirará en 1 hora.</p>
          <p>Si no solicitaste este cambio de contraseña, puedes ignorar este mensaje de forma segura.</p>
          
          <div class="footer">
            <p>© ${new Date().getFullYear()} ManiGrab. Todos los derechos reservados.</p>
          </div>
        </div>
      </div>
    </body>
    </html>
  `
  
  const emailText = `Recuperación de Contraseña - ManiGrab

Hola ${userName},

Hemos recibido una solicitud para restablecer tu contraseña.

Tu código de verificación es: ${otpCode}

Sigue estos pasos:
1. Ingresa el código ${otpCode} en la app
2. Después de verificar el código, podrás cambiar tu contraseña

O también puedes usar este enlace después de verificar tu código:
${finalRecoveryUrl}

⚠️ Importante: Este código expirará en 1 hora.

Si no solicitaste este cambio de contraseña, puedes ignorar este mensaje de forma segura.

© ${new Date().getFullYear()} ManiGrab. Todos los derechos reservados.`
  
  // OPCIÓN 1: Usar servidor propio con IP estática (recomendado)
  if (EMAIL_SERVER_URL && EMAIL_SERVER_SECRET) {
    try {
      console.log('📧 Enviando email a través del servidor propio (IP estática)...')
      console.log('   Servidor:', EMAIL_SERVER_URL)
      
      // Obtener nombre del usuario para el template
      const userName = foundUser.user_metadata?.full_name || foundUser.user_metadata?.name || foundUser.email?.split('@')[0] || 'Usuario'
      
      // Preparar payload para el servidor
      // Si hay template_id configurado, usar template; si no, usar HTML directo
      let serverPayload: any = {
        to: requestEmail,
      }
      
      if (SENDGRID_TEMPLATE_RECOVERY) {
        // VALIDACIÓN FINAL CRÍTICA antes de construir template_data
        if (!finalRecoveryUrl || finalRecoveryUrl.trim() === '' || typeof finalRecoveryUrl !== 'string') {
          console.error('❌ ERROR CRÍTICO: finalRecoveryUrl está vacío o inválido antes de construir template_data')
          console.error('   Tipo:', typeof finalRecoveryUrl)
          console.error('   Valor:', finalRecoveryUrl)
          await saveLog(supabase, requestEmail, 'final_url_invalid_before_template', `finalRecoveryUrl inválido antes de template_data`, 'error', {
            type: typeof finalRecoveryUrl,
            value: finalRecoveryUrl
          }, insertedOtp?.id, foundUser.id)
          throw new Error('finalRecoveryUrl no puede estar vacío')
        }
        
        // Usar template de SendGrid
        console.log('   Usando template de SendGrid a través del servidor')
        console.log('   Template ID:', SENDGRID_TEMPLATE_RECOVERY)
        console.log('   OTP Code:', otpCode)
        console.log('   Recovery Link FINAL COMPLETO:', finalRecoveryUrl)
        console.log('   User Name:', userName)
        
        serverPayload.template_id = SENDGRID_TEMPLATE_RECOVERY
        serverPayload.template_data = {
          name: userName || 'Usuario',
          app_name: 'ManiGrab',
          otp_code: otpCode, // ⚠️ Código OTP de 6 dígitos
          recovery_link: finalRecoveryUrl.trim() // URL final validada
        }
        serverPayload.subject = 'Recuperación de Contraseña - ManiGrab'
        
        // Validación post-construcción
        if (!serverPayload.template_data.recovery_link || serverPayload.template_data.recovery_link.trim() === '') {
          console.error('❌ ERROR CRÍTICO: recovery_link está vacío después de construir template_data')
          await saveLog(supabase, requestEmail, 'recovery_link_empty_in_template_data', `recovery_link vacío en template_data`, 'error', {
            template_data: serverPayload.template_data
          }, insertedOtp?.id, foundUser.id)
          throw new Error('recovery_link no puede estar vacío en template_data')
        }
        
        console.log('📦 PAYLOAD COMPLETO A ENVIAR AL SERVIDOR:')
        console.log(JSON.stringify(serverPayload, null, 2))
        console.log('   recovery_link en template_data:', serverPayload.template_data.recovery_link ? '✅ PRESENTE' : '❌ AUSENTE')
        console.log('   recovery_link length:', serverPayload.template_data.recovery_link ? serverPayload.template_data.recovery_link.length : 0)
        console.log('   recovery_link valor completo:', serverPayload.template_data.recovery_link || 'VACÍO')
        
        // ⚠️ DEBUG: También incluir HTML directo como fallback para diagnóstico
        // Si el template no funciona, el servidor puede usar HTML directo
        serverPayload.html = emailHtml.replace(/\{\{name\}\}/g, userName || 'Usuario')
          .replace(/\{\{app_name\}\}/g, 'ManiGrab')
          .replace(/\{\{recovery_link\}\}/g, finalRecoveryUrl)
        serverPayload.text = emailText.replace(/\{\{name\}\}/g, userName || 'Usuario')
          .replace(/\{\{app_name\}\}/g, 'ManiGrab')
          .replace(/\{\{recovery_link\}\}/g, finalRecoveryUrl)
        console.log('   🔧 HTML directo también incluido como fallback (con variables reemplazadas)')
      } else {
        // Usar HTML directo
        serverPayload.subject = 'Recuperación de Contraseña - ManiGrab'
        serverPayload.html = emailHtml
        serverPayload.text = emailText
      }
      
      console.log('📤 Enviando request al servidor PHP...')
      const serverResponse = await fetch(EMAIL_SERVER_URL, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${EMAIL_SERVER_SECRET}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(serverPayload)
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
        console.log('   Recovery link enviado en el email')
        await saveLog(supabase, requestEmail, 'recovery_email_sent', `Email con recovery link enviado exitosamente vía servidor propio`, 'info', {
          method: 'server_proxy',
          server_url: EMAIL_SERVER_URL
        }, insertedOtp?.id, foundUser.id)
        // Retornar éxito
        const response = {
          ok: true
        }
        console.log('✅ Función completada exitosamente - recovery link enviado por email')
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
      
      // Obtener nombre del usuario (si está disponible)
      const userName = foundUser.user_metadata?.full_name || foundUser.user_metadata?.name || foundUser.email?.split('@')[0] || 'Usuario'
      const appName = 'ManiGrab'
      
      let emailBody: any
      
      // Si hay template_id configurado, usar template de SendGrid
      if (SENDGRID_TEMPLATE_RECOVERY) {
      console.log('   Usando template de SendGrid:', SENDGRID_TEMPLATE_RECOVERY)
      console.log('   OTP Code:', otpCode)
      console.log('   Recovery link FINAL a enviar al template:', finalRecoveryUrl.substring(0, 100) + '...')
      
      // VALIDACIÓN FINAL antes de enviar
      if (!otpCode || otpCode.trim() === '' || otpCode.length !== 6) {
        console.error('❌ ERROR CRÍTICO: OTP code está vacío o inválido')
        await saveLog(supabase, requestEmail, 'otp_code_empty', `OTP code está vacío antes de enviar`, 'error', {}, undefined, foundUser.id)
        return new Response(JSON.stringify({ 
          error: 'No se pudo generar código OTP válido'
        }), { status: 500, headers: corsHeaders })
      }
      
      if (!finalRecoveryUrl || finalRecoveryUrl.trim() === '') {
        console.error('❌ ERROR CRÍTICO: finalRecoveryUrl está vacío, no se puede enviar email')
        await saveLog(supabase, requestEmail, 'final_url_empty', `finalRecoveryUrl está vacío antes de enviar`, 'error', {}, undefined, foundUser.id)
        return new Response(JSON.stringify({ 
          error: 'No se pudo generar link de recuperación válido'
        }), { status: 500, headers: corsHeaders })
      }
      
      const templateData = {
        name: userName || 'Usuario',
        app_name: appName || 'ManiGrab',
        otp_code: otpCode, // ⚠️ Código OTP de 6 dígitos
        recovery_link: finalRecoveryUrl  // URL final validada
      }
        
        console.log('📋 DATOS A ENVIAR AL TEMPLATE:')
        console.log('   Template ID:', SENDGRID_TEMPLATE_RECOVERY)
        console.log('   Template Data:', JSON.stringify(templateData, null, 2))
        console.log('   recovery_link length:', finalRecoveryUrl.length)
        console.log('   recovery_link completo:', finalRecoveryUrl)
        
        emailBody = {
          personalizations: [{
            to: [{ email: requestEmail }],
            dynamic_template_data: templateData
          }],
          from: {
            email: SENDGRID_FROM_EMAIL,
            name: SENDGRID_FROM_NAME
          },
          template_id: SENDGRID_TEMPLATE_RECOVERY
        }
        
        console.log('📦 JSON COMPLETO A ENVIAR A SENDGRID:')
        console.log(JSON.stringify(emailBody, null, 2))
      } else {
        // Fallback: usar HTML directo
        console.log('   Usando HTML directo (template_id no configurado)')
        emailBody = {
          personalizations: [{
            to: [{ email: requestEmail }],
            subject: 'Recuperación de Contraseña - ManiGrab'
          }],
          from: {
            email: SENDGRID_FROM_EMAIL,
            name: SENDGRID_FROM_NAME
          },
          content: [{
            type: 'text/html',
            value: emailHtml
          }, {
            type: 'text/plain',
            value: emailText
          }]
        }
      }

      console.log('📤 Enviando request a SendGrid API...')
      const sendGridResponse = await fetch('https://api.sendgrid.com/v3/mail/send', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${SENDGRID_API_KEY}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(emailBody)
      })

      console.log('📥 Respuesta de SendGrid:')
      console.log('   Status:', sendGridResponse.status)
      console.log('   Status Text:', sendGridResponse.statusText)
      
      const responseText = await sendGridResponse.text()
      
      if (!sendGridResponse.ok) {
        console.error('❌ Error enviando email con SendGrid')
        console.error('   Status:', sendGridResponse.status)
        console.error('   Status Text:', sendGridResponse.statusText)
        console.error('   Error completo:', responseText)
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
      }), { status: 500, headers: corsHeaders })
      } else {
        console.log('✅ Email enviado correctamente con SendGrid')
        console.log('   Destino:', requestEmail)
        console.log('   Remitente:', SENDGRID_FROM_EMAIL)
        console.log('   Template ID:', SENDGRID_TEMPLATE_RECOVERY)
        console.log('   Recovery link enviado:', finalRecoveryUrl.substring(0, 100) + '...')
        console.log('   Response body:', responseText.substring(0, 200))
        await saveLog(supabase, requestEmail, 'recovery_email_sent', `Email con recovery link enviado exitosamente con SendGrid`, 'info', {
          method: 'sendgrid_direct',
          from_email: SENDGRID_FROM_EMAIL
        }, insertedOtp?.id, foundUser.id)
      }
    } catch (emailError: any) {
      console.error('❌ Error en envío de email:', emailError)
      console.error('   Tipo de error:', emailError?.constructor?.name)
      console.error('   Mensaje:', emailError?.message)
      console.error('   Stack:', emailError?.stack)
      await saveLog(supabase, requestEmail, 'email_send_exception', `Excepción al enviar email: ${emailError?.message}`, 'error', {
        method: 'sendgrid_direct'
      }, insertedOtp?.id, foundUser.id, {
        error_message: emailError?.message,
        error_type: emailError?.constructor?.name,
        stack: emailError?.stack
      })
      // Retornar error para que el cliente sepa que hubo un problema
      return new Response(JSON.stringify({ 
        ok: false, 
        error: `Error en envío de email: ${emailError?.message || 'Error desconocido'}`,
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
      error: 'SENDGRID_API_KEY no configurada en las variables de entorno de Supabase'
    }), { status: 500, headers: corsHeaders })
  }

  // Retornar éxito si llegamos aquí (el email se envió correctamente)
  const response = {
    ok: true
  }
  
  await saveLog(supabase, requestEmail, 'recovery_process_completed', `Proceso de recuperación completado exitosamente - recovery link enviado por email`, 'info', {
    final_status: 'success'
  }, insertedOtp?.id, foundUser.id)
  
  console.log('✅ Función completada exitosamente - recovery link enviado por email')
  return new Response(JSON.stringify(response), { status: 200, headers: corsHeaders })
})
