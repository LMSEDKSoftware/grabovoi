-- Script para debuggear el problema de autenticación
-- Ejecutar estos comandos uno por uno en el SQL Editor de Supabase

-- 1. Verificar que el trigger existe y está activo
SELECT 
    trigger_name, 
    event_manipulation, 
    action_timing, 
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- 2. Verificar las políticas RLS en la tabla users
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual, 
    with_check
FROM pg_policies 
WHERE tablename = 'users';

-- 3. Verificar si RLS está habilitado en la tabla users
SELECT 
    schemaname, 
    tablename, 
    rowsecurity 
FROM pg_tables 
WHERE tablename = 'users';

-- 4. Probar insertar un usuario manualmente (reemplaza el UUID con uno real)
-- Primero obtén un UUID de auth.users:
SELECT id, email FROM auth.users LIMIT 1;

-- Luego intenta insertar manualmente (reemplaza 'USER_ID_AQUI' con el ID real):
/*
INSERT INTO public.users (id, email, name, created_at, is_email_verified)
VALUES (
    'USER_ID_AQUI',
    'test@example.com',
    'Usuario Test',
    NOW(),
    false
);
*/

-- 5. Verificar si hay usuarios en la tabla users
SELECT COUNT(*) as total_users FROM public.users;

-- 6. Verificar la función del trigger
SELECT 
    routine_name, 
    routine_definition 
FROM information_schema.routines 
WHERE routine_name = 'handle_new_user';
