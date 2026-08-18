import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// "Redes sociales" no era una categoría: fue un error de implementación
// que acabó siendo la etiqueta de todo lo importado. "Otros" sí existe en
// el catálogo y dice la verdad: llegó por importación y falta
// clasificarlo bien.
const CATEGORY_FOR_IMPORTED_CODES = "Otros";

// Un título es aprovechable si de verdad dice qué es la secuencia. Los
// genéricos que se usaban como relleno ("Secuencia", "Código") no
// distinguen nada: 1128 filas llamadas igual no son un catálogo.
function tituloAprovechable(titulo: string): boolean {
  const t = (titulo || "").trim();
  if (t.length < 3) return false;
  if (!/[a-záéíóúüñ]/i.test(t)) return false;
  const generico = t.toLowerCase().replace(/[.\s]+$/, "");
  return !["secuencia", "codigo", "código", "secuencia importada", "sin nombre"]
    .includes(generico);
}

// Un hallazgo entra al catálogo solo si se puede justificar: título real
// y fuente comprobable. Lo demás va a cuarentena, no se tira.
function esImportable(item: { nombre?: string; fuente_url?: string }): boolean {
  return tituloAprovechable(String(item.nombre ?? "")) &&
    String(item.fuente_url ?? "").trim().length > 0;
}

// '519_714_812' y '519714812' son el mismo código escrito distinto. El
// upsert por "codigo" no los ve iguales, y por eso convivían 30
// duplicados. La base ya lo impide con un índice único sobre el código
// normalizado; esto evita además que el upsert reviente al chocar.
async function codigosYaExistentes(
  supabase: ReturnType<typeof createClient>,
  codigos: string[],
): Promise<Set<string>> {
  const existentes = new Set<string>();
  if (!codigos.length) return existentes;
  const { data } = await supabase.from("codigos_grabovoi").select("codigo");
  for (const fila of (data ?? []) as any[]) {
    existentes.add(String(fila.codigo).replaceAll("_", ""));
  }
  return existentes;
}

async function aCuarentena(
  supabase: ReturnType<typeof createClient>,
  filas: Array<{
    codigo: string;
    nombre_detectado?: string | null;
    fuente_url: string;
    fuente_titulo?: string | null;
    contexto?: string | null;
  }>,
): Promise<void> {
  if (!filas.length) return;
  await supabase
    .from("codigos_pendientes")
    .upsert(filas, { onConflict: "codigo,fuente_url", ignoreDuplicates: true });
}
const DEFAULT_COLOR = "#FFD700";

type SourceRow = {
  id: number;
  url: string;
  source_type: string;
  enabled: boolean;
  crawl_interval_hours: number;
  last_crawled_at: string | null;
  last_error: string | null;
};

type RequestRow = {
  id: number;
  user_id: string | null;
  query_text: string;
  query_norm: string;
  status: string;
  attempts: number;
};

type TavilyResult = { title?: string; url?: string; content?: string };

function nowIso(): string {
  return new Date().toISOString();
}

// Envía un push reutilizando la función send-push ya desplegada (mismo secreto
// compartido que usa notify_push_from_db() desde Postgres). Nunca debe tumbar
// el cron: cualquier fallo solo se loguea.
async function sendPushNotification(params: {
  supabaseUrl: string;
  pushSecret: string;
  anonKey: string;
  userId: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}): Promise<void> {
  const { supabaseUrl, pushSecret, anonKey, userId, title, body, data } = params;
  if (!pushSecret) {
    console.warn("sendPushNotification: PUSH_SECRET no configurado, se omite el push");
    return;
  }
  if (!userId) return;
  try {
    const resp = await fetch(`${supabaseUrl}/functions/v1/send-push`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        // El gateway de Supabase exige un Authorization válido antes de que
        // corra el código de la función, aunque send-push valide su propio
        // x-push-secret por dentro (mismo problema ya resuelto en
        // notify_push_from_db). Sin esto, la llamada nunca llega a enviarse.
        "Authorization": `Bearer ${anonKey}`,
        "x-push-secret": pushSecret,
      },
      body: JSON.stringify({ userId, title, body, data: data ?? {} }),
    });
    if (!resp.ok) {
      const text = await resp.text().catch(() => "");
      console.error(`sendPushNotification: fallo para user ${userId}: ${resp.status} ${text.slice(0, 200)}`);
    }
  } catch (e) {
    console.error(`sendPushNotification: error para user ${userId}:`, e);
  }
}

async function getAdminUserIds(supabase: ReturnType<typeof createClient>): Promise<string[]> {
  const { data, error } = await supabase.from("users_admin").select("user_id");
  if (error) {
    console.error("getAdminUserIds: fallo consultando users_admin:", error.message);
    return [];
  }
  return (data ?? []).map((r: any) => String(r.user_id)).filter(Boolean);
}

function normalizeQuery(input: string): string {
  return input.toLowerCase().trim().replace(/\s+/g, " ");
}

function queryDigits(input: string): string {
  return input.replace(/\D/g, "");
}

function isConceptualQuery(norm: string): boolean {
  return queryDigits(norm).length < 3;
}

function titleCaseEs(input: string): string {
  const s = input.trim();
  if (!s) return s;
  return s
    .split(/\s+/g)
    .map((w) => (w ? w[0].toUpperCase() + w.slice(1) : w))
    .join(" ");
}

function hasLetters(input: string): boolean {
  return /[a-zA-ZáéíóúñüÁÉÍÓÚÑÜ]/.test(input);
}

function foldText(input: string): string {
  return (input || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase();
}

function normalizeCodigo(input: string): string {
  return input
    .trim()
    .replaceAll("-", "_")
    .replaceAll(" ", "_")
    .replaceAll(/_+/g, "_");
}

function isValidCodigo(input: string): boolean {
  const c = normalizeCodigo(input);
  if (!c) return false;
  if (!/^[0-9_]+$/.test(c)) return false;
  const digits = c.replaceAll("_", "");
  return digits.length >= 3 && digits.length <= 32;
}

function stripHtmlToText(html: string): string {
  if (!html) return "";
  // Remove scripts/styles (cheap heuristic)
  let t = html.replace(/<script[\s\S]*?<\/script>/gi, " ");
  t = t.replace(/<style[\s\S]*?<\/style>/gi, " ");
  // Remove tags
  t = t.replace(/<[^>]+>/g, " ");
  // Collapse whitespace
  t = t.replace(/\s+/g, " ").trim();
  return t;
}

function looksLikeDateCode(code: string): boolean {
  const c = normalizeCodigo(code);
  const parts = c.split("_").filter(Boolean);
  if (parts.length < 2 || parts.length > 4) return false;
  if (!parts.every((p) => /^\d+$/.test(p))) return false;
  if (parts[0].length !== 4) return false;
  const year = Number(parts[0]);
  if (year < 1900 || year > 2105) return false;

  // Excluir rangos tipo YYYY_YYYY
  if (parts.length === 2 && parts[1].length === 4) {
    const year2 = Number(parts[1]);
    if (year2 >= 1900 && year2 <= 2105) return true;
  }

  // Excluir fechas tipo YYYY_MM[_DD[_HH]]
  const month = Number(parts[1]);
  if (month >= 1 && month <= 12) {
    if (parts.length >= 3) {
      const day = Number(parts[2]);
      if (!(day >= 1 && day <= 31)) return false;
    }
    return true;
  }

  return false;
}

function extractCodesFromText(text: string): string[] {
  if (!text) return [];
  const found = new Set<string>();

  // Matches sequences like: 520 741 889, 519_7148, 891-420-19
  const reGrouped = /\b\d{3,}(?:[ _-]\d{2,})+\b/g;
  for (const m of text.matchAll(reGrouped)) {
    const raw = String(m[0] ?? "").trim();
    if (!raw) continue;
    const normalized = normalizeCodigo(raw);
    if (!isValidCodigo(normalized)) continue;
    if (looksLikeDateCode(normalized)) continue;
    // Context check: grouped matches must appear near Grabovoi/código/code to reduce false positives.
    const idx = (m as any).index ?? -1;
    if (idx >= 0) {
      const start = Math.max(0, idx - 90);
      const end = Math.min(text.length, idx + raw.length + 90);
      const ctx = text.substring(start, end).toLowerCase();
      const okCtx =
        ctx.includes("grabov") ||
        ctx.includes("código") ||
        ctx.includes("codigo") ||
        ctx.includes("code");
      if (!okCtx) continue;
    }
    found.add(normalized);
  }

  // Single long numeric codes (6-11 digits) but only if nearby “grabovoi/código/code”
  const reLong = /\b\d{6,11}\b/g;
  for (const m of text.matchAll(reLong)) {
    const raw = String(m[0] ?? "").trim();
    if (!raw) continue;
    const idx = (m as any).index ?? -1;
    const start = Math.max(0, idx - 50);
    const end = Math.min(text.length, idx + raw.length + 50);
    const ctx = text.substring(start, end).toLowerCase();
    if (ctx.includes("grabov") || ctx.includes("código") || ctx.includes("codigo") || ctx.includes("code")) {
      const normalized = normalizeCodigo(raw);
      if (isValidCodigo(normalized)) found.add(normalized);
    }
  }

  return Array.from(found);
}

function extractCodesFromTextRelaxed(text: string): string[] {
  if (!text) return [];
  const found = new Set<string>();

  const reGrouped = /\b\d{3,}(?:[ _-]\d{2,})+\b/g;
  for (const m of text.matchAll(reGrouped)) {
    const raw = String(m[0] ?? "").trim();
    if (!raw) continue;
    const normalized = normalizeCodigo(raw);
    if (!isValidCodigo(normalized)) continue;
    if (looksLikeDateCode(normalized)) continue;
    found.add(normalized);
  }

  const reLong = /\b\d{6,11}\b/g;
  for (const m of text.matchAll(reLong)) {
    const raw = String(m[0] ?? "").trim();
    if (!raw) continue;
    const normalized = normalizeCodigo(raw);
    if (!isValidCodigo(normalized)) continue;
    if (looksLikeDateCode(normalized)) continue;
    found.add(normalized);
  }

  return Array.from(found);
}

function shortify(input: string, maxLen: number): string {
  const s = (input || "").replace(/\s+/g, " ").trim();
  if (s.length <= maxLen) return s;
  return s.slice(0, maxLen).trim();
}

// Fragmentos de ruta de imagen/CDN o markdown de imagen que un scraper roto
// puede confundir con un título (ej. rutas de Etsy "il/xxxxx/...jpg)" o un
// alt-text de perfil de Slideshare "![Nombre](https://cdn...)"). "il", "jpg"
// o el nombre de archivo tienen letras, así que hasLetters() por sí solo no
// los detecta — de ahí que 9 filas reales de codigos_grabovoi quedaran con
// este tipo de basura como nombre.
function looksLikeUrlOrImagePath(input: string): boolean {
  return /!\[|\]\(|\.jpe?g\)|\.png\)|\.gif\)|\.webp\)|cdn\.|slidesharecdn|etsystatic|^\s*\/[a-z0-9_]+\//i.test(
    input,
  );
}

function sanitizeNombreEs(input: string): string {
  let s = stripHtmlToText(String(input || "")).replace(/\s+/g, " ").trim();
  if (!s) return "";
  if (looksLikeUrlOrImagePath(s)) return "";

  // Quitar secuencias/códigos incrustados en el título
  s = s
    .replace(/\b\d{3,}(?:[ _-]\d{2,})+\b/g, " ")
    .replace(/\b\d{6,11}\b/g, " ")
    .replace(/[0-9_]{3,}/g, " ")
    .replace(/\s+/g, " ")
    .trim();

  // Quitar separadores/ruido
  s = s
    .replace(/^[\s\-\–\—\:\|\=\u2022\,\.]+/g, "")
    .replace(/[\s\-\–\—\:\|\,\.\;]+$/g, "")
    .trim();

  // Si no quedan letras, no sirve como nombre
  if (!hasLetters(s)) return "";

  // Best-effort: convertir portugués/variantes cercanas a español
  s = bestEffortToSpanish(s);

  // Evitar caracteres típicos no-españoles que suelen venir de portugués
  s = s.replace(/[ãõ]/gi, (m) => (m.toLowerCase() === "ã" ? "a" : "o"));
  s = s.replace(/[ç]/gi, "c");

  // Si aún no hay letras, o quedó vacío, fallback
  if (!hasLetters(s)) return "";

  s = titleCaseEs(s);

  return shortify(s, 80);
}

function bestEffortToSpanish(input: string): string {
  let s = String(input || "").trim();
  if (!s) return s;

  // Reemplazos comunes PT -> ES en este dominio (palabras frecuentes)
  const reps: Array<[RegExp, string]> = [
    [/\bmedo\b/gi, "miedo"],
    [/\besperan[cç]a\b/gi, "esperanza"],
    [/\bperigo\b/gi, "peligro"],
    [/\bang[uú]stia\b/gi, "angustia"],
    [/\bdepress[aã]o\b/gi, "depresión"],
    [/\bdepress[ãa]o\b/gi, "depresión"],
    [/\btristeza\b/gi, "tristeza"],
    [/\bexpectativa de\b/gi, "expectativa de"],
  ];
  for (const [re, v] of reps) s = s.replace(re, v);

  // Capitalización simple si inicia en mayúscula
  if (s && /[A-ZÁÉÍÓÚÑÜ]/.test(s[0])) {
    s = s[0].toUpperCase() + s.slice(1);
  }
  return s;
}

function generalDescripcionFromTitle(title: string): string {
  const t = sanitizeNombreEs(title);
  if (!t) return "Secuencia importada desde fuentes externas.";
  // Siempre en español, sin repetir el código.
  return shortify(`Proporciona apoyo y soporte energético para ${t}.`, 180);
}

function parseTitleForCodeFromLine(params: { line: string; codeRaw: string; idx: number }): string | null {
  const line = params.line.trim();
  if (!line) return null;

  // Remove the code token
  const left = line.slice(0, params.idx).trim();
  const right = line.slice(params.idx + params.codeRaw.length).trim();

  const clean = (s: string) =>
    s
      .replace(/^[\s\-\–\—\:\|\=\u2022]+/g, "")
      .replace(/[\s\-\–\—\:\|\,\.\;]+$/g, "")
      .trim();

  const stripLeadingNumeric = (s: string) =>
    s
      // e.g. "4894971 Auto dominio" -> "Auto dominio"
      .replace(/^\d[\d_ ]{2,}\s+/, "")
      .trim();

  // Prefer text on the right (common: CODE <title>)
  let rightClean = clean(right);
  if (rightClean.includes("=")) rightClean = clean(rightClean.split("=")[0]);
  rightClean = stripLeadingNumeric(rightClean);
  if (rightClean && hasLetters(rightClean) && rightClean.length >= 3 && rightClean.length <= 80) {
    return rightClean;
  }

  // If line has '=' chain, take last meaningful segment before the code
  const leftClean = clean(left);
  if (leftClean) {
    const parts = leftClean.split("=").map((p) => clean(p)).filter(Boolean);
    let candidate = parts.length ? parts[parts.length - 1] : leftClean;
    if (candidate.includes("=")) candidate = clean(candidate.split("=").pop() ?? candidate);
    candidate = stripLeadingNumeric(candidate);
    if (candidate && hasLetters(candidate) && candidate.length >= 3 && candidate.length <= 80) {
      return candidate;
    }
  }

  return null;
}

function extractCodeItemsFromChunk(params: {
  chunk: string;
  keyword: string;
  sourceUrl: string;
  sourceTitle: string;
  maxItems: number;
}): Array<{ codigo: string; titulo: string; descripcion: string; fuente_url: string; fuente_titulo: string; fuente_extracto: string }> {
  const chunk = params.chunk || "";
  const keyword = params.keyword.trim();
  if (!chunk) return [];

  const keywordFold = foldText(keyword);
  const lines = chunk
    .split(/\r?\n/g)
    .map((l) => l.trim())
    .filter((l) => l.length >= 6)
    .slice(0, 400);

  const items: Array<{ codigo: string; titulo: string; descripcion: string; fuente_url: string; fuente_titulo: string; fuente_extracto: string }> = [];
  const seen = new Set<string>();

  const addItem = (codigo: string, titulo: string, extracto: string) => {
    if (seen.has(codigo)) return;
    seen.add(codigo);

    const t = sanitizeNombreEs(titulo) || sanitizeNombreEs(titleCaseEs(keyword)) || "Secuencia";
    // Descripción breve en español; debe incluir la keyword para que quede relacionada textualmente.
    let descripcion = `Proporciona apoyo y soporte energético para ${t}.`;
    if (keyword && !foldText(descripcion).includes(keywordFold)) {
      descripcion = `${descripcion} Intención: ${keyword.toLowerCase()}.`;
    }
    descripcion = shortify(descripcion, 180);

    items.push({
      codigo,
      titulo: t,
      descripcion,
      fuente_url: params.sourceUrl,
      fuente_titulo: params.sourceTitle,
      fuente_extracto: shortify(extracto, 220),
    });
  };

  for (const line of lines) {
    if (!hasLetters(line)) continue;
    // Estricto: solo aceptar pares de la(s) línea(s) que contienen la keyword.
    const lineFold = foldText(line);
    if (keywordFold && !lineFold.includes(keywordFold)) continue;

    // Prefer mapping keyword <-> code using '=' segments to avoid over-associating many codes.
    // Example: "... Melancolia = 614 318... Desamparo = 519..." -> pick only 614... for melancolia.
    const parts = line.split("=").map((p) => p.trim()).filter(Boolean);
    for (let i = 0; i < parts.length; i += 1) {
      const pFold = foldText(parts[i]);
      const hasKey = keywordFold && pFold.includes(keywordFold);
      if (!hasKey) continue;

      // Forward: keyword segment -> next segment contains the code.
      if (i + 1 < parts.length) {
        const next = parts[i + 1];
        const nextCodes = extractCodesFromTextRelaxed(next);
        if (nextCodes.length) {
          // Extracto centrado: "keyword = code/title" para auditoría manual.
          const extracto = `${parts[i]} = ${next}`.replace(/\s+/g, " ").trim();
          addItem(nextCodes[0], titleCaseEs(keyword), extracto);
          if (items.length >= params.maxItems) return items;
        }
      }
    }
  }

  // Fallback: if no line-level pairs, use relaxed extraction and generic titles
  if (!items.length) {
    // Estricto: fallback solo si el chunk realmente contiene la keyword.
    if (!keywordFold || !foldText(chunk).includes(keywordFold)) return items;
    for (const codigo of extractCodesFromTextRelaxed(chunk).slice(0, params.maxItems)) {
      addItem(codigo, titleCaseEs(keyword), chunk);
      if (items.length >= params.maxItems) break;
    }
  }

  return items;
}

function extractGeneralCodeItemsFromText(params: {
  text: string;
  sourceUrl: string;
  sourceTitle: string;
  maxItems: number;
}): Array<{ codigo: string; titulo: string; descripcion: string; fuente_url: string; fuente_titulo: string; fuente_extracto: string }> {
  const text = params.text || "";
  if (!text) return [];

  const lines = text
    .split(/\r?\n/g)
    .map((l) => l.trim())
    .filter((l) => l.length >= 6)
    .slice(0, 1200);

  const items: Array<{ codigo: string; titulo: string; descripcion: string; fuente_url: string; fuente_titulo: string; fuente_extracto: string }> = [];
  const seen = new Set<string>();

  const add = (codigo: string, titulo: string, extracto: string) => {
    if (seen.has(codigo)) return;
    seen.add(codigo);
    const t = sanitizeNombreEs(titulo) || "Secuencia";
    items.push({
      codigo,
      titulo: t,
      descripcion: generalDescripcionFromTitle(t),
      fuente_url: params.sourceUrl,
      fuente_titulo: params.sourceTitle,
      fuente_extracto: shortify(extracto, 220),
    });
  };

  // Prefer lines with "=" pairs (most lists are like "Title = CODE" or "CODE Title")
  for (const line of lines) {
    // Skip very long lines (noise)
    if (line.length > 320) continue;

    if (line.includes("=")) {
      const parts = line.split("=").map((p) => p.trim()).filter(Boolean);
      for (let i = 0; i < parts.length - 1; i += 1) {
        const left = parts[i];
        const right = parts[i + 1];

        const leftCodes = extractCodesFromTextRelaxed(left);
        const rightCodes = extractCodesFromTextRelaxed(right);

        // Case: Title = CODE
        if (!leftCodes.length && rightCodes.length && hasLetters(left)) {
          add(rightCodes[0], left, `${left} = ${right}`);
          if (items.length >= params.maxItems) return items;
        }
        // Case: CODE = Title
        if (leftCodes.length && !rightCodes.length && hasLetters(right)) {
          add(leftCodes[0], right, `${left} = ${right}`);
          if (items.length >= params.maxItems) return items;
        }
      }
    } else {
      // Case: CODE Title
      const re = /\b\d{3,}(?:[ _-]\d{2,})+\b|\b\d{6,11}\b/g;
      const m = re.exec(line);
      if (!m) continue;
      const raw = String(m[0] ?? "").trim();
      const codigo = normalizeCodigo(raw);
      if (!isValidCodigo(codigo) || looksLikeDateCode(codigo)) continue;
      const idx = m.index ?? -1;
      const title = idx >= 0 ? (parseTitleForCodeFromLine({ line, codeRaw: raw, idx }) ?? "") : "";
      if (!title) continue;
      add(codigo, title, line);
      if (items.length >= params.maxItems) return items;
    }
  }

  return items;
}

function bestEffortNameAndDescription(params: {
  keyword: string;
  codigo: string;
  context: string;
}): { nombre: string; descripcion: string } {
  const keyword = params.keyword.trim();
  const keywordLower = keyword.toLowerCase();
  const baseName = titleCaseEs(keyword);

  // Try to build a short description from context (remove code digits, trim noise)
  let ctx = (params.context || "")
    .replace(/\s+/g, " ")
    .trim();

  // Remove the code itself (with flexible separators) from the context
  const digits = queryDigits(params.codigo);
  if (digits.length >= 3) {
    const re = new RegExp(digits.split("").join("[ _-]*"));
    ctx = ctx.replace(re, " ").replace(/\s+/g, " ").trim();
  }

  // Keep a short sentence-like chunk
  if (ctx.length > 240) ctx = ctx.slice(0, 240).trim();
  ctx = ctx.replace(/^[\-\–\—\:\|]+/, "").trim();

  // Ensure the keyword appears for future search relevance
  let descripcion = ctx;
  if (!descripcion) {
    descripcion = `Secuencia asociada a ${keywordLower}.`;
  } else if (!descripcion.toLowerCase().includes(keywordLower)) {
    descripcion = `${descripcion}. Asociado a ${keywordLower}.`;
  }

  // Avoid mentioning “usuario” or automation wording
  descripcion = descripcion
    .replace(/búsqueda del usuario/gi, "búsqueda")
    .replace(/detectad[oa] automátic[a-záéíóúñ ]*/gi, "")
    .replace(/\s+/g, " ")
    .trim();

  return {
    nombre: baseName || "Secuencia",
    descripcion,
  };
}

function safeUrlToDomain(url: string): string {
  try {
    return new URL(url).hostname.toLowerCase();
  } catch (_) {
    return "";
  }
}

function shouldSkipDiscoveredUrl(url: string): boolean {
  const u = url.toLowerCase();
  if (!u.startsWith("http://") && !u.startsWith("https://")) return true;
  if (u.endsWith(".pdf") || u.includes(".pdf?") || u.includes("/pdf")) return true;

  const domain = safeUrlToDomain(url);
  const deny = [
    "amazon.",
    "pinterest.",
    "music.apple.com",
    "open.spotify.com",
    "spotify.com",
    "youtube.com",
    "youtu.be",
    "tiktok.com",
    "instagram.com",
    "facebook.com",
    "x.com",
    "twitter.com",
    "shazam.com",
  ];
  for (const d of deny) {
    if (domain === d || domain.endsWith(d) || domain.includes(d)) return true;
  }
  return false;
}

async function tavilyDiscoverUrls(params: {
  query: string;
  maxResults: number;
  depth: "basic" | "advanced";
  includeRaw: boolean;
}): Promise<TavilyResult[]> {
  const apiKey = Deno.env.get("TAVILY_API_KEY") ?? "";
  if (!apiKey) throw new Error("missing_tavily_secret");

  const resp = await fetch("https://api.tavily.com/search", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      api_key: apiKey,
      query: params.query,
      search_depth: params.depth,
      include_answer: false,
      include_raw_content: params.includeRaw,
      max_results: params.maxResults,
    }),
  });

  const text = await resp.text();
  if (!resp.ok) {
    const snippet = text.replace(/\s+/g, " ").slice(0, 240);
    throw new Error(`tavily_http_${resp.status}:${snippet}`);
  }

  const data = JSON.parse(text);
  const results = Array.isArray(data?.results) ? data.results : [];
  return results.map((r: any) => ({
    title: r?.title,
    url: r?.url,
    content: r?.raw_content ?? r?.content,
  }));
}

function extractCodesNearKeyword(params: {
  text: string;
  keyword: string;
  windowChars: number;
  maxCodes: number;
  sourceUrl: string;
  sourceTitle: string;
}): Array<{ codigo: string; context: string; item?: { titulo: string; descripcion: string; fuente_url: string; fuente_titulo: string; fuente_extracto: string } }> {
  const text = params.text || "";
  const keywordRaw = (params.keyword || "").trim();
  if (!text || !keywordRaw) return [];

  // Build folded text + index map foldedIndex -> originalIndex
  const foldedParts: string[] = [];
  const idxMap: number[] = [];
  for (let i = 0; i < text.length; i += 1) {
    const folded = foldText(text[i]);
    if (!folded) continue;
    for (let j = 0; j < folded.length; j += 1) {
      foldedParts.push(folded[j]);
      idxMap.push(i);
    }
  }
  const foldedText = foldedParts.join("");
  const foldedKeyword = foldText(keywordRaw).trim();
  if (!foldedKeyword) return [];

  const globalHasCtx =
    foldedText.includes("grabov") ||
    foldedText.includes("codigo") ||
    foldedText.includes("code");

  const positions: number[] = [];
  let idx = 0;
  while (idx >= 0 && positions.length < 20) {
    idx = foldedText.indexOf(foldedKeyword, idx);
    if (idx >= 0) {
      positions.push(idx);
      idx += foldedKeyword.length;
    }
  }

  const found = new Map<string, { context: string; item?: any }>();
  for (const p of positions) {
    const startOrig = idxMap[Math.max(0, p - params.windowChars)] ?? 0;
    const endOrig = idxMap[Math.min(idxMap.length - 1, p + foldedKeyword.length + params.windowChars)] ?? text.length;
    const start = Math.max(0, startOrig);
    const end = Math.min(text.length, endOrig);
    const chunk = text.slice(start, end);
    // Si la fuente global menciona Grabovoi/código/code, no exigirlo en la misma ventana.
    // Esto ayuda con PDFs donde el keyword aparece lejos del encabezado.
    if (!globalHasCtx) {
      const chunkLower = chunk.toLowerCase();
      const hasCtx =
        chunkLower.includes("grabov") ||
        chunkLower.includes("código") ||
        chunkLower.includes("codigo") ||
        chunkLower.includes("code");
      // Si no hay contexto, todavía permitimos extracción pero solo si aparecen patrones de códigos.
      if (!hasCtx && !/\d{3,}(?:[ _-]\d{2,})+|\b\d{6,11}\b/.test(chunk)) continue;
    }

    // En esta etapa (discovery por keyword) usamos extractor RELAJADO: la ventana ya está acotada por keyword.
    const items = extractCodeItemsFromChunk({
      chunk,
      keyword: keywordRaw,
      sourceUrl: params.sourceUrl,
      sourceTitle: params.sourceTitle,
      maxItems: params.maxCodes,
    });
    for (const it of items) {
      if (found.has(it.codigo)) continue;
      found.set(it.codigo, { context: it.fuente_extracto || chunk, item: it });
      if (found.size >= params.maxCodes) break;
    }
    if (found.size >= params.maxCodes) break;
  }

  return Array.from(found.entries()).map(([codigo, v]) => ({ codigo, context: v.context, item: v.item }));
}

async function fetchSourceText(url: string): Promise<string> {
  const resp = await fetch(url, {
    headers: {
      "User-Agent":
        "ManiGrabBot/1.0 (+https://manigrab.app) deep-search crawler",
      "Accept":
        "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    },
  });
  const text = await resp.text();
  if (!resp.ok) {
    const snippet = text.replace(/\s+/g, " ").slice(0, 240);
    throw new Error(`fetch_http_${resp.status}:${snippet}`);
  }
  return text;
}

async function discoveryControlled(params: {
  supabase: ReturnType<typeof createClient>;
  queriesLimit: number;
  sourcesPerQuery: number;
  tavilyMaxResults: number;
  codesPerQuery: number;
  gainCodesPerQuery: number;
}): Promise<{
  queries: number;
  sources_added: number;
  added: any[];
  resolved: number;
  resolved_queries: any[];
  errors: any[];
}> {
  const { supabase, queriesLimit, sourcesPerQuery, tavilyMaxResults } = params;

  const { data: reqs, error } = await supabase
    .from("deep_search_requests")
    .select("id,query_text,query_norm,updated_at")
    .eq("status", "pending")
    .order("updated_at", { ascending: false })
    .limit(queriesLimit * 4);
  if (error) throw new Error(`discovery_select_failed:${error.message}`);

  const conceptual = (reqs ?? [])
    .map((r: any) => ({
      id: Number(r.id),
      query_text: String(r.query_text ?? "").trim(),
      query_norm: normalizeQuery(String(r.query_norm ?? r.query_text ?? "")),
    }))
    .filter((r: any) => r.query_text && isConceptualQuery(r.query_norm));

  // Dedup by query_norm
  const uniq: any[] = [];
  const seen = new Set<string>();
  for (const r of conceptual) {
    if (seen.has(r.query_norm)) continue;
    seen.add(r.query_norm);
    uniq.push(r);
    if (uniq.length >= queriesLimit) break;
  }

  const added: any[] = [];
  const errorsAll: any[] = [];
  let sourcesAdded = 0;
  let resolvedCount = 0;
  const resolvedQueries: any[] = [];

  for (const r of uniq) {
    try {
      const keywordForSearch = (r.query_norm || r.query_text || "").trim();
      const keywordForExtraction = keywordForSearch;
      const q = `${keywordForSearch} grabovoi código`;
      const results = await tavilyDiscoverUrls({
        query: q,
        maxResults: tavilyMaxResults,
        depth: "advanced",
        includeRaw: true,
      });

      const keywordFold = foldText(keywordForExtraction);
      const filteredResults = results.filter((res) => {
        const content = String(res?.content ?? "");
        if (!content) return false;
        return foldText(content).includes(keywordFold);
      });

      let addedForQuery = 0;
      const codes = new Map<string, { item: any }>();
      const gainItems: Array<{
        codigo: string;
        titulo: string;
        descripcion: string;
        fuente_url: string;
        fuente_titulo: string;
        fuente_extracto: string;
      }> = [];

      for (const res of filteredResults) {
        const url = String(res?.url ?? "").trim();
        if (url && !shouldSkipDiscoveredUrl(url)) {
          const { error: upsertError } = await supabase
            .from("deep_search_sources")
            .upsert(
              {
                url,
                source_type: "discovered",
                enabled: true,
                crawl_interval_hours: 24,
                updated_at: nowIso(),
              },
              { onConflict: "url", ignoreDuplicates: true },
            );

          if (upsertError) {
            errorsAll.push({ query: r.query_text, url, error: upsertError.message });
          } else {
            added.push({ query: r.query_text, url, title: res?.title ?? null });
            sourcesAdded += 1;
            addedForQuery += 1;
          }
        }

        // Extraer códigos relevantes cerca del keyword, usando raw_content (incluye PDFs en texto).
        const content = String(res?.content ?? "");
        if (content) {
          for (const hit of extractCodesNearKeyword({
            text: content,
            keyword: keywordForExtraction,
            windowChars: 350,
            maxCodes: params.codesPerQuery,
            sourceUrl: url,
            sourceTitle: String(res?.title ?? ""),
          })) {
            if (!codes.has(hit.codigo) && hit.item) {
              codes.set(hit.codigo, { item: hit.item });
            }
            if (codes.size >= params.codesPerQuery) break;
          }

          // Gain: importar algunos códigos adicionales desde la misma fuente SIN keyword.
          if (params.gainCodesPerQuery > 0 && gainItems.length < params.gainCodesPerQuery) {
            const general = extractGeneralCodeItemsFromText({
              text: content,
              sourceUrl: url,
              sourceTitle: String(res?.title ?? ""),
              maxItems: params.gainCodesPerQuery - gainItems.length,
            });
            for (const it of general) {
              // Evitar duplicar los estrictos (relacionados al keyword)
              if (codes.has(it.codigo)) continue;
              gainItems.push(it);
              if (gainItems.length >= params.gainCodesPerQuery) break;
            }
          }
        }

        if (addedForQuery >= sourcesPerQuery && codes.size >= params.codesPerQuery) break;
      }

      const codeList = Array.from(codes.keys()).slice(0, params.codesPerQuery);

      // Ganancia: importar códigos extra descubiertos en las fuentes, aunque no haya match estricto
      // para resolver el request. Esto alimenta el catálogo sin asociarlos al query del usuario.
      const now = nowIso();
      if (gainItems.length) {
        // Solo pasan los que se pueden justificar: título real y fuente.
        // Los demás van a cuarentena en vez de colarse como "Secuencia".
        const aprovechables = gainItems.filter((it) =>
          esImportable({ nombre: it.titulo, fuente_url: it.fuente_url })
        );
        const descartados = gainItems.filter((it) =>
          !esImportable({ nombre: it.titulo, fuente_url: it.fuente_url })
        );

        await aCuarentena(
          supabase,
          descartados.map((it) => ({
            codigo: it.codigo,
            nombre_detectado: it.titulo || null,
            fuente_url: it.fuente_url || "(sin fuente)",
            fuente_titulo: it.fuente_titulo || null,
            contexto: it.fuente_extracto || null,
          })),
        );

        const yaExisten = await codigosYaExistentes(
          supabase,
          aprovechables.map((it) => it.codigo),
        );
        const gainInserts = aprovechables
          .filter((it) => !yaExisten.has(it.codigo.replaceAll("_", "")))
          .map((it) => ({
            codigo: it.codigo,
            nombre: it.titulo,
            descripcion: it.descripcion, // sin keyword
            categoria: CATEGORY_FOR_IMPORTED_CODES,
            color: DEFAULT_COLOR,
            fuente_url: it.fuente_url || null,
            fuente_titulo: it.fuente_titulo || null,
            fuente_extracto: it.fuente_extracto || null,
            created_at: now,
            updated_at: now,
          }));
        await supabase
          .from("codigos_grabovoi")
          .upsert(gainInserts, { onConflict: "codigo", ignoreDuplicates: true });
        for (const row of gainInserts) {
          await supabase
            .from("codigos_grabovoi")
            .update({
              nombre: row.nombre,
              descripcion: row.descripcion,
              fuente_url: row.fuente_url,
              fuente_titulo: row.fuente_titulo,
              fuente_extracto: row.fuente_extracto,
              updated_at: now,
            })
            .eq("codigo", row.codigo)
            .eq("categoria", CATEGORY_FOR_IMPORTED_CODES);
        }
      }

      if (codeList.length) {
        const itemsForRequest: any[] = [];
        const candidatos = codeList.map((codigo) => {
          const it = codes.get(codigo)?.item;
          // Ya no se rellena con "Secuencia": si no hay título, el
          // hallazgo no está listo para el catálogo y se queda vacío
          // para que el filtro de abajo lo mande a cuarentena.
          const titulo = String(it?.titulo ?? "").trim();
          const descripcion = String(it?.descripcion ?? "").trim() ||
            (titulo ? `Apoyo para ${titulo.toLowerCase()}. Para ${keywordForExtraction.toLowerCase()}.` : "");
          const fuenteUrl = String(it?.fuente_url ?? "").trim();
          const fuenteTitulo = String(it?.fuente_titulo ?? "").trim();
          const fuenteExtracto = String(it?.fuente_extracto ?? "").trim();

          // El usuario que buscó igual ve todos los resultados; el filtro
          // solo decide qué se queda guardado para siempre.
          itemsForRequest.push({
            codigo,
            nombre: titulo || codigo,
            descripcion,
            fuente_url: fuenteUrl,
            fuente_titulo: fuenteTitulo,
            fuente_extracto: fuenteExtracto,
          });

          return {
            codigo,
            nombre: titulo,
            descripcion, // sin fuentes visibles
            categoria: CATEGORY_FOR_IMPORTED_CODES,
            color: DEFAULT_COLOR,
            fuente_url: fuenteUrl || null,
            fuente_titulo: fuenteTitulo || null,
            fuente_extracto: fuenteExtracto || null,
            created_at: now,
            updated_at: now,
          };
        });

        await aCuarentena(
          supabase,
          candidatos.filter((c) => !esImportable(c)).map((c) => ({
            codigo: c.codigo,
            nombre_detectado: c.nombre || null,
            fuente_url: c.fuente_url || "(sin fuente)",
            fuente_titulo: c.fuente_titulo,
            contexto: c.fuente_extracto,
          })),
        );

        const yaExisten = await codigosYaExistentes(
          supabase,
          candidatos.map((c) => c.codigo),
        );
        const inserts = candidatos
          .filter((c) => esImportable(c))
          .filter((c) => !yaExisten.has(c.codigo.replaceAll("_", "")));

        // Upsert/ignore duplicates (no sobreescribe códigos curados existentes).
        await supabase
          .from("codigos_grabovoi")
          .upsert(inserts, { onConflict: "codigo", ignoreDuplicates: true });

        // Actualizar siempre en categoría "Redes sociales" (solo afecta a los códigos importados por este pipeline).
        for (const row of inserts) {
          await supabase
            .from("codigos_grabovoi")
            .update({
              nombre: row.nombre,
              descripcion: row.descripcion,
              fuente_url: row.fuente_url,
              fuente_titulo: row.fuente_titulo,
              fuente_extracto: row.fuente_extracto,
              updated_at: now,
            })
            .eq("codigo", row.codigo)
            .eq("categoria", CATEGORY_FOR_IMPORTED_CODES);
        }

        // Resolver TODOS los requests pendientes con el mismo query_norm.
        const { error: updErr } = await supabase
          .from("deep_search_requests")
          .update({
            status: "resolved",
            resolved_at: now,
            resolved_codigos: codeList,
            resolved_items: itemsForRequest,
            last_checked_at: now,
            updated_at: now,
            last_error: null,
          })
          .eq("status", "pending")
          .eq("query_norm", r.query_norm);
        if (updErr) {
          errorsAll.push({ query: r.query_text, error: `resolve_update_failed:${updErr.message}` });
        } else {
          resolvedCount += 1;
          resolvedQueries.push({ query: r.query_text, codigos: codeList });
        }
      }
    } catch (e) {
      errorsAll.push({ query: r.query_text, error: String(e) });
    }
  }

  return {
    queries: uniq.length,
    sources_added: sourcesAdded,
    added,
    resolved: resolvedCount,
    resolved_queries: resolvedQueries,
    errors: errorsAll,
  };
}

// El <title> de la página, para guardar de dónde salió cada hallazgo con
// algo legible y no solo la URL. deep_search_sources no guarda título, y
// esa falta de trazabilidad es parte de lo que hacía imposible juzgar los
// códigos importados.
function tituloDeLaPagina(html: string): string | null {
  if (!html) return null;
  const m = /<title[^>]*>([\s\S]*?)<\/title>/i.exec(html);
  if (!m) return null;
  const t = m[1].replace(/\s+/g, " ").trim();
  return t ? t.slice(0, 200) : null;
}

// El texto que rodea al número en la página. Es lo que permite decidir
// después si era una secuencia o el pie de un PDF, sin volver a abrir la
// fuente: "...Versión 1 - 240123 - 150749" canta solo.
function contextoDelCodigo(text: string, codigo: string): string | null {
  if (!text) return null;
  // El código se guarda normalizado (con guiones bajos), pero en la
  // página puede venir con espacios o guiones.
  const patron = codigo.replaceAll("_", "[ _-]?");
  const re = new RegExp(patron);
  const m = re.exec(text);
  if (!m || m.index < 0) return null;
  const desde = Math.max(0, m.index - 90);
  const hasta = Math.min(text.length, m.index + m[0].length + 90);
  return text.substring(desde, hasta).replace(/\s+/g, " ").trim();
}

async function crawlSources(params: {
  supabase: ReturnType<typeof createClient>;
  sourcesLimit: number;
  maxCodesPerSource: number;
  force: boolean;
}): Promise<{ crawled: number; inserted: string[]; errors: any[] }> {
  const { supabase, sourcesLimit, maxCodesPerSource, force } = params;

  const { data: sources, error } = await supabase
    .from("deep_search_sources")
    .select("*")
    .eq("enabled", true)
    .order("last_crawled_at", { ascending: true, nullsFirst: true })
    .limit(sourcesLimit);

  if (error) throw new Error(`sources_select_failed:${error.message}`);

  const insertedAll: string[] = [];
  const errorsAll: any[] = [];
  let crawledCount = 0;

  for (const s of (sources ?? []) as SourceRow[]) {
    // Nota: por ahora solo soportamos páginas HTML (no PDFs). Los PDFs se pueden implementar después.
    if (String(s.source_type ?? "page").toLowerCase() === "pdf") continue;

    const due = force ||
      !s.last_crawled_at ||
      (Date.now() - Date.parse(s.last_crawled_at)) >=
        (Number(s.crawl_interval_hours ?? 24) * 3600 * 1000);
    if (!due) continue;

    try {
      const html = await fetchSourceText(s.url);
      const text = stripHtmlToText(html);
      const codes = extractCodesFromText(text).slice(0, maxCodesPerSource);
      const now = nowIso();

      if (codes.length) {
        // A CUARENTENA, no al catálogo. Esto escribía directo en
        // codigos_grabovoi con nombre "Secuencia" y sin fuente, y de ahí
        // salió toda la basura que hubo que limpiar el 17 de agosto:
        // fechas, horas, números de página y trozos de nombres de PDF.
        //
        // No basta con afinar el filtro: NO se puede distinguir basura de
        // código legítimo mirando solo el número. '121918' es "Permanecer
        // centrado", una secuencia real del catálogo, y a la vez se lee
        // como la hora 12:19:18. Cualquier heurística que rechace horas
        // se come esa secuencia; cualquiera que las acepte deja pasar
        // '150749'. Por eso decide una persona.
        //
        // Se guarda el contexto de la página para poder juzgar después
        // sin volver a abrir la fuente.
        const pendientes = codes.map((codigo) => ({
          codigo,
          nombre_detectado: null,
          fuente_url: s.url,
          fuente_titulo: tituloDeLaPagina(html),
          contexto: contextoDelCodigo(text, codigo),
          detectado_en: now,
        }));

        // onConflict sobre (codigo, fuente_url): rastrear la misma página
        // cada 24h no debe apilar el mismo hallazgo una y otra vez.
        const { data: encolados, error: pendientesError } = await supabase
          .from("codigos_pendientes")
          .upsert(pendientes, {
            onConflict: "codigo,fuente_url",
            ignoreDuplicates: true,
          })
          .select("codigo");

        if (pendientesError) {
          throw new Error(`codigos_pendientes_failed:${pendientesError.message}`);
        }
        const encoladosCodes = (encolados ?? []).map((x: any) => String(x.codigo));
        insertedAll.push(...encoladosCodes);
      }

      await supabase
        .from("deep_search_sources")
        .update({ last_crawled_at: now, last_error: null, updated_at: now })
        .eq("id", s.id);

      crawledCount += 1;
    } catch (e) {
      const err = String(e);
      errorsAll.push({ source_id: s.id, url: s.url, error: err });
      await supabase
        .from("deep_search_sources")
        .update({ last_error: err, updated_at: nowIso() })
        .eq("id", s.id);
    }
  }

  return { crawled: crawledCount, inserted: insertedAll, errors: errorsAll };
}

async function cleanupBadImportedCodes(params: {
  supabase: ReturnType<typeof createClient>;
  maxToDelete: number;
}): Promise<{ deleted: number; sample: string[] }> {
  const { supabase, maxToDelete } = params;
  const since = new Date(Date.now() - 2 * 24 * 3600 * 1000).toISOString();

  const { data: rows, error } = await supabase
    .from("codigos_grabovoi")
    .select("codigo,created_at")
    .eq("categoria", CATEGORY_FOR_IMPORTED_CODES)
    .eq("nombre", "Secuencia importada")
    .gte("created_at", since)
    .or("codigo.like.19%_%,codigo.like.20%_%")
    .limit(5000);

  if (error) {
    console.error("cleanup select error", error);
    return { deleted: 0, sample: [] };
  }

  const isYearNoise = (codigo: string) =>
    /^(19|20)\d{2}_\d{1,4}(_\d{1,4}){0,2}$/.test(codigo);

  const candidates = (rows ?? [])
    .map((r: any) => String(r.codigo ?? ""))
    .filter((c: string) => c && isYearNoise(c))
    .slice(0, maxToDelete);

  if (!candidates.length) return { deleted: 0, sample: [] };

  // Delete in chunks to avoid URL/plan limits
  let deleted = 0;
  const sample = candidates.slice(0, 20);
  for (let i = 0; i < candidates.length; i += 500) {
    const chunk = candidates.slice(i, i + 500);
    const { error: delErr } = await supabase
      .from("codigos_grabovoi")
      .delete()
      .in("codigo", chunk);
    if (delErr) {
      console.error("cleanup delete error", delErr);
      break;
    }
    deleted += chunk.length;
  }

  return { deleted, sample };
}

async function cleanupImportedNombreFormato(params: {
  supabase: ReturnType<typeof createClient>;
  maxToFix: number;
}): Promise<{ fixed: number; sample: Array<{ codigo: string; nombre: string }> }> {
  const { supabase, maxToFix } = params;
  const since = new Date(Date.now() - 14 * 24 * 3600 * 1000).toISOString();

  const { data: rows, error } = await supabase
    .from("codigos_grabovoi")
    .select("codigo,nombre,descripcion,updated_at")
    .eq("categoria", CATEGORY_FOR_IMPORTED_CODES)
    .gte("updated_at", since)
    .limit(2000);

  if (error) {
    console.error("cleanup nombre select error", error);
    return { fixed: 0, sample: [] };
  }

  const candidates = (rows ?? [])
    .map((r: any) => ({
      codigo: String(r.codigo ?? ""),
      nombre: String(r.nombre ?? ""),
      descripcion: String(r.descripcion ?? ""),
    }))
    .filter((r: any) => {
      if (!r.codigo || !r.nombre) return false;
      const nombre = String(r.nombre);
      const folded = foldText(nombre);
      // Fix si trae código pegado o si parece portugués (caracteres/palabras frecuentes).
      return (
        /[0-9_]/.test(nombre) ||
        /[ãõç]/i.test(nombre) ||
        /\bmedo\b/.test(folded) ||
        /\besperanca\b/.test(folded) ||
        /\bperigo\b/.test(folded) ||
        /\bangustia\b/.test(folded) ||
        // O si quedó en minúsculas (formato visual incorrecto en UI)
        /^[a-záéíóúñü]/.test(nombre.trim())
      );
    })
    .slice(0, maxToFix);

  if (!candidates.length) return { fixed: 0, sample: [] };

  let fixed = 0;
  const sample: Array<{ codigo: string; nombre: string }> = [];
  const now = nowIso();

  for (const c of candidates) {
    const nombreFixed = sanitizeNombreEs(c.nombre);
    if (!nombreFixed) continue;
    const descripcionFixed = generalDescripcionFromTitle(nombreFixed);
    const { error: updErr } = await supabase
      .from("codigos_grabovoi")
      .update({
        nombre: nombreFixed,
        descripcion: descripcionFixed,
        updated_at: now,
      })
      .eq("codigo", c.codigo)
      .eq("categoria", CATEGORY_FOR_IMPORTED_CODES);
    if (!updErr) {
      fixed += 1;
      if (sample.length < 20) sample.push({ codigo: c.codigo, nombre: nombreFixed });
    }
  }

  return { fixed, sample };
}

async function pruneKeywordNoise(params: {
  supabase: ReturnType<typeof createClient>;
  keyword: string;
  keepCodes: string[];
  maxToPrune: number;
}): Promise<{ pruned: number }> {
  const keywordFold = foldText(params.keyword).trim();
  if (!keywordFold) return { pruned: 0 };

  // Only touch recently updated imported rows to avoid damaging curated data.
  const since = new Date(Date.now() - 7 * 24 * 3600 * 1000).toISOString();

  const { data: rows, error } = await params.supabase
    .from("codigos_grabovoi")
    .select("codigo,descripcion,fuente_extracto,updated_at")
    .eq("categoria", CATEGORY_FOR_IMPORTED_CODES)
    .gte("updated_at", since)
    .ilike("descripcion", `%Para %${keywordFold}%`)
    .limit(5000);

  if (error) {
    console.error("prune select error", error);
    return { pruned: 0 };
  }

  const keep = new Set(params.keepCodes);
  const toUpdate = (rows ?? [])
    .filter((r: any) => !keep.has(String(r.codigo)))
    .filter((r: any) => {
      const extracto = String(r.fuente_extracto ?? "");
      // If we don't have evidence containing the keyword, it's probably noise.
      return !foldText(extracto).includes(keywordFold);
    })
    .slice(0, params.maxToPrune);

  let pruned = 0;
  for (const r of toUpdate) {
    const codigo = String((r as any).codigo);
    const desc = String((r as any).descripcion ?? "");
    const cleaned = desc.replace(new RegExp(`\\s*Para\\s+${keywordFold}\\.?\\s*`, "ig"), " ").replace(/\s+/g, " ").trim();
    if (cleaned === desc) continue;
    const { error: updErr } = await params.supabase
      .from("codigos_grabovoi")
      .update({ descripcion: cleaned, updated_at: nowIso() })
      .eq("codigo", codigo)
      .eq("categoria", CATEGORY_FOR_IMPORTED_CODES);
    if (updErr) {
      console.error("prune update error", codigo, updErr);
      continue;
    }
    pruned += 1;
  }

  return { pruned };
}

async function resolveRequests(params: {
  supabase: ReturnType<typeof createClient>;
  requestsLimit: number;
  supabaseUrl: string;
  pushSecret: string;
  anonKey: string;
}): Promise<{ checked: number; resolved: number; noResults: number; items: any[] }> {
  const { supabase, requestsLimit, supabaseUrl, pushSecret, anonKey } = params;

  const { data: reqs, error } = await supabase
    .from("deep_search_requests")
    .select("*")
    .eq("status", "pending")
    .order("updated_at", { ascending: true })
    .limit(requestsLimit);

  if (error) throw new Error(`requests_select_failed:${error.message}`);

  const items: any[] = [];
  let resolved = 0;
  let noResults = 0;

  for (const r of (reqs ?? []) as RequestRow[]) {
    const now = nowIso();
    const norm = normalizeQuery(r.query_norm || r.query_text || "");
    const digits = queryDigits(norm);

    let matches: any[] = [];
    let resolvedItems: any[] = [];
    if (digits.length >= 3) {
      // Buscar por dígitos ignorando separadores: equivalencia (519 7148) == (519_7148)
      // Nota: no podemos hacer translate()/regexp en PostgREST fácilmente; hacemos una preselección
      // por prefijo corto y luego filtramos en memoria por coincidencia de dígitos.
      const prefix = digits.slice(0, Math.min(4, digits.length));
      const { data: found, error: findErr } = await supabase
        .from("codigos_grabovoi")
        .select("codigo,nombre,descripcion,fuente_url,fuente_titulo,fuente_extracto")
        .ilike("codigo", `%${prefix}%`)
        .limit(200);
      if (findErr) {
        await supabase
          .from("deep_search_requests")
          .update({
            attempts: Number(r.attempts ?? 0) + 1,
            last_error: `resolve_find_failed:${findErr.message}`,
            last_checked_at: now,
            updated_at: now,
          })
          .eq("id", r.id);
        items.push({ id: r.id, query: r.query_text, resolved: false, error: "resolve_find_failed" });
        continue;
      }
      matches = (found ?? []).filter((x: any) => queryDigits(String(x.codigo)).includes(digits));
      resolvedItems = matches.map((x: any) => ({
        codigo: String(x.codigo),
        nombre: String(x.nombre ?? ""),
        descripcion: String(x.descripcion ?? ""),
        fuente_url: x.fuente_url ?? null,
        fuente_titulo: x.fuente_titulo ?? null,
        fuente_extracto: x.fuente_extracto ?? null,
      }));
    } else {
      // Búsquedas conceptuales (sin dígitos): intentar match por texto en nombre/descripcion.
      // Esto solo funciona si el catálogo ya tiene metadata; si no, seguirá pending.
      const q = norm.slice(0, 64);
      const { data: found, error: findErr } = await supabase
        .from("codigos_grabovoi")
        .select("codigo,nombre,descripcion,fuente_url,fuente_titulo,fuente_extracto")
        .or(`nombre.ilike.%${q}%,descripcion.ilike.%${q}%`)
        .limit(10);
      if (findErr) {
        await supabase
          .from("deep_search_requests")
          .update({
            attempts: Number(r.attempts ?? 0) + 1,
            last_error: `resolve_text_find_failed:${findErr.message}`,
            last_checked_at: now,
            updated_at: now,
          })
          .eq("id", r.id);
        items.push({ id: r.id, query: r.query_text, resolved: false, error: "resolve_text_find_failed" });
        continue;
      }
      matches = found ?? [];
      resolvedItems = matches.map((x: any) => ({
        codigo: String(x.codigo),
        nombre: String(x.nombre ?? ""),
        descripcion: String(x.descripcion ?? ""),
        fuente_url: x.fuente_url ?? null,
        fuente_titulo: x.fuente_titulo ?? null,
        fuente_extracto: x.fuente_extracto ?? null,
      }));
    }

    if (matches.length) {
      resolved += 1;
      const codigos = matches.map((x: any) => String(x.codigo));
      await supabase
        .from("deep_search_requests")
        .update({
          status: "resolved",
          resolved_at: now,
          resolved_codigos: codigos,
          resolved_items: resolvedItems,
          attempts: Number(r.attempts ?? 0) + 1,
          last_error: null,
          last_checked_at: now,
          updated_at: now,
        })
        .eq("id", r.id);
      items.push({ id: r.id, query: r.query_text, resolved: true, codigos });

      if (r.user_id) {
        const nombres = resolvedItems
          .map((it: any) => String(it?.nombre ?? "").trim())
          .filter((n: string) => n.length > 0);
        const listado = (nombres.length ? nombres : codigos).slice(0, 3).join(", ");
        const restantes = matches.length - Math.min(3, matches.length);
        const extra = restantes > 0 ? ` y ${restantes} más` : "";
        await sendPushNotification({
          supabaseUrl,
          pushSecret,
          anonKey,
          userId: r.user_id,
          title: "🔎 Encontramos tu secuencia",
          body: `Ya está disponible tu búsqueda "${r.query_text}": ${listado}${extra}.`,
          data: {
            type: "deep_search_resolved",
            request_id: String(r.id),
            codigos: codigos.join(","),
          },
        });
      }
      continue;
    }

    const attemptsNext = Number(r.attempts ?? 0) + 1;
    const statusNext = attemptsNext >= 24 ? "no_results" : "pending";
    if (statusNext === "no_results") noResults += 1;

    await supabase
      .from("deep_search_requests")
      .update({
        status: statusNext,
        attempts: attemptsNext,
        last_checked_at: now,
        updated_at: now,
      })
      .eq("id", r.id);
    items.push({ id: r.id, query: r.query_text, resolved: false, status: statusNext });
  }

  return { checked: (reqs ?? []).length, resolved, noResults, items };
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // Falla cerrado: si CRON_SECRET no está configurado, antes se saltaba el
  // chequeo por completo y cualquiera podía disparar crawling + búsquedas
  // pagadas (Tavily) sin autenticación. Ahora sin CRON_SECRET configurado el
  // endpoint queda inaccesible en vez de abierto.
  const cronSecret = Deno.env.get("CRON_SECRET") ?? "";
  if (!cronSecret) {
    return new Response(JSON.stringify({ success: false, error: "CRON_SECRET no configurado" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
  const provided = req.headers.get("x-cron-secret") ?? "";
  if (provided !== cronSecret) {
    return new Response(JSON.stringify({ success: false, error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!supabaseUrl || !serviceKey) {
    return new Response(
      JSON.stringify({ success: false, error: "Missing SUPABASE_URL/SUPABASE_SERVICE_ROLE_KEY" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
  const supabase = createClient(supabaseUrl, serviceKey);
  // Mismo secreto compartido que ya usa notify_push_from_db() / send-push.
  const pushSecret = Deno.env.get("PUSH_SECRET") ?? "";
  // Requerido por el gateway de Supabase como Authorization al llamar a otra
  // función (send-push); no es la sesión de ningún usuario.
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

  const sourcesLimit = Number(Deno.env.get("DEEP_SEARCH_SOURCES_PER_RUN") ?? "20");
  const maxCodesPerSource = Number(Deno.env.get("DEEP_SEARCH_MAX_CODES_PER_SOURCE") ?? "250");
  const requestsLimit = Number(Deno.env.get("DEEP_SEARCH_REQUESTS_PER_RUN") ?? "200");
  const cleanupMax = Number(Deno.env.get("DEEP_SEARCH_CLEANUP_MAX") ?? "2000");
  const cleanupNombreMax = Number(Deno.env.get("DEEP_SEARCH_CLEANUP_NOMBRE_MAX") ?? "200");
  const discoveryQueries = Number(Deno.env.get("DEEP_SEARCH_DISCOVERY_QUERIES_PER_RUN") ?? "5");
  const discoverySourcesPerQuery = Number(Deno.env.get("DEEP_SEARCH_DISCOVERY_SOURCES_PER_QUERY") ?? "2");
  const discoveryMaxResults = Number(Deno.env.get("DEEP_SEARCH_DISCOVERY_MAX_RESULTS") ?? "5");
  const discoveryCodesPerQuery = Number(Deno.env.get("DEEP_SEARCH_DISCOVERY_CODES_PER_QUERY") ?? "2");
  const discoveryGainCodes = Number(Deno.env.get("DEEP_SEARCH_DISCOVERY_GAIN_CODES_PER_QUERY") ?? "8");
  const body = req.method === "POST" ? await req.json().catch(() => ({})) : {};
  const forceCrawl = body?.force_crawl === true;

  try {
    const discovery = await discoveryControlled({
      supabase,
      queriesLimit: discoveryQueries,
      sourcesPerQuery: discoverySourcesPerQuery,
      tavilyMaxResults: discoveryMaxResults,
      codesPerQuery: discoveryCodesPerQuery,
      gainCodesPerQuery: discoveryGainCodes,
    });

    // Prune noise for the queries we just processed (best effort).
    if (Array.isArray(discovery.resolved_queries)) {
      for (const rq of discovery.resolved_queries) {
        const keyword = String(rq?.query ?? "").trim();
        const keepCodes = Array.isArray(rq?.codigos) ? rq.codigos.map(String) : [];
        if (!keyword || keepCodes.length === 0) continue;
        await pruneKeywordNoise({ supabase, keyword, keepCodes, maxToPrune: 200 });
      }
	    }
	    const crawl = await crawlSources({ supabase, sourcesLimit, maxCodesPerSource, force: forceCrawl });
	    const cleanup = await cleanupBadImportedCodes({ supabase, maxToDelete: cleanupMax });
	    const cleanupNombre = await cleanupImportedNombreFormato({ supabase, maxToFix: cleanupNombreMax });
	    const resolve = await resolveRequests({ supabase, requestsLimit, supabaseUrl, pushSecret, anonKey });

	    // Aviso a admins: que la base se está "alimentando" (código nuevo por
	    // crawl) y/o que se resolvieron búsquedas de usuarios en este ciclo.
	    let adminNotified = 0;
	    const totalInserted = crawl.inserted.length;
	    if (totalInserted > 0 || resolve.resolved > 0) {
	      const adminIds = await getAdminUserIds(supabase);
	      const partes: string[] = [];
	      if (totalInserted > 0) partes.push(`${totalInserted} secuencia(s) nueva(s) en la base`);
	      if (resolve.resolved > 0) partes.push(`${resolve.resolved} búsqueda(s) de usuarios resuelta(s)`);
	      const muestra = crawl.inserted.slice(0, 5).join(", ");
	      const body = totalInserted > 0
	        ? `${partes.join(" · ")}. Ejemplos: ${muestra}${totalInserted > 5 ? "…" : ""}`
	        : partes.join(" · ");
	      await Promise.all(adminIds.map((adminId) =>
	        sendPushNotification({
	          supabaseUrl,
	          pushSecret,
	          anonKey,
	          userId: adminId,
	          title: "📥 Base de datos alimentada",
	          body,
	          data: {
	            type: "deep_search_admin_summary",
	            inserted_count: String(totalInserted),
	            resolved_count: String(resolve.resolved),
	          },
	        })
	      ));
	      adminNotified = adminIds.length;
	    }

	    return new Response(
	      JSON.stringify({
	        success: true,
        discovery: {
          queries: discovery.queries,
          sources_added: discovery.sources_added,
          added: discovery.added,
          resolved: discovery.resolved,
          resolved_queries: discovery.resolved_queries,
          errors: discovery.errors,
        },
        crawl: {
          sources_crawled: crawl.crawled,
          inserted_codes_count: crawl.inserted.length,
          inserted_codes_sample: crawl.inserted.slice(0, 20),
          forced: forceCrawl,
          errors: crawl.errors,
        },
	        cleanup: {
	          deleted: cleanup.deleted,
	          deleted_sample: cleanup.sample,
	        },
	        cleanup_nombre: {
	          fixed: cleanupNombre.fixed,
	          sample: cleanupNombre.sample,
	        },
	        resolve: {
	          checked: resolve.checked,
	          resolved: resolve.resolved,
	          no_results: resolve.noResults,
	          items: resolve.items,
        },
        admin_notified: adminNotified,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("process-deep-search-queue unexpected", e);
    return new Response(JSON.stringify({ success: false, error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
