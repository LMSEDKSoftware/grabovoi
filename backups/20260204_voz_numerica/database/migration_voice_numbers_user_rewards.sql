-- Migración: Voz numérica en pilotajes (user_rewards)
-- Ejecutar en Supabase SQL Editor después de hacer respaldo de la DB.
-- Ver docs/RESPALDO_DB_ANTES_MIGRACIONES.md

ALTER TABLE public.user_rewards
  ADD COLUMN IF NOT EXISTS voice_numbers_enabled BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS voice_gender TEXT NOT NULL DEFAULT 'female';

-- Constraint para valores válidos de voz
ALTER TABLE public.user_rewards
  DROP CONSTRAINT IF EXISTS chk_voice_gender;
ALTER TABLE public.user_rewards
  ADD CONSTRAINT chk_voice_gender CHECK (voice_gender IN ('male', 'female'));
