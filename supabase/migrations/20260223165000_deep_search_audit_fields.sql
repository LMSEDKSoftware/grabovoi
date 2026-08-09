-- Add audit/source fields for deep search generated codes and richer request resolution payloads

alter table if exists public.codigos_grabovoi
  add column if not exists fuente_url text,
  add column if not exists fuente_titulo text,
  add column if not exists fuente_extracto text;

alter table if exists public.deep_search_requests
  add column if not exists resolved_items jsonb;

