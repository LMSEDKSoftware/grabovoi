-- =================================================================
-- SCRIPT PARA AGREGAR UN USUARIO COMO ADMINISTRADOR POR EMAIL
-- =================================================================
-- Instrucciones:
-- 1. Reemplaza 'tu_email_de_admin@ejemplo.com' con el email del usuario que quieres hacer admin.
-- 2. Ejecuta este script en el SQL Editor de tu proyecto de Supabase.
-- =================================================================

DO $$
DECLARE
    target_user_id UUID;
BEGIN
    -- 1. Busca el UUID del usuario usando su email
    SELECT id INTO target_user_id FROM auth.users WHERE email = 'tu_email_de_admin@ejemplo.com';

    -- 2. Si el usuario existe, inserta su ID en la tabla de administradores
    IF target_user_id IS NOT NULL THEN
        INSERT INTO public.users_admin (user_id) VALUES (target_user_id)
        ON CONFLICT (user_id) DO NOTHING; -- Evita errores si el usuario ya es admin
    END IF;
END $$;