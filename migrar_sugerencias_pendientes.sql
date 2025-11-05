-- Script para investigar y migrar las sugerencias que no se migraron
-- Este script identifica por qué no se migraron y las migra

-- Paso 1: Verificar por qué no se migraron estas sugerencias
SELECT 
    sc.id,
    sc.codigo_existente,
    sc.tema_sugerido,
    sc.descripcion_sugerida,
    sc.estado,
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM codigos_grabovoi cg WHERE cg.codigo = sc.codigo_existente) 
        THEN 'Código no existe en codigos_grabovoi'
        WHEN sc.tema_sugerido IS NULL OR sc.tema_sugerido = '' 
        THEN 'Título sugerido vacío'
        WHEN EXISTS (
            SELECT 1 
            FROM codigos_titulos_relacionados ctr
            WHERE ctr.codigo_existente = sc.codigo_existente
              AND LOWER(TRIM(ctr.titulo)) = LOWER(TRIM(sc.tema_sugerido))
        )
        THEN 'Ya existe en títulos relacionados'
        WHEN cg.nombre = sc.tema_sugerido
        THEN 'Título igual al título principal'
        ELSE 'OK para migrar'
    END as razon_no_migracion,
    cg.nombre as titulo_principal,
    cg.categoria as categoria_principal
FROM sugerencias_codigos sc
LEFT JOIN codigos_grabovoi cg ON sc.codigo_existente = cg.codigo
WHERE sc.estado = 'aprobada'
  AND NOT EXISTS (
    SELECT 1 
    FROM codigos_titulos_relacionados ctr
    WHERE ctr.sugerencia_id = sc.id
  )
ORDER BY sc.fecha_resolucion DESC;

-- Paso 2: Migrar las sugerencias que faltan (con validaciones mejoradas)
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
SELECT 
    sc.codigo_existente,
    sc.tema_sugerido as titulo,
    sc.descripcion_sugerida as descripcion,
    COALESCE(cg.categoria, 'General') as categoria,
    COALESCE(sc.fuente, 'sugerencia_aprobada') as fuente,
    sc.id as sugerencia_id,
    sc.usuario_id,
    COALESCE(sc.fecha_resolucion, sc.fecha_sugerencia) as created_at
FROM sugerencias_codigos sc
LEFT JOIN codigos_grabovoi cg ON sc.codigo_existente = cg.codigo
WHERE sc.estado = 'aprobada'
  AND sc.tema_sugerido IS NOT NULL
  AND sc.tema_sugerido != ''
  -- Verificar que el código existe en codigos_grabovoi
  AND EXISTS (SELECT 1 FROM codigos_grabovoi WHERE codigo = sc.codigo_existente)
  -- No insertar si el título sugerido es igual al título principal (insensible a mayúsculas)
  AND (cg.nombre IS NULL OR LOWER(TRIM(cg.nombre)) != LOWER(TRIM(sc.tema_sugerido)))
  -- No insertar si ya existe en títulos relacionados
  AND NOT EXISTS (
    SELECT 1 
    FROM codigos_titulos_relacionados ctr
    WHERE ctr.codigo_existente = sc.codigo_existente
      AND LOWER(TRIM(ctr.titulo)) = LOWER(TRIM(sc.tema_sugerido))
  )
  -- No insertar si ya existe una relación con esta sugerencia_id
  AND NOT EXISTS (
    SELECT 1 
    FROM codigos_titulos_relacionados ctr
    WHERE ctr.sugerencia_id = sc.id
  )
ORDER BY sc.fecha_resolucion DESC NULLS LAST, sc.fecha_sugerencia DESC;

-- Paso 3: Verificar que todas las sugerencias aprobadas fueron migradas
SELECT 
    'Sugerencias aprobadas totales' as tipo,
    COUNT(*) as cantidad
FROM sugerencias_codigos
WHERE estado = 'aprobada'

UNION ALL

SELECT 
    'Sugerencias migradas' as tipo,
    COUNT(DISTINCT sugerencia_id) as cantidad
FROM codigos_titulos_relacionados
WHERE sugerencia_id IS NOT NULL

UNION ALL

SELECT 
    'Sugerencias NO migradas' as tipo,
    COUNT(*) as cantidad
FROM sugerencias_codigos sc
WHERE sc.estado = 'aprobada'
  AND NOT EXISTS (
    SELECT 1 
    FROM codigos_titulos_relacionados ctr
    WHERE ctr.sugerencia_id = sc.id
  );

-- Paso 4: Mostrar detalles de las sugerencias que aún no se migraron (si las hay)
SELECT 
    sc.id,
    sc.codigo_existente,
    sc.tema_sugerido,
    sc.descripcion_sugerida,
    cg.nombre as titulo_principal,
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM codigos_grabovoi WHERE codigo = sc.codigo_existente) 
        THEN '❌ Código no existe'
        WHEN LOWER(TRIM(cg.nombre)) = LOWER(TRIM(sc.tema_sugerido))
        THEN '⚠️ Título igual al principal'
        ELSE '✅ Debería migrarse'
    END as estado
FROM sugerencias_codigos sc
LEFT JOIN codigos_grabovoi cg ON sc.codigo_existente = cg.codigo
WHERE sc.estado = 'aprobada'
  AND NOT EXISTS (
    SELECT 1 
    FROM codigos_titulos_relacionados ctr
    WHERE ctr.sugerencia_id = sc.id
  )
ORDER BY sc.id;

