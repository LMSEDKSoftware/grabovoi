-- daily_code_assignments tenía políticas de INSERT/UPDATE con USING(true)/
-- WITH CHECK(true) sin cláusula TO, lo que las aplica también al rol 'anon':
-- cualquiera con la anon key pública (sin haber iniciado sesión) podía
-- insertar/sobrescribir el "código del día" que ve toda la app.
--
-- El escritor real es DailyCodeService (lib/services/daily_code_service.dart):
-- cualquier cliente puede ser "el primero" en calcular y guardar el código
-- determinístico del día (rotación por día del año) si aún no existe uno para
-- hoy. Esa lógica de "quien llega primero, escribe" sigue funcionando para
-- usuarios logueados; lo que se cierra es el acceso sin autenticación.
--
-- Ejecutar en Supabase SQL Editor.

DROP POLICY IF EXISTS "Allow public insert" ON daily_code_assignments;
CREATE POLICY "Authenticated users can insert" ON daily_code_assignments
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public update" ON daily_code_assignments;
CREATE POLICY "Authenticated users can update" ON daily_code_assignments
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- La lectura pública ("Allow public read access") se mantiene: es contenido
-- no sensible que todos los usuarios deben poder ver.
