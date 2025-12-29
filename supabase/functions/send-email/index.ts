import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const { to, template, userId, name, actionUrl, otpCode } = await req.json();

    if (!to || typeof to !== "string") {
      return new Response(JSON.stringify({ error: "Missing 'to' email" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Configuración de envío de email
    // Opción 1: Usar servidor propio con IP estática (recomendado para whitelist)
    const EMAIL_SERVER_URL = Deno.env.get("EMAIL_SERVER_URL");
    const EMAIL_SERVER_SECRET = Deno.env.get("EMAIL_SERVER_SECRET");
    
    // Opción 2: Enviar directamente desde Supabase (requiere IP en whitelist)
    const API_KEY = Deno.env.get("SENDGRID_API_KEY");
    const FROM_EMAIL = Deno.env.get("SENDGRID_FROM_EMAIL");
    const FROM_NAME = Deno.env.get("SENDGRID_FROM_NAME") ?? "ManiGrab";
    const TEMPLATE_WELCOME = Deno.env.get("SENDGRID_TEMPLATE_WELCOME");
    const TEMPLATE_OTP = Deno.env.get("SENDGRID_TEMPLATE_OTP");
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const APP_NAME = Deno.env.get("APP_NAME") ?? "ManiGrab";

    console.log("🔍 Verificando configuración de envío de email...");
    console.log("   Email Server URL:", EMAIL_SERVER_URL || "No configurado");
    console.log("   Email Server Secret:", EMAIL_SERVER_SECRET ? "Configurado" : "No configurado");
    console.log("   SendGrid API Key:", API_KEY ? "Configurado" : "No configurado");

    // Preparar datos dinámicos según el template (necesario para ambos métodos)
    let dynamicTemplateData: any = {
      app_name: APP_NAME,
      name: name || "Usuario",
    };

    if (template === "welcome_or_confirm") {
      // Para correo de bienvenida, generar action_url con token de confirmación
      // Si actionUrl ya viene proporcionado, usarlo como redirectTo para generar el link
      const redirectToUrl = actionUrl || (SUPABASE_URL ? `${SUPABASE_URL.replace('/rest/v1', '')}/auth/callback` : 'https://manigrab.app/auth/callback');
      
      console.log("🔗 Generando link de confirmación...");
      console.log("   Email:", to);
      console.log("   User ID:", userId);
      console.log("   Redirect URL:", redirectToUrl);
      console.log("   SUPABASE_URL:", SUPABASE_URL || "No configurado");
      console.log("   SUPABASE_SERVICE_ROLE_KEY:", SUPABASE_SERVICE_ROLE_KEY ? "Configurado" : "No configurado");
      
      if (userId && SUPABASE_URL && SUPABASE_SERVICE_ROLE_KEY) {
        try {
          const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
          
          // Intentar generar link de confirmación usando admin API
          // Primero intentamos con 'signup', si falla porque el usuario ya existe, intentamos con 'recovery'
          let linkData = null;
          let linkError = null;
          
          // Intentar con type: 'signup' primero
          const signupResult = await supabaseAdmin.auth.admin.generateLink({
            type: 'signup',
            email: to,
            options: {
              redirectTo: redirectToUrl,
            },
          });
          
          linkData = signupResult.data;
          linkError = signupResult.error;
          
          // Si falla porque el usuario ya existe, intentar con 'recovery' o 'magiclink'
          if (linkError && (linkError.message?.includes('already been registered') || linkError.code === 'email_exists')) {
            console.log("⚠️ Usuario ya existe, intentando generar link de recuperación...");
            const recoveryResult = await supabaseAdmin.auth.admin.generateLink({
              type: 'recovery',
              email: to,
              options: {
                redirectTo: redirectToUrl,
              },
            });
            
            if (!recoveryResult.error && recoveryResult.data?.properties?.action_link) {
              linkData = recoveryResult.data;
              linkError = null;
              console.log("✅ Link de recuperación generado exitosamente");
            } else {
              linkError = recoveryResult.error;
              console.warn("⚠️ No se pudo generar link de recuperación, usando URL básica");
            }
          }

          if (!linkError && linkData?.properties?.action_link) {
            dynamicTemplateData.action_url = linkData.properties.action_link;
            console.log("✅ Link de confirmación generado exitosamente");
            console.log("   Link completo:", linkData.properties.action_link);
            console.log("   Link (primeros 100 chars):", linkData.properties.action_link.substring(0, 100) + "...");
          } else {
            console.error("❌ Error generando link de confirmación");
            console.error("   Error:", linkError);
            // Fallback: construir URL básica (sin token, el usuario tendrá que usar otro método)
            console.warn("⚠️ Usando URL básica como fallback:", redirectToUrl);
            dynamicTemplateData.action_url = redirectToUrl;
          }
        } catch (err: any) {
          console.error("❌ Error en generateLink:", err);
          console.error("   Tipo:", err?.constructor?.name);
          console.error("   Mensaje:", err?.message);
          // Fallback: usar URL básica
          console.warn("⚠️ Usando URL básica como fallback:", redirectToUrl);
          dynamicTemplateData.action_url = redirectToUrl;
        }
      } else {
        // Si no hay credenciales de admin, usar URL básica
        console.warn("⚠️ No hay credenciales de admin, usando URL básica:", redirectToUrl);
        dynamicTemplateData.action_url = redirectToUrl;
      }
    } else if (template === "otp") {
      // Para OTP, incluir el código
      if (otpCode) {
        dynamicTemplateData.otp_code = otpCode;
      } else {
        console.error("❌ Falta otpCode para template OTP");
        return new Response(JSON.stringify({ error: "Missing otpCode for OTP template" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    }

    // OPCIÓN 1: Usar servidor propio con IP estática (recomendado)
    if (EMAIL_SERVER_URL && EMAIL_SERVER_SECRET) {
      try {
        console.log("📧 Enviando email a través del servidor propio (IP estática)...");
        console.log("   Servidor:", EMAIL_SERVER_URL);
        
        // Construir HTML del email según el template
        let emailHtml = "";
        let emailSubject = "";
        let emailText = "";
        
        if (template === "welcome_or_confirm") {
          emailSubject = `¡Bienvenido a ${APP_NAME}! Activa tu cuenta`;
          emailText = `Hola ${name || "Usuario"},\n\n¡Bienvenido a ${APP_NAME}!\n\nPara activar tu cuenta, haz clic en el siguiente enlace:\n${dynamicTemplateData.action_url}\n\nSi no solicitaste este registro, puedes ignorar este mensaje.\n\nSaludos,\nEl equipo de ${APP_NAME}`;
          emailHtml = `
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
                  <p style="color: #1C2541; margin: 10px 0 0 0;">Manifestaciones Cuánticas Grabovoi</p>
                </div>
                <div class="content">
                  <h2 style="color: #1C2541;">¡Bienvenido${name ? `, ${name}` : ""}!</h2>
                  <p>Gracias por registrarte en ${APP_NAME}. Estamos emocionados de tenerte con nosotros.</p>
                  <p>Para activar tu cuenta y comenzar tu viaje de transformación personal, haz clic en el siguiente botón:</p>
                  <div style="text-align: center;">
                    <a href="${dynamicTemplateData.action_url}" class="button">Activar mi cuenta</a>
                  </div>
                  <p>O copia y pega este enlace en tu navegador:</p>
                  <p style="word-break: break-all; color: #666; font-size: 12px;">${dynamicTemplateData.action_url}</p>
                  <p>Si no solicitaste este registro, puedes ignorar este mensaje de forma segura.</p>
                  <div class="footer">
                    <p>© ${new Date().getFullYear()} ${APP_NAME}. Todos los derechos reservados.</p>
                  </div>
                </div>
              </div>
            </body>
            </html>
          `;
        } else if (template === "otp") {
          emailSubject = `Código de verificación - ${APP_NAME}`;
          emailText = `Tu código de verificación es: ${dynamicTemplateData.otp_code || otpCode}`;
          emailHtml = `
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
                  <h1 style="color: #1C2541; margin: 0;">${APP_NAME}</h1>
                  <p style="color: #1C2541; margin: 10px 0 0 0;">Manifestaciones Cuánticas Grabovoi</p>
                </div>
                <div class="content">
                  <h2 style="color: #1C2541;">Código de Verificación</h2>
                  <p>Hola${name ? ` ${name}` : ""},</p>
                  <p>Tu código de verificación es:</p>
                  <div class="otp-code">${dynamicTemplateData.otp_code || otpCode}</div>
                  <p>Este código expirará en 10 minutos.</p>
                  <p>Si no solicitaste este código, puedes ignorar este mensaje de forma segura.</p>
                  <div class="footer">
                    <p>© ${new Date().getFullYear()} ${APP_NAME}. Todos los derechos reservados.</p>
                  </div>
                </div>
              </div>
            </body>
            </html>
          `;
        }
        
        const serverResponse = await fetch(EMAIL_SERVER_URL, {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${EMAIL_SERVER_SECRET}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            to: to,
            subject: emailSubject,
            html: emailHtml,
            text: emailText,
          }),
        });
        
        if (!serverResponse.ok) {
          const errorText = await serverResponse.text();
          console.error("❌ Error enviando email a través del servidor");
          console.error("   Status:", serverResponse.status);
          console.error("   Error:", errorText);
          // Fallback a envío directo si el servidor falla
          console.log("⚠️ Intentando envío directo como fallback...");
        } else {
          const result = await serverResponse.json();
          console.log("✅ Email enviado correctamente a través del servidor");
          console.log("   Destino:", to);
          return new Response(JSON.stringify({ ok: true }), {
            status: 200,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }
      } catch (serverError: any) {
        console.error("❌ Error en envío a través del servidor:", serverError);
        console.log("⚠️ Intentando envío directo como fallback...");
        // Continuar con envío directo como fallback
      }
    }
    
    // OPCIÓN 2: Envío directo desde Supabase (requiere IP en whitelist)
    if (!API_KEY || !FROM_EMAIL) {
      console.error("❌ Faltan variables SENDGRID_API_KEY o SENDGRID_FROM_EMAIL");
      return new Response(JSON.stringify({ error: "Missing SendGrid configuration" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Verificar template_id solo para envío directo (no necesario para servidor propio)
    const templateId = template === "welcome_or_confirm" ? TEMPLATE_WELCOME : TEMPLATE_OTP;

    if (!templateId) {
      console.error("❌ Falta template_id de SendGrid para el template:", template);
      return new Response(JSON.stringify({ error: "Missing SendGrid template id" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    console.log("📧 Enviando email directamente desde Supabase...");
    const payload = {
      personalizations: [
        {
          to: [{ email: to }],
          dynamic_template_data: dynamicTemplateData,
        },
      ],
      from: {
        email: FROM_EMAIL,
        name: FROM_NAME,
      },
      template_id: templateId,
    };

    const sgResponse = await fetch("https://api.sendgrid.com/v3/mail/send", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    if (!sgResponse.ok) {
      const text = await sgResponse.text();
      console.error("❌ Error enviando email con SendGrid:", sgResponse.status, text);
      return new Response(JSON.stringify({ error: text }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("❌ Error en send-email:", err);
    const message = err instanceof Error ? err.message : "Unknown error";
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
