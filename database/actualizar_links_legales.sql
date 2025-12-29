-- Script para actualizar solo los links legales (asume que la tabla ya existe)
-- Ejecutar este script en el SQL Editor de Supabase
-- Útil cuando solo necesitas cambiar las URLs sin recrear la tabla

-- ⚠️ IMPORTANTE: Reemplaza las URLs de ejemplo con tus URLs reales antes de ejecutar

-- Actualizar Política de Privacidad
UPDATE public.app_config 
SET 
  value = 'https://example.com/privacy-policy',  -- ⚠️ REEMPLAZAR con tu URL real
  updated_at = NOW()
WHERE key = 'legal_privacy_policy_url';

-- Si no existe, insertarlo
INSERT INTO public.app_config (key, value, description)
SELECT 
  'legal_privacy_policy_url',
  'https://example.com/privacy-policy',  -- ⚠️ REEMPLAZAR con tu URL real
  'URL de la Política de Privacidad'
WHERE NOT EXISTS (
  SELECT 1 FROM public.app_config WHERE key = 'legal_privacy_policy_url'
);

-- Actualizar Términos y Condiciones
UPDATE public.app_config 
SET 
  value = 'https://example.com/terms',  -- ⚠️ REEMPLAZAR con tu URL real
  updated_at = NOW()
WHERE key = 'legal_terms_url';

INSERT INTO public.app_config (key, value, description)
SELECT 
  'legal_terms_url',
  'https://example.com/terms',  -- ⚠️ REEMPLAZAR con tu URL real
  'URL de los Términos y Condiciones'
WHERE NOT EXISTS (
  SELECT 1 FROM public.app_config WHERE key = 'legal_terms_url'
);

-- Actualizar Política de Cookies
UPDATE public.app_config 
SET 
  value = 'https://example.com/cookies',  -- ⚠️ REEMPLAZAR con tu URL real
  updated_at = NOW()
WHERE key = 'legal_cookies_url';

INSERT INTO public.app_config (key, value, description)
SELECT 
  'legal_cookies_url',
  'https://example.com/cookies',  -- ⚠️ REEMPLAZAR con tu URL real
  'URL de la Política de Cookies'
WHERE NOT EXISTS (
  SELECT 1 FROM public.app_config WHERE key = 'legal_cookies_url'
);

-- Verificar resultados
SELECT 
  key,
  value,
  description,
  updated_at
FROM public.app_config
WHERE key LIKE 'legal_%'
ORDER BY key;

