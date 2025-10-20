-- Script para verificar y corregir el trigger
-- Ejecutar estos comandos en el SQL Editor de Supabase

-- 1. Eliminar el trigger existente
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 2. Eliminar la función existente
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 3. Recrear la función con mejor manejo de errores
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insertar en la tabla users con manejo de errores
  INSERT INTO public.users (
    id, 
    email, 
    name, 
    created_at, 
    last_login_at, 
    is_email_verified
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NOW(),
    NOW(),
    NEW.email_confirmed_at IS NOT NULL
  )
  ON CONFLICT (id) DO NOTHING; -- Evitar duplicados
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log del error pero no fallar el registro
    RAISE LOG 'Error creating user in public.users: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Recrear el trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 5. Verificar que el trigger está activo
SELECT 
    trigger_name, 
    event_manipulation, 
    action_timing, 
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';
