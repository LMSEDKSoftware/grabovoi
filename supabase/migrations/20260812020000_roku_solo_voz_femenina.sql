-- Decisión de producto: el canal de Roku se queda solo con la voz
-- femenina (se elimina la opción de male/male 2). El selector de voz ya
-- se quitó de la UI (HomeScreen.brs) y el endpoint /roku-voice se borró
-- del backend; esto cierra la puerta también a nivel de base de datos,
-- para que ninguna fila pueda volver a quedar en male/male 2.
update public.roku_account_links
  set voice_gender = 'female'
  where voice_gender <> 'female';

alter table public.roku_account_links
  drop constraint if exists roku_account_links_voice_gender_check;

alter table public.roku_account_links
  add constraint roku_account_links_voice_gender_check
  check (voice_gender = 'female');

notify pgrst, 'reload schema';
