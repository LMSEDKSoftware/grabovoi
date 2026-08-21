import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Verificación server-side de compras de Google Play, antes de otorgar
// premium.
//
// Hasta ahora el cliente escribía "is_active: true" directo en
// user_subscriptions con su propia sesión (RLS solo exigía
// auth.uid() = user_id) -- cualquiera con conocimientos técnicos podía
// mandar esa misma petición a mano, sin pagar nada, y quedar premium.
// Esta función es la única puerta ahora: el cliente le manda el
// purchaseToken que le dio Google Play, esta función le pregunta
// directo a Google si esa compra es real y sigue vigente, y solo
// entonces escribe en la base -- con el service_role, porque el cliente
// ya no puede escribir esa tabla (ver migración
// 20260821_cerrar_escritura_directa_suscripciones.sql).

const PACKAGE_NAME = "com.manifestacion.grabovoi";
const PLAY_SCOPE = "https://www.googleapis.com/auth/androidpublisher";

type ServiceAccount = {
  client_email: string;
  private_key: string;
};

function base64UrlEncode(bytes: Uint8Array): string {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function base64UrlEncodeString(input: string): string {
  return base64UrlEncode(new TextEncoder().encode(input));
}

// PEM -> clave importable por Web Crypto (Deno no trae un parser de PEM
// propio; el PEM es solo el DER en base64 con encabezados alrededor).
async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const cleaned = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const der = Uint8Array.from(atob(cleaned), (c) => c.charCodeAt(0));
  return await crypto.subtle.importKey(
    "pkcs8",
    der.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

// OAuth2 de cuenta de servicio (JWT bearer grant): se firma un JWT propio
// con la llave privada de la cuenta de servicio y Google lo cambia por un
// access_token de verdad. No hay librería de Google para Deno, es el
// mismo procedimiento que usan sus SDKs por debajo.
async function obtenerTokenDeGoogle(sa: ServiceAccount): Promise<string> {
  const ahora = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: sa.client_email,
    scope: PLAY_SCOPE,
    aud: "https://oauth2.googleapis.com/token",
    exp: ahora + 3600,
    iat: ahora,
  };
  const sinFirmar = `${base64UrlEncodeString(JSON.stringify(header))}.${base64UrlEncodeString(JSON.stringify(claim))}`;
  const clave = await importPrivateKey(sa.private_key);
  const firma = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    clave,
    new TextEncoder().encode(sinFirmar),
  );
  const jwt = `${sinFirmar}.${base64UrlEncode(new Uint8Array(firma))}`;

  const resp = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=${encodeURIComponent("urn:ietf:params:oauth:grant-type:jwt-bearer")}&assertion=${jwt}`,
  });
  const data = await resp.json();
  if (!resp.ok || !data.access_token) {
    throw new Error(`No se pudo obtener token de Google: ${JSON.stringify(data)}`);
  }
  return data.access_token as string;
}

// Consulta la API real de Google Play. paymentState=1 es "pago recibido";
// 0 es pendiente (no otorgar todavía) y expiryTimeMillis es la fecha de
// vencimiento REAL calculada por Google -- no una suposición del cliente
// de "hoy + 30 días", que podía desalinearse con lo que Google cobra de
// verdad (renovaciones tempranas/tardías, cambios de plan, etc.).
async function verificarSuscripcionEnGoogle(
  accessToken: string,
  subscriptionId: string,
  purchaseToken: string,
) {
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE_NAME}` +
    `/purchases/subscriptions/${subscriptionId}/tokens/${purchaseToken}`;
  const resp = await fetch(url, { headers: { Authorization: `Bearer ${accessToken}` } });
  const data = await resp.json();
  if (!resp.ok) {
    throw new Error(`Google rechazó la verificación: ${JSON.stringify(data)}`);
  }
  return data as { paymentState?: number; expiryTimeMillis?: string; cancelReason?: number };
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    if (!authHeader) {
      return new Response(JSON.stringify({ success: false, error: "Missing authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const saJson = Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON") ?? "";
    if (!supabaseUrl || !anonKey || !serviceKey || !saJson) {
      return new Response(JSON.stringify({ success: false, error: "server_misconfigured" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Identidad real del usuario, a partir de SU token (no de un
    // user_id que el propio cliente pudiera mandar en el body).
    const authClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userErr } = await authClient.auth.getUser();
    const userId = userData?.user?.id ?? "";
    if (userErr || !userId) {
      return new Response(JSON.stringify({ success: false, error: "unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json().catch(() => ({}));
    const productId = String(body?.productId ?? "");
    const purchaseToken = String(body?.purchaseToken ?? "");
    if (!productId || !purchaseToken) {
      return new Response(JSON.stringify({ success: false, error: "missing_purchase_data" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    if (productId !== "subscription_monthly" && productId !== "subscription_yearly") {
      return new Response(JSON.stringify({ success: false, error: "unknown_product" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const sa = JSON.parse(saJson) as ServiceAccount;
    const accessToken = await obtenerTokenDeGoogle(sa);
    const compra = await verificarSuscripcionEnGoogle(accessToken, productId, purchaseToken);

    const expiraEn = compra.expiryTimeMillis ? new Date(Number(compra.expiryTimeMillis)) : null;
    const vigente = expiraEn !== null && expiraEn.getTime() > Date.now() && compra.paymentState === 1;

    if (!vigente) {
      return new Response(
        JSON.stringify({ success: false, error: "purchase_not_valid", detalle: compra }),
        { status: 402, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Ya verificado de verdad: aquí sí se escribe, con service_role
    // (el cliente ya no tiene permiso de insert/update directo).
    const admin = createClient(supabaseUrl, serviceKey);

    const { data: existente } = await admin
      .from("user_subscriptions")
      .select("id")
      .eq("user_id", userId)
      .eq("purchase_id", purchaseToken)
      .maybeSingle();

    // Cualquier otra suscripción activa de este usuario se desactiva --
    // solo una vigente a la vez, igual que ya hacía el cliente.
    await admin
      .from("user_subscriptions")
      .update({ is_active: false })
      .eq("user_id", userId)
      .eq("is_active", true)
      .neq("purchase_id", purchaseToken);

    if (existente) {
      await admin
        .from("user_subscriptions")
        .update({
          product_id: productId,
          expires_at: expiraEn!.toISOString(),
          is_active: true,
          transaction_date: new Date().toISOString(),
        })
        .eq("id", existente.id);
    } else {
      await admin.from("user_subscriptions").insert({
        user_id: userId,
        product_id: productId,
        purchase_id: purchaseToken,
        transaction_date: new Date().toISOString(),
        expires_at: expiraEn!.toISOString(),
        is_active: true,
        created_at: new Date().toISOString(),
      });
    }

    return new Response(
      JSON.stringify({ success: true, expires_at: expiraEn!.toISOString(), product_id: productId }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("verify-purchase error", e);
    return new Response(JSON.stringify({ success: false, error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
