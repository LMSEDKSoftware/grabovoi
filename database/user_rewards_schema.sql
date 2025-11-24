-- Tabla para almacenar las recompensas del usuario
CREATE TABLE IF NOT EXISTS user_rewards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  cristales_energia INTEGER NOT NULL DEFAULT 0,
  restauradores_armonia INTEGER NOT NULL DEFAULT 0,
  anclas_continuidad INTEGER NOT NULL DEFAULT 0,
  luz_cuantica DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  mantras_desbloqueados TEXT[] DEFAULT ARRAY[]::TEXT[],
  codigos_premium_desbloqueados TEXT[] DEFAULT ARRAY[]::TEXT[],
  ultima_actualizacion TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  ultima_meditacion_especial TIMESTAMP WITH TIME ZONE,
  logros JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_user_rewards_user_id ON user_rewards(user_id);
CREATE INDEX IF NOT EXISTS idx_user_rewards_cristales ON user_rewards(cristales_energia);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_user_rewards_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar updated_at
DROP TRIGGER IF EXISTS trigger_update_user_rewards_updated_at ON user_rewards;
CREATE TRIGGER trigger_update_user_rewards_updated_at
  BEFORE UPDATE ON user_rewards
  FOR EACH ROW
  EXECUTE FUNCTION update_user_rewards_updated_at();

-- Políticas RLS (Row Level Security)
ALTER TABLE user_rewards ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen (para evitar duplicados)
DROP POLICY IF EXISTS "Users can view their own rewards" ON user_rewards;
DROP POLICY IF EXISTS "Users can insert their own rewards" ON user_rewards;
DROP POLICY IF EXISTS "Users can update their own rewards" ON user_rewards;

-- Los usuarios solo pueden ver y modificar sus propias recompensas
CREATE POLICY "Users can view their own rewards" ON user_rewards
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own rewards" ON user_rewards
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own rewards" ON user_rewards
  FOR UPDATE USING (auth.uid() = user_id);

-- Tabla para mantras desbloqueables
CREATE TABLE IF NOT EXISTS mantras (
  id TEXT PRIMARY KEY,
  nombre TEXT NOT NULL,
  descripcion TEXT NOT NULL,
  texto TEXT NOT NULL,
  dias_requeridos INTEGER NOT NULL,
  categoria TEXT DEFAULT 'Espiritualidad',
  es_premium BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insertar mantras por defecto
INSERT INTO mantras (id, nombre, descripcion, texto, dias_requeridos, categoria) VALUES
  ('mantra_21_dias', 'Mantra de Manifestación Cuántica', 'Mantra especial desbloqueado tras 21 días consecutivos', 'Om Namah Shivaya - Yo honro la conciencia dentro de mí', 21, 'Espiritualidad'),
  ('mantra_30_dias', 'Mantra de Transformación', 'Mantra para transformación profunda', 'Om Mani Padme Hum - La joya en el loto', 30, 'Transformación'),
  ('mantra_7_dias', 'Mantra de Protección', 'Mantra de protección y armonía', 'Om Tare Tuttare Ture Svaha', 7, 'Protección')
ON CONFLICT (id) DO NOTHING;

-- Tabla para códigos premium
CREATE TABLE IF NOT EXISTS codigos_premium (
  id TEXT PRIMARY KEY,
  codigo TEXT NOT NULL UNIQUE,
  nombre TEXT NOT NULL,
  descripcion TEXT NOT NULL,
  costo_cristales INTEGER NOT NULL,
  categoria TEXT DEFAULT 'Premium',
  es_raro BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insertar códigos premium por defecto
INSERT INTO codigos_premium (id, codigo, nombre, descripcion, costo_cristales, categoria, es_raro) VALUES
  ('premium_1', '888_888_888', 'Código de Manifestación Máxima', 'Código especial para manifestación de máximo potencial', 100, 'Manifestación', false),
  ('premium_2', '999_999_999', 'Código de Transformación Total', 'Transformación profunda y completa', 150, 'Transformación', true),
  ('premium_3', '777_777_777', 'Código de Sabiduría Cuántica', 'Acceso a sabiduría cuántica superior', 200, 'Espiritualidad', true)
ON CONFLICT (id) DO NOTHING;

-- Tabla para meditaciones especiales
CREATE TABLE IF NOT EXISTS meditaciones_especiales (
  id TEXT PRIMARY KEY,
  nombre TEXT NOT NULL,
  descripcion TEXT NOT NULL,
  audio_url TEXT,
  luz_cuantica_requerida DOUBLE PRECISION DEFAULT 100.0,
  duracion_minutos INTEGER DEFAULT 15,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insertar meditaciones especiales por defecto
INSERT INTO meditaciones_especiales (id, nombre, descripcion, audio_url, luz_cuantica_requerida, duracion_minutos) VALUES
  ('meditacion_1', 'Meditación de Luz Cuántica', 'Meditación guiada especial cuando la luz cuántica está completa', NULL, 100.0, 15),
  ('meditacion_2', 'Viaje Cuántico', 'Viaje profundo de transformación cuántica', NULL, 100.0, 20),
  ('meditacion_3', 'Reconexión Energética', 'Reconexión con tu esencia energética', NULL, 100.0, 10)
ON CONFLICT (id) DO NOTHING;

-- Políticas RLS para tablas de referencia (públicas para lectura)
ALTER TABLE mantras ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can view mantras" ON mantras;
CREATE POLICY "Anyone can view mantras" ON mantras FOR SELECT USING (true);

ALTER TABLE codigos_premium ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can view premium codes" ON codigos_premium;
CREATE POLICY "Anyone can view premium codes" ON codigos_premium FOR SELECT USING (true);

ALTER TABLE meditaciones_especiales ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can view special meditations" ON meditaciones_especiales;
CREATE POLICY "Anyone can view special meditations" ON meditaciones_especiales FOR SELECT USING (true);

