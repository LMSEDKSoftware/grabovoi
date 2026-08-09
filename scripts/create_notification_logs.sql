
-- Tabla para trazabilidad completa de notificaciones push
CREATE TABLE IF NOT EXISTS public.notification_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- Null si es broadcast
    topic TEXT, -- 'all' o nulo si es directo
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}'::jsonb,
    status TEXT NOT NULL, -- 'sent', 'error', 'received', 'opened'
    fcm_message_id TEXT, -- ID retornado por Firebase
    error_details TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    received_at TIMESTAMP WITH TIME ZONE,
    opened_at TIMESTAMP WITH TIME ZONE,
    device_info JSONB DEFAULT '{}'::jsonb
);

-- Índices para búsqueda rápida
CREATE INDEX IF NOT EXISTS idx_notification_logs_user_id ON public.notification_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_logs_status ON public.notification_logs(status);

-- Habilitar RLS
ALTER TABLE public.notification_logs ENABLE ROW LEVEL SECURITY;

-- Políticas: Solo lectura para el usuario dueño, control total para service_role
CREATE POLICY "Users can view their own and broadcast logs" 
    ON public.notification_logs FOR SELECT 
    USING (auth.uid() = user_id OR topic = 'all');

CREATE POLICY "Service role has full access to notification logs" 
    ON public.notification_logs FOR ALL 
    USING (auth.role() = 'service_role');
