-- Interruptor general de notificaciones, visible al servidor. Antes
-- NotificationPreferences solo vivía en SharedPreferences del dispositivo,
-- así que ningún cron/trigger del lado del servidor (challenge-streak-check,
-- engagement-notifications-check, check_streaks_at_risk, los triggers de
-- logros) tenía forma de saber si el usuario había apagado las
-- notificaciones. Con esta columna, send-push (el único punto por el que
-- pasan todos los envíos por userId) puede negarse a enviar si está en false.
alter table public.users add column if not exists notifications_enabled boolean not null default true;
