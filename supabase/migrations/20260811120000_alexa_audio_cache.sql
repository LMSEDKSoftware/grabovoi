-- Catálogo de audios pre-renderizados para el skill de Alexa.
--
-- Alexa no puede reproducir 90 clips sueltos en una respuesta (el límite
-- es 5 en SSML y ~15 en APLA), y renderizar en vivo tampoco sirve porque
-- corta la respuesta a los ~8 segundos. Así que la voz grabada de la app
-- + la música se mezclan de antemano en UN solo MP3 (scripts/
-- render_alexa_audio.py), se sube a Storage, y aquí queda el índice de
-- qué hay disponible para que el skill lo consulte en una sola query.
--
-- Si no hay fila para una secuencia, el skill cae a leerla con la voz de
-- Alexa sobre música (APLA Mixer). Nunca se queda sin respuesta.

create table if not exists public.alexa_audio_cache (
  codigo text not null,
  voz text not null check (voz in ('female', 'male', 'male 2')),
  musica text not null default 'crystal_bowls',
  url text not null,
  duracion_s numeric not null,
  repeticiones int not null,
  volumen_musica numeric not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (codigo, voz)
);

comment on table public.alexa_audio_cache is
  'Audios pre-renderizados (voz de la app + música) para el skill de Alexa. Ver scripts/render_alexa_audio.py y docs/ALEXA_SKILL_PLAN.md.';

-- Solo el service_role escribe y lee esto: el skill usa la service key y
-- los usuarios finales nunca consultan esta tabla desde la app.
alter table public.alexa_audio_cache enable row level security;
