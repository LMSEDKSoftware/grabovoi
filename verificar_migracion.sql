-- Script para verificar si la migración se ejecutó correctamente
-- Verificar si existe el título relacionado "Comprensión y perdón" para el código 814_418_719

-- 1. Verificar si existe el código principal
SELECT 
    'Código principal' as tipo,
    codigo,
    nombre,
    descripcion
FROM codigos_grabovoi
WHERE codigo = '814_418_719';

-- 2. Verificar si existe el título relacionado
SELECT 
    'Título relacionado' as tipo,
    id,
    codigo_existente,
    titulo,
    descripcion,
    fuente,
    sugerencia_id,
    created_at
FROM codigos_titulos_relacionados
WHERE codigo_existente = '814_418_719';

-- 3. Buscar cualquier título relacionado con "Comprensión"
SELECT 
    'Búsqueda por título' as tipo,
    codigo_existente,
    titulo,
    descripcion
FROM codigos_titulos_relacionados
WHERE LOWER(titulo) LIKE '%comprensión%' 
   OR LOWER(descripcion) LIKE '%comprensión%';

-- 4. Verificar todas las sugerencias aprobadas que deberían migrarse
SELECT 
    'Sugerencia aprobada' as tipo,
    id,
    codigo_existente,
    tema_sugerido,
    descripcion_sugerida,
    estado
FROM sugerencias_codigos
WHERE estado = 'aprobada'
  AND codigo_existente = '814_418_719';

-- 5. Verificar si hay títulos relacionados migrados
SELECT 
    COUNT(*) as total_titulos_relacionados,
    COUNT(DISTINCT codigo_existente) as codigos_unicos
FROM codigos_titulos_relacionados
WHERE fuente = 'sugerencia_aprobada';

