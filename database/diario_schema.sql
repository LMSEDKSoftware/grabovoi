-- Esquema para Diario de Secuencias ManiGrab
-- Ejecutar este script en el SQL Editor de Supabase

-- Tabla de entradas del diario
CREATE TABLE IF NOT EXISTS diario_entradas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  codigo TEXT REFERENCES codigos_grabovoi(codigo) ON DELETE SET NULL,
  intencion TEXT NOT NULL,
  estado_animo TEXT,
  sensaciones TEXT,
  horas_sueno INTEGER,
  hizo_ejercicio BOOLEAN DEFAULT FALSE,
  gratitud TEXT,
  fecha DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
  -- PERMITIR múltiples entradas por día (una por cada repetición/código)
  -- Se eliminó la restricción UNIQUE(user_id, fecha) para permitir varias entradas diarias
);

-- Índices para optimización
CREATE INDEX IF NOT EXISTS idx_diario_entradas_user_id ON diario_entradas(user_id);
CREATE INDEX IF NOT EXISTS idx_diario_entradas_fecha ON diario_entradas(fecha);
CREATE INDEX IF NOT EXISTS idx_diario_entradas_codigo ON diario_entradas(codigo);
CREATE INDEX IF NOT EXISTS idx_diario_entradas_user_fecha ON diario_entradas(user_id, fecha DESC);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_diario_entradas_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para actualizar updated_at
CREATE TRIGGER update_diario_entradas_updated_at 
  BEFORE UPDATE ON diario_entradas
  FOR EACH ROW 
  EXECUTE FUNCTION update_diario_entradas_updated_at();

-- Políticas de seguridad RLS (Row Level Security)
ALTER TABLE diario_entradas ENABLE ROW LEVEL SECURITY;

-- Política para usuarios: solo pueden ver y modificar sus propias entradas
CREATE POLICY "Users can view their own diary entries"
  ON diario_entradas FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own diary entries"
  ON diario_entradas FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own diary entries"
  ON diario_entradas FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own diary entries"
  ON diario_entradas FOR DELETE
  USING (auth.uid() = user_id);

