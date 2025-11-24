-- Tabla para OTP de recuperación de contraseña
create table if not exists public.password_reset_otps (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  otp_code text not null,
  expires_at timestamptz not null,
  used boolean not null default false,
  created_at timestamptz not null default now()
);

-- Índices útiles
create index if not exists idx_password_reset_otps_email on public.password_reset_otps (email);
create index if not exists idx_password_reset_otps_expires_at on public.password_reset_otps (expires_at);
create index if not exists idx_password_reset_otps_used on public.password_reset_otps (used);

-- Política de seguridad (RLS): sólo funciones/servidor deben acceder a esta tabla
alter table public.password_reset_otps enable row level security;
drop policy if exists select_none_password_reset_otps on public.password_reset_otps;
create policy select_none_password_reset_otps on public.password_reset_otps
  for select using (false);
drop policy if exists modify_none_password_reset_otps on public.password_reset_otps;
create policy modify_none_password_reset_otps on public.password_reset_otps
  for all using (false);
