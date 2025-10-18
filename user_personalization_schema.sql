-- Esquema para personalización por usuario
-- Ejecutar este script en el SQL Editor de Supabase

-- Crear tabla de favoritos por usuario
CREATE TABLE IF NOT EXISTS user_favorites (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  code_id TEXT NOT NULL,
  added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, code_id)
);

-- Crear tabla de progreso personalizado por usuario
CREATE TABLE IF NOT EXISTS user_progress (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  total_sessions INTEGER DEFAULT 0,
  consecutive_days INTEGER DEFAULT 0,
  last_session_date TIMESTAMP WITH TIME ZONE,
  total_pilotage_time INTEGER DEFAULT 0, -- en minutos
  total_meditation_time INTEGER DEFAULT 0, -- en minutos
  favorite_categories TEXT[] DEFAULT '{}',
  energy_level INTEGER DEFAULT 50, -- 0-100
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  achievements TEXT[] DEFAULT '{}',
  preferences JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear tabla de sesiones de usuario
CREATE TABLE IF NOT EXISTS user_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  session_type TEXT NOT NULL, -- 'pilotage', 'meditation', 'repetition'
  code_id TEXT,
  code_name TEXT,
  duration_minutes INTEGER DEFAULT 0,
  category TEXT,
  energy_before INTEGER,
  energy_after INTEGER,
  notes TEXT,
  session_data JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear tabla de historial de códigos usados
CREATE TABLE IF NOT EXISTS user_code_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  code_id TEXT NOT NULL,
  code_name TEXT NOT NULL,
  usage_count INTEGER DEFAULT 1,
  last_used TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  total_time_minutes INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, code_id)
);

-- Crear tabla de estadísticas de usuario
CREATE TABLE IF NOT EXISTS user_statistics (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  total_days_active INTEGER DEFAULT 0,
  most_used_category TEXT,
  most_used_code TEXT,
  average_session_duration INTEGER DEFAULT 0,
  best_streak_day INTEGER DEFAULT 0,
  total_energy_gained INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  experience_points INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear índices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_user_favorites_user_id ON user_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_created_at ON user_sessions(created_at);
CREATE INDEX IF NOT EXISTS idx_user_code_history_user_id ON user_code_history(user_id);
CREATE INDEX IF NOT EXISTS idx_user_code_history_last_used ON user_code_history(last_used);

-- Crear políticas RLS para seguridad
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_code_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_statistics ENABLE ROW LEVEL SECURITY;

-- Políticas para user_favorites
CREATE POLICY "Users can view own favorites" ON user_favorites
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own favorites" ON user_favorites
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own favorites" ON user_favorites
  FOR DELETE USING (auth.uid() = user_id);

-- Políticas para user_progress
CREATE POLICY "Users can view own progress" ON user_progress
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own progress" ON user_progress
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own progress" ON user_progress
  FOR UPDATE USING (auth.uid() = user_id);

-- Políticas para user_sessions
CREATE POLICY "Users can view own sessions" ON user_sessions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sessions" ON user_sessions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Políticas para user_code_history
CREATE POLICY "Users can view own code history" ON user_code_history
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own code history" ON user_code_history
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own code history" ON user_code_history
  FOR UPDATE USING (auth.uid() = user_id);

-- Políticas para user_statistics
CREATE POLICY "Users can view own statistics" ON user_statistics
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own statistics" ON user_statistics
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own statistics" ON user_statistics
  FOR UPDATE USING (auth.uid() = user_id);

-- Función para crear progreso inicial del usuario
CREATE OR REPLACE FUNCTION create_user_initial_progress()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_progress (user_id)
  VALUES (NEW.id);
  
  INSERT INTO user_statistics (user_id)
  VALUES (NEW.id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para crear progreso inicial
CREATE TRIGGER create_user_initial_progress_trigger
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION create_user_initial_progress();
