-- Esquema de usuarios para Supabase
-- Ejecutar este script en el SQL Editor de Supabase

-- Crear tabla de usuarios
CREATE TABLE IF NOT EXISTS users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  avatar TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login_at TIMESTAMP WITH TIME ZONE,
  is_email_verified BOOLEAN DEFAULT FALSE,
  preferences JSONB DEFAULT '{}',
  level INTEGER DEFAULT 1,
  experience INTEGER DEFAULT 0,
  achievements TEXT[] DEFAULT '{}',
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear tabla de desafíos de usuario
CREATE TABLE IF NOT EXISTS user_challenges (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  challenge_id TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'no_iniciado',
  start_date TIMESTAMP WITH TIME ZONE,
  end_date TIMESTAMP WITH TIME ZONE,
  current_day INTEGER DEFAULT 0,
  total_progress INTEGER DEFAULT 0,
  day_progress JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear tabla de acciones de usuario
CREATE TABLE IF NOT EXISTS user_actions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  challenge_id UUID REFERENCES user_challenges(id) ON DELETE CASCADE,
  action_type TEXT NOT NULL,
  action_data JSONB DEFAULT '{}',
  recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear tabla de progreso diario
CREATE TABLE IF NOT EXISTS daily_progress (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  challenge_id UUID REFERENCES user_challenges(id) ON DELETE CASCADE NOT NULL,
  day_number INTEGER NOT NULL,
  date DATE NOT NULL,
  actions_completed JSONB DEFAULT '{}',
  is_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, challenge_id, day_number)
);

-- Crear índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_user_challenges_user_id ON user_challenges(user_id);
CREATE INDEX IF NOT EXISTS idx_user_challenges_status ON user_challenges(status);
CREATE INDEX IF NOT EXISTS idx_user_actions_user_id ON user_actions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_actions_challenge_id ON user_actions(challenge_id);
CREATE INDEX IF NOT EXISTS idx_daily_progress_user_challenge ON daily_progress(user_id, challenge_id);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para actualizar updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_challenges_updated_at BEFORE UPDATE ON user_challenges
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daily_progress_updated_at BEFORE UPDATE ON daily_progress
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Políticas de seguridad RLS (Row Level Security)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_progress ENABLE ROW LEVEL SECURITY;

-- Política para usuarios: solo pueden ver y modificar sus propios datos
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Política para desafíos de usuario
CREATE POLICY "Users can view own challenges" ON user_challenges
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own challenges" ON user_challenges
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own challenges" ON user_challenges
    FOR UPDATE USING (auth.uid() = user_id);

-- Política para acciones de usuario
CREATE POLICY "Users can view own actions" ON user_actions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own actions" ON user_actions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Política para progreso diario
CREATE POLICY "Users can view own daily progress" ON daily_progress
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own daily progress" ON daily_progress
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own daily progress" ON daily_progress
    FOR UPDATE USING (auth.uid() = user_id);

-- Función para crear usuario automáticamente después del registro
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, name, created_at, last_login_at, is_email_verified)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NOW(),
    NOW(),
    NEW.email_confirmed_at IS NOT NULL
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para crear usuario automáticamente
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Función para actualizar last_login_at cuando el usuario inicia sesión
CREATE OR REPLACE FUNCTION public.handle_user_login()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.users
  SET last_login_at = NOW()
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para obtener estadísticas del usuario
CREATE OR REPLACE FUNCTION get_user_stats(user_uuid UUID)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_challenges', COUNT(uc.id),
    'completed_challenges', COUNT(uc.id) FILTER (WHERE uc.status = 'completado'),
    'active_challenges', COUNT(uc.id) FILTER (WHERE uc.status = 'en_progreso'),
    'total_experience', u.experience,
    'current_level', u.level,
    'achievements_count', array_length(u.achievements, 1)
  ) INTO result
  FROM users u
  LEFT JOIN user_challenges uc ON u.id = uc.user_id
  WHERE u.id = user_uuid;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para agregar experiencia al usuario
CREATE OR REPLACE FUNCTION add_user_experience(user_uuid UUID, exp_amount INTEGER)
RETURNS JSON AS $$
DECLARE
  current_exp INTEGER;
  current_level INTEGER;
  new_exp INTEGER;
  new_level INTEGER;
  leveled_up BOOLEAN := FALSE;
BEGIN
  -- Obtener experiencia y nivel actual
  SELECT experience, level INTO current_exp, current_level
  FROM users WHERE id = user_uuid;
  
  -- Calcular nueva experiencia y nivel
  new_exp := current_exp + exp_amount;
  new_level := current_level;
  
  -- Verificar si subió de nivel
  WHILE new_exp >= (new_level * 100) LOOP
    new_exp := new_exp - (new_level * 100);
    new_level := new_level + 1;
    leveled_up := TRUE;
  END LOOP;
  
  -- Actualizar usuario
  UPDATE users 
  SET experience = new_exp, level = new_level
  WHERE id = user_uuid;
  
  -- Retornar resultado
  RETURN json_build_object(
    'old_level', current_level,
    'new_level', new_level,
    'old_experience', current_exp,
    'new_experience', new_exp,
    'leveled_up', leveled_up
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
