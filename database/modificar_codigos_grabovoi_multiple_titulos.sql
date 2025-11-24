-- Script para permitir múltiples registros con el mismo código en codigos_grabovoi
-- Esto permite que un mismo código tenga múltiples títulos/descripciones

-- IMPORTANTE: Este script elimina las foreign keys que dependen del índice único
-- Las foreign keys NO se recrearán porque PostgreSQL requiere columnas UNIQUE para foreign keys
-- La integridad referencial se manejará a nivel de aplicación

-- Paso 1: Eliminar las foreign keys que dependen del índice único
ALTER TABLE usuario_favoritos 
DROP CONSTRAINT IF EXISTS usuario_favoritos_codigo_id_fkey CASCADE;

ALTER TABLE codigo_popularidad 
DROP CONSTRAINT IF EXISTS codigo_popularidad_codigo_id_fkey CASCADE;

-- Paso 2: Eliminar la restricción UNIQUE del campo codigo
ALTER TABLE codigos_grabovoi 
DROP CONSTRAINT IF EXISTS codigos_grabovoi_codigo_key;

-- Paso 3: Crear un índice en codigo para mejorar las búsquedas (sin UNIQUE)
-- Este índice mejora el rendimiento de las consultas que buscan por código
CREATE INDEX IF NOT EXISTS idx_codigos_grabovoi_codigo ON codigos_grabovoi(codigo);

-- Paso 4: NO recrear las foreign keys
-- IMPORTANTE: PostgreSQL NO permite foreign keys a columnas no únicas
-- Las foreign keys han sido eliminadas y la integridad referencial se manejará a nivel de aplicación
-- 
-- La aplicación verificará que el código existe antes de insertar en:
-- - usuario_favoritos (ya lo hace en user_favorites_service.dart)
-- - codigo_popularidad (se debe verificar antes de insertar)
--
-- Beneficios de esta aproximación:
-- - Permite múltiples títulos para el mismo código
-- - La aplicación ya tiene validaciones para verificar existencia de códigos
-- - Mantiene la flexibilidad del sistema
--
-- Si necesitas mantener alguna restricción, puedes usar triggers o checks en la aplicación

-- Paso 5: Agregar comentario explicativo
COMMENT ON COLUMN codigos_grabovoi.codigo IS 'Código numérico de Grabovoi. Puede tener múltiples registros con diferentes títulos/descripciones para el mismo código.';

-- Verificar que el cambio se aplicó correctamente
SELECT 
    conname AS constraint_name,
    contype AS constraint_type
FROM pg_constraint
WHERE conrelid = 'codigos_grabovoi'::regclass
AND conname LIKE '%codigo%';

