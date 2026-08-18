-- "Racha en Peligro" llegaba 4 veces seguidas, una por hora.
--
-- No era casualidad que fueran siempre 4: la funcion selecciona a quien
-- lleva ENTRE 20 y 24 horas sin pilotaje, o sea una ventana de 4 horas, y
-- el cron check-streaks-at-risk-hourly la ejecuta cada hora. Sin ninguna
-- marca de "ya avisé", cada pasada volvia a encontrar al mismo usuario
-- dentro de la ventana y volvia a mandar. 4 horas de ventana = 4 avisos
-- identicos.
--
-- En los registros de ifernandez@lmsedk.com se ve exacto:
--   08-16 a las 14:00, 15:00, 16:00 y 17:00
--   08-17 a las 21:00, 22:00, 23:00 y 08-18 00:00
--
-- El arreglo usa user_notifications_sent, que ya existia para esto y ya
-- tenia el tipo 'streak_at_risk' registrado.

create or replace function public.check_streaks_at_risk()
returns void
language plpgsql
as $function$
DECLARE
    v_row RECORD;
    v_user_name TEXT;
BEGIN
    FOR v_row IN
        SELECT p.user_id, p.dias_consecutivos, p.ultimo_pilotaje
        FROM public.usuario_progreso p
        WHERE p.dias_consecutivos >= 1
          AND (p.ultimo_pilotaje IS NULL OR (now() - p.ultimo_pilotaje) > INTERVAL '20 hours')
          AND (p.ultimo_pilotaje IS NULL OR (now() - p.ultimo_pilotaje) < INTERVAL '24 hours')
          -- Un solo aviso por episodio. 20 horas es mas ancho que la
          -- ventana de riesgo (4 horas), asi que garantiza uno por dia
          -- sin dejar fuera el del dia siguiente: para cuando vuelva a
          -- estar en riesgo habran pasado ~24 horas desde el anterior.
          AND NOT EXISTS (
            SELECT 1
              FROM public.user_notifications_sent s
             WHERE s.user_id = p.user_id
               AND s.notification_type = 'streak_at_risk'
               AND s.sent_at > now() - INTERVAL '20 hours'
          )
    LOOP
        SELECT COALESCE(raw_user_meta_data->>'name', 'Piloto Consciente')
          INTO v_user_name
          FROM auth.users WHERE id = v_row.user_id;

        PERFORM public.notify_push_from_db(
            v_row.user_id,
            '🔥 ¡Racha en Peligro!',
            v_user_name || ', tu racha de ' || v_row.dias_consecutivos || ' días está por expirar. Realiza un pilotaje ahora para mantenerla.'
        );

        -- Se marca DESPUES de mandar y dentro del mismo bucle: si la
        -- funcion falla a medias, los que ya recibieron quedan marcados y
        -- no se les repite en la siguiente pasada.
        INSERT INTO public.user_notifications_sent (user_id, notification_type, sent_at)
        VALUES (v_row.user_id, 'streak_at_risk', now());
    END LOOP;
END;
$function$;

comment on function public.check_streaks_at_risk is
  'Avisa una sola vez por episodio que la racha esta por expirar. El cron corre cada hora y la ventana de riesgo dura 4, por eso hace falta la marca en user_notifications_sent.';
