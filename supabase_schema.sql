-- Esquema de base de datos para Manifestación Numérica Grabovoi
-- Ejecutar este script en el SQL Editor de Supabase

-- Tabla de códigos Grabovoi
CREATE TABLE IF NOT EXISTS codigos_grabovoi (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  codigo TEXT UNIQUE NOT NULL,
  nombre TEXT NOT NULL,
  descripcion TEXT NOT NULL,
  categoria TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de favoritos de usuario
CREATE TABLE IF NOT EXISTS usuario_favoritos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL,
  codigo_id TEXT NOT NULL REFERENCES codigos_grabovoi(codigo),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, codigo_id)
);

-- Tabla de popularidad de códigos
CREATE TABLE IF NOT EXISTS codigo_popularidad (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  codigo_id TEXT NOT NULL REFERENCES codigos_grabovoi(codigo),
  contador INTEGER DEFAULT 0,
  ultimo_uso TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(codigo_id)
);

-- Tabla de archivos de audio
CREATE TABLE IF NOT EXISTS audio_files (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre TEXT NOT NULL,
  archivo TEXT NOT NULL,
  descripcion TEXT NOT NULL,
  categoria TEXT NOT NULL,
  duracion INTEGER NOT NULL,
  url TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de progreso de usuario
CREATE TABLE IF NOT EXISTS usuario_progreso (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT UNIQUE NOT NULL,
  dias_consecutivos INTEGER DEFAULT 0,
  total_pilotajes INTEGER DEFAULT 0,
  nivel_energetico INTEGER DEFAULT 1,
  ultimo_pilotaje TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para optimización
CREATE INDEX IF NOT EXISTS idx_codigos_categoria ON codigos_grabovoi(categoria);
CREATE INDEX IF NOT EXISTS idx_codigos_nombre ON codigos_grabovoi(nombre);
CREATE INDEX IF NOT EXISTS idx_favoritos_user ON usuario_favoritos(user_id);
CREATE INDEX IF NOT EXISTS idx_popularidad_contador ON codigo_popularidad(contador DESC);
CREATE INDEX IF NOT EXISTS idx_audio_categoria ON audio_files(categoria);

-- Habilitar RLS (Row Level Security) si es necesario
ALTER TABLE codigos_grabovoi ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuario_favoritos ENABLE ROW LEVEL SECURITY;
ALTER TABLE codigo_popularidad ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuario_progreso ENABLE ROW LEVEL SECURITY;

-- Políticas de seguridad (permite acceso público para lectura)
CREATE POLICY "Allow public read access" ON codigos_grabovoi FOR SELECT USING (true);
CREATE POLICY "Allow public read access" ON audio_files FOR SELECT USING (true);
CREATE POLICY "Allow public read access" ON codigo_popularidad FOR SELECT USING (true);

-- Políticas para favoritos y progreso (requieren autenticación)
CREATE POLICY "Allow authenticated users to manage favorites" ON usuario_favoritos 
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to manage progress" ON usuario_progreso 
  FOR ALL USING (auth.role() = 'authenticated');

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para actualizar updated_at
CREATE TRIGGER update_codigos_grabovoi_updated_at BEFORE UPDATE ON codigos_grabovoi 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_codigo_popularidad_updated_at BEFORE UPDATE ON codigo_popularidad 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_usuario_progreso_updated_at BEFORE UPDATE ON usuario_progreso 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
