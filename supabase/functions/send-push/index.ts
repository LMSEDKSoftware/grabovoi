import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import * as djwt from "https://deno.land/x/djwt@v2.8/mod.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

async function getAccessToken(firebaseConfig: any) {
  const header = { alg: "RS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: firebaseConfig.client_email,
    sub: firebaseConfig.client_email,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
    scope: "https://www.googleapis.com/auth/cloud-platform",
  };

  // Convert PEM to CryptoKey
  const pem = firebaseConfig.private_key;
  const pemHeader = "-----BEGIN PRIVATE KEY-----";
  const pemFooter = "-----END PRIVATE KEY-----";
  const pemContents = pem.substring(
    pem.indexOf(pemHeader) + pemHeader.length,
    pem.indexOf(pemFooter)
  ).replace(/\s/g, "");
  
  const binaryDerString = atob(pemContents);
  const binaryDer = new Uint8Array(binaryDerString.length);
  for (let i = 0; i < binaryDerString.length; i++) {
    binaryDer[i] = binaryDerString.charCodeAt(i);
  }

  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const jwt = await djwt.create(header, payload, key);

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const data = await res.json();
  if (!res.ok) {
    throw new Error(`Failed to get access token: ${JSON.stringify(data)}`);
  }
  return data.access_token;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  // MANEJO DE TRACKING (GET)
  if (req.method === "GET") {
    try {
      const url = new URL(req.url);
      const logId = url.searchParams.get("log_id");
      const action = url.searchParams.get("action"); // 'received' o 'opened'

      if (!logId || !action) {
        return new Response(JSON.stringify({ error: "Missing log_id or action" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      // log_id es un UUID aleatorio (no secuencial/adivinable) y este endpoint
      // se llama sin sesión desde el dispositivo al recibir un push, así que no
      // exigimos JWT aquí; sí acotamos 'action' a los dos valores válidos.
      if (action !== 'received' && action !== 'opened') {
        return new Response(JSON.stringify({ error: "Invalid action" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
      const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
      const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

      const updateData: any = { status: action };
      if (action === 'received') updateData.received_at = new Date().toISOString();
      if (action === 'opened') updateData.opened_at = new Date().toISOString();

      const { error } = await supabaseAdmin
        .from('notification_logs')
        .update(updateData)
        .eq('id', logId);

      if (error) throw error;

      return new Response(JSON.stringify({ success: true }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    } catch (err: any) {
      return new Response(JSON.stringify({ error: err.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
  }

  // --- SEGURIDAD: solo la función notify_push_from_db() (trigger de Postgres,
  // ver scripts/realtime_notifications_setup.sql) puede disparar envíos reales.
  // Antes cualquiera en internet podía mandar push a un userId o hacer broadcast
  // a un topic (a toda la base de usuarios) sin ninguna autenticación.
  const PUSH_SECRET = Deno.env.get("PUSH_SECRET");
  if (!PUSH_SECRET) {
    return new Response(JSON.stringify({ error: "PUSH_SECRET no configurado" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
  if (req.headers.get("x-push-secret") !== PUSH_SECRET) {
    return new Response(JSON.stringify({ error: "No autorizado" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
  // ---------------------------------------------------------------------

  try {
    const { userId, topic, title, body, data: customData } = await req.json();

    if ((!userId && !topic) || !title || !body) {
      return new Response(JSON.stringify({ error: "Missing required fields: (userId or topic), title, body" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const firebaseConfigRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!firebaseConfigRaw) {
      throw new Error("FIREBASE_SERVICE_ACCOUNT not set");
    }
    const firebaseConfig = JSON.parse(firebaseConfigRaw);
    const accessToken = await getAccessToken(firebaseConfig);
    const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${firebaseConfig.project_id}/messages:send`;

    // CASO 1: Envío a un TOPIC (Broadcast)
    if (topic) {
      const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
      const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
      const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

      // 1. CREAR LOG PRIMERO PARA TENER EL ID
      const { data: logEntry, error: logError } = await supabaseAdmin
        .from('notification_logs')
        .insert({
          topic: topic,
          title: title,
          body: body,
          data: customData || {},
          status: 'pending'
        })
        .select()
        .single();

      if (logError) throw logError;
      const logId = logEntry.id;

      const message = {
        message: {
          topic: topic,
          notification: { title, body },
          data: { ...(customData || {}), logId: logId }, // INCLUIR logId AQUÍ
          android: { 
            priority: "high", 
            notification: { 
              sound: "default",
              click_action: "FLUTTER_NOTIFICATION_CLICK"
            } 
          },
          apns: { 
            payload: { 
              aps: { 
                sound: "default",
                badge: 1,
                "content-available": 1
              } 
            } 
          }
        }
      };

      const response = await fetch(fcmEndpoint, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(message),
      });

      const result = await response.json();
      
      // 2. ACTUALIZAR LOG CON EL RESULTADO DE FIREBASE
      await supabaseAdmin.from('notification_logs').update({
        status: response.ok ? 'sent' : 'error',
        fcm_message_id: result.name || null,
        error_details: response.ok ? null : JSON.stringify(result)
      }).eq('id', logId);

      return new Response(JSON.stringify({ success: response.ok, result, topic, logId }), {
        status: response.ok ? 200 : 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // CASO 2: Envío por userId (Existente)
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Único punto por el que pasan todos los envíos por userId (triggers de
    // Postgres vía notify_push_from_db, y los cron de challenge-streak-check /
    // engagement-notifications-check): si el usuario apagó las notificaciones
    // desde la app, no se manda nada, sin importar qué evento lo disparó.
    const { data: userRow } = await supabaseAdmin
      .from('users')
      .select('notifications_enabled')
      .eq('id', userId)
      .maybeSingle();
    if (userRow && userRow.notifications_enabled === false) {
      return new Response(JSON.stringify({ success: true, skipped: 'notifications_disabled_by_user' }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: tokens, error: tokenError } = await supabaseAdmin
      .from('user_fcm_tokens')
      .select('token')
      .eq('user_id', userId);

    if (tokenError || !tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ error: "No FCM tokens found for this user", details: tokenError }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const results = [];
    for (const { token } of tokens) {
      // 1. CREAR LOG PARA CADA TOKEN RECONOCIDO
      const { data: logEntry, error: logError } = await supabaseAdmin
        .from('notification_logs')
        .insert({
          user_id: userId,
          title: title,
          body: body,
          data: { ...(customData || {}), target_token: token },
          status: 'pending'
        })
        .select()
        .single();

      if (logError) {
        console.error("Error creating log entry:", logError);
        continue;
      }
      const logId = logEntry.id;

      const message = {
        message: {
          token: token,
          notification: { title, body },
          data: { ...(customData || {}), logId: logId }, // INCLUIR logId AQUÍ
          android: { 
            priority: "high", 
            notification: { 
              sound: "default",
              click_action: "FLUTTER_NOTIFICATION_CLICK"
            } 
          },
          apns: { 
            payload: { 
              aps: { 
                sound: "default",
                badge: 1,
                "content-available": 1
              } 
            } 
          }
        }
      };

      const response = await fetch(fcmEndpoint, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(message),
      });

      const result = await response.json();
      results.push({ token, result, ok: response.ok, logId });
      
      // 2. ACTUALIZAR LOG CON EL RESULTADO
      await supabaseAdmin.from('notification_logs').update({
        status: response.ok ? 'sent' : 'error',
        fcm_message_id: result.name || null,
        error_details: response.ok ? null : JSON.stringify(result)
      }).eq('id', logId);

      if (!response.ok && (result.error?.status === "NOT_FOUND" || result.error?.status === "UNREGISTERED")) {
        await supabaseAdmin.from('user_fcm_tokens').delete().eq('token', token);
      }
    }

    return new Response(JSON.stringify({ success: true, results }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (err: any) {
    console.error("❌ send-push error:", err);
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
