-- ManiGraB TV (Roku): vinculación de cuenta + rutinas.
--
-- Roku prohíbe explícitamente el patrón de login "código en pantalla,
-- actívalo en tu teléfono" (lo llaman "rendezvous", deprecado) para apps
-- públicas: el login debe pasar enteramente dentro del canal, con
-- teclado en pantalla. Por eso roku_account_links no replica el flujo
-- OAuth de Alexa (alexa_account_links) — el canal llama directo a un
-- endpoint con email+password, valida contra Supabase Auth, y aquí solo
-- guardamos el token opaco resultante. Ver docs/ROKU_TV_PLAN.md.

create table if not exists public.roku_account_links (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  access_token text not null unique,
  access_token_expires_at timestamptz not null,
  device_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.roku_account_links is
  'Vínculo entre una cuenta ManiGraB y una sesión del canal de Roku. Login on-device (requisito de Roku), no OAuth. Ver docs/ROKU_TV_PLAN.md.';

alter table public.roku_account_links enable row level security;

-- Rutinas: listas ordenadas de secuencias creadas por el usuario. No
-- existía ningún concepto parecido en el schema ni en la app — es
-- feature nueva, pensada para crearse primero en la app/web y que Roku
-- (y a futuro Alexa) las consuma.
create table if not exists public.rutinas (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  nombre text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.rutina_items (
  id uuid primary key default gen_random_uuid(),
  rutina_id uuid not null references public.rutinas(id) on delete cascade,
  codigo_id uuid not null references public.codigos_grabovoi(id) on delete cascade,
  orden int not null,
  created_at timestamptz not null default now(),
  unique (rutina_id, orden)
);

comment on table public.rutinas is
  'Playlists de secuencias creadas por el usuario ("mi rutina de mañana"). Feature nueva, compartida entre app/web y ManiGraB TV.';

alter table public.rutinas enable row level security;
alter table public.rutina_items enable row level security;

-- El dueño de la rutina puede hacer todo con ella. Sin acceso público:
-- las rutinas son privadas por diseño, a diferencia de codigos_grabovoi.
create policy "rutinas_select_own" on public.rutinas
  for select using (auth.uid() = user_id);
create policy "rutinas_insert_own" on public.rutinas
  for insert with check (auth.uid() = user_id);
create policy "rutinas_update_own" on public.rutinas
  for update using (auth.uid() = user_id);
create policy "rutinas_delete_own" on public.rutinas
  for delete using (auth.uid() = user_id);

create policy "rutina_items_select_own" on public.rutina_items
  for select using (
    exists (select 1 from public.rutinas r where r.id = rutina_id and r.user_id = auth.uid())
  );
create policy "rutina_items_insert_own" on public.rutina_items
  for insert with check (
    exists (select 1 from public.rutinas r where r.id = rutina_id and r.user_id = auth.uid())
  );
create policy "rutina_items_update_own" on public.rutina_items
  for update using (
    exists (select 1 from public.rutinas r where r.id = rutina_id and r.user_id = auth.uid())
  );
create policy "rutina_items_delete_own" on public.rutina_items
  for delete using (
    exists (select 1 from public.rutinas r where r.id = rutina_id and r.user_id = auth.uid())
  );

create index if not exists idx_rutina_items_rutina on public.rutina_items(rutina_id);
create index if not exists idx_rutinas_user on public.rutinas(user_id);
