-- Tabla para registrar recompensas otorgadas por código, usuario y día
-- Esto previene que un usuario reciba múltiples recompensas por el mismo código en el mismo día

CREATE TABLE IF NOT EXISTS user_rewarded_actions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  codigo_id TEXT NOT NULL,
  tipo_accion TEXT NOT NULL CHECK (tipo_accion IN ('repeticion', 'pilotaje')),
  cristales_otorgados INTEGER NOT NULL DEFAULT 0,
  fecha TIMESTAMP WITH TIME ZONE NOT NULL,
  fecha_dia DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índice único para prevenir duplicados: un usuario solo puede recibir recompensas una vez por código, tipo y día
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_rewarded_actions_unique 
  ON user_rewarded_actions(user_id, codigo_id, tipo_accion, fecha_dia);

-- Índices para mejorar el rendimiento de las consultas
CREATE INDEX IF NOT EXISTS idx_user_rewarded_actions_user_id ON user_rewarded_actions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_rewarded_actions_codigo_id ON user_rewarded_actions(codigo_id);
CREATE INDEX IF NOT EXISTS idx_user_rewarded_actions_fecha ON user_rewarded_actions(fecha);
CREATE INDEX IF NOT EXISTS idx_user_rewarded_actions_fecha_dia ON user_rewarded_actions(fecha_dia);

-- Comentarios para documentación
COMMENT ON TABLE user_rewarded_actions IS 'Registra las recompensas otorgadas a usuarios por código, tipo de acción y día para prevenir duplicados';
COMMENT ON COLUMN user_rewarded_actions.codigo_id IS 'ID del código Grabovoi usado';
COMMENT ON COLUMN user_rewarded_actions.tipo_accion IS 'Tipo de acción: repeticion o pilotaje';
COMMENT ON COLUMN user_rewarded_actions.cristales_otorgados IS 'Cantidad de cristales otorgados en esta acción';
COMMENT ON COLUMN user_rewarded_actions.fecha IS 'Fecha y hora en que se otorgó la recompensa';
COMMENT ON COLUMN user_rewarded_actions.fecha_dia IS 'Fecha del día (sin hora) para agrupar por día y prevenir duplicados';

-- Política RLS (Row Level Security) - Solo el usuario puede ver sus propios registros
ALTER TABLE user_rewarded_actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own rewarded actions"
  ON user_rewarded_actions
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own rewarded actions"
  ON user_rewarded_actions
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

