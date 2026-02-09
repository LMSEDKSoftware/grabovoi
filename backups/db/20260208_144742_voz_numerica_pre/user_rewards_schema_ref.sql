-- Referencia de schema user_rewards (para respaldo/restauración)
-- Ejecutar en Supabase SQL Editor para ver estructura actual
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'user_rewards'
ORDER BY ordinal_position;
