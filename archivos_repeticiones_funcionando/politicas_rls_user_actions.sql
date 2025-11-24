-- ============================================
-- POLÍTICAS RLS PARA TABLA user_actions
-- ============================================
-- Este script configura las políticas de Row-Level Security (RLS)
-- para permitir que los usuarios puedan insertar sus propias acciones
-- en Supabase.
--
-- IMPORTANTE: Ejecutar este script en el SQL Editor de Supabase
-- ============================================

-- 1. Habilitar RLS en la tabla user_actions
ALTER TABLE public.user_actions ENABLE ROW LEVEL SECURITY;

-- 2. Eliminar políticas existentes si las hay (opcional, para empezar limpio)
DROP POLICY IF EXISTS "Usuarios pueden insertar sus propias acciones" ON public.user_actions;
DROP POLICY IF EXISTS "Usuarios pueden leer sus propias acciones" ON public.user_actions;
DROP POLICY IF EXISTS "Usuarios pueden actualizar sus propias acciones" ON public.user_actions;

-- 3. Política para INSERT: Permitir que los usuarios inserten sus propias acciones
CREATE POLICY "Usuarios pueden insertar sus propias acciones"
ON public.user_actions
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- 4. Política para SELECT: Permitir que los usuarios lean sus propias acciones (opcional)
CREATE POLICY "Usuarios pueden leer sus propias acciones"
ON public.user_actions
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- 5. Política para UPDATE: Permitir que los usuarios actualicen sus propias acciones (opcional)
CREATE POLICY "Usuarios pueden actualizar sus propias acciones"
ON public.user_actions
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Después de ejecutar este script, verifica que las políticas estén activas:
-- 
-- SELECT * FROM pg_policies WHERE tablename = 'user_actions';
--
-- Deberías ver 3 políticas:
-- 1. "Usuarios pueden insertar sus propias acciones" (INSERT)
-- 2. "Usuarios pueden leer sus propias acciones" (SELECT)
-- 3. "Usuarios pueden actualizar sus propias acciones" (UPDATE)
-- ============================================

