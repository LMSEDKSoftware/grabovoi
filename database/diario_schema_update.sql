-- Script para actualizar el esquema del diario
-- Permite múltiples entradas por día (una por cada repetición/código)

-- Paso 1: Eliminar la restricción UNIQUE que impide múltiples entradas por día
ALTER TABLE diario_entradas DROP CONSTRAINT IF EXISTS diario_entradas_user_id_fecha_key;

-- Paso 2: Verificar que la restricción se eliminó correctamente
-- (Esto se puede ejecutar manualmente en Supabase para verificar)

-- NOTA: Si el nombre de la restricción es diferente, puedes encontrarlo con:
-- SELECT constraint_name 
-- FROM information_schema.table_constraints 
-- WHERE table_name = 'diario_entradas' 
-- AND constraint_type = 'UNIQUE';

-- Si necesitas eliminar por nombre específico:
-- ALTER TABLE diario_entradas DROP CONSTRAINT IF EXISTS <nombre_constraint>;


