-- Queries SQL para generar estadísticas de la encuesta inicial
-- Ejecutar en Supabase SQL Editor

-- ============================================
-- ESTADÍSTICAS GENERALES
-- ============================================

-- 1. Total de usuarios que completaron la encuesta
SELECT COUNT(DISTINCT user_id) as total_usuarios_completaron
FROM user_assessments;

-- 2. Total de encuestas completadas (puede haber múltiples por usuario si se permite)
SELECT COUNT(*) as total_encuestas
FROM user_assessments;

-- ============================================
-- DISTRIBUCIONES POR CATEGORÍA
-- ============================================

-- 3. Distribución por nivel de conocimiento
SELECT 
  assessment_data->>'knowledge_level' as nivel_conocimiento,
  COUNT(*) as cantidad,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM user_assessments), 2) as porcentaje
FROM user_assessments
GROUP BY assessment_data->>'knowledge_level'
ORDER BY cantidad DESC;

-- 4. Distribución por nivel de experiencia
SELECT 
  assessment_data->>'experience_level' as nivel_experiencia,
  COUNT(*) as cantidad,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM user_assessments), 2) as porcentaje
FROM user_assessments
GROUP BY assessment_data->>'experience_level'
ORDER BY cantidad DESC;

-- 5. Distribución por motivación principal
SELECT 
  assessment_data->>'motivation' as motivacion,
  COUNT(*) as cantidad,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM user_assessments), 2) as porcentaje
FROM user_assessments
GROUP BY assessment_data->>'motivation'
ORDER BY cantidad DESC;

-- 6. Distribución por tiempo disponible
SELECT 
  assessment_data->>'time_available' as tiempo_disponible,
  COUNT(*) as cantidad,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM user_assessments), 2) as porcentaje
FROM user_assessments
GROUP BY assessment_data->>'time_available'
ORDER BY cantidad DESC;

-- ============================================
-- ANÁLISIS DE OBJETIVOS (ARRAY)
-- ============================================

-- 7. Objetivos más populares (desagregando el array)
SELECT 
  objetivo,
  COUNT(*) as cantidad,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM user_assessments), 2) as porcentaje
FROM user_assessments,
  jsonb_array_elements_text(assessment_data->'goals') as objetivo
GROUP BY objetivo
ORDER BY cantidad DESC;

-- 8. Top 5 objetivos más seleccionados
SELECT 
  objetivo,
  COUNT(*) as cantidad
FROM user_assessments,
  jsonb_array_elements_text(assessment_data->'goals') as objetivo
GROUP BY objetivo
ORDER BY cantidad DESC
LIMIT 5;

-- ============================================
-- ANÁLISIS DE PREFERENCIAS (ARRAY)
-- ============================================

-- 9. Preferencias más comunes (desagregando el array)
SELECT 
  preferencia,
  COUNT(*) as cantidad,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM user_assessments), 2) as porcentaje
FROM user_assessments,
  jsonb_array_elements_text(assessment_data->'preferences') as preferencia
GROUP BY preferencia
ORDER BY cantidad DESC;

-- ============================================
-- ANÁLISIS TEMPORAL
-- ============================================

-- 10. Encuestas completadas por día
SELECT 
  DATE(created_at) as fecha,
  COUNT(*) as cantidad_encuestas,
  COUNT(DISTINCT user_id) as usuarios_unicos
FROM user_assessments
GROUP BY DATE(created_at)
ORDER BY fecha DESC;

-- 11. Encuestas completadas por mes
SELECT 
  DATE_TRUNC('month', created_at) as mes,
  COUNT(*) as cantidad_encuestas,
  COUNT(DISTINCT user_id) as usuarios_unicos
FROM user_assessments
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY mes DESC;

-- 12. Encuestas completadas por semana
SELECT 
  DATE_TRUNC('week', created_at) as semana,
  COUNT(*) as cantidad_encuestas,
  COUNT(DISTINCT user_id) as usuarios_unicos
FROM user_assessments
GROUP BY DATE_TRUNC('week', created_at)
ORDER BY semana DESC;

-- ============================================
-- ANÁLISIS COMBINADO
-- ============================================

-- 13. Combinación: Nivel de conocimiento vs Motivación
SELECT 
  assessment_data->>'knowledge_level' as nivel_conocimiento,
  assessment_data->>'motivation' as motivacion,
  COUNT(*) as cantidad
FROM user_assessments
GROUP BY assessment_data->>'knowledge_level', assessment_data->>'motivation'
ORDER BY nivel_conocimiento, cantidad DESC;

-- 14. Combinación: Experiencia vs Tiempo disponible
SELECT 
  assessment_data->>'experience_level' as experiencia,
  assessment_data->>'time_available' as tiempo,
  COUNT(*) as cantidad
FROM user_assessments
GROUP BY assessment_data->>'experience_level', assessment_data->>'time_available'
ORDER BY experiencia, cantidad DESC;

-- ============================================
-- DATOS POR USUARIO
-- ============================================

-- 15. Ver todas las encuestas con datos del usuario
SELECT 
  ua.id,
  ua.user_id,
  u.email,
  u.name,
  ua.assessment_data,
  ua.created_at
FROM user_assessments ua
LEFT JOIN auth.users u ON u.id = ua.user_id
ORDER BY ua.created_at DESC;

-- 16. Usuarios con sus respuestas completas (formato legible)
SELECT 
  ua.user_id,
  u.email,
  ua.assessment_data->>'knowledge_level' as conocimiento,
  ua.assessment_data->>'experience_level' as experiencia,
  ua.assessment_data->>'motivation' as motivacion,
  ua.assessment_data->'goals' as objetivos,
  ua.assessment_data->'preferences' as preferencias,
  ua.created_at
FROM user_assessments ua
LEFT JOIN auth.users u ON u.id = ua.user_id
ORDER BY ua.created_at DESC;

-- ============================================
-- ESTADÍSTICAS AVANZADAS
-- ============================================

-- 17. Promedio de objetivos seleccionados por usuario
SELECT 
  AVG(jsonb_array_length(assessment_data->'goals')) as promedio_objetivos,
  MIN(jsonb_array_length(assessment_data->'goals')) as minimo_objetivos,
  MAX(jsonb_array_length(assessment_data->'goals')) as maximo_objetivos
FROM user_assessments;

-- 18. Promedio de preferencias seleccionadas por usuario
SELECT 
  AVG(jsonb_array_length(assessment_data->'preferences')) as promedio_preferencias,
  MIN(jsonb_array_length(assessment_data->'preferences')) as minimo_preferencias,
  MAX(jsonb_array_length(assessment_data->'preferences')) as maximo_preferencias
FROM user_assessments;

-- 19. Usuarios que seleccionaron múltiples objetivos
SELECT 
  user_id,
  jsonb_array_length(assessment_data->'goals') as cantidad_objetivos,
  assessment_data->'goals' as objetivos
FROM user_assessments
WHERE jsonb_array_length(assessment_data->'goals') > 1
ORDER BY cantidad_objetivos DESC;

-- ============================================
-- EXPORTACIÓN PARA ANÁLISIS
-- ============================================

-- 20. Exportar todos los datos en formato CSV-friendly
SELECT 
  ua.id,
  ua.user_id,
  u.email,
  u.name,
  ua.assessment_data->>'knowledge_level' as conocimiento,
  ua.assessment_data->>'experience_level' as experiencia,
  ua.assessment_data->>'time_available' as tiempo_disponible,
  ua.assessment_data->>'motivation' as motivacion,
  array_to_string(ARRAY(SELECT jsonb_array_elements_text(ua.assessment_data->'goals')), ', ') as objetivos,
  array_to_string(ARRAY(SELECT jsonb_array_elements_text(ua.assessment_data->'preferences')), ', ') as preferencias,
  ua.assessment_data->>'completed_at' as fecha_completado,
  ua.created_at
FROM user_assessments ua
LEFT JOIN auth.users u ON u.id = ua.user_id
ORDER BY ua.created_at DESC;



