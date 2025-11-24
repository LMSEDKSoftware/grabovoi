-- Script SQL para activar acceso Premium temporal para pruebas
-- Ejecutar este script en Supabase SQL Editor
-- 
-- INSTRUCCIONES:
-- 1. Reemplaza 'TU_EMAIL_AQUI' con tu email de usuario
-- 2. Ejecuta el script completo
-- 3. La suscripción durará 1 año desde hoy

-- Opción 1: Activar por email (más fácil)
-- Reemplaza 'TU_EMAIL_AQUI' con tu email
DO $$
DECLARE
    v_user_id UUID;
    v_expires_at TIMESTAMPTZ;
BEGIN
    -- Buscar el user_id por email
    SELECT id INTO v_user_id
    FROM auth.users
    WHERE email = 'TU_EMAIL_AQUI';
    
    -- Si no se encuentra el usuario, mostrar error
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuario no encontrado. Verifica que el email sea correcto.';
    END IF;
    
    -- Calcular fecha de expiración (1 año desde hoy)
    v_expires_at := NOW() + INTERVAL '1 year';
    
    -- Eliminar suscripciones anteriores activas (si existen)
    UPDATE user_subscriptions
    SET is_active = false
    WHERE user_id = v_user_id AND is_active = true;
    
    -- Insertar nueva suscripción activa
    INSERT INTO user_subscriptions (
        user_id,
        product_id,
        purchase_id,
        transaction_date,
        expires_at,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        v_user_id,
        'subscription_yearly', -- Puedes cambiar a 'subscription_monthly' si prefieres
        'test_premium_access_' || gen_random_uuid()::text,
        NOW(),
        v_expires_at,
        true,
        NOW(),
        NOW()
    );
    
    RAISE NOTICE '✅ Suscripción Premium activada para el usuario: %', v_user_id;
    RAISE NOTICE '📅 Expira el: %', v_expires_at;
END $$;

-- Opción 2: Activar por user_id directamente (si ya conoces tu UUID)
-- Descomenta y reemplaza 'TU_USER_ID_AQUI' con tu UUID de usuario
/*
DO $$
DECLARE
    v_user_id UUID := 'TU_USER_ID_AQUI'::UUID;
    v_expires_at TIMESTAMPTZ;
BEGIN
    -- Calcular fecha de expiración (1 año desde hoy)
    v_expires_at := NOW() + INTERVAL '1 year';
    
    -- Eliminar suscripciones anteriores activas
    UPDATE user_subscriptions
    SET is_active = false
    WHERE user_id = v_user_id AND is_active = true;
    
    -- Insertar nueva suscripción activa
    INSERT INTO user_subscriptions (
        user_id,
        product_id,
        purchase_id,
        transaction_date,
        expires_at,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        v_user_id,
        'subscription_yearly',
        'test_premium_access_' || gen_random_uuid()::text,
        NOW(),
        v_expires_at,
        true,
        NOW(),
        NOW()
    );
    
    RAISE NOTICE '✅ Suscripción Premium activada';
END $$;
*/

-- Verificar que la suscripción se creó correctamente
-- (Ejecuta esta consulta después para verificar)
SELECT 
    us.id,
    us.user_id,
    u.email,
    us.product_id,
    us.expires_at,
    us.is_active,
    CASE 
        WHEN us.expires_at > NOW() THEN '✅ Activa'
        ELSE '❌ Expirada'
    END as estado
FROM user_subscriptions us
JOIN auth.users u ON u.id = us.user_id
WHERE us.is_active = true
ORDER BY us.created_at DESC
LIMIT 10;


