import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function normalizeQuery(input: string): string {
  return input
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim()
    .replace(/\s+/g, " ");
}

function buildQueuedOpenAIContent(query: string): string {
  return JSON.stringify({
    codigos: [],
    sin_fuente: true,
    mensaje:
      "No encontramos evidencia confiable aún. Guardamos tu búsqueda para revisión automática. Mientras tanto te doy alternativas cercanas.",
    query,
    queued: true,
  });
}

async function enqueueRequest(params: {
  userId: string;
  queryText: string;
  queryNorm: string;
}): Promise<{ queued: boolean; id?: number }> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!supabaseUrl || !serviceKey) {
    console.error("missing supabase env for queue insert");
    return { queued: false };
  }

  const supabase = createClient(supabaseUrl, serviceKey);

  // Insert (dedupe por usuario+query_norm via índice parcial).
  const now = new Date().toISOString();
  const { data: inserted, error: insError } = await supabase
    .from("deep_search_requests")
    .insert({
      user_id: params.userId,
      query_text: params.queryText,
      query_norm: params.queryNorm,
      status: "pending",
      updated_at: now,
      created_at: now,
    })
    .select("id")
    .single();

  if (!insError) {
    return { queued: true, id: inserted?.id as number | undefined };
  }

  // Si ya existe pendiente, tocar updated_at para “refrescar” la demanda del usuario.
  // (Postgres devuelve 23505 por unique violation)
  const msg = String((insError as any)?.message ?? "");
  if (!msg.toLowerCase().includes("duplicate") && !(insError as any)?.code) {
    console.error("deep_search_requests insert error", insError);
    return { queued: false };
  }

  const { data: existing, error: selErr } = await supabase
    .from("deep_search_requests")
    .select("id")
    .eq("user_id", params.userId)
    .eq("query_norm", params.queryNorm)
    .eq("status", "pending")
    .order("updated_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (selErr || !existing?.id) {
    console.error("deep_search_requests select error", selErr);
    return { queued: false };
  }

  const { error: updErr } = await supabase
    .from("deep_search_requests")
    .update({ updated_at: now, query_text: params.queryText })
    .eq("id", existing.id);
  if (updErr) {
    console.error("deep_search_requests update error", updErr);
    return { queued: false };
  }

  return { queued: true, id: existing.id as number };
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = req.method === "POST" ? await req.json().catch(() => ({})) : {};
    const query = String(body?.query ?? "").trim();
    if (!query) {
      return new Response(JSON.stringify({ success: false, error: "Missing query" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Requiere auth para poder notificar luego (email en siguiente iteración).
    const authHeader = req.headers.get("Authorization") ?? "";
    if (!authHeader) {
      return new Response(JSON.stringify({ success: false, error: "Missing authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    if (!supabaseUrl || !anonKey) {
      return new Response(JSON.stringify({ success: false, error: "Missing SUPABASE_URL/SUPABASE_ANON_KEY" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const authClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userErr } = await authClient.auth.getUser();
    const userId = userData?.user?.id ?? "";
    if (userErr || !userId) {
      console.error("auth.getUser error", userErr);
      return new Response(JSON.stringify({ success: false, error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const queryNorm = normalizeQuery(query);
    const queueResult = await enqueueRequest({
      userId,
      queryText: query,
      queryNorm,
    });
    const openaiContent = buildQueuedOpenAIContent(query);

    return new Response(
      JSON.stringify({
        success: true,
        query,
        openai_content: openaiContent,
        queued: true,
        request_id: queueResult.id ?? null,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("deep-search-codes unexpected error:", error);
    return new Response(JSON.stringify({ success: false, error: "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
