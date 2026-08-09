-- Deep search v2: requests per user + crawler sources

create table if not exists public.deep_search_sources (
  id bigint generated always as identity primary key,
  url text not null,
  source_type text not null default 'page', -- page | list | blog | pdf | etc
  enabled boolean not null default true,
  crawl_interval_hours integer not null default 24,
  last_crawled_at timestamptz,
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists deep_search_sources_url_unique
  on public.deep_search_sources (url);

create index if not exists deep_search_sources_due_idx
  on public.deep_search_sources (enabled, last_crawled_at);

create table if not exists public.deep_search_requests (
  id bigint generated always as identity primary key,
  user_id uuid,
  query_text text not null,
  query_norm text not null,
  status text not null default 'pending', -- pending | resolved | no_results
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolved_codigos jsonb, -- array de strings (codigo) que resolvieron la búsqueda
  attempts integer not null default 0,
  last_error text,
  last_checked_at timestamptz
);

create index if not exists deep_search_requests_status_idx
  on public.deep_search_requests (status, updated_at);

create index if not exists deep_search_requests_query_norm_idx
  on public.deep_search_requests (query_norm, status);

-- Dedupe por usuario: una request pendiente por (user_id, query_norm)
create unique index if not exists deep_search_requests_unique_pending_user
  on public.deep_search_requests (user_id, query_norm)
  where status = 'pending';

-- Seed inicial de fuentes (mejor esfuerzo). Se puede editar en Dashboard luego.
insert into public.deep_search_sources (url, source_type, enabled, crawl_interval_hours)
select s.url, s.source_type, true, 24
from (
  values
    ('https://numerosgrabovoi.wordpress.com/', 'blog'),
    ('https://www.lifespiritssocietyofmagick.com/post/master-list-of-grabovoi-numbers', 'list'),
    ('https://gist.github.com/yashodhank/957c6eedccfecff6cbe6ca9b18217c09', 'list')
) as s(url, source_type)
where not exists (
  select 1 from public.deep_search_sources existing where existing.url = s.url
);
