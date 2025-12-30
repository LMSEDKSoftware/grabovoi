-- Script para permitir múltiples códigos por día por usuario
-- Ejecutar este script en el SQL Editor de Supabase

-- Paso 1: Verificar y eliminar cualquier restricción UNIQUE que limite a una entrada por día
-- Primero, encontrar todas las restricciones UNIQUE en la tabla
DO $$
DECLARE
    constraint_name text;
BEGIN
    -- Buscar y eliminar restricciones UNIQUE que incluyan user_id y fecha
    FOR constraint_name IN
        SELECT conname
        FROM pg_constraint
        WHERE conrelid = 'diario_entradas'::regclass
        AND contype = 'u'
        AND (
            conname LIKE '%user_id%fecha%' 
            OR conname LIKE '%fecha%user_id%'
            OR conname = 'diario_entradas_user_id_fecha_key'
        )
    LOOP
        EXECUTE format('ALTER TABLE diario_entradas DROP CONSTRAINT IF EXISTS %I', constraint_name);
        RAISE NOTICE 'Eliminada restricción: %', constraint_name;
    END LOOP;
END $$;

-- Paso 2: Verificar que no existan restricciones que impidan múltiples entradas
-- (Este query se puede ejecutar manualmente para verificar)
-- SELECT constraint_name, constraint_type
-- FROM information_schema.table_constraints
-- WHERE table_name = 'diario_entradas'
-- AND constraint_type = 'UNIQUE';

-- Paso 3: Asegurar que los índices estén correctos para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_diario_entradas_user_fecha_codigo 
ON diario_entradas(user_id, fecha DESC, codigo);

-- Verificación final: La tabla ahora permite múltiples entradas por día
-- Cada usuario puede tener múltiples entradas en la misma fecha, una por cada código ejecutado

