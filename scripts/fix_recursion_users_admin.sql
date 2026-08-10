-- Script para corregir la recursión infinita en users_admin
-- Ejecuta este script en el Editor SQL de Supabase
--
-- ⚠️ OBSOLETO: la política "Allow read access for authenticated users" de
-- este script (paso 5) dejaba leer la tabla completa de admins a CUALQUIER
-- usuario logueado. Fue reemplazada por database/migration_fix_users_admin_policies.sql,
-- que usa la función es_admin() (ya evita la recursión sin exponer la lista
-- de admins a todo el mundo). NO vuelvas a ejecutar este script tal cual;
-- si necesitas repetir el fix de recursión, usa el nuevo archivo.

-- 1. Función segura para verificar si un usuario es admin (bypasses RLS)
-- Esta función 'SECURITY DEFINER' se ejecuta con privilegios de creador, evitando el bucle de políticas
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.users_admin
    WHERE user_id = auth.uid()
  );
$$;

-- 2. Asegurar que la tabla users_admin existe
CREATE TABLE IF NOT EXISTS public.users_admin (
    user_id uuid REFERENCES auth.users NOT NULL PRIMARY KEY,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Limpiar políticas antiguas que causan recursión
DROP POLICY IF EXISTS "Admins can view admins" ON public.users_admin;
DROP POLICY IF EXISTS "Users can view own admin status" ON public.users_admin;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.users_admin;
DROP POLICY IF EXISTS "Read access for all users" ON public.users_admin;
DROP POLICY IF EXISTS "Select users_admin" ON public.users_admin;

-- 4. Habilitar RLS
ALTER TABLE public.users_admin ENABLE ROW LEVEL SECURITY;

-- 5. Crear política segura y simple
-- Permite que cualquiera (autenticado) lea la tabla users_admin
-- Esto rompe la recursión porque no depende de una condición compleja
CREATE POLICY "Allow read access for authenticated users"
ON public.users_admin
FOR SELECT
TO authenticated
USING (true);

-- 6. Asegurar permisos de acceso a nivel de base de datos
GRANT SELECT ON public.users_admin TO authenticated;
GRANT SELECT ON public.users_admin TO service_role;

-- 7. Asegurar app_config también (por si acaso)
GRANT SELECT ON public.app_config TO anon;
GRANT SELECT ON public.app_config TO authenticated;
GRANT SELECT ON public.app_config TO service_role;
