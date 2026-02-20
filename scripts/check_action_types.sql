-- Verificar los TIPOS de acción que tiene este usuario
-- Esto nos dirá si estamos filtrando por el string incorrecto en Dart (ej. 'pilotsage' vs 'sesionPilotaje')
SELECT 
    action_type,
    count(*) as total
FROM public.user_actions 
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'ifernandez@lmsedk.com')
GROUP BY action_type;

-- Verificar ID del usuario para cruzar con los logs de la app
SELECT id FROM auth.users WHERE email = 'ifernandez@lmsedk.com';
