-- ============================================
-- POLÍTICAS RLS PARA TABLA user_rewards
-- ============================================
-- Este script configura las políticas de Row-Level Security (RLS)
-- para permitir que los usuarios puedan insertar, actualizar y leer
-- sus propias recompensas en Supabase.
--
-- IMPORTANTE: Ejecutar este script en el SQL Editor de Supabase
-- ============================================

-- 1. Habilitar RLS en la tabla user_rewards
ALTER TABLE public.user_rewards ENABLE ROW LEVEL SECURITY;

-- 2. Eliminar políticas existentes si las hay (opcional, para empezar limpio)
DROP POLICY IF EXISTS "Insertar recompensas propias" ON public.user_rewards;
DROP POLICY IF EXISTS "Actualizar recompensas propias" ON public.user_rewards;
DROP POLICY IF EXISTS "Leer recompensas propias" ON public.user_rewards;
DROP POLICY IF EXISTS "Usuarios pueden insertar sus propias recompensas" ON public.user_rewards;
DROP POLICY IF EXISTS "Usuarios pueden actualizar sus propias recompensas" ON public.user_rewards;
DROP POLICY IF EXISTS "Usuarios pueden leer sus propias recompensas" ON public.user_rewards;

-- 3. Política para INSERT: Permitir que los usuarios inserten sus propias recompensas
CREATE POLICY "Usuarios pueden insertar sus propias recompensas"
ON public.user_rewards
FOR INSERT
WITH CHECK (user_id = auth.uid());

-- 4. Política para UPDATE: Permitir que los usuarios actualicen sus propias recompensas
CREATE POLICY "Usuarios pueden actualizar sus propias recompensas"
ON public.user_rewards
FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 5. Política para SELECT: Permitir que los usuarios lean sus propias recompensas
CREATE POLICY "Usuarios pueden leer sus propias recompensas"
ON public.user_rewards
FOR SELECT
USING (user_id = auth.uid());

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Después de ejecutar este script, verifica que las políticas estén activas:
-- 
-- SELECT * FROM pg_policies WHERE tablename = 'user_rewards';
--
-- Deberías ver 3 políticas:
-- 1. "Usuarios pueden insertar sus propias recompensas" (INSERT)
-- 2. "Usuarios pueden actualizar sus propias recompensas" (UPDATE)
-- 3. "Usuarios pueden leer sus propias recompensas" (SELECT)
-- ============================================

