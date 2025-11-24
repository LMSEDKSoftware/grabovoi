-- Tabla para rastrear notificaciones enviadas y evitar duplicados
-- Ejecutar este script en el SQL Editor de Supabase

CREATE TABLE IF NOT EXISTS public.user_notifications_sent (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL,
  action_type TEXT NOT NULL,
  code_id TEXT,
  code_name TEXT,
  sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índice único para evitar duplicados: usuario + tipo + código (code_id o code_name) + acción
-- Usamos una expresión funcional para combinar code_id y code_name
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_notifications_sent_unique 
ON public.user_notifications_sent(
  user_id, 
  notification_type, 
  action_type, 
  COALESCE(NULLIF(code_id, ''), NULLIF(code_name, ''), '')
);

-- Índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_user_notifications_sent_user_id ON public.user_notifications_sent(user_id);
CREATE INDEX IF NOT EXISTS idx_user_notifications_sent_type ON public.user_notifications_sent(notification_type);
CREATE INDEX IF NOT EXISTS idx_user_notifications_sent_code ON public.user_notifications_sent(code_id, code_name);
CREATE INDEX IF NOT EXISTS idx_user_notifications_sent_sent_at ON public.user_notifications_sent(sent_at);

-- Políticas RLS (Row Level Security)
ALTER TABLE public.user_notifications_sent ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Users can view their own sent notifications" ON public.user_notifications_sent;
DROP POLICY IF EXISTS "Users can insert their own sent notifications" ON public.user_notifications_sent;

-- Los usuarios solo pueden ver y insertar sus propias notificaciones enviadas
CREATE POLICY "Users can view their own sent notifications" ON public.user_notifications_sent
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own sent notifications" ON public.user_notifications_sent
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Limpiar notificaciones antiguas (más de 30 días) automáticamente
-- Esto se puede ejecutar periódicamente o mediante un trigger
CREATE OR REPLACE FUNCTION public.cleanup_old_notifications()
RETURNS void AS $$
BEGIN
  DELETE FROM public.user_notifications_sent
  WHERE sent_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

