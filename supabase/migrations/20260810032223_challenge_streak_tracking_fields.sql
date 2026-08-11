-- Campos para el seguimiento de racha/ancla de continuidad de los desafíos,
-- usados por la edge function challenge-streak-check (cron):
--   at_risk_day: número de día detectado como perdido y sin ancla disponible;
--     si en la siguiente revisión sigue sin resolverse, se reinicia el desafío.
--   last_morning_reminder_date / last_evening_warning_date: fecha local
--     (zona horaria del usuario) en que ya se envió cada push, para no
--     duplicar notificaciones el mismo día.
alter table public.user_challenges
  add column if not exists at_risk_day integer,
  add column if not exists last_morning_reminder_date date,
  add column if not exists last_evening_warning_date date;
