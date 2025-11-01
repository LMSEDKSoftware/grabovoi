-- Script para crear y configurar daily_code_assignments con políticas RLS
-- Ejecutar este script en el SQL Editor de Supabase

-- Crear tabla daily_code_assignments si no existe
CREATE TABLE IF NOT EXISTS daily_code_assignments (
  id SERIAL PRIMARY KEY,
  codigo_id INTEGER NOT NULL REFERENCES daily_codes(id) ON DELETE CASCADE,
  fecha_asignacion DATE NOT NULL,
  es_activo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
  -- Solo puede haber un código activo por fecha (esto se maneja con un índice parcial único)
);

-- Crear índice para búsquedas rápidas por fecha
CREATE INDEX IF NOT EXISTS idx_daily_code_assignments_fecha ON daily_code_assignments(fecha_asignacion);
CREATE INDEX IF NOT EXISTS idx_daily_code_assignments_activo ON daily_code_assignments(es_activo) WHERE es_activo = TRUE;

-- Restricción única: solo un código activo por fecha
CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_code_assignments_fecha_activo 
  ON daily_code_assignments(fecha_asignacion) 
  WHERE es_activo = TRUE;

-- Habilitar RLS
ALTER TABLE daily_code_assignments ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen (para hacer el script idempotente)
DROP POLICY IF EXISTS "Allow public read access" ON daily_code_assignments;
DROP POLICY IF EXISTS "Allow authenticated insert" ON daily_code_assignments;
DROP POLICY IF EXISTS "Allow authenticated update" ON daily_code_assignments;
DROP POLICY IF EXISTS "Allow public insert" ON daily_code_assignments;
DROP POLICY IF EXISTS "Allow public update" ON daily_code_assignments;

-- Política 1: Permitir lectura pública (todos pueden ver qué código está asignado para cada día)
CREATE POLICY "Allow public read access" ON daily_code_assignments
  FOR SELECT
  USING (true);

-- Política 2: Permitir inserción pública (necesario para asignación automática del código diario)
-- Esto permite que el sistema asigne códigos automáticamente sin requerir autenticación
CREATE POLICY "Allow public insert" ON daily_code_assignments
  FOR INSERT
  WITH CHECK (true);

-- Política 3: Permitir actualización pública (necesario para desactivar códigos anteriores)
CREATE POLICY "Allow public update" ON daily_code_assignments
  FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_daily_code_assignments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para actualizar updated_at
DROP TRIGGER IF EXISTS update_daily_code_assignments_updated_at ON daily_code_assignments;
CREATE TRIGGER update_daily_code_assignments_updated_at 
  BEFORE UPDATE ON daily_code_assignments
  FOR EACH ROW 
  EXECUTE FUNCTION update_daily_code_assignments_updated_at();

