# 🔍 CONTEXTO COMPLETO: Problema OTP con Supabase

## 📋 PROBLEMA DESCRITO

Estoy implementando un sistema de OTP personalizado para recuperación de contraseña en Supabase. El flujo es:

1. Usuario solicita cambio de contraseña → Se genera un código OTP de 6 dígitos
2. Usuario recibe código por email → Ingresa código + nueva contraseña
3. Sistema verifica OTP → Actualiza contraseña usando Admin API
4. **PROBLEMA:** Aunque la contraseña se reporta como actualizada exitosamente, el usuario NO puede hacer login con la nueva contraseña (error "Invalid login credentials")

---

## 🔬 MÉTODOS INTENTADOS (TODOS FALLAN)

### Método 1: `admin.updateUserById()` simple
```typescript
await supabase.auth.admin.updateUserById(user.id, {
  password: new_password,
});
```
**Resultado:** ❌ Falla - Contraseña no funciona para login

### Método 2: `admin.updateUserById()` con confirmación de email
```typescript
await supabase.auth.admin.updateUserById(user.id, {
  password: new_password,
  email_confirm: true,
});
```
**Resultado:** ❌ Falla - Email se confirma pero contraseña no funciona

### Método 3: API REST directa
```typescript
const response = await fetch(`${SUPABASE_URL}/auth/v1/admin/users/${user.id}`, {
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
});
```
**Resultado:** ❌ Falla - Mismo problema

### Método 4: Usar recovery token de Supabase
```typescript
// Generar token oficial de Supabase
const { data: linkData } = await supabase.auth.admin.generateLink({
  type: 'recovery',
  email: email,
});

// Extraer token del link
const recoveryToken = extractTokenFromLink(linkData.properties.action_link);

// Intentar usar con exchangeCodeForSession
const sessionResponse = await supabase.auth.exchangeCodeForSession(recoveryToken);
```
**Resultado:** ❌ Falla - `exchangeCodeForSession` requiere code verifier (PKCE), no funciona con recovery token directo

### Método 5: Recovery token → Session → updateUser()
```typescript
// Intentar crear sesión con recovery token
const sessionResponse = await supabase.auth.exchangeCodeForSession({
  auth_code: recoveryToken,
  type: 'recovery',
});

// Luego actualizar con updateUser()
const updateResponse = await supabase.auth.updateUser({
  password: new_password,
});
```
**Resultado:** ❌ Falla - No se puede crear sesión con recovery token de esta forma

---

## 📁 ARCHIVOS RELEVANTES

### 1. Edge Function: `send-otp/index.ts`

**Ubicación:** `supabase/functions/send-otp/index.ts`

**Función:** Genera OTP y token de recuperación de Supabase

**Contenido completo:**

```typescript
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
  console.log('🔍 Buscando usuario en auth...')
  await saveLog(supabase, requestEmail, 'user_lookup_started', `Iniciando búsqueda de usuario en auth`, 'debug')
  const { data: usersData, error: usersErr } = await supabase.auth.admin.listUsers({
    page: 1,
    perPage: 1000,
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
  
  if (!userExists) {
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
  const expiresAt = new Date(Date.now() + 60 * 60 * 1000).toISOString() // 1 hora
  
  console.log(`🔑 Código para usuario: ${userFriendlyCode}`)
  console.log(`   Token completo de Supabase guardado (últimos 8 chars): ...${recoveryToken.slice(-8)}`)
  
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
  const EMAIL_SERVER_URL = Deno.env.get('EMAIL_SERVER_URL')
  const EMAIL_SERVER_SECRET = Deno.env.get('EMAIL_SERVER_SECRET')
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
    }
  }
  
  // OPCIÓN 2: Envío directo desde Supabase (requiere IP en whitelist)
  if (SENDGRID_API_KEY) {
    try {
      console.log('📧 Enviando email directamente desde Supabase...')
      const emailBody = {
        personalizations: [{
          to: [{ email: requestEmail }],
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
        return new Response(JSON.stringify({ 
          ok: false, 
          error: `Error enviando email: ${sendGridResponse.status} - ${errorText}`,
          dev_code: isProd ? undefined : userFriendlyCode
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
      return new Response(JSON.stringify({ 
        ok: false, 
        error: `Error en envío de email: ${emailError?.message || 'Error desconocido'}`,
        dev_code: isProd ? undefined : userFriendlyCode
      }), { status: 500, headers: corsHeaders })
    }
  } else {
    console.warn('⚠️ SENDGRID_API_KEY no configurada, email no enviado')
    await saveLog(supabase, requestEmail, 'email_config_error', `SENDGRID_API_KEY no configurada`, 'error', {
      has_key: !!Deno.env.get('SENDGRID_API_KEY'),
      from_email: Deno.env.get('SENDGRID_FROM_EMAIL'),
      from_name: Deno.env.get('SENDGRID_FROM_NAME')
    }, insertedOtp.id, foundUser.id)
    return new Response(JSON.stringify({ 
      ok: false, 
      error: 'SENDGRID_API_KEY no configurada en las variables de entorno de Supabase',
      dev_code: isProd ? undefined : userFriendlyCode
    }), { status: 500, headers: corsHeaders })
  }

  // Retornar éxito si llegamos aquí
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
```

---

### 2. Edge Function: `verify-otp/index.ts`

**Ubicación:** `supabase/functions/verify-otp/index.ts`

**Función:** Verifica OTP y actualiza contraseña

**Contenido completo (versión actual con múltiples intentos):**

```typescript
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
  
  // NUEVA ESTRATEGIA: Intentar múltiples métodos
  console.log('🔑 Intentando método alternativo: Usar recovery token para sesión...')
  await saveLog(supabase, requestEmail, 'password_update_started', `Iniciando actualización usando recovery token`, 'info', {
    user_id: user.id,
    password_length: String(new_password).length,
    method: 'Recovery token -> Session -> updateUser()'
  }, otpRow.id, user.id)
  
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY') || Deno.env.get('SB_ANON_KEY') || ''
  let updateSuccess = false
  let lastError: any = null
  
  // INTENTO 1: Usar recovery token directamente en exchangeCodeForSession
  try {
    const tempSupabase = createClient(SUPABASE_URL, anonKey)
    
    const exchangeResponse = await tempSupabase.auth.exchangeCodeForSession({
      auth_code: recoveryToken,
      type: 'recovery',
    } as any)
    
    if (!exchangeResponse.error && exchangeResponse.data.session) {
      console.log('✅ Sesión creada exitosamente con recovery token')
      
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
      method: 'All methods failed'
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
```

---

### 3. Script de Prueba: `debug_otp_complete_flow.dart`

**Ubicación:** `scripts/debug_otp_complete_flow.dart`

**Función:** Script completo para probar el flujo OTP paso a paso

**Contenido completo:**

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Script de debugging completo para el flujo OTP
/// Este script prueba todo el flujo paso a paso con logging detallado

const String SUPABASE_URL = 'https://whtiazgcxdnemrrgjjqf.supabase.co';
const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1MjM2MzgsImV4cCI6MjA3NjA5OTYzOH0.1CFkusMrMKcvSU_-5RyGYPoKDM_yizuQMVGo7W3mXHU';
const String SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDUyMzYzOCwiZXhwIjoyMDc2MDk5NjM4fQ.LIVQ2FpXRpJD7ie4GVkrwU7lLPRm4S5NekNG2Cqme8o';

const String TEST_EMAIL = '2005.ivan@gmail.com';
const String TEST_NEW_PASSWORD = 'TestPass123!';

void main() async {
  print('🔍 ============================================');
  print('🔍 SCRIPT DE DEBUGGING COMPLETO - FLUJO OTP');
  print('🔍 ============================================\n');

  try {
    // PASO 1: Solicitar OTP
    print('📧 PASO 1: Solicitando OTP para $TEST_EMAIL');
    print('   ────────────────────────────────────────────');
    final otpCode = await step1RequestOTP();
    
    if (otpCode == null) {
      print('❌ ERROR: No se pudo obtener el código OTP');
      return;
    }
    
    print('✅ Código OTP recibido: $otpCode\n');
    
    // Esperar un momento
    await Future.delayed(Duration(seconds: 2));
    
    // PASO 2: Verificar OTP y actualizar contraseña
    print('🔐 PASO 2: Verificando OTP y actualizando contraseña');
    print('   ────────────────────────────────────────────');
    final updateSuccess = await step2VerifyOTPAndUpdatePassword(otpCode);
    
    if (!updateSuccess) {
      print('❌ ERROR: No se pudo actualizar la contraseña');
      return;
    }
    
    print('✅ Contraseña actualizada exitosamente\n');
    
    // Esperar un momento para propagación
    print('⏳ Esperando 3 segundos para propagación de cambios...\n');
    await Future.delayed(Duration(seconds: 3));
    
    // PASO 3: Verificar estado del usuario después de actualizar
    print('🔍 PASO 3: Verificando estado del usuario en Supabase');
    print('   ────────────────────────────────────────────');
    await step3CheckUserStatus();
    
    // PASO 4: Verificar login con nueva contraseña
    print('\n🔑 PASO 4: Verificando login con nueva contraseña');
    print('   ────────────────────────────────────────────');
    final loginSuccess = await step4TestLogin();
    
    if (loginSuccess) {
      print('\n✅✅✅ ÉXITO COMPLETO: Todo el flujo funciona correctamente');
    } else {
      print('\n❌❌❌ FALLO: El login NO funciona después de actualizar la contraseña');
      print('   Esto confirma el problema que estamos intentando resolver');
      print('\n🔍 Revisando logs en Supabase para más detalles...');
      await step3CheckUserStatus();
    }
    
  } catch (e, stackTrace) {
    print('\n❌ ERROR CRÍTICO:');
    print('   $e');
    print('\n📚 Stack trace:');
    print('   $stackTrace');
  }
}

/// PASO 1: Solicitar OTP
Future<String?> step1RequestOTP() async {
  try {
    final url = Uri.parse('$SUPABASE_URL/functions/v1/send-otp');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $SUPABASE_ANON_KEY',
        'apikey': SUPABASE_ANON_KEY,
      },
      body: jsonEncode({
        'email': TEST_EMAIL,
      }),
    );
    
    print('   📡 Response status: ${response.statusCode}');
    print('   📡 Response body: ${response.body}');
    
    if (response.statusCode != 200) {
      print('   ❌ Error en la solicitud OTP');
      return null;
    }
    
    final data = jsonDecode(response.body);
    
    String? otpCode;
    if (data is Map) {
      otpCode = data['dev_code'] as String?;
      
      if (otpCode == null) {
        print('   ⚠️  No se recibió dev_code (estamos en producción o no está configurado)');
        print('   💡 Ingresa el código que recibiste por email:');
        otpCode = stdin.readLineSync();
      }
    }
    
    return otpCode?.trim();
    
  } catch (e) {
    print('   ❌ Error solicitando OTP: $e');
    return null;
  }
}

/// PASO 2: Verificar OTP y actualizar contraseña
Future<bool> step2VerifyOTPAndUpdatePassword(String otpCode) async {
  try {
    final url = Uri.parse('$SUPABASE_URL/functions/v1/verify-otp');
    
    print('   📡 Enviando:');
    print('      Email: $TEST_EMAIL');
    print('      OTP Code: $otpCode');
    print('      Nueva contraseña: ${TEST_NEW_PASSWORD.length} caracteres');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $SUPABASE_ANON_KEY',
        'apikey': SUPABASE_ANON_KEY,
      },
      body: jsonEncode({
        'email': TEST_EMAIL,
        'otp_code': otpCode,
        'new_password': TEST_NEW_PASSWORD,
      }),
    );
    
    print('   📡 Response status: ${response.statusCode}');
    print('   📡 Response body: ${response.body}');
    
    if (response.statusCode != 200) {
      print('   ❌ Error actualizando contraseña');
      try {
        final errorData = jsonDecode(response.body);
        print('   📋 Error details: $errorData');
      } catch (_) {}
      return false;
    }
    
    final data = jsonDecode(response.body);
    
    if (data is Map && data['ok'] == true) {
      print('   ✅ Respuesta exitosa del servidor');
      return true;
    } else {
      print('   ❌ Respuesta indica error: $data');
      return false;
    }
    
  } catch (e) {
    print('   ❌ Error verificando OTP: $e');
    return false;
  }
}

/// PASO 3: Verificar estado del usuario
Future<void> step3CheckUserStatus() async {
  try {
    final url = Uri.parse('$SUPABASE_URL/auth/v1/admin/users?per_page=1000');
    
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $SUPABASE_SERVICE_ROLE_KEY',
        'apikey': SUPABASE_SERVICE_ROLE_KEY,
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final users = data['users'] as List?;
      
      if (users != null) {
        final user = users.firstWhere(
          (u) => (u['email'] as String?)?.toLowerCase() == TEST_EMAIL.toLowerCase(),
          orElse: () => null,
        );
        
        if (user != null) {
          print('   ✅ Usuario encontrado:');
          print('      ID: ${user['id']}');
          print('      Email: ${user['email']}');
          print('      Email confirmado: ${user['email_confirmed_at'] != null ? "SÍ ✅ (${user['email_confirmed_at']})" : "NO ❌"}');
          print('      Último sign in: ${user['last_sign_in_at'] ?? "Nunca"}');
          print('      Creado: ${user['created_at']}');
          print('      Updated: ${user['updated_at']}');
          
          if (user['phone'] != null) {
            print('      Phone: ${user['phone']}');
            print('      Phone confirmado: ${user['phone_confirmed_at'] != null ? "SÍ ✅" : "NO ❌"}');
          }
        } else {
          print('   ⚠️  Usuario NO encontrado en auth.users');
        }
      }
    } else {
      print('   ⚠️  No se pudo verificar estado (status: ${response.statusCode})');
      print('   📡 Response: ${response.body}');
    }
  } catch (e) {
    print('   ⚠️  Error verificando estado: $e');
  }
}

/// PASO 4: Probar login con nueva contraseña
Future<bool> step4TestLogin() async {
  try {
    final url = Uri.parse('$SUPABASE_URL/auth/v1/token?grant_type=password');
    
    print('   📡 Intentando login con:');
    print('      Email: $TEST_EMAIL');
    print('      Password: ${TEST_NEW_PASSWORD.length} caracteres');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $SUPABASE_ANON_KEY',
        'apikey': SUPABASE_ANON_KEY,
      },
      body: jsonEncode({
        'email': TEST_EMAIL,
        'password': TEST_NEW_PASSWORD,
      }),
    );
    
    print('   📡 Response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('   ✅ Login exitoso!');
      print('   📋 Access token recibido: ${(data['access_token'] as String?)?.substring(0, 20)}...');
      
      if (data['user'] != null) {
        final user = data['user'] as Map;
        final emailConfirmed = user['email_confirmed_at'];
        print('   📋 Email confirmado: ${emailConfirmed != null ? "SÍ ✅" : "NO ❌"}');
      }
      
      return true;
    } else {
      print('   ❌ Login falló');
      print('   📡 Response body: ${response.body}');
      
      try {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error_description'] ?? errorData['error'] ?? 'Error desconocido';
        print('   📋 Error: $errorMsg');
      } catch (_) {}
      
      return false;
    }
    
  } catch (e) {
    print('   ❌ Error probando login: $e');
    return false;
  }
}
```

---

## 📊 RESULTADOS DE PRUEBAS

### Ejecución del script de prueba:

```
🔍 ============================================
🔍 SCRIPT DE DEBUGGING COMPLETO - FLUJO OTP
🔍 ============================================

📧 PASO 1: Solicitando OTP para 2005.ivan@gmail.com
   ────────────────────────────────────────────
   📡 Response status: 200
   📡 Response body: {"ok":true,"dev_code":"920012"}
✅ Código OTP recibido: 920012

🔐 PASO 2: Verificando OTP y actualizando contraseña
   ────────────────────────────────────────────
   📡 Enviando:
      Email: 2005.ivan@gmail.com
      OTP Code: 920012
      Nueva contraseña: 12 caracteres
   📡 Response status: 200
   📡 Response body: {"ok":true,"message":"Contraseña actualizada exitosamente"}
   ✅ Respuesta exitosa del servidor
✅ Contraseña actualizada exitosamente

⏳ Esperando 3 segundos para propagación de cambios...

🔍 PASO 3: Verificando estado del usuario en Supabase
   ────────────────────────────────────────────
   ✅ Usuario encontrado:
      ID: cd005147-55f2-49c7-830c-b1464acb68c7
      Email: 2005.ivan@gmail.com
      Email confirmado: SÍ ✅ (2025-10-18T00:53:35.943161Z)
      Último sign in: 2025-11-26T02:56:34.425498Z
      Creado: 2025-10-18T00:51:12.41871Z
      Updated: 2025-11-28T00:34:44.14017Z
      Phone: 
      Phone confirmado: NO ❌

🔑 PASO 4: Verificando login con nueva contraseña
   ────────────────────────────────────────────
   📡 Intentando login con:
      Email: 2005.ivan@gmail.com
      Password: 12 caracteres
   📡 Response status: 400
   ❌ Login falló
   📡 Response body: {"code":400,"error_code":"invalid_credentials","msg":"Invalid login credentials"}
   📋 Error: Error desconocido

❌❌❌ FALLO: El login NO funciona después de actualizar la contraseña
```

---

## 🔍 OBSERVACIONES CRÍTICAS

1. **Email está confirmado**: El campo `email_confirmed_at` tiene valor, por lo que no es un problema de confirmación de email.

2. **Updated_at cambia**: El campo `updated_at` se actualiza después de cada intento, indicando que Supabase está procesando la actualización.

3. **Todos los métodos reportan éxito**: Todos los métodos (`admin.updateUserById()`, API REST directa, etc.) reportan que la contraseña se actualizó exitosamente.

4. **Login siempre falla**: Independientemente del método usado para actualizar, el login siempre falla con "Invalid login credentials".

5. **Recovery token generado correctamente**: El token de recuperación de Supabase se genera correctamente usando `admin.generateLink()`.

---

## 💾 ESTRUCTURA DE BASE DE DATOS

### Tabla: `password_reset_otps`

```sql
create table if not exists public.password_reset_otps (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  otp_code text not null, -- Código corto mostrado al usuario (6 dígitos)
  recovery_token text, -- Token completo de Supabase (si se usa sistema oficial)
  expires_at timestamptz not null,
  used boolean not null default false,
  created_at timestamptz not null default now()
);
```

### Tabla: `otp_transaction_logs`

```sql
create table if not exists public.otp_transaction_logs (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  function_name text not null,
  action text not null,
  message text not null,
  log_level text not null,
  metadata jsonb,
  otp_id uuid,
  user_id uuid,
  error_details jsonb,
  created_at timestamptz not null default now()
);
```

---

## 📋 PREGUNTA PARA CHATGPT

**¿Cómo actualizar correctamente la contraseña de un usuario en Supabase usando Admin API cuando se tiene un sistema de OTP personalizado, de forma que la contraseña actualizada funcione inmediatamente para login con `signInWithPassword()`?**

**Restricciones:**
- No puedo cambiar al flujo oficial de Supabase (`resetPasswordForEmail()`)
- Debo mantener el sistema de OTP personalizado (código de 6 dígitos)
- Tengo acceso a SERVICE_ROLE_KEY
- Tengo acceso a recovery tokens generados con `admin.generateLink({ type: 'recovery' })`

**Problema específico:**
- Todos los métodos probados reportan éxito al actualizar la contraseña
- El campo `updated_at` del usuario cambia después de la actualización
- El email está confirmado (`email_confirmed_at` tiene valor)
- PERO el login siempre falla con "Invalid login credentials"

**¿Hay alguna forma correcta de usar `admin.updateUserById()` para actualizar contraseñas que funcione para login?**
**¿Hay algún paso adicional requerido después de actualizar la contraseña?**
**¿Hay algún problema conocido con este enfoque en Supabase?**

---

## 🔗 VERSIÓN Y CONFIGURACIÓN

- **Supabase:** Cloud (no self-hosted)
- **SDK:** `@supabase/supabase-js@2`
- **Edge Functions:** Deno runtime
- **Cliente:** Flutter/Dart (pero el problema también ocurre en scripts de prueba independientes)

---

**Fecha:** 2025-11-28
**Última actualización:** Después de múltiples intentos con diferentes métodos

