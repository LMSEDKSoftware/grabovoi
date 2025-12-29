-- Migración: Agregar columna recovery_link a password_reset_otps
-- Este campo guardará el link completo de recuperación de Supabase

-- Agregar columna recovery_link si no existe
do $$
begin
  if not exists (
    select 1 
    from information_schema.columns 
    where table_schema = 'public' 
    and table_name = 'password_reset_otps' 
    and column_name = 'recovery_link'
  ) then
    alter table public.password_reset_otps 
    add column recovery_link text;
    
    comment on column public.password_reset_otps.recovery_link is 
    'Link completo de recuperación de Supabase generado con admin.generateLink(). Se devuelve al cliente después de verificar OTP.';
    
    raise notice '✅ Columna recovery_link agregada exitosamente';
  else
    raise notice '⚠️ Columna recovery_link ya existe';
  end if;
end $$;

-- Índice opcional para búsquedas
CREATE INDEX IF NOT EXISTS idx_otp_email_used_expires
ON public.password_reset_otps (email, used, expires_at DESC);

