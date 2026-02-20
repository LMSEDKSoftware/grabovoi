-- Script para reparar la tabla app_config y sus permisos
-- Ejecuta este script en el Editor SQL de Supabase

-- 1. Asegurar que la tabla existe con la estructura correcta
CREATE TABLE IF NOT EXISTS public.app_config (
    key text PRIMARY KEY,
    value text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Asegurar permisos explícitos para el rol 'anon' (público) y 'authenticated'
-- Esto es crucial porque a veces RLS está bien pero el rol no tiene permiso de SELECT en la tabla
GRANT SELECT ON public.app_config TO anon;
GRANT SELECT ON public.app_config TO authenticated;
GRANT SELECT ON public.app_config TO service_role;

-- 3. Habilitar RLS (Row Level Security)
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

-- 4. Recrear la política de lectura pública para asegurar que es correcta
DROP POLICY IF EXISTS "Public read access" ON public.app_config;
CREATE POLICY "Public read access" ON public.app_config FOR SELECT USING (true);

-- 5. Insertar valores por defecto para evitar errores de datos faltantes
INSERT INTO public.app_config (key, value)
VALUES 
    ('legal_privacy_policy_url', 'https://manigrab.app/politica-privacidad.html'),
    ('legal_terms_url', 'https://manigrab.app/terminos-condiciones.html'),
    ('legal_cookies_url', 'https://manigrab.app/politica-cookies.html'),
    ('legal_data_usage_url', 'https://manigrab.app/uso-datos.html'),
    ('legal_credits_url', 'https://manigrab.app/creditos.html')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- 6. Forzar recarga del esquema de API (útil si Supabase tiene caché antigua)
NOTIFY pgrst, 'reload config';
