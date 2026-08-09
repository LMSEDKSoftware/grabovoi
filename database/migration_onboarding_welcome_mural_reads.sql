-- Persistencia en DB de:
-- 1) Tour/Onboarding (solo 1 vez)
-- 2) WelcomeModal (mostrar siempre salvo "no volver a mostrar")
-- 3) Lecturas de mensajes del Mural por usuario
--
-- Ejecutar en Supabase SQL Editor.

-- 1) + 2) Flags en public.users
alter table public.users
  add column if not exists onboarding_seen_at timestamp with time zone;

alter table public.users
  add column if not exists welcome_dont_show_again boolean not null default false;

alter table public.users
  add column if not exists welcome_dont_show_again_set_at timestamp with time zone;

-- 3) Relación users ↔ mural_messages (mensajes vistos)
create table if not exists public.mural_message_reads (
  user_id uuid not null references public.users (id) on delete cascade,
  message_id bigint not null references public.mural_messages (id) on delete cascade,
  seen_at timestamp with time zone not null default now(),
  constraint mural_message_reads_pkey primary key (user_id, message_id)
);

create index if not exists idx_mural_message_reads_user_id
  on public.mural_message_reads using btree (user_id);

create index if not exists idx_mural_message_reads_message_id
  on public.mural_message_reads using btree (message_id);

alter table public.mural_message_reads enable row level security;

-- Políticas RLS: cada usuario ve/crea sus propios "reads"
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'mural_message_reads'
      and policyname = 'Users can view own mural reads'
  ) then
    create policy "Users can view own mural reads"
      on public.mural_message_reads for select
      using (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'mural_message_reads'
      and policyname = 'Users can insert own mural reads'
  ) then
    create policy "Users can insert own mural reads"
      on public.mural_message_reads for insert
      with check (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'mural_message_reads'
      and policyname = 'Users can delete own mural reads'
  ) then
    create policy "Users can delete own mural reads"
      on public.mural_message_reads for delete
      using (auth.uid() = user_id);
  end if;
end $$;

