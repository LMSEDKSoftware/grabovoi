// deno-lint-ignore-file no-explicit-any
import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

function generateOtp(length = 6): string {
  const min = Math.pow(10, length - 1)
  const max = Math.pow(10, length) - 1
  return Math.floor(Math.random() * (max - min + 1) + min).toString()
}

Deno.serve(async (req) => {
  console.log('🚀 Función send-otp invocada')
  console.log('📥 Método:', req.method)
  console.log('📥 URL:', req.url)
  
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

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  // Verificar que el usuario exista en auth
  // Nota: listUsers no soporta filtro por email directamente, necesitamos listar y filtrar
  console.log('🔍 Buscando usuario en auth...')
  const { data: usersData, error: usersErr } = await supabase.auth.admin.listUsers({
    page: 1,
    perPage: 1000, // Aumentar para buscar en más usuarios
  } as any)
  
  if (usersErr) {
    console.error('❌ Error listando usuarios:', usersErr)
    return new Response(JSON.stringify({ error: 'Error validando usuario' }), { status: 500, headers: corsHeaders })
  }
  
  // Filtrar por email (case-insensitive)
  const normalizedEmail = email.toLowerCase().trim()
  const userExists = usersData?.users?.some((u: any) => {
    const userEmail = u.email?.toLowerCase().trim()
    return userEmail === normalizedEmail
  })
  
  console.log('👤 Usuario existe en auth:', userExists)
  console.log('📧 Email buscado:', normalizedEmail)
  if (usersData?.users && usersData.users.length > 0) {
    console.log('📊 Total usuarios encontrados:', usersData.users.length)
    // Log de los primeros 3 emails para debugging
    const sampleEmails = usersData.users.slice(0, 3).map((u: any) => u.email?.toLowerCase().trim())
    console.log('📋 Primeros emails en auth:', sampleEmails)
  }
  
  if (!userExists) {
    // Para no filtrar emails válidos, responder 200 siempre
    console.log('⚠️ Usuario no existe, pero respondiendo OK por seguridad')
    return new Response(JSON.stringify({ ok: true }), { status: 200, headers: corsHeaders })
  }

  console.log('🔑 Generando OTP...')
  const otp = generateOtp(6)
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString() // 10 min
  console.log('🔑 OTP generado:', otp)

  console.log('💾 Guardando OTP en base de datos...')
  const { error: insErr } = await supabase.from('password_reset_otps').insert({
    email,
    otp_code: otp,
    expires_at: expiresAt,
  })
  if (insErr) {
    console.error('❌ Error guardando OTP:', insErr)
    return new Response(JSON.stringify({ error: 'Error guardando OTP' }), { status: 500, headers: corsHeaders })
  }
  console.log('✅ OTP guardado en base de datos')

  // Enviar OTP por email usando SendGrid
  const SENDGRID_API_KEY = Deno.env.get('SENDGRID_API_KEY')
  // Nota: El email debe coincidir con el dominio verificado en SendGrid
  // Si el dominio verificado es em6490.manigrab.app, usar hola@em6490.manigrab.app
  // Si el dominio raíz manigrab.app está verificado, usar hola@manigrab.app
  const SENDGRID_FROM_EMAIL = Deno.env.get('SENDGRID_FROM_EMAIL') || 'hola@em6490.manigrab.app'
  const SENDGRID_FROM_NAME = Deno.env.get('SENDGRID_FROM_NAME') || 'ManiGrab'
  
  console.log('🔍 Verificando configuración SendGrid...')
  console.log('   API Key presente:', !!SENDGRID_API_KEY)
  console.log('   From Email:', SENDGRID_FROM_EMAIL)
  console.log('   From Name:', SENDGRID_FROM_NAME)
  
  if (SENDGRID_API_KEY) {
    try {
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
          value: `
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
                  <div class="otp-code">${otp}</div>
                  <p>Este código expirará en 10 minutos.</p>
                  <p>Si no solicitaste este código, puedes ignorar este mensaje de forma segura.</p>
                  <div class="footer">
                    <p>© ${new Date().getFullYear()} ManiGrab. Todos los derechos reservados.</p>
                  </div>
                </div>
              </div>
            </body>
            </html>
          `
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
        console.error('   Error:', errorText)
        // No retornar error aquí, solo loguear. El OTP ya se guardó en la BD.
        // Continuar para retornar éxito con el OTP
      } else {
        console.log('✅ Email enviado correctamente con SendGrid')
        console.log('   Destino:', email)
        console.log('   Remitente:', SENDGRID_FROM_EMAIL)
      }
    } catch (emailError: any) {
      console.error('❌ Error en envío de email:', emailError)
      // No retornar error aquí, solo loguear. El OTP ya se guardó en la BD.
      // Continuar para retornar éxito con el OTP
    }
  } else {
    console.warn('⚠️ SENDGRID_API_KEY no configurada, email no enviado')
    console.warn('⚠️ Variables disponibles:', {
      hasKey: !!Deno.env.get('SENDGRID_API_KEY'),
      fromEmail: Deno.env.get('SENDGRID_FROM_EMAIL'),
      fromName: Deno.env.get('SENDGRID_FROM_NAME')
    })
  }

  // Siempre retornar éxito si el OTP se guardó correctamente
  // En desarrollo, también retornar el OTP para facilitar pruebas
  const isProd = (Deno.env.get('ENV') || '').toLowerCase() === 'production'
  const response = {
    ok: true,
    dev_otp: isProd ? undefined : otp
  }
  
  console.log('✅ Función completada exitosamente. OTP generado:', otp)
  return new Response(JSON.stringify(response), { status: 200, headers: corsHeaders })
})
