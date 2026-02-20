-- 1. Verificar el ID del usuario
SELECT id, email, last_sign_in_at 
FROM auth.users 
WHERE email = 'ifernandez@lmsedk.com';

-- 2. Consultar todas las acciones de pilotaje registradas para este usuario
-- Esto mostrará qué códigos están guardados "raw" en la base de datos
SELECT 
    recorded_at,
    action_type,
    action_data->>'codeId' as code_id_extracted,
    action_data->>'codeName' as code_name,
    action_data
FROM public.user_actions 
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'ifernandez@lmsedk.com')
AND action_type IN ('sesionPilotaje', 'codigoRepetido', 'pilotajeCompartido')
ORDER BY recorded_at DESC;

-- 3. Verificar si hay discrepancias de espacios en blanco (trimming)
SELECT 
    action_data->>'codeId' as raw_code,
    length(action_data->>'codeId') as len_raw,
    trim(action_data->>'codeId') as trimmed_code,
    length(trim(action_data->>'codeId')) as len_trimmed
FROM public.user_actions
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'ifernandez@lmsedk.com')
AND action_data->>'codeId' = '8431257';
