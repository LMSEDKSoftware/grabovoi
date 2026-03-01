-- Tabla para almacenar configuración de la aplicación
-- Ejecutar este script en el SQL Editor de Supabase
-- Esta tabla permite configurar links legales y otras configuraciones desde la DB

CREATE TABLE IF NOT EXISTS public.app_config (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  key TEXT NOT NULL UNIQUE,
  value TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índice para búsquedas rápidas por key
CREATE INDEX IF NOT EXISTS idx_app_config_key ON public.app_config(key);

-- RLS (Row Level Security)
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

-- Política: Lectura pública (todos pueden leer la configuración)
CREATE POLICY "Public can read app config" ON public.app_config
  FOR SELECT
  USING (true);

-- Política: Solo admins pueden insertar/actualizar/eliminar
-- IMPORTANTE: NO usar "FOR ALL" aquí, porque también aplica a SELECT y puede
-- provocar errores si la verificación de admin depende de RLS (p.ej. users_admin).
CREATE POLICY "Admins can modify app config" ON public.app_config
  FOR INSERT
  WITH CHECK (
    public.es_admin(auth.uid())
  );

CREATE POLICY "Admins can update app config" ON public.app_config
  FOR UPDATE
  USING (
    public.es_admin(auth.uid())
  )
  WITH CHECK (
    public.es_admin(auth.uid())
  );

CREATE POLICY "Admins can delete app config" ON public.app_config
  FOR DELETE
  USING (
    public.es_admin(auth.uid())
  );

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION public.update_app_config_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar updated_at
DROP TRIGGER IF EXISTS trigger_update_app_config_updated_at ON public.app_config;
CREATE TRIGGER trigger_update_app_config_updated_at
  BEFORE UPDATE ON public.app_config
  FOR EACH ROW
  EXECUTE FUNCTION public.update_app_config_updated_at();

-- Insertar valores por defecto para links legales
-- Estos pueden ser modificados desde el dashboard de Supabase o desde la app (si eres admin)
INSERT INTO public.app_config (key, value, description) VALUES
  ('legal_privacy_policy_url', 'https://manigrab.app/politica-privacidad.html', 'URL de la Política de Privacidad'),
  ('legal_terms_url', 'https://manigrab.app/terminos-condiciones.html', 'URL de los Términos y Condiciones'),
  ('legal_cookies_url', 'https://manigrab.app/politica-cookies.html', 'URL de la Política de Cookies'),
  ('legal_data_usage_url', 'https://example.com/data-usage', 'URL de la Política de Uso de Datos'),
  ('legal_credits_url', 'https://example.com/credits', 'URL de Créditos y Reconocimientos')
ON CONFLICT (key) DO NOTHING;

-- Comentarios para documentación
COMMENT ON TABLE public.app_config IS 'Tabla para almacenar configuración de la aplicación, incluyendo links legales y otras configuraciones';
COMMENT ON COLUMN public.app_config.key IS 'Clave única de la configuración (ej: legal_privacy_policy_url)';
COMMENT ON COLUMN public.app_config.value IS 'Valor de la configuración (ej: URL del link legal)';
COMMENT ON COLUMN public.app_config.description IS 'Descripción opcional de la configuración';
