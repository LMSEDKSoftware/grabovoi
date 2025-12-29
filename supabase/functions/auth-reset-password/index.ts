// deno-lint-ignore-file no-explicit-any
import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

/**
 * SISTEMA ROBUSTO DE RECUPERACIÓN DE CONTRASEÑA
 * Usa el flujo OFICIAL de Supabase (generateLink + recovery token)
 */

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
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: corsHeaders,
    })
  }

  try {
    console.log('🚀 auth-reset-password invocada')
    console.log('📥 Método:', req.method)
    console.log('📥 URL:', req.url)
    
    const body = await req.json().catch((err) => {
      console.error('❌ Error parseando body:', err)
      return {}
    })
    
    console.log('📥 Body recibido:', JSON.stringify(body))
    
    const { email } = body
    
    if (!email || typeof email !== 'string') {
      console.error('❌ Email no válido o faltante')
      return new Response(JSON.stringify({ error: 'email requerido' }), {
        status: 400,
        headers: corsHeaders,
      })
    }

    console.log(`📧 Email recibido: ${email}`)

    const SUPABASE_URL = Deno.env.get('SB_URL')
    const SERVICE_ROLE_KEY = Deno.env.get('SERVICE_ROLE_KEY')
    
    console.log('🔧 Variables de entorno:')
    console.log(`   SUPABASE_URL: ${SUPABASE_URL ? 'Configurado' : 'FALTANTE'}`)
    console.log(`   SERVICE_ROLE_KEY: ${SERVICE_ROLE_KEY ? 'Configurado' : 'FALTANTE'}`)
    
    if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
      console.error('❌ Configuración del servidor incompleta')
      return new Response(JSON.stringify({ error: 'Configuración del servidor incompleta' }), {
        status: 500,
        headers: corsHeaders,
      })
    }

    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

    // Verificar que el usuario existe
    // NOTA: listUsers no acepta filtro por email directamente, necesitamos listar y filtrar
    console.log(`🔍 Verificando usuario: ${email}`)
    const normalizedEmail = email.toLowerCase().trim()
    
    const { data: usersData, error: usersErr } = await supabase.auth.admin.listUsers({
      page: 1,
      perPage: 1000, // Listar más usuarios para buscar
    } as any)

    if (usersErr) {
      console.error('❌ Error listando usuarios:', usersErr)
      // Por seguridad, responder OK aunque haya error
      return new Response(JSON.stringify({ ok: true }), {
        status: 200,
        headers: corsHeaders,
      })
    }

    // Filtrar por email (case-insensitive)
    const user = usersData?.users?.find((u: any) => {
      const userEmail = u.email?.toLowerCase().trim()
      return userEmail === normalizedEmail
    })

    if (!user) {
      // Por seguridad, no revelar si el usuario existe o no
      console.log('⚠️ Usuario no encontrado, pero respondiendo OK por seguridad')
      return new Response(JSON.stringify({ ok: true }), {
        status: 200,
        headers: corsHeaders,
      })
    }

    console.log(`✅ Usuario encontrado: ${user.id} (${user.email})`)

    // MÉTODO OFICIAL: Generar link de recuperación de Supabase
    console.log('🔑 Generando link de recuperación oficial de Supabase...')
    
    // Determinar redirect URL según el entorno
    const redirectTo = Deno.env.get('APP_URL') || 'https://manigrab.app/auth/callback'
    
    const { data: linkData, error: linkError } = await supabase.auth.admin.generateLink({
      type: 'recovery',
      email: email,
      options: {
        redirectTo: redirectTo,
      },
    } as any)

    if (linkError || !linkData?.properties?.action_link) {
      console.error('❌ Error generando link de recuperación:', linkError)
      return new Response(JSON.stringify({ 
        error: 'No se pudo generar link de recuperación',
        details: linkError?.message || 'Error desconocido'
      }), {
        status: 500,
        headers: corsHeaders,
      })
    }

    const recoveryLink = linkData.properties.action_link
    console.log('✅ Link de recuperación generado exitosamente')
    console.log(`   Link: ${recoveryLink.substring(0, 80)}...`)

    // Extraer el token del link
    const tokenMatch = recoveryLink.match(/token=([^&]+)/)
    if (!tokenMatch) {
      console.error('❌ No se pudo extraer token del link')
      return new Response(JSON.stringify({ 
        error: 'Error procesando link de recuperación'
      }), {
        status: 500,
        headers: corsHeaders,
      })
    }

    const recoveryToken = tokenMatch[1]
    console.log(`✅ Token extraído: ${recoveryToken.substring(0, 20)}...`)

    // Enviar email con el link de recuperación usando nuestro servidor con IP estática
    const EMAIL_SERVER_URL = Deno.env.get('EMAIL_SERVER_URL')
    const EMAIL_SERVER_SECRET = Deno.env.get('EMAIL_SERVER_SECRET')
    const APP_NAME = Deno.env.get('APP_NAME') || 'ManiGrab'

    console.log('📧 Configuración de email:')
    console.log(`   EMAIL_SERVER_URL: ${EMAIL_SERVER_URL ? 'Configurado' : 'FALTANTE'}`)
    console.log(`   EMAIL_SERVER_SECRET: ${EMAIL_SERVER_SECRET ? 'Configurado' : 'FALTANTE'}`)
    console.log(`   APP_NAME: ${APP_NAME}`)

    if (EMAIL_SERVER_URL && EMAIL_SERVER_SECRET) {
      console.log('📧 Enviando email de recuperación a través del servidor propio...')
      
      const emailSubject = `Recuperación de contraseña - ${APP_NAME}`
      const emailText = `Hola,\n\nPara recuperar tu contraseña, haz clic en el siguiente enlace:\n${recoveryLink}\n\nEste enlace expirará en 1 hora.\n\nSi no solicitaste este cambio, ignora este mensaje.\n\nSaludos,\nEl equipo de ${APP_NAME}`
      
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
    .button { display: inline-block; padding: 15px 30px; background: #FFD700; color: #1C2541; text-decoration: none; border-radius: 8px; font-weight: bold; margin: 20px 0; }
    .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1 style="color: #1C2541; margin: 0;">${APP_NAME}</h1>
    </div>
    <div class="content">
      <h2 style="color: #1C2541;">Recuperación de Contraseña</h2>
      <p>Hola,</p>
      <p>Recibimos una solicitud para recuperar tu contraseña. Haz clic en el siguiente botón para continuar:</p>
      <div style="text-align: center;">
        <a href="${recoveryLink}" class="button">Recuperar Contraseña</a>
      </div>
      <p>O copia y pega este enlace en tu navegador:</p>
      <p style="word-break: break-all; color: #666; font-size: 12px;">${recoveryLink}</p>
      <p><strong>Este enlace expirará en 1 hora.</strong></p>
      <p>Si no solicitaste este cambio, puedes ignorar este mensaje de forma segura.</p>
      <div class="footer">
        <p>© ${new Date().getFullYear()} ${APP_NAME}. Todos los derechos reservados.</p>
      </div>
    </div>
  </div>
</body>
</html>
      `

      try {
        const serverResponse = await fetch(EMAIL_SERVER_URL, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${EMAIL_SERVER_SECRET}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            to: email,
            subject: emailSubject,
            html: emailHtml,
            text: emailText,
          }),
        })

        if (!serverResponse.ok) {
          const errorText = await serverResponse.text()
          console.error('❌ Error enviando email:', serverResponse.status, errorText)
          return new Response(JSON.stringify({ 
            error: 'No se pudo enviar el email de recuperación',
            details: errorText
          }), {
            status: 500,
            headers: corsHeaders,
          })
        }

        console.log('✅ Email de recuperación enviado correctamente')
        return new Response(JSON.stringify({ 
          ok: true,
          message: 'Email de recuperación enviado'
        }), {
          status: 200,
          headers: corsHeaders,
        })
      } catch (serverError: any) {
        console.error('❌ Error en envío de email:', serverError)
        return new Response(JSON.stringify({ 
          error: 'Error enviando email',
          details: serverError.message
        }), {
          status: 500,
          headers: corsHeaders,
        })
      }
    } else {
      return new Response(JSON.stringify({ 
        error: 'Servidor de email no configurado'
      }), {
        status: 500,
        headers: corsHeaders,
      })
    }
  } catch (err: any) {
    console.error('❌ Error en auth-reset-password:', err)
    return new Response(JSON.stringify({ 
      error: 'Error interno del servidor',
      details: err.message
    }), {
      status: 500,
      headers: corsHeaders,
    })
  }
})

