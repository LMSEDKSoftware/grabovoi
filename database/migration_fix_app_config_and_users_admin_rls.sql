-- Fix RLS recursion that can break reading app_config (legal links)
-- Symptoms: GET /rest/v1/app_config ... -> 500 with PostgREST error 42P17 (infinite recursion in policy for relation "users_admin")
--
-- Ejecutar en Supabase SQL Editor.

-- 1) Asegurar función segura para verificar admin (bypasses RLS)
create or replace function public.es_admin(user_uuid uuid)
returns boolean
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  return exists (
    select 1 from public.users_admin
    where user_id = user_uuid
  );
end;
$$;

-- 2) Users admin: reemplazar política recursiva por una basada en es_admin()
alter table public.users_admin enable row level security;

drop policy if exists "Admins can view all admin users" on public.users_admin;
create policy "Admins can view all admin users" on public.users_admin
  for select
  using (public.es_admin(auth.uid()));

-- 3) App config: separar policies de modificación para que NO apliquen a SELECT
alter table public.app_config enable row level security;

-- Mantener lectura pública si existe; si no, crearla
drop policy if exists "Public can read app config" on public.app_config;
create policy "Public can read app config" on public.app_config
  for select
  using (true);

-- Borrar policy antigua (FOR ALL) si existe y crear policies específicas
drop policy if exists "Admins can modify app config" on public.app_config;
drop policy if exists "Admins can update app config" on public.app_config;
drop policy if exists "Admins can delete app config" on public.app_config;

create policy "Admins can modify app config" on public.app_config
  for insert
  with check (public.es_admin(auth.uid()));

create policy "Admins can update app config" on public.app_config
  for update
  using (public.es_admin(auth.uid()))
  with check (public.es_admin(auth.uid()));

create policy "Admins can delete app config" on public.app_config
  for delete
  using (public.es_admin(auth.uid()));

-- Opcional: grants explícitos para REST (si tu proyecto los requiere)
grant select on public.app_config to anon;
grant select on public.app_config to authenticated;
grant select on public.app_config to service_role;

