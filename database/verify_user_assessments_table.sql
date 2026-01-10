-- Script para verificar si la tabla user_assessments existe
-- Ejecutar este script en el SQL Editor de Supabase

-- 1. Verificar si la tabla existe
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'user_assessments'
    ) 
    THEN '✅ La tabla user_assessments EXISTE'
    ELSE '❌ La tabla user_assessments NO EXISTE'
  END as tabla_status;

-- 2. Si existe, mostrar su estructura
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'user_assessments'
ORDER BY ordinal_position;

-- 3. Verificar si tiene RLS habilitado
SELECT 
  tablename,
  rowsecurity as rls_enabled,
  CASE 
    WHEN rowsecurity THEN '✅ RLS habilitado'
    ELSE '❌ RLS NO habilitado'
  END as rls_status
FROM pg_tables
WHERE schemaname = 'public' 
  AND tablename = 'user_assessments';

-- 4. Verificar políticas RLS
SELECT 
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'user_assessments';

-- 5. Verificar índices
SELECT 
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public' 
  AND tablename = 'user_assessments';

-- 6. Verificar triggers
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE event_object_schema = 'public' 
  AND event_object_table = 'user_assessments';

-- 7. Contar registros (si la tabla existe)
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'user_assessments'
    ) 
    THEN (SELECT COUNT(*) FROM user_assessments)
    ELSE 0
  END as total_registros;



