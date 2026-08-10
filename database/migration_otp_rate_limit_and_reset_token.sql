-- Cierra dos vulnerabilidades críticas encadenadas en el flujo de "olvidé mi
-- contraseña" (OTP de 6 dígitos + server/reset-password.php):
--
-- 1) verify-otp no tenía límite de intentos: un OTP de 6 dígitos (900,000
--    combinaciones) era agotable por fuerza bruta en minutos.
-- 2) reset-password.php solo validaba "existe un OTP used=true reciente para
--    este email" — sin ningún token ligado a ESA verificación puntual. Con el
--    OTP de la víctima adivinado (punto 1), cualquiera podía cambiarle la
--    contraseña sin sesión ni JWT.
--
-- Ejecutar en Supabase SQL Editor.

alter table public.password_reset_otps
  add column if not exists attempts integer not null default 0,
  add column if not exists reset_token text null,
  add column if not exists reset_token_expires_at timestamptz null;

create index if not exists idx_password_reset_otps_reset_token
  on public.password_reset_otps (reset_token)
  where reset_token is not null;

comment on column public.password_reset_otps.attempts is 'Intentos fallidos de verificación de este código. Se bloquea (used=true) al llegar al máximo permitido en verify-otp.';
comment on column public.password_reset_otps.reset_token is 'Token aleatorio de un solo uso, generado por verify-otp tras verificar el OTP correctamente. reset-password.php lo exige junto al email; se invalida (null) tras usarse.';
comment on column public.password_reset_otps.reset_token_expires_at is 'Expiración corta (10 min) del reset_token, independiente de la expiración del OTP original.';
