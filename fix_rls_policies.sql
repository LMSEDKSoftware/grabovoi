-- Script para corregir las políticas RLS
-- Ejecutar estos comandos en el SQL Editor de Supabase

-- 1. Eliminar políticas existentes si hay conflictos
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;

-- 2. Crear políticas RLS correctas
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 3. Verificar que RLS esté habilitado
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 4. Crear una política temporal para permitir inserción desde el trigger
-- Esta política permite que el trigger (que se ejecuta como SECURITY DEFINER) inserte usuarios
CREATE POLICY "Allow trigger to insert users" ON users
    FOR INSERT WITH CHECK (true);

-- 5. Verificar el estado final
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
WHERE tablename = 'users'
ORDER BY policyname;
