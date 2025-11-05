-- Script de prueba para verificar que las búsquedas funcionan correctamente
-- Ejecutar después de migrar las sugerencias aprobadas

-- ============================================
-- PRUEBA 1: Verificar que los datos están disponibles
-- ============================================

-- Ver cuántos títulos relacionados hay
SELECT 
    'Total títulos relacionados' as prueba,
    COUNT(*) as resultado
FROM codigos_titulos_relacionados;

-- Ver códigos con títulos relacionados
SELECT 
    'Códigos con títulos relacionados' as prueba,
    COUNT(DISTINCT codigo_existente) as resultado
FROM codigos_titulos_relacionados;

-- ============================================
-- PRUEBA 2: Buscar un código específico (Escenario B)
-- ============================================

-- Ejemplo: Buscar código "148_596_481" y ver todos sus títulos
-- Cambia el código por uno que tengas en tu base de datos
SELECT 
    cg.codigo,
    cg.nombre as titulo_principal,
    cg.descripcion as descripcion_principal,
    cg.categoria,
    ctr.titulo as titulo_relacionado,
    ctr.descripcion as descripcion_relacionada
FROM codigos_grabovoi cg
LEFT JOIN codigos_titulos_relacionados ctr ON cg.codigo = ctr.codigo_existente
WHERE cg.codigo = '148_596_481'  -- ⚠️ CAMBIAR por un código que exista
ORDER BY ctr.created_at ASC;

-- ============================================
-- PRUEBA 3: Buscar por tema (Escenario A)
-- ============================================

-- Ejemplo: Buscar códigos relacionados con "Éxito en exámenes"
-- Esta consulta simula lo que hace la aplicación
WITH codigos_por_titulo AS (
    -- Buscar en codigos_grabovoi
    SELECT DISTINCT codigo
    FROM codigos_grabovoi
    WHERE LOWER(nombre) LIKE '%éxito en exámenes%'
       OR LOWER(descripcion) LIKE '%éxito en exámenes%'
    
    UNION
    
    -- Buscar en títulos relacionados
    SELECT DISTINCT codigo_existente as codigo
    FROM codigos_titulos_relacionados
    WHERE LOWER(titulo) LIKE '%éxito en exámenes%'
       OR LOWER(descripcion) LIKE '%éxito en exámenes%'
)
SELECT 
    cg.codigo,
    cg.nombre as titulo_principal,
    cg.descripcion as descripcion_principal,
    cg.categoria
FROM codigos_grabovoi cg
WHERE cg.codigo IN (SELECT codigo FROM codigos_por_titulo)
ORDER BY cg.nombre;

-- ============================================
-- PRUEBA 4: Ver todos los títulos relacionados de un código
-- ============================================

-- Ver todos los títulos relacionados para códigos que tienen múltiples títulos
SELECT 
    ctr.codigo_existente,
    cg.nombre as titulo_principal,
    COUNT(ctr.id) as cantidad_titulos_relacionados,
    STRING_AGG(ctr.titulo, ', ' ORDER BY ctr.created_at) as titulos_relacionados
FROM codigos_titulos_relacionados ctr
LEFT JOIN codigos_grabovoi cg ON ctr.codigo_existente = cg.codigo
GROUP BY ctr.codigo_existente, cg.nombre
HAVING COUNT(ctr.id) > 0
ORDER BY COUNT(ctr.id) DESC
LIMIT 10;

-- ============================================
-- PRUEBA 5: Verificar integridad de datos
-- ============================================

-- Verificar que todos los códigos en títulos relacionados existen en codigos_grabovoi
SELECT 
    'Títulos relacionados con códigos inexistentes' as prueba,
    COUNT(*) as resultado
FROM codigos_titulos_relacionados ctr
WHERE NOT EXISTS (
    SELECT 1 
    FROM codigos_grabovoi cg 
    WHERE cg.codigo = ctr.codigo_existente
);

-- Esto debería devolver 0 (cero) si todo está bien

-- ============================================
-- PRUEBA 6: Ver sugerencias aprobadas que NO se migraron
-- ============================================

-- Verificar si hay sugerencias aprobadas que no se migraron
SELECT 
    sc.id,
    sc.codigo_existente,
    sc.tema_sugerido,
    sc.estado,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM codigos_titulos_relacionados ctr
            WHERE ctr.codigo_existente = sc.codigo_existente
              AND LOWER(TRIM(ctr.titulo)) = LOWER(TRIM(sc.tema_sugerido))
        ) THEN 'Migrado'
        ELSE 'NO migrado'
    END as estado_migracion
FROM sugerencias_codigos sc
WHERE sc.estado = 'aprobada'
ORDER BY sc.fecha_resolucion DESC;

