-- Campos de dedupe para los nuevos avisos de "resumen semanal" y "prueba
-- gratis por terminar" (engagement-notifications-check).
alter table public.usuario_progreso add column if not exists last_weekly_summary_date date;
alter table public.users add column if not exists trial_ending_notified boolean not null default false;
