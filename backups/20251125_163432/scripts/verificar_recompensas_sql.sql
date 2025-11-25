-- Script SQL para verificar recompensas directamente en Supabase
-- Ejecutar en el SQL Editor de Supabase

-- 1. Buscar usuario por email
SELECT 
    id,
    email,
    created_at,
    last_sign_in_at
FROM auth.users
WHERE email = '2005.ivan@gmail.com';

-- 2. Verificar datos en user_rewards (reemplazar USER_ID con el ID del paso 1)
-- Primero verificar qué columnas existen
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
    AND table_name = 'user_rewards'
ORDER BY ordinal_position;

-- 2b. Verificar datos en user_rewards (sin anclas_continuidad por si no existe)
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

-- 4. Verificar si existe la tabla rewards_history
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'rewards_history'
) as tabla_rewards_history_existe;

-- 4b. Verificar historial de recompensas (solo si la tabla existe)
-- Si la tabla no existe, esta query fallará pero no es crítica
-- SELECT 
--     id,
--     user_id,
--     tipo,
--     descripcion,
--     cantidad,
--     created_at
-- FROM public.rewards_history
-- WHERE user_id = (
--     SELECT id FROM auth.users WHERE email = '2005.ivan@gmail.com'
-- )
-- ORDER BY created_at DESC
-- LIMIT 20;

-- 5. Verificar usuario_progreso (para calcular luz cuántica)
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

-- 6. Verificar todas las tablas relacionadas en una sola query
SELECT 
    'user_rewards' as tabla,
    cristales_energia as valor_cristales,
    luz_cuantica as valor_luz,
    updated_at
FROM public.user_rewards
WHERE user_id = (SELECT id FROM auth.users WHERE email = '2005.ivan@gmail.com')
UNION ALL
SELECT 
    'usuario_progreso' as tabla,
    NULL as valor_cristales,
    NULL as valor_luz,
    updated_at
FROM public.usuario_progreso
WHERE user_id = (SELECT id FROM auth.users WHERE email = '2005.ivan@gmail.com');

-- 7. Contar registros de recompensas otorgadas (solo si la tabla existe)
-- Si la tabla rewards_history no existe, esta query no se ejecutará
-- SELECT 
--     tipo,
--     COUNT(*) as cantidad,
--     SUM(cantidad) as total_cristales_otorgados
-- FROM public.rewards_history
-- WHERE user_id = (SELECT id FROM auth.users WHERE email = '2005.ivan@gmail.com')
--     AND tipo = 'cristales'
-- GROUP BY tipo;

