-- Esquema para evaluaciones de usuario
-- Ejecutar este script en el SQL Editor de Supabase

-- Crear tabla de evaluaciones de usuario
CREATE TABLE IF NOT EXISTS user_assessments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  assessment_data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear índice para búsquedas por usuario
CREATE INDEX IF NOT EXISTS idx_user_assessments_user_id ON user_assessments(user_id);

-- Crear índice para búsquedas por fecha
CREATE INDEX IF NOT EXISTS idx_user_assessments_created_at ON user_assessments(created_at);

-- Habilitar RLS (Row Level Security)
ALTER TABLE user_assessments ENABLE ROW LEVEL SECURITY;

-- Política para que los usuarios solo puedan ver sus propias evaluaciones
CREATE POLICY "Users can view own assessments" ON user_assessments
  FOR SELECT USING (auth.uid() = user_id);

-- Política para que los usuarios solo puedan insertar sus propias evaluaciones
CREATE POLICY "Users can insert own assessments" ON user_assessments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Política para que los usuarios solo puedan actualizar sus propias evaluaciones
CREATE POLICY "Users can update own assessments" ON user_assessments
  FOR UPDATE USING (auth.uid() = user_id);

-- Política para que los usuarios solo puedan eliminar sus propias evaluaciones
CREATE POLICY "Users can delete own assessments" ON user_assessments
  FOR DELETE USING (auth.uid() = user_id);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_user_assessments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar updated_at
CREATE TRIGGER trigger_update_user_assessments_updated_at
  BEFORE UPDATE ON user_assessments
  FOR EACH ROW
  EXECUTE FUNCTION update_user_assessments_updated_at();

-- Comentarios para documentación
COMMENT ON TABLE user_assessments IS 'Evaluaciones iniciales de usuarios sobre su conocimiento y preferencias de Grabovoi';
COMMENT ON COLUMN user_assessments.user_id IS 'ID del usuario que completó la evaluación';
COMMENT ON COLUMN user_assessments.assessment_data IS 'Datos JSON de la evaluación (nivel de conocimiento, objetivos, etc.)';
COMMENT ON COLUMN user_assessments.created_at IS 'Fecha de creación de la evaluación';
COMMENT ON COLUMN user_assessments.updated_at IS 'Fecha de última actualización de la evaluación';

