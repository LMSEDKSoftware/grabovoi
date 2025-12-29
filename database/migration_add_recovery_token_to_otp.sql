-- Migración: Agregar columna recovery_token a password_reset_otps
-- Este campo guardará el token completo de Supabase para usar el método oficial

-- Agregar columna recovery_token si no existe
do $$
begin
  if not exists (
    select 1 
    from information_schema.columns 
    where table_schema = 'public' 
    and table_name = 'password_reset_otps' 
    and column_name = 'recovery_token'
  ) then
    alter table public.password_reset_otps 
    add column recovery_token text;
    
    comment on column public.password_reset_otps.recovery_token is 
    'Token completo de recuperación de Supabase (generado con admin.generateLink). Se usa junto con otp_code (código corto mostrado al usuario)';
    
    raise notice 'Columna recovery_token agregada exitosamente';
  else
    raise notice 'Columna recovery_token ya existe';
  end if;
end $$;

-- Índice opcional para búsquedas por recovery_token (si es necesario)
-- create index if not exists idx_password_reset_otps_recovery_token 
-- on public.password_reset_otps (recovery_token) 
-- where recovery_token is not null;

