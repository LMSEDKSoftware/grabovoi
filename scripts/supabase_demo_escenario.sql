-- =============================================================================
-- ESCENARIO DE DEMO: Simular que hay una nueva versión disponible
-- Ejecutar en Supabase DESPUÉS de que el APK esté compilado e instalado
--
-- El APK compilado será v2.3.52.
-- Este SQL simula que ya existe una v2.4.0 en la tienda, activa y lista.
-- =============================================================================

-- Simular versión futura '2.4.0' activa (como si ya pasaron 24h de revisión)
UPDATE app_config
SET "value"              = '2.4.0',
    implementada         = 'OK',
    fecha_visualizacion  = NOW() - INTERVAL '1 hour'  -- ya pasó el tiempo
WHERE "key" = 'version_actual';

UPDATE app_config
SET "value"              = '2.4.0',
    implementada         = 'OK',
    fecha_visualizacion  = NOW() - INTERVAL '1 hour'
WHERE "key" = 'version_minima';

-- Actualizar mensaje para el dialog
UPDATE app_config
SET "value" = 'Nueva versión 2.4.0 disponible. Actualiza para disfrutar las últimas mejoras de la app.'
WHERE "key" = 'mensaje_actualizacion';

-- Verificar resultado
SELECT "key", "value", implementada, fecha_visualizacion
FROM app_config
WHERE "key" IN ('version_actual', 'version_minima', 'mensaje_actualizacion')
ORDER BY "key";

-- =============================================================================
-- REVERTIR DESPUÉS DE LA DEMO (ejecutar cuando termines):
-- =============================================================================
-- UPDATE app_config SET "value" = '2.3.52', implementada = 'OK',
--   fecha_visualizacion = NOW() - INTERVAL '1 hour'
-- WHERE "key" IN ('version_actual', 'version_minima');
-- =============================================================================
