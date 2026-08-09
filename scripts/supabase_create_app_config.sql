-- =============================================================================
-- Script: Agregar columnas fecha_visualizacion e implementada a app_config
-- + Trigger de auto-activación via pg_cron
-- Ejecutar en: Supabase SQL Editor
-- =============================================================================

-- ─── 1. Agregar columnas nuevas ───────────────────────────────────────────────
ALTER TABLE app_config
  ADD COLUMN IF NOT EXISTS fecha_visualizacion TIMESTAMPTZ DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS implementada         TEXT        DEFAULT NULL;

-- ─── 2. Inicializar columnas en las filas de version ya existentes ────────────
-- Las filas de versión empiezan en 'OK' (son la versión actual en producción)
UPDATE app_config
SET implementada = 'OK',
    fecha_visualizacion = updated_at
WHERE "key" IN ('version_actual', 'version_minima');

-- Las filas legales no necesitan estos campos
UPDATE app_config
SET implementada = NULL,
    fecha_visualizacion = NULL
WHERE "key" NOT IN ('version_actual', 'version_minima', 'forzar_actualizacion',
                    'mensaje_actualizacion', 'url_playstore', 'url_appstore');

-- ─── 3. Activar la extensión pg_cron (si no está activada) ───────────────────
-- NOTA: En Supabase, pg_cron ya viene habilitado en proyectos Pro.
-- Si tienes plan Free, necesitas habilitarla desde:
-- Dashboard → Settings → Database → Extensions → pg_cron → Enable

-- ─── 4. Crear el job de pg_cron que auto-activa 'implementada' ───────────────
-- Se ejecuta cada 30 minutos y activa versiones cuya fecha_visualizacion ya pasó
SELECT cron.schedule(
  'auto-activar-version-grabovoi',   -- nombre único del job
  '*/30 * * * *',                    -- cada 30 minutos
  $$
    UPDATE app_config
    SET implementada = 'OK'
    WHERE "key" IN ('version_actual', 'version_minima')
      AND fecha_visualizacion IS NOT NULL
      AND fecha_visualizacion <= NOW()
      AND (implementada IS DISTINCT FROM 'OK');
  $$
);

-- ─── 5. Verificar que el job quedó registrado ─────────────────────────────────
SELECT jobid, jobname, schedule, command, active
FROM cron.job
WHERE jobname = 'auto-activar-version-grabovoi';

-- ─── 6. Verificar estado actual de la tabla ──────────────────────────────────
SELECT "key", "value", fecha_visualizacion, implementada, updated_at
FROM app_config
WHERE "key" IN ('version_actual', 'version_minima',
                'forzar_actualizacion', 'mensaje_actualizacion')
ORDER BY "key";
