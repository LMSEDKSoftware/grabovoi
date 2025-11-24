-- Script para migrar sugerencias aprobadas existentes a codigos_titulos_relacionados
-- Este script toma todas las sugerencias con estado 'aprobada' y las inserta en la nueva tabla

-- Paso 1: Verificar cuántas sugerencias aprobadas hay
SELECT 
    COUNT(*) as total_sugerencias_aprobadas,
    COUNT(DISTINCT codigo_existente) as codigos_unicos
FROM sugerencias_codigos
WHERE estado = 'aprobada';

-- Paso 2: Insertar sugerencias aprobadas en codigos_titulos_relacionados
-- Solo insertar si no existe ya un título relacionado con el mismo código y título
-- Usar DISTINCT ON para evitar duplicados si hay múltiples sugerencias aprobadas con el mismo código y título
INSERT INTO codigos_titulos_relacionados (
    codigo_existente,
    titulo,
    descripcion,
    categoria,
    fuente,
    sugerencia_id,
    usuario_id,
    created_at
)
SELECT DISTINCT ON (sc.codigo_existente, sc.tema_sugerido)
    sc.codigo_existente,
    sc.tema_sugerido as titulo,
    sc.descripcion_sugerida as descripcion,
    COALESCE(cg.categoria, 'General') as categoria,
    COALESCE(sc.fuente, 'sugerencia_aprobada') as fuente,
    sc.id as sugerencia_id,
    sc.usuario_id,
    COALESCE(sc.fecha_resolucion, sc.fecha_sugerencia) as created_at  -- Usar fecha de resolución o fecha de sugerencia
FROM sugerencias_codigos sc
LEFT JOIN codigos_grabovoi cg ON sc.codigo_existente = cg.codigo
WHERE sc.estado = 'aprobada'
  AND sc.tema_sugerido IS NOT NULL
  AND sc.tema_sugerido != ''
  -- No insertar si el título sugerido es igual al título principal (comparación insensible a mayúsculas)
  AND (cg.nombre IS NULL OR LOWER(TRIM(cg.nombre)) != LOWER(TRIM(sc.tema_sugerido)))
  -- No insertar si ya existe una relación con esta sugerencia_id
  AND NOT EXISTS (
    SELECT 1 
    FROM codigos_titulos_relacionados ctr
    WHERE ctr.sugerencia_id = sc.id
  )
  -- Evitar duplicados: no insertar si ya existe un título relacionado con el mismo código y título
  AND NOT EXISTS (
    SELECT 1 
    FROM codigos_titulos_relacionados ctr
    WHERE ctr.codigo_existente = sc.codigo_existente
      AND LOWER(TRIM(ctr.titulo)) = LOWER(TRIM(sc.tema_sugerido))
  )
ORDER BY sc.codigo_existente, sc.tema_sugerido, sc.fecha_resolucion DESC NULLS LAST, sc.fecha_sugerencia DESC;

-- Paso 3: Verificar los registros insertados
SELECT 
    COUNT(*) as total_titulos_relacionados_insertados,
    COUNT(DISTINCT codigo_existente) as codigos_con_titulos_relacionados
FROM codigos_titulos_relacionados
WHERE fuente = 'sugerencia_aprobada';

-- Paso 4: Mostrar algunos ejemplos de títulos relacionados insertados
SELECT 
    ctr.codigo_existente,
    ctr.titulo,
    cg.nombre as titulo_principal,
    ctr.descripcion,
    ctr.created_at
FROM codigos_titulos_relacionados ctr
LEFT JOIN codigos_grabovoi cg ON ctr.codigo_existente = cg.codigo
WHERE ctr.fuente = 'sugerencia_aprobada'
ORDER BY ctr.created_at DESC
LIMIT 10;

-- Paso 5: Verificar que las foreign keys funcionan correctamente
SELECT 
    COUNT(*) as total_registros,
    COUNT(DISTINCT codigo_existente) as codigos_unicos,
    COUNT(DISTINCT sugerencia_id) as sugerencias_unicas
FROM codigos_titulos_relacionados
WHERE fuente = 'sugerencia_aprobada';

