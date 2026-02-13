-- ============================================================================
-- Verificar secuencias pilotadas/repetidas por usuario (habilitadas para compartir)
-- Ejecutar en Supabase SQL Editor (usa auth.users para el email)
-- ============================================================================

-- 1. Obtener user_id del usuario por email
-- NOTA: Si usas auth.users, el schema puede ser auth.users
SELECT id, email, last_sign_in_at 
FROM auth.users 
WHERE email = 'ifernandez@lmsedk.com';

-- 2. Secuencias con icono de compartir HABILITADO (solo codigoRepetido)
-- El botón compartir se habilita solo para códigos con action_type = 'codigoRepetido'
SELECT 
    TRIM(COALESCE(action_data->>'codeId', action_data->>'codeName', ''))::text AS codigo,
    MAX(action_data->>'codeName') AS nombre,
    COUNT(*) AS veces_registrado
FROM public.user_actions 
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'ifernandez@lmsedk.com')
  AND action_type = 'codigoRepetido'
  AND COALESCE(action_data->>'codeId', action_data->>'codeName', '') != ''
GROUP BY TRIM(COALESCE(action_data->>'codeId', action_data->>'codeName', ''))
ORDER BY codigo;

-- 3. Detalle de acciones codigoRepetido por secuencia
SELECT 
    recorded_at,
    TRIM(COALESCE(action_data->>'codeId', action_data->>'codeName', '')) AS codigo,
    action_data->>'codeName' AS code_name
FROM public.user_actions 
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'ifernandez@lmsedk.com')
  AND action_type = 'codigoRepetido'
ORDER BY codigo, recorded_at DESC;
