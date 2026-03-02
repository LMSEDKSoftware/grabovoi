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

  try {
    const { userId, title, body, data: customData } = await req.json();

    if (!userId || !title || !body) {
      return new Response(JSON.stringify({ error: "Missing required fields: userId, title, body" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

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

    const firebaseConfigRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!firebaseConfigRaw) {
      throw new Error("FIREBASE_SERVICE_ACCOUNT not set");
    }
    const firebaseConfig = JSON.parse(firebaseConfigRaw);
    
    const accessToken = await getAccessToken(firebaseConfig);

    const results = [];
    const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${firebaseConfig.project_id}/messages:send`;

    for (const { token } of tokens) {
      const message = {
        message: {
          token: token,
          notification: { title, body },
          data: customData || {},
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
      results.push({ token, result, ok: response.ok });
      
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
