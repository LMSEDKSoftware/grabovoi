-- users_admin tenía dos problemas de política acumulados de arreglos previos:
--
-- 1) scripts/fix_recursion_users_admin.sql (un parche anterior contra
--    recursión infinita) dejó una política "Allow read access for
--    authenticated users" con USING(true) para el rol authenticated: CUALQUIER
--    usuario logueado podía leer la lista completa de administradores
--    (recon útil para un ataque dirigido). La convive con la política correcta
--    basada en es_admin() de database/users_admin_schema.sql — Postgres
--    combina políticas permisivas con OR, así que la más permisiva ganaba.
--
-- 2) La política de DELETE usaba un subquery directo contra la misma tabla
--    (el patrón exacto que causó la recursión original) en vez de la función
--    es_admin() (SECURITY DEFINER, ya prueba no causar recursión).
--
-- Ahora que todas las mutaciones de users_admin pasan por la edge function
-- admin-users (service_role, bypassa RLS con su propio chequeo de es_admin()),
-- estas políticas de cliente solo necesitan cubrir lectura para admins.
--
-- Ejecutar en Supabase SQL Editor.

DROP POLICY IF EXISTS "Allow read access for authenticated users" ON public.users_admin;

DROP POLICY IF EXISTS "Admins can view all admin users" ON public.users_admin;
CREATE POLICY "Admins can view all admin users" ON public.users_admin
  FOR SELECT
  USING (public.es_admin(auth.uid()));

DROP POLICY IF EXISTS "Admins can delete admin users" ON public.users_admin;
CREATE POLICY "Admins can delete admin users" ON public.users_admin
  FOR DELETE
  USING (public.es_admin(auth.uid()));
