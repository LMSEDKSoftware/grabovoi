-- ============================================
-- POLÍTICAS RLS COMPLETAS PARA SUPABASE
-- ============================================
-- Este script configura las políticas de Row-Level Security (RLS)
-- para las tablas user_rewards y user_actions.
--
-- IMPORTANTE: Ejecutar este script en el SQL Editor de Supabase
-- ============================================

-- ============================================
-- TABLA: user_rewards
-- ============================================

-- Habilitar RLS en la tabla user_rewards
ALTER TABLE public.user_rewards ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si las hay
DROP POLICY IF EXISTS "Insertar recompensas propias" ON public.user_rewards;
DROP POLICY IF EXISTS "Actualizar recompensas propias" ON public.user_rewards;
DROP POLICY IF EXISTS "Leer recompensas propias" ON public.user_rewards;
DROP POLICY IF EXISTS "Usuarios pueden insertar sus propias recompensas" ON public.user_rewards;
DROP POLICY IF EXISTS "Usuarios pueden actualizar sus propias recompensas" ON public.user_rewards;
DROP POLICY IF EXISTS "Usuarios pueden leer sus propias recompensas" ON public.user_rewards;

-- Política para INSERT: Permitir que los usuarios inserten sus propias recompensas
CREATE POLICY "Usuarios pueden insertar sus propias recompensas"
ON public.user_rewards
FOR INSERT
WITH CHECK (user_id = auth.uid());

-- Política para UPDATE: Permitir que los usuarios actualicen sus propias recompensas
CREATE POLICY "Usuarios pueden actualizar sus propias recompensas"
ON public.user_rewards
FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Política para SELECT: Permitir que los usuarios lean sus propias recompensas
CREATE POLICY "Usuarios pueden leer sus propias recompensas"
ON public.user_rewards
FOR SELECT
USING (user_id = auth.uid());

-- ============================================
-- TABLA: user_actions
-- ============================================

-- Habilitar RLS en la tabla user_actions
ALTER TABLE public.user_actions ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si las hay
DROP POLICY IF EXISTS "Usuarios pueden insertar sus propias acciones" ON public.user_actions;
DROP POLICY IF EXISTS "Usuarios pueden leer sus propias acciones" ON public.user_actions;
DROP POLICY IF EXISTS "Usuarios pueden actualizar sus propias acciones" ON public.user_actions;

-- Política para INSERT: Permitir que los usuarios inserten sus propias acciones
CREATE POLICY "Usuarios pueden insertar sus propias acciones"
ON public.user_actions
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Política para SELECT: Permitir que los usuarios lean sus propias acciones
CREATE POLICY "Usuarios pueden leer sus propias acciones"
ON public.user_actions
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Política para UPDATE: Permitir que los usuarios actualicen sus propias acciones
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
-- SELECT * FROM pg_policies WHERE tablename IN ('user_rewards', 'user_actions');
--
-- Deberías ver 6 políticas en total:
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

