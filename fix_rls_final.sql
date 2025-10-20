-- Script FINAL para corregir RLS y permitir inserción de usuarios
-- Ejecutar estos comandos en el SQL Editor de Supabase

-- 1. DESHABILITAR temporalmente RLS para debug
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- 2. Eliminar todas las políticas existentes
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Allow trigger to insert users" ON users;

-- 3. Verificar que no hay políticas
SELECT policyname FROM pg_policies WHERE tablename = 'users';

-- 4. Probar inserción manual (reemplaza con un UUID real de auth.users)
-- Primero obtén un UUID: SELECT id FROM auth.users LIMIT 1;
-- Luego ejecuta:
/*
INSERT INTO public.users (id, email, name, created_at, is_email_verified)
VALUES (
    'UUID_AQUI',
    'test@example.com',
    'Usuario Test',
    NOW(),
    false
);
*/

-- 5. Si la inserción manual funciona, habilitar RLS con políticas correctas
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 6. Crear políticas que permitan inserción desde el trigger
CREATE POLICY "Enable insert for authenticated users" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Enable read access for users based on user_id" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Enable update for users based on user_id" ON users
    FOR UPDATE USING (auth.uid() = id);

-- 7. Verificar políticas finales
SELECT 
    policyname, 
    cmd, 
    qual, 
    with_check
FROM pg_policies 
WHERE tablename = 'users';
