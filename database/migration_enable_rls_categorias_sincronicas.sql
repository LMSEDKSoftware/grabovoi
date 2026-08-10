-- categorias_sincronicas nunca tenía RLS habilitada: con solo la anon key,
-- cualquiera podía leer/escribir/borrar sin restricción vía PostgREST. Es
-- contenido de solo lectura (matriz de recomendaciones), así que se habilita
-- RLS con únicamente una política de lectura pública.
--
-- Ejecutar en Supabase SQL Editor.

ALTER TABLE categorias_sincronicas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read access" ON categorias_sincronicas;
CREATE POLICY "Allow public read access" ON categorias_sincronicas
  FOR SELECT
  USING (true);
