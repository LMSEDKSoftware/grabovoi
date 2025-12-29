-- Script para agregar campo confirmado-correo a la tabla users
-- Ejecutar este script en el SQL Editor de Supabase

-- Agregar columna confirmado-correo si no existe
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS "confirmado-correo" BOOLEAN DEFAULT FALSE;

-- Actualizar usuarios existentes que ya tienen email verificado
UPDATE public.users 
SET "confirmado-correo" = TRUE 
WHERE is_email_verified = TRUE AND ("confirmado-correo" IS NULL OR "confirmado-correo" = FALSE);

-- Crear índice para mejorar rendimiento en consultas
CREATE INDEX IF NOT EXISTS idx_users_email_confirmed ON public.users("confirmado-correo");

-- Comentario para documentación
COMMENT ON COLUMN public.users."confirmado-correo" IS 'Indica si el usuario ha confirmado su correo electrónico haciendo clic en el enlace de activación';


