-- ============================================
-- LIMPIAR Y CREAR POLÍTICAS RLS CORRECTAS
-- ============================================
-- Este script ELIMINA todas las políticas existentes (duplicadas)
-- y crea solo las políticas correctas en español.
--
-- IMPORTANTE: Ejecutar este script en el SQL Editor de Supabase
-- ============================================

-- ============================================
-- TABLA: user_rewards
-- ============================================

-- Habilitar RLS en la tabla user_rewards
ALTER TABLE public.user_rewards ENABLE ROW LEVEL SECURITY;

-- Eliminar TODAS las políticas existentes (en inglés y español)
DROP POLICY IF EXISTS "Insertar recompensas propias" ON public.user_rewards;
DROP POLICY IF EXISTS "Actualizar recompensas propias" ON public.user_rewards;
DROP POLICY IF EXISTS "Leer recompensas propias" ON public.user_rewards;
DROP POLICY IF EXISTS "Usuarios pueden insertar sus propias recompensas" ON public.user_rewards;
DROP POLICY IF EXISTS "Usuarios pueden actualizar sus propias recompensas" ON public.user_rewards;
DROP POLICY IF EXISTS "Usuarios pueden leer sus propias recompensas" ON public.user_rewards;
DROP POLICY IF EXISTS "Users can insert their own rewards" ON public.user_rewards;
DROP POLICY IF EXISTS "Users can update their own rewards" ON public.user_rewards;
DROP POLICY IF EXISTS "Users can view their own rewards" ON public.user_rewards;

-- Crear políticas CORRECTAS (solo en español, sin duplicados)
CREATE POLICY "Usuarios pueden insertar sus propias recompensas"
ON public.user_rewards
FOR INSERT
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Usuarios pueden actualizar sus propias recompensas"
ON public.user_rewards
FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Usuarios pueden leer sus propias recompensas"
ON public.user_rewards
FOR SELECT
USING (user_id = auth.uid());

-- ============================================
-- TABLA: user_actions
-- ============================================

-- Habilitar RLS en la tabla user_actions
ALTER TABLE public.user_actions ENABLE ROW LEVEL SECURITY;

-- Eliminar TODAS las políticas existentes (en inglés y español)
DROP POLICY IF EXISTS "Usuarios pueden insertar sus propias acciones" ON public.user_actions;
DROP POLICY IF EXISTS "Usuarios pueden leer sus propias acciones" ON public.user_actions;
DROP POLICY IF EXISTS "Usuarios pueden actualizar sus propias acciones" ON public.user_actions;
DROP POLICY IF EXISTS "Users can insert own actions" ON public.user_actions;
DROP POLICY IF EXISTS "Users can view own actions" ON public.user_actions;
DROP POLICY IF EXISTS "Users can update own actions" ON public.user_actions;

-- Crear políticas CORRECTAS (solo en español, sin duplicados)
CREATE POLICY "Usuarios pueden insertar sus propias acciones"
ON public.user_actions
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Usuarios pueden leer sus propias acciones"
ON public.user_actions
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Usuarios pueden actualizar sus propias acciones"
ON public.user_actions
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ============================================
-- VERIFICACIÓN FINAL
-- ============================================
-- Después de ejecutar este script, ejecuta esta consulta para verificar:
-- 
-- SELECT tablename, policyname, cmd
-- FROM pg_policies
-- WHERE tablename IN ('user_rewards', 'user_actions')
-- ORDER BY tablename, cmd;
--
-- Deberías ver EXACTAMENTE 6 políticas (sin duplicados):
-- 
-- user_rewards:
-- 1. "Usuarios pueden insertar sus propias recompensas" (INSERT)
-- 2. "Usuarios pueden actualizar sus propias recompensas" (UPDATE)
-- 3. "Usuarios pueden leer sus propias recompensas" (SELECT)
--
-- user_actions:
-- 4. "Usuarios pueden insertar sus propias acciones" (INSERT)
-- 5. "Usuarios pueden leer sus propias acciones" (SELECT)
-- 6. "Usuarios pueden actualizar sus propias acciones" (UPDATE)
-- ============================================

