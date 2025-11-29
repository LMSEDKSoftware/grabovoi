-- Tabla para sesiones de reset de password (seguridad)
-- Solo permite cambio de password si el OTP fue validado previamente

create table if not exists public.password_reset_sessions (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  allowed_for_reset boolean not null default false,
  expires_at timestamptz not null,
  ip_address text,
  used boolean not null default false,
  user_id uuid, -- ID del usuario en auth.users
  otp_id uuid, -- Referencia al OTP que fue validado
  created_at timestamptz not null default now()
);

-- Índices útiles
create index if not exists idx_password_reset_sessions_email on public.password_reset_sessions (email);
create index if not exists idx_password_reset_sessions_allowed on public.password_reset_sessions (allowed_for_reset);
create index if not exists idx_password_reset_sessions_expires on public.password_reset_sessions (expires_at);
create index if not exists idx_password_reset_sessions_used on public.password_reset_sessions (used);

-- Política de seguridad: Solo funciones/servidor pueden acceder
alter table public.password_reset_sessions enable row level security;

drop policy if exists select_none_password_reset_sessions on public.password_reset_sessions;
create policy select_none_password_reset_sessions on public.password_reset_sessions
  for select using (false);

drop policy if exists modify_none_password_reset_sessions on public.password_reset_sessions;
create policy modify_none_password_reset_sessions on public.password_reset_sessions
  for all using (false);

-- Función para limpiar sesiones expiradas (opcional, puede ejecutarse con cron)
create or replace function cleanup_expired_password_reset_sessions()
returns void
language plpgsql
as $$
begin
  delete from public.password_reset_sessions
  where expires_at < now() - interval '1 day';
end;
$$;


