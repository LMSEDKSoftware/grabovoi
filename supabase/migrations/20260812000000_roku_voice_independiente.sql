-- Roku deja de depender de user_rewards.voice_gender (el ajuste de voz
-- de la app/Alexa). Esto se disparó por un susto real: cambiar la voz
-- para probar Roku tocaba la misma fila que usa el resto del
-- ecosistema, y coincidió en el tiempo con un fallo (no relacionado)
-- de Alexa, generando confusión sobre si un cambio afectó al otro.
-- A partir de ahora cada plataforma es dueña de su propia preferencia.

alter table public.roku_account_links
  add column if not exists voice_gender text not null default 'female'
    check (voice_gender in ('female', 'male', 'male 2'));

comment on column public.roku_account_links.voice_gender is
  'Preferencia de voz exclusiva de ManiGraB TV, independiente de user_rewards.voice_gender (app/Alexa). Ver docs/ROKU_TV_PLAN.md.';
