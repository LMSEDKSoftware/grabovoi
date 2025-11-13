-- Script SQL MÍNIMO para verificar recompensas
-- Solo consulta las tablas que SÍ existen
-- Ejecutar en el SQL Editor de Supabase

-- 1. Buscar usuario por email
SELECT 
    id,
    email,
    created_at,
    last_sign_in_at
FROM auth.users
WHERE email = '2005.ivan@gmail.com';

-- 2. Verificar estructura de la tabla user_rewards
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
    AND table_name = 'user_rewards'
ORDER BY ordinal_position;

-- 3. Verificar datos en user_rewards (ESTA ES LA MÁS IMPORTANTE)
SELECT 
    id,
    user_id,
    cristales_energia,
    luz_cuantica,
    restauradores_armonia,
    ultima_actualizacion,
    updated_at,
    created_at
FROM public.user_rewards
WHERE user_id = (
    SELECT id FROM auth.users WHERE email = '2005.ivan@gmail.com'
);

-- 4. Verificar usuario_progreso (para calcular luz cuántica)
SELECT 
    id,
    user_id,
    dias_consecutivos,
    total_pilotajes,
    ultimo_pilotaje,
    energy_level,
    updated_at
FROM public.usuario_progreso
WHERE user_id = (
    SELECT id FROM auth.users WHERE email = '2005.ivan@gmail.com'
);

-- 5. Resumen: Comparar datos entre tablas
SELECT 
    'user_rewards' as fuente,
    cristales_energia as cristales,
    luz_cuantica as luz_cuantica_pct,
    updated_at as ultima_actualizacion
FROM public.user_rewards
WHERE user_id = (SELECT id FROM auth.users WHERE email = '2005.ivan@gmail.com');


