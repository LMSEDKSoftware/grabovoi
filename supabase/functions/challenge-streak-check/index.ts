import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

type Requirements = {
  durationDays: number;
  codigoRepetido: number;
  sesionPilotaje: number;
  pilotajeCompartido: number;
  tiempoEnAppMin: number;
};

// Mismas reglas que ChallengeService._createDefaultChallenges() en el cliente
// (lib/services/challenge_service.dart). maestro_abundancia queda fuera de
// este cron: ya tiene su propia lógica de "bajar de nivel" tras 2 días
// perdidos consecutivos, manejada del lado del cliente.
const CHALLENGES: Record<string, { title: string; req: Requirements }> = {
  iniciacion_energetica: {
    title: "Desafío de Iniciación Energética",
    req: { durationDays: 7, codigoRepetido: 1, sesionPilotaje: 0, pilotajeCompartido: 1, tiempoEnAppMin: 15 },
  },
  armonizacion_intermedia: {
    title: "Desafío de Armonización Intermedia",
    req: { durationDays: 14, codigoRepetido: 2, sesionPilotaje: 1, pilotajeCompartido: 1, tiempoEnAppMin: 20 },
  },
  luz_dorada_avanzada: {
    title: "Desafío Avanzado de Luz Dorada",
    req: { durationDays: 21, codigoRepetido: 3, sesionPilotaje: 2, pilotajeCompartido: 2, tiempoEnAppMin: 30 },
  },
};

function getDayNumber(startDate: Date, now: Date, durationDays: number): number {
  const daysSinceStart = Math.floor((now.getTime() - startDate.getTime()) / 86400000);
  const day = daysSinceStart + 1;
  return Math.min(Math.max(day, 1), durationDays);
}

// Hora y fecha LOCALES del usuario para un instante dado, a partir de su
// timezone IANA guardada en user_metadata (ver edit_profile_screen.dart).
// Sin librerías externas: Intl con `timeZone` ya resuelve el offset correcto
// incluyendo horario de verano.
function localHourAndDate(tz: string, now: Date): { hour: number; dateStr: string } {
  try {
    const parts = new Intl.DateTimeFormat("en-CA", {
      timeZone: tz,
      hour: "numeric",
      hour12: false,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    }).formatToParts(now);
    const get = (type: string) => parts.find((p) => p.type === type)?.value ?? "";
    const hour = Number(get("hour")) % 24;
    const dateStr = `${get("year")}-${get("month")}-${get("day")}`;
    return { hour, dateStr };
  } catch {
    // Timezone inválida/desconocida: usar UTC como respaldo en vez de tronar.
    return { hour: now.getUTCHours(), dateStr: now.toISOString().slice(0, 10) };
  }
}

type DayCounts = { codigoRepetido: number; sesionPilotaje: number; pilotajeCompartido: number; tiempoEnAppMin: number };

async function countDayActions(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  dayStart: Date,
  dayEnd: Date,
): Promise<DayCounts> {
  const counts: DayCounts = { codigoRepetido: 0, sesionPilotaje: 0, pilotajeCompartido: 0, tiempoEnAppMin: 0 };
  const { data, error } = await supabase
    .from("user_actions")
    .select("action_type, action_data")
    .eq("user_id", userId)
    .gte("recorded_at", dayStart.toISOString())
    .lt("recorded_at", dayEnd.toISOString());
  if (error || !data) return counts;
  for (const row of data as any[]) {
    switch (row.action_type) {
      case "codigoRepetido": counts.codigoRepetido += 1; break;
      case "sesionPilotaje": counts.sesionPilotaje += 1; break;
      case "pilotajeCompartido": counts.pilotajeCompartido += 1; break;
      case "tiempoEnApp": counts.tiempoEnAppMin += Number(row.action_data?.duration ?? 0); break;
    }
  }
  return counts;
}

function dayIsComplete(counts: DayCounts, req: Requirements): boolean {
  return (
    counts.codigoRepetido >= req.codigoRepetido &&
    counts.sesionPilotaje >= req.sesionPilotaje &&
    counts.pilotajeCompartido >= req.pilotajeCompartido &&
    counts.tiempoEnAppMin >= req.tiempoEnAppMin
  );
}

function completedDayProgressJson(dayNum: number, isoDate: string, now: Date) {
  return {
    day: dayNum,
    date: isoDate,
    actionCounts: {},
    actionDurations: {},
    isCompleted: true,
    completedAt: now.toISOString(),
    completedActions: [],
  };
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
        // x-push-secret por dentro (mismo detalle ya resuelto en
        // process-deep-search-queue / notify_push_from_db).
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

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // Mismo secreto compartido que process-deep-search-queue.
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
    checked: 0,
    morningReminders: 0,
    eveningWarnings: 0,
    anchorsUsed: 0,
    riskWarnings: 0,
    resets: 0,
    errors: [] as any[],
  };

  // Maneja un día detectado como perdido (no completado, ya pasó): intenta
  // usar una ancla de continuidad; si no hay, avisa una vez y da una revisión
  // más de margen antes de reiniciar el desafío.
  async function handleMissedDay(params: {
    row: any;
    meta: { title: string; req: Requirements };
    missedDay: number;
    dayStart: Date;
    dayProgress: Record<string, any>;
  }) {
    const { row, meta, missedDay, dayStart, dayProgress } = params;

    const { data: rewardsRow } = await supabase
      .from("user_rewards")
      .select("anclas_continuidad")
      .eq("user_id", row.user_id)
      .maybeSingle();
    const anclas = (rewardsRow as any)?.anclas_continuidad ?? 0;

    if (anclas > 0) {
      const { data: updatedRewards } = await supabase
        .from("user_rewards")
        .update({ anclas_continuidad: anclas - 1, ultima_actualizacion: now.toISOString(), updated_at: now.toISOString() })
        .eq("user_id", row.user_id)
        .gt("anclas_continuidad", 0)
        .select("anclas_continuidad");

      if (updatedRewards && updatedRewards.length > 0) {
        const updatedDp = { ...dayProgress, [String(missedDay)]: completedDayProgressJson(missedDay, dayStart.toISOString(), now) };
        await supabase.from("user_challenges").update({ day_progress: updatedDp, at_risk_day: null })
          .eq("user_id", row.user_id).eq("challenge_id", row.challenge_id);
        results.anchorsUsed += 1;
        await sendPush({
          supabaseUrl, pushSecret, anonKey, userId: row.user_id,
          title: "🔗 ¡Tu ancla te salvó!",
          body: `Tu ancla de continuidad salvó el día ${missedDay} del desafío "${meta.title}". ¡Sigue así!`,
          data: { type: "challenge_anchor_used", challenge_id: row.challenge_id, day: String(missedDay) },
        });
        return;
      }
      // Carrera: alguien más consumió la última ancla justo antes. Cae al caso sin ancla.
    }

    if (row.at_risk_day === missedDay) {
      // Segunda revisión consecutiva sin resolver: se pierde la racha.
      const newStartDate = now;
      const newEndDate = new Date(newStartDate.getTime() + meta.req.durationDays * 86400000);
      await supabase.from("user_challenges").update({
        start_date: newStartDate.toISOString(),
        end_date: newEndDate.toISOString(),
        current_day: 1,
        total_progress: 0,
        day_progress: { "1": { day: 1, date: newStartDate.toISOString(), actionCounts: {}, actionDurations: {}, isCompleted: false, completedAt: null, completedActions: [] } },
        at_risk_day: null,
      }).eq("user_id", row.user_id).eq("challenge_id", row.challenge_id);
      results.resets += 1;
      await sendPush({
        supabaseUrl, pushSecret, anonKey, userId: row.user_id,
        title: "💔 Racha perdida",
        body: `Se reinició tu desafío "${meta.title}" al día 1 porque no completaste el día ${missedDay} a tiempo.`,
        data: { type: "challenge_reset", challenge_id: row.challenge_id },
      });
    } else {
      // Primera vez que se detecta: avisar y dar un día más de margen.
      await supabase.from("user_challenges").update({ at_risk_day: missedDay })
        .eq("user_id", row.user_id).eq("challenge_id", row.challenge_id);
      results.riskWarnings += 1;
      await sendPush({
        supabaseUrl, pushSecret, anonKey, userId: row.user_id,
        title: "⚠️ Tu racha está en riesgo",
        body: `No completaste el día ${missedDay} del desafío "${meta.title}" y no tienes anclas de continuidad. Consigue una para no perder tu progreso.`,
        data: { type: "challenge_at_risk", challenge_id: row.challenge_id, day: String(missedDay) },
      });
    }
  }

  try {
    const { data: rows, error } = await supabase
      .from("user_challenges")
      .select("user_id, challenge_id, start_date, day_progress, at_risk_day, last_morning_reminder_date, last_evening_warning_date")
      .eq("status", "enProgreso")
      .in("challenge_id", Object.keys(CHALLENGES));

    if (error) throw new Error(`select_failed:${error.message}`);

    for (const row of (rows ?? []) as any[]) {
      results.checked += 1;
      try {
        const meta = CHALLENGES[row.challenge_id as string];
        if (!meta) continue;
        const startDate = new Date(row.start_date);

        let timezone = "UTC";
        try {
          const { data: userResp } = await supabase.auth.admin.getUserById(row.user_id);
          timezone = (userResp?.user?.user_metadata as any)?.timezone || "UTC";
        } catch (e) {
          console.error(`No se pudo obtener timezone de ${row.user_id}:`, e);
        }

        const { hour: localHour, dateStr: localDate } = localHourAndDate(timezone, now);
        const currentDayNum = getDayNumber(startDate, now, meta.req.durationDays);
        const dayProgress = (row.day_progress ?? {}) as Record<string, any>;

        // ── 1) Racha/ancla para el día de AYER (1 a.m. local, una vez al día) ──
        if (localHour === 1 && currentDayNum > 1) {
          const yesterdayDayNum = currentDayNum - 1;
          const yesterdayEntry = dayProgress[String(yesterdayDayNum)];
          if (!yesterdayEntry?.isCompleted) {
            const dayStart = new Date(startDate.getTime() + (yesterdayDayNum - 1) * 86400000);
            const dayEnd = new Date(dayStart.getTime() + 86400000);
            const counts = await countDayActions(supabase, row.user_id, dayStart, dayEnd);

            if (dayIsComplete(counts, meta.req)) {
              // Se completó pero no se había sincronizado a day_progress todavía.
              const updatedDp = { ...dayProgress, [String(yesterdayDayNum)]: completedDayProgressJson(yesterdayDayNum, dayStart.toISOString(), now) };
              await supabase.from("user_challenges").update({ day_progress: updatedDp, at_risk_day: null })
                .eq("user_id", row.user_id).eq("challenge_id", row.challenge_id);
            } else {
              await handleMissedDay({ row, meta, missedDay: yesterdayDayNum, dayStart, dayProgress });
            }
          }
        }

        // ── 2) Recordatorio matutino (8 a.m. local) ──
        if (localHour === 8 && row.last_morning_reminder_date !== localDate) {
          const dayStart = new Date(startDate.getTime() + (currentDayNum - 1) * 86400000);
          const dayEnd = new Date(dayStart.getTime() + 86400000);
          const counts = await countDayActions(supabase, row.user_id, dayStart, dayEnd);
          if (!dayIsComplete(counts, meta.req)) {
            await sendPush({
              supabaseUrl, pushSecret, anonKey, userId: row.user_id,
              title: "🌅 ¡Buenos días!",
              body: `No olvides completar el día ${currentDayNum} de tu desafío "${meta.title}" hoy.`,
              data: { type: "challenge_morning_reminder", challenge_id: row.challenge_id, day: String(currentDayNum) },
            });
            results.morningReminders += 1;
          }
          await supabase.from("user_challenges").update({ last_morning_reminder_date: localDate })
            .eq("user_id", row.user_id).eq("challenge_id", row.challenge_id);
        }

        // ── 3) Aviso de último momento (9 p.m. local) ──
        if (localHour === 21 && row.last_evening_warning_date !== localDate) {
          const dayStart = new Date(startDate.getTime() + (currentDayNum - 1) * 86400000);
          const dayEnd = new Date(dayStart.getTime() + 86400000);
          const counts = await countDayActions(supabase, row.user_id, dayStart, dayEnd);
          if (!dayIsComplete(counts, meta.req)) {
            await sendPush({
              supabaseUrl, pushSecret, anonKey, userId: row.user_id,
              title: "⏰ Se acaba el día",
              body: `Aún no completas el día ${currentDayNum} del desafío "${meta.title}". ¡Termínalo antes de medianoche para no perder tu racha!`,
              data: { type: "challenge_evening_warning", challenge_id: row.challenge_id, day: String(currentDayNum) },
            });
            results.eveningWarnings += 1;
          }
          await supabase.from("user_challenges").update({ last_evening_warning_date: localDate })
            .eq("user_id", row.user_id).eq("challenge_id", row.challenge_id);
        }
      } catch (e) {
        results.errors.push({ user_id: row.user_id, challenge_id: row.challenge_id, error: String(e) });
      }
    }

    return new Response(JSON.stringify({ success: true, ...results }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("challenge-streak-check unexpected", e);
    return new Response(JSON.stringify({ success: false, error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
