-- Dedupe para los 3 avisos nuevos que se agregan a engagement-notifications-check:
-- aniversario de registro, análisis mensual y recomendación semanal de código.
alter table public.users add column if not exists last_anniversary_year integer;
alter table public.usuario_progreso add column if not exists last_monthly_summary_month text;
alter table public.usuario_progreso add column if not exists last_code_recommendation_week text;
