-- Tabla para logs detallados de transacciones OTP
create table if not exists public.otp_transaction_logs (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  function_name text not null, -- 'send-otp' o 'verify-otp'
  action text not null, -- 'otp_requested', 'otp_sent', 'otp_verified', 'password_updated', 'error', etc.
  message text not null, -- Mensaje descriptivo
  log_level text not null default 'info', -- 'debug', 'info', 'warning', 'error'
  metadata jsonb, -- Información adicional estructurada (OTP código, user_id, errores, etc.)
  otp_id uuid references public.password_reset_otps(id) on delete set null,
  user_id uuid, -- ID del usuario de auth.users si está disponible
  error_details jsonb, -- Detalles de errores si los hay
  created_at timestamptz not null default now()
);

-- Índices útiles para búsquedas rápidas
create index if not exists idx_otp_logs_email on public.otp_transaction_logs (email);
create index if not exists idx_otp_logs_function on public.otp_transaction_logs (function_name);
create index if not exists idx_otp_logs_action on public.otp_transaction_logs (action);
create index if not exists idx_otp_logs_level on public.otp_transaction_logs (log_level);
create index if not exists idx_otp_logs_created_at on public.otp_transaction_logs (created_at desc);
create index if not exists idx_otp_logs_otp_id on public.otp_transaction_logs (otp_id);

-- Política de seguridad: Permitir que las Edge Functions escriban logs
alter table public.otp_transaction_logs enable row level security;

-- Permitir que el servicio (service_role) pueda insertar y leer logs
drop policy if exists service_role_all_otp_logs on public.otp_transaction_logs;
create policy service_role_all_otp_logs on public.otp_transaction_logs
  for all
  using (true)
  with check (true);

-- Los usuarios normales NO pueden ver los logs (privacidad)
drop policy if exists users_no_otp_logs on public.otp_transaction_logs;
create policy users_no_otp_logs on public.otp_transaction_logs
  for select
  using (false);

