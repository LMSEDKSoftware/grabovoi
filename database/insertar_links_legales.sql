-- Script para insertar/actualizar links legales en la tabla app_config
-- Ejecutar este script en el SQL Editor de Supabase
-- Este script usa ON CONFLICT DO UPDATE para poder ejecutarse múltiples veces

-- Asegurar que la tabla existe (si no existe, ejecutar primero app_config_schema.sql)
-- CREATE TABLE IF NOT EXISTS public.app_config (
--   id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
--   key TEXT NOT NULL UNIQUE,
--   value TEXT NOT NULL,
--   description TEXT,
--   created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
--   updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
-- );

-- Insertar o actualizar links legales
-- IMPORTANTE: Reemplaza las URLs de ejemplo con tus URLs reales

INSERT INTO public.app_config (key, value, description) VALUES
  (
    'legal_privacy_policy_url',
    'https://example.com/privacy-policy',  -- ⚠️ REEMPLAZAR con tu URL real
    'URL de la Política de Privacidad'
  ),
  (
    'legal_terms_url',
    'https://example.com/terms',  -- ⚠️ REEMPLAZAR con tu URL real
    'URL de los Términos y Condiciones'
  ),
  (
    'legal_cookies_url',
    'https://example.com/cookies',  -- ⚠️ REEMPLAZAR con tu URL real
    'URL de la Política de Cookies'
  ),
  (
    'legal_data_usage_url',
    'https://example.com/data-usage',  -- ⚠️ REEMPLAZAR con tu URL real (opcional)
    'URL de la Política de Uso de Datos'
  ),
  (
    'legal_credits_url',
    'https://example.com/credits',  -- ⚠️ REEMPLAZAR con tu URL real (opcional)
    'URL de Créditos y Reconocimientos'
  )
ON CONFLICT (key) 
DO UPDATE SET
  value = EXCLUDED.value,
  description = EXCLUDED.description,
  updated_at = NOW();

-- Verificar que se insertaron correctamente
SELECT 
  key,
  value,
  description,
  updated_at
FROM public.app_config
WHERE key LIKE 'legal_%'
ORDER BY key;

-- Mensaje de confirmación
DO $$
BEGIN
  RAISE NOTICE '✅ Links legales insertados/actualizados correctamente';
  RAISE NOTICE '📝 Recuerda reemplazar las URLs de ejemplo con tus URLs reales';
END $$;

