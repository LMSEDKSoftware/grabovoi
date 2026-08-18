-- ¿Existe una cuenta de ManiGraB con ese correo?
--
-- Hace falta para el inicio de sesión con la cuenta de Roku: cuando el
-- usuario acepta compartir su correo (ChannelStore getUserData, criterio
-- RP 2.1), el canal necesita saber si ya tiene cuenta para decidir entre
-- pedirle la contraseña o mandarlo a registrarse en la app.
--
-- Va como función y no como consulta directa porque auth.users no está
-- expuesta por PostgREST, y supabase-js no tiene getUserByEmail.
--
-- Devuelve SOLO un booleano: nunca el id, el nombre ni ningún otro dato
-- de la cuenta. Con eso basta para decidir el siguiente paso, y entrar
-- sigue exigiendo contraseña o vinculación por QR.
create or replace function public.existe_correo(p_email text)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from auth.users
     where lower(email) = lower(trim(p_email))
  );
$$;

-- Solo el service_role la llama, desde el endpoint. No se concede a anon
-- ni a authenticated: seria un oraculo abierto para averiguar que correos
-- estan registrados.
revoke all on function public.existe_correo(text) from public, anon, authenticated;

comment on function public.existe_correo is
  'Dice si un correo tiene cuenta, sin revelar nada mas. Para el login con cuenta de Roku. Ver roku-device.js.';
