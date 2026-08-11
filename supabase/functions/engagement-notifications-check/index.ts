import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Mismo largo de prueba gratis que SubscriptionService.freeTrialDays en el
// cliente (lib/services/subscription_service.dart).
const FREE_TRIAL_DAYS = 7;

// Hora y fecha LOCALES del usuario a partir de su timezone IANA guardada en
// user_metadata (mismo helper que challenge-streak-check/index.ts).
function localHourDateWeekday(tz: string, now: Date): { hour: number; dateStr: string; weekday: number } {
  try {
    const parts = new Intl.DateTimeFormat("en-CA", {
      timeZone: tz,
      hour: "numeric",
      hour12: false,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      weekday: "short",
    }).formatToParts(now);
    const get = (type: string) => parts.find((p) => p.type === type)?.value ?? "";
    const hour = Number(get("hour")) % 24;
    const dateStr = `${get("year")}-${get("month")}-${get("day")}`;
    const weekdayMap: Record<string, number> = { Sun: 0, Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6 };
    const weekday = weekdayMap[get("weekday")] ?? new Date(dateStr).getUTCDay();
    return { hour, dateStr, weekday };
  } catch {
    return { hour: now.getUTCHours(), dateStr: now.toISOString().slice(0, 10), weekday: now.getUTCDay() };
  }
}

async function sendPush(params: {
  supabaseUrl: string;
  pushSecret: string;
  anonKey: string;
  userId: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}): Promise<void> {
  const { supabaseUrl, pushSecret, anonKey, userId, title, body, data } = params;
  if (!pushSecret || !userId) return;
  try {
    const resp = await fetch(`${supabaseUrl}/functions/v1/send-push`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        // El gateway de Supabase exige Authorization antes de correr el
        // código de la función, aunque send-push valide su propio
        // x-push-secret por dentro.
        "Authorization": `Bearer ${anonKey}`,
        "x-push-secret": pushSecret,
      },
      body: JSON.stringify({ userId, title, body, data: data ?? {} }),
    });
    if (!resp.ok) {
      const text = await resp.text().catch(() => "");
      console.error(`sendPush: fallo para user ${userId}: ${resp.status} ${text.slice(0, 200)}`);
    }
  } catch (e) {
    console.error(`sendPush: error para user ${userId}:`, e);
  }
}

async function sendBroadcast(params: {
  supabaseUrl: string;
  pushSecret: string;
  anonKey: string;
  topic: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}): Promise<void> {
  const { supabaseUrl, pushSecret, anonKey, topic, title, body, data } = params;
  try {
    const resp = await fetch(`${supabaseUrl}/functions/v1/send-push`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${anonKey}`,
        "x-push-secret": pushSecret,
      },
      body: JSON.stringify({ topic, title, body, data: data ?? {} }),
    });
    if (!resp.ok) {
      const text = await resp.text().catch(() => "");
      console.error(`sendBroadcast: fallo para topic ${topic}: ${resp.status} ${text.slice(0, 200)}`);
    }
  } catch (e) {
    console.error(`sendBroadcast: error para topic ${topic}:`, e);
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const cronSecret = Deno.env.get("CRON_SECRET") ?? "";
  if (!cronSecret) {
    return new Response(JSON.stringify({ success: false, error: "CRON_SECRET no configurado" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
  if ((req.headers.get("x-cron-secret") ?? "") !== cronSecret) {
    return new Response(JSON.stringify({ success: false, error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const pushSecret = Deno.env.get("PUSH_SECRET") ?? "";
  if (!supabaseUrl || !serviceKey) {
    return new Response(
      JSON.stringify({ success: false, error: "Missing SUPABASE_URL/SUPABASE_SERVICE_ROLE_KEY" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
  const supabase = createClient(supabaseUrl, serviceKey);
  const now = new Date();

  const results = {
    weeklySummariesSent: 0,
    trialWarningsSent: 0,
    anniversariesSent: 0,
    monthlyTrendsSent: 0,
    recommendationsSent: 0,
    rankingsSent: 0,
    seasonalBroadcastSent: 0,
    errors: [] as any[],
  };

  // ── 1) Resumen semanal: lunes 9 a.m. local, una vez por semana ──
  try {
    const { data: rows, error } = await supabase
      .from("usuario_progreso")
      .select("user_id, nivel_energetico, last_weekly_summary_date");
    if (error) throw new Error(`usuario_progreso_select_failed:${error.message}`);

    for (const row of (rows ?? []) as any[]) {
      try {
        let timezone = "UTC";
        try {
          const { data: userResp } = await supabase.auth.admin.getUserById(row.user_id);
          timezone = (userResp?.user?.user_metadata as any)?.timezone || "UTC";
        } catch (e) {
          console.error(`No se pudo obtener timezone de ${row.user_id}:`, e);
        }

        const { hour, dateStr, weekday } = localHourDateWeekday(timezone, now);
        if (weekday !== 1 || hour !== 9) continue;
        if (row.last_weekly_summary_date === dateStr) continue;

        const weekAgo = new Date(now.getTime() - 7 * 86400000);
        const { data: actions } = await supabase
          .from("user_actions")
          .select("action_type, action_data")
          .eq("user_id", row.user_id)
          .eq("action_type", "sesionPilotaje")
          .gte("recorded_at", weekAgo.toISOString());

        const pilotajes = (actions ?? []).length;
        const codesUsed = new Set(
          (actions ?? []).map((a: any) => a.action_data?.codeId).filter(Boolean),
        ).size;

        if (pilotajes > 0) {
          await sendPush({
            supabaseUrl, pushSecret, anonKey, userId: row.user_id,
            title: "📊 Tu semana cuántica",
            body: `${pilotajes} pilotajes, ${codesUsed} códigos usados, nivel ${row.nivel_energetico}/10. ¡Sigue así!`,
            data: { type: "weekly_progress_summary" },
          });
          results.weeklySummariesSent += 1;
        }

        await supabase.from("usuario_progreso").update({ last_weekly_summary_date: dateStr })
          .eq("user_id", row.user_id);
      } catch (e) {
        results.errors.push({ stage: "weekly_summary", user_id: row.user_id, error: String(e) });
      }
    }
  } catch (e) {
    results.errors.push({ stage: "weekly_summary_outer", error: String(e) });
  }

  // ── 2) Prueba gratis por terminar: ~2 días antes de que termine (10 a.m. local) ──
  try {
    const { data: rows, error } = await supabase
      .from("users")
      .select("id, created_at")
      .eq("trial_ending_notified", false);
    if (error) throw new Error(`users_select_failed:${error.message}`);

    for (const row of (rows ?? []) as any[]) {
      try {
        const createdAt = new Date(row.created_at);
        const daysSinceCreated = Math.floor((now.getTime() - createdAt.getTime()) / 86400000);
        const daysLeft = FREE_TRIAL_DAYS - daysSinceCreated;
        // Ventana: entre 1 y 2 días restantes de prueba (evita reintentos infinitos
        // si por algún motivo la corrida de la hora exacta se pierde).
        if (daysLeft > 2 || daysLeft < 1) continue;

        let timezone = "UTC";
        try {
          const { data: userResp } = await supabase.auth.admin.getUserById(row.id);
          timezone = (userResp?.user?.user_metadata as any)?.timezone || "UTC";
        } catch (e) {
          console.error(`No se pudo obtener timezone de ${row.id}:`, e);
        }
        const { hour } = localHourDateWeekday(timezone, now);
        if (hour !== 10) continue;

        const { data: activeSub } = await supabase
          .from("user_subscriptions")
          .select("id")
          .eq("user_id", row.id)
          .eq("is_active", true)
          .gt("expires_at", now.toISOString())
          .maybeSingle();
        if (activeSub) {
          // Ya es premium: no necesita el aviso, marcar como resuelto.
          await supabase.from("users").update({ trial_ending_notified: true }).eq("id", row.id);
          continue;
        }

        const diasTexto = daysLeft === 1 ? "1 día" : `${daysLeft} días`;
        await sendPush({
          supabaseUrl, pushSecret, anonKey, userId: row.id,
          title: "⏳ Tu prueba gratis termina pronto",
          body: `Te quedan ${diasTexto} de acceso Premium gratis. Suscríbete para no perder tus beneficios.`,
          data: { type: "trial_ending_soon", days_left: String(daysLeft) },
        });
        results.trialWarningsSent += 1;
        await supabase.from("users").update({ trial_ending_notified: true }).eq("id", row.id);
      } catch (e) {
        results.errors.push({ stage: "trial_ending", user_id: row.id, error: String(e) });
      }
    }
  } catch (e) {
    results.errors.push({ stage: "trial_ending_outer", error: String(e) });
  }

  // ── 3) Aniversario de registro: mismo mes/día que created_at, 10 a.m. local ──
  try {
    const { data: rows, error } = await supabase
      .from("users")
      .select("id, created_at, last_anniversary_year");
    if (error) throw new Error(`users_anniversary_select_failed:${error.message}`);

    for (const row of (rows ?? []) as any[]) {
      try {
        const createdAt = new Date(row.created_at);
        let timezone = "UTC";
        try {
          const { data: userResp } = await supabase.auth.admin.getUserById(row.id);
          timezone = (userResp?.user?.user_metadata as any)?.timezone || "UTC";
        } catch (e) {
          console.error(`No se pudo obtener timezone de ${row.id}:`, e);
        }

        const { hour, dateStr } = localHourDateWeekday(timezone, now);
        if (hour !== 10) continue;

        const [localYearStr, localMonthStr, localDayStr] = dateStr.split("-");
        const localYear = Number(localYearStr);
        const createdMonth = createdAt.getUTCMonth() + 1;
        const createdDay = createdAt.getUTCDate();
        if (Number(localMonthStr) !== createdMonth || Number(localDayStr) !== createdDay) continue;

        const years = localYear - createdAt.getUTCFullYear();
        if (years < 1) continue;
        if (row.last_anniversary_year === years) continue;

        await sendPush({
          supabaseUrl, pushSecret, anonKey, userId: row.id,
          title: "🎂 ¡Feliz aniversario!",
          body: `Hace ${years} ${years === 1 ? "año" : "años"} comenzaste tu viaje cuántico con ManiGraB. ¡Gracias por tu constancia!`,
          data: { type: "registration_anniversary", years: String(years) },
        });
        results.anniversariesSent += 1;
        await supabase.from("users").update({ last_anniversary_year: years }).eq("id", row.id);
      } catch (e) {
        results.errors.push({ stage: "anniversary", user_id: row.id, error: String(e) });
      }
    }
  } catch (e) {
    results.errors.push({ stage: "anniversary_outer", error: String(e) });
  }

  // ── 4) Análisis mensual: día 1 del mes local, 11 a.m. local ──
  try {
    const { data: rows, error } = await supabase
      .from("usuario_progreso")
      .select("user_id, nivel_energetico, last_monthly_summary_month");
    if (error) throw new Error(`monthly_select_failed:${error.message}`);

    for (const row of (rows ?? []) as any[]) {
      try {
        let timezone = "UTC";
        try {
          const { data: userResp } = await supabase.auth.admin.getUserById(row.user_id);
          timezone = (userResp?.user?.user_metadata as any)?.timezone || "UTC";
        } catch (e) {
          console.error(`No se pudo obtener timezone de ${row.user_id}:`, e);
        }

        const { hour, dateStr } = localHourDateWeekday(timezone, now);
        const [localYear, localMonth, localDay] = dateStr.split("-");
        if (localDay !== "01" || hour !== 11) continue;

        const monthKey = `${localYear}-${localMonth}`;
        if (row.last_monthly_summary_month === monthKey) continue;

        const monthAgo = new Date(now.getTime() - 30 * 86400000);
        const { data: actions } = await supabase
          .from("user_actions")
          .select("action_type, action_data")
          .eq("user_id", row.user_id)
          .eq("action_type", "sesionPilotaje")
          .gte("recorded_at", monthAgo.toISOString());

        const pilotajes = (actions ?? []).length;
        if (pilotajes > 0) {
          const codesUsed = new Set(
            (actions ?? []).map((a: any) => a.action_data?.codeId).filter(Boolean),
          ).size;

          await sendPush({
            supabaseUrl, pushSecret, anonKey, userId: row.user_id,
            title: "📈 Tu mes en números",
            body: `Este mes completaste ${pilotajes} pilotajes con ${codesUsed} secuencias distintas. Tu nivel energético actual es ${row.nivel_energetico}/10.`,
            data: { type: "monthly_trends_analysis" },
          });
          results.monthlyTrendsSent += 1;
        }

        await supabase.from("usuario_progreso").update({ last_monthly_summary_month: monthKey })
          .eq("user_id", row.user_id);
      } catch (e) {
        results.errors.push({ stage: "monthly_trends", user_id: row.user_id, error: String(e) });
      }
    }
  } catch (e) {
    results.errors.push({ stage: "monthly_trends_outer", error: String(e) });
  }

  // ── 5) Recomendación personalizada: jueves 9 a.m. local, código popular que el usuario no ha probado ──
  try {
    const { data: rows, error } = await supabase
      .from("usuario_progreso")
      .select("user_id, last_code_recommendation_week");
    if (error) throw new Error(`recommend_select_failed:${error.message}`);

    const { data: popular } = await supabase
      .from("codigo_popularidad")
      .select("codigo_id, contador")
      .order("contador", { ascending: false })
      .limit(50);

    for (const row of (rows ?? []) as any[]) {
      try {
        let timezone = "UTC";
        try {
          const { data: userResp } = await supabase.auth.admin.getUserById(row.user_id);
          timezone = (userResp?.user?.user_metadata as any)?.timezone || "UTC";
        } catch (e) {
          console.error(`No se pudo obtener timezone de ${row.user_id}:`, e);
        }

        const { hour, dateStr, weekday } = localHourDateWeekday(timezone, now);
        if (weekday !== 4 || hour !== 9) continue;

        // Dedupe por semana: usar el lunes de esa semana local como clave.
        const localDate = new Date(`${dateStr}T00:00:00Z`);
        const mondayOffset = (localDate.getUTCDay() + 6) % 7;
        const monday = new Date(localDate.getTime() - mondayOffset * 86400000);
        const weekKey = monday.toISOString().slice(0, 10);
        if (row.last_code_recommendation_week === weekKey) continue;

        const { data: used } = await supabase
          .from("user_code_history")
          .select("code_id")
          .eq("user_id", row.user_id);
        const usedIds = new Set((used ?? []).map((u: any) => u.code_id));

        const candidate = (popular ?? []).find((p: any) => !usedIds.has(p.codigo_id));
        await supabase.from("usuario_progreso").update({ last_code_recommendation_week: weekKey })
          .eq("user_id", row.user_id);
        if (!candidate) continue;

        const { data: codeInfo } = await supabase
          .from("codigos_grabovoi")
          .select("nombre")
          .eq("codigo", candidate.codigo_id)
          .maybeSingle();
        const nombreTexto = codeInfo?.nombre ? ` - ${codeInfo.nombre}` : "";

        await sendPush({
          supabaseUrl, pushSecret, anonKey, userId: row.user_id,
          title: "✨ Secuencia Personalizada para Ti",
          body: `Basado en la actividad de la comunidad, este código podría ser perfecto para ti: ${candidate.codigo_id}${nombreTexto}`,
          data: { type: "personalized_code_recommendation", codigo: candidate.codigo_id },
        });
        results.recommendationsSent += 1;
      } catch (e) {
        results.errors.push({ stage: "recommendation", user_id: row.user_id, error: String(e) });
      }
    }
  } catch (e) {
    results.errors.push({ stage: "recommendation_outer", error: String(e) });
  }

  // ── 6) Ranking semanal (Top 3): una vez, lunes 9 a.m. UTC (evento global, no por timezone) ──
  try {
    if (now.getUTCDay() === 1 && now.getUTCHours() === 9) {
      const dedupeKey = now.toISOString().slice(0, 10);
      const { data: cfg } = await supabase
        .from("app_config")
        .select("value")
        .eq("key", "last_weekly_rankings_date")
        .maybeSingle();

      if (cfg?.value !== dedupeKey) {
        const weekAgo = new Date(now.getTime() - 7 * 86400000);
        const { data: actions } = await supabase
          .from("user_actions")
          .select("user_id")
          .eq("action_type", "sesionPilotaje")
          .gte("recorded_at", weekAgo.toISOString());

        const counts = new Map<string, number>();
        for (const a of (actions ?? []) as any[]) {
          counts.set(a.user_id, (counts.get(a.user_id) ?? 0) + 1);
        }
        const ranked = Array.from(counts.entries()).sort((a, b) => b[1] - a[1]).slice(0, 3);
        const medals = ["🥇", "🥈", "🥉"];

        for (let i = 0; i < ranked.length; i++) {
          const [userId, count] = ranked[i];
          await sendPush({
            supabaseUrl, pushSecret, anonKey, userId,
            title: `${medals[i]} ¡Top ${i + 1} de la semana!`,
            body: `Con ${count} pilotajes esta semana, estás entre los pilotos más constantes de ManiGraB.`,
            data: { type: "weekly_rankings", rank: String(i + 1) },
          });
          results.rankingsSent += 1;
        }

        await supabase.from("app_config")
          .upsert({ key: "last_weekly_rankings_date", value: dedupeKey }, { onConflict: "key" });
      }
    }
  } catch (e) {
    results.errors.push({ stage: "weekly_rankings", error: String(e) });
  }

  // ── 7) Cambio de estación: broadcast global en 4 fechas fijas del año, 9 a.m. UTC ──
  try {
    const seasonalDates = [
      { month: 3, day: 20, emoji: "🌸" },
      { month: 6, day: 21, emoji: "☀️" },
      { month: 9, day: 22, emoji: "🍂" },
      { month: 12, day: 21, emoji: "❄️" },
    ];
    const nowMonth = now.getUTCMonth() + 1;
    const nowDay = now.getUTCDate();
    const match = seasonalDates.find((d) => d.month === nowMonth && d.day === nowDay);

    if (match && now.getUTCHours() === 9) {
      const dedupeKey = `${now.getUTCFullYear()}-${nowMonth}-${nowDay}`;
      const { data: cfg } = await supabase
        .from("app_config")
        .select("value")
        .eq("key", "last_seasonal_broadcast")
        .maybeSingle();

      if (cfg?.value !== dedupeKey) {
        await sendBroadcast({
          supabaseUrl, pushSecret, anonKey, topic: "all",
          title: `${match.emoji} Cambio de estación`,
          body: "Una nueva estación trae nueva energía. Descubre los códigos especiales de temporada.",
          data: { type: "seasonal_change" },
        });
        results.seasonalBroadcastSent = 1;
        await supabase.from("app_config")
          .upsert({ key: "last_seasonal_broadcast", value: dedupeKey }, { onConflict: "key" });
      }
    }
  } catch (e) {
    results.errors.push({ stage: "seasonal_change", error: String(e) });
  }

  return new Response(JSON.stringify({ success: true, ...results }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
