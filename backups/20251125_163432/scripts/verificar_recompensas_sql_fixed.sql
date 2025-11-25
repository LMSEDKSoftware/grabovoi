-- Script SQL para verificar recompensas directamente en Supabase
-- Ejecutar en el SQL Editor de Supabase
-- VERSIÓN CORREGIDA: Sin anclas_continuidad

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
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
    AND table_name = 'user_rewards'
ORDER BY ordinal_position;

-- 3. Verificar datos en user_rewards
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
-- Descomenta estas líneas si la tabla rewards_history existe:
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

-- 6. Resumen completo: todas las tablas relacionadas
SELECT 
    'user_rewards' as tabla,
    cristales_energia as valor_cristales,
    luz_cuantica as valor_luz,
    updated_at,
    ultima_actualizacion
FROM public.user_rewards
WHERE user_id = (SELECT id FROM auth.users WHERE email = '2005.ivan@gmail.com');

-- 7. Contar registros de recompensas otorgadas (solo si la tabla existe)
-- Descomenta estas líneas si la tabla rewards_history existe:
-- SELECT 
--     tipo,
--     COUNT(*) as cantidad_registros,
--     SUM(cantidad) as total_cristales_otorgados,
--     MAX(created_at) as ultima_recompensa
-- FROM public.rewards_history
-- WHERE user_id = (SELECT id FROM auth.users WHERE email = '2005.ivan@gmail.com')
--     AND tipo = 'cristales'
-- GROUP BY tipo;

-- 8. Verificar si hay registros recientes en rewards_history (solo si la tabla existe)
-- Descomenta estas líneas si la tabla rewards_history existe:
-- SELECT 
--     DATE(created_at) as fecha,
--     COUNT(*) as recompensas_ese_dia,
--     SUM(cantidad) as cristales_ese_dia
-- FROM public.rewards_history
-- WHERE user_id = (SELECT id FROM auth.users WHERE email = '2005.ivan@gmail.com')
--     AND tipo = 'cristales'
--     AND created_at >= NOW() - INTERVAL '7 days'
-- GROUP BY DATE(created_at)
-- ORDER BY fecha DESC;

