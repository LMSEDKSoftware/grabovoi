-- Tabla para códigos personalizados del usuario
-- Estos códigos NO se agregan a la base central, son exclusivos del usuario
-- Ejecutar en Supabase SQL Editor

CREATE TABLE IF NOT EXISTS user_custom_codes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  codigo TEXT NOT NULL,
  nombre TEXT NOT NULL,
  descripcion TEXT DEFAULT 'Código personalizado del usuario',
  categoria TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, codigo)
);

-- Crear índices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_user_custom_codes_user_id ON user_custom_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_user_custom_codes_categoria ON user_custom_codes(categoria);

-- Habilitar RLS
ALTER TABLE user_custom_codes ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
CREATE POLICY "Users can view own custom codes" ON user_custom_codes
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own custom codes" ON user_custom_codes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own custom codes" ON user_custom_codes
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own custom codes" ON user_custom_codes
  FOR DELETE USING (auth.uid() = user_id);

