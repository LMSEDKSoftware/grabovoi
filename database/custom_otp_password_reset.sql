-- Tabla para OTP de recuperación de contraseña
create table if not exists public.password_reset_otps (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  otp_code text not null, -- Código corto mostrado al usuario (6 dígitos)
  recovery_token text, -- Token completo de Supabase (si se usa sistema oficial)
  expires_at timestamptz not null,
  used boolean not null default false,
  created_at timestamptz not null default now()
);

-- Agregar columna recovery_token si no existe (para migración)
do $$
begin
  if not exists (select 1 from information_schema.columns 
                 where table_schema = 'public' 
                 and table_name = 'password_reset_otps' 
                 and column_name = 'recovery_token') then
    alter table public.password_reset_otps add column recovery_token text;
  end if;
end $$;

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
