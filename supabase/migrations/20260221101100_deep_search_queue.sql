create table if not exists public.deep_search_queue (
  id bigint generated always as identity primary key,
  query_text text not null,
  query_norm text not null,
  requested_count integer not null default 1,
  created_at timestamptz not null default now(),
  last_requested_at timestamptz not null default now(),
  status text not null default 'pending',
  sent_at timestamptz,
  attempts integer not null default 0,
  last_error text,
  last_web_results jsonb,
  last_openai_content text,
  inserted_codes jsonb
);

create index if not exists deep_search_queue_status_idx
  on public.deep_search_queue (status, sent_at, last_requested_at);

-- Dedupe: solo un registro "pendiente" por query_norm a la vez.
create unique index if not exists deep_search_queue_unique_pending
  on public.deep_search_queue (query_norm)
  where sent_at is null;

