-- Migración: Agregar columna anclas_continuidad a user_rewards
-- Este script es seguro para ejecutar múltiples veces (idempotente)

-- 1. Agregar columna anclas_continuidad si no existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'user_rewards' 
        AND column_name = 'anclas_continuidad'
    ) THEN
        ALTER TABLE public.user_rewards
        ADD COLUMN anclas_continuidad INTEGER NOT NULL DEFAULT 0;
        
        RAISE NOTICE 'Columna anclas_continuidad agregada exitosamente';
    ELSE
        RAISE NOTICE 'Columna anclas_continuidad ya existe, omitiendo...';
    END IF;
END $$;

-- 2. Verificar y crear políticas RLS solo si no existen
-- Las políticas ya deberían existir, pero por si acaso las creamos solo si no existen

-- Política para SELECT (ver sus propias recompensas)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'user_rewards' 
        AND policyname = 'Users can view their own rewards'
    ) THEN
        CREATE POLICY "Users can view their own rewards" ON public.user_rewards
        FOR SELECT USING (auth.uid() = user_id);
        
        RAISE NOTICE 'Política "Users can view their own rewards" creada';
    ELSE
        RAISE NOTICE 'Política "Users can view their own rewards" ya existe, omitiendo...';
    END IF;
END $$;

-- Política para INSERT (insertar sus propias recompensas)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'user_rewards' 
        AND policyname = 'Users can insert their own rewards'
    ) THEN
        CREATE POLICY "Users can insert their own rewards" ON public.user_rewards
        FOR INSERT WITH CHECK (auth.uid() = user_id);
        
        RAISE NOTICE 'Política "Users can insert their own rewards" creada';
    ELSE
        RAISE NOTICE 'Política "Users can insert their own rewards" ya existe, omitiendo...';
    END IF;
END $$;

-- Política para UPDATE (actualizar sus propias recompensas)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'user_rewards' 
        AND policyname = 'Users can update their own rewards'
    ) THEN
        CREATE POLICY "Users can update their own rewards" ON public.user_rewards
        FOR UPDATE USING (auth.uid() = user_id);
        
        RAISE NOTICE 'Política "Users can update their own rewards" creada';
    ELSE
        RAISE NOTICE 'Política "Users can update their own rewards" ya existe, omitiendo...';
    END IF;
END $$;

-- 3. Asegurar que RLS está habilitado
ALTER TABLE public.user_rewards ENABLE ROW LEVEL SECURITY;

-- Verificar que la función update_user_rewards_updated_at existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public' 
        AND p.proname = 'update_user_rewards_updated_at'
    ) THEN
        CREATE OR REPLACE FUNCTION public.update_user_rewards_updated_at()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.updated_at = NOW();
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
        
        RAISE NOTICE 'Función update_user_rewards_updated_at creada';
    ELSE
        RAISE NOTICE 'Función update_user_rewards_updated_at ya existe, omitiendo...';
    END IF;
END $$;

-- Verificar que el trigger existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_trigger 
        WHERE tgname = 'trigger_update_user_rewards_updated_at'
        AND tgrelid = 'public.user_rewards'::regclass
    ) THEN
        CREATE TRIGGER trigger_update_user_rewards_updated_at
        BEFORE UPDATE ON public.user_rewards
        FOR EACH ROW
        EXECUTE FUNCTION public.update_user_rewards_updated_at();
        
        RAISE NOTICE 'Trigger trigger_update_user_rewards_updated_at creado';
    ELSE
        RAISE NOTICE 'Trigger trigger_update_user_rewards_updated_at ya existe, omitiendo...';
    END IF;
END $$;

-- Verificar índices
CREATE INDEX IF NOT EXISTS idx_user_rewards_user_id ON public.user_rewards(user_id);
CREATE INDEX IF NOT EXISTS idx_user_rewards_cristales ON public.user_rewards(cristales_energia);

-- Resumen
SELECT 
    'Migración completada' as estado,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'user_rewards' 
            AND column_name = 'anclas_continuidad'
        ) THEN 'Columna anclas_continuidad: ✓ Existe'
        ELSE 'Columna anclas_continuidad: ✗ No existe'
    END as anclas_continuidad;

