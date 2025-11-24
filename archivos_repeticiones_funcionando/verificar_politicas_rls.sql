-- ============================================
-- VERIFICAR POLÍTICAS RLS Y AUTENTICACIÓN
-- ============================================
-- Este script verifica que las políticas RLS estén correctamente
-- configuradas y que el usuario autenticado pueda insertar datos.
-- ============================================

-- 1. Verificar que RLS esté habilitado en ambas tablas
SELECT 
    tablename,
    rowsecurity as "RLS Habilitado"
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('user_rewards', 'user_actions')
ORDER BY tablename;

-- 2. Ver todas las políticas RLS activas
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd as "Comando",
    qual as "Condición USING",
    with_check as "Condición WITH CHECK"
FROM pg_policies 
WHERE tablename IN ('user_rewards', 'user_actions')
ORDER BY tablename, cmd;

-- 3. Verificar el usuario actual autenticado
-- NOTA: Esto solo funciona si ejecutas desde el contexto de un usuario autenticado
SELECT 
    auth.uid() as "Usuario Autenticado (auth.uid())",
    auth.role() as "Rol";

-- 4. Verificar si hay registros de prueba (opcional)
-- Descomenta estas líneas si quieres ver los últimos registros
-- SELECT user_id, action_type, recorded_at 
-- FROM user_actions 
-- ORDER BY recorded_at DESC 
-- LIMIT 5;

-- ============================================
-- DIAGNÓSTICO ESPECÍFICO PARA EL ERROR 42501
-- ============================================
-- Si el error persiste, verifica:

-- A. Que las políticas tengan la condición correcta:
--    Las políticas deben tener: WITH CHECK (user_id = auth.uid())
--    Y para UPDATE/SELECT: USING (user_id = auth.uid())

-- B. Que el usuario esté autenticado:
--    auth.uid() debe retornar un UUID válido (no NULL)

-- C. Que el user_id en el payload coincida con auth.uid():
--    En tu caso: user_id = "cd005147-55f2-49c7-830c-b1464acb68c7"
--    Debe ser igual a auth.uid()

-- ============================================
-- SOLUCIÓN ALTERNATIVA: Política más permisiva (solo para testing)
-- ============================================
-- Si las políticas actuales no funcionan, prueba esta política temporal:
-- (NO usar en producción sin revisar la seguridad)

/*
DROP POLICY IF EXISTS "Usuarios pueden insertar sus propias acciones" ON public.user_actions;

CREATE POLICY "Usuarios pueden insertar sus propias acciones"
ON public.user_actions
FOR INSERT
TO authenticated
WITH CHECK (
  user_id = auth.uid() OR 
  (auth.uid() IS NOT NULL AND user_id IS NOT NULL)
);
*/

