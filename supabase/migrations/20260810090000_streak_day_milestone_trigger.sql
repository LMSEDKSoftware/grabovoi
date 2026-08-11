-- Cierra el último hueco de la matriz: streakMilestone3/7/14/21/30 (racha en
-- días consecutivos) no tenía NINGÚN disparador real después de quitar el
-- fallback local — solo existía como método muerto en el cliente. Se agrega
-- al mismo trigger que ya vigila usuario_progreso, con los mismos textos que
-- tenía notifyStreakMilestone() en el cliente (ahora eliminado).
CREATE OR REPLACE FUNCTION public.tr_check_pilotage_milestones()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_milestones INT[] := ARRAY[10, 50, 100, 500, 1000];
    v_streak_milestones INT[] := ARRAY[3, 7, 14, 21, 30];
    v_title TEXT;
    v_body TEXT;
    v_user_name TEXT;
BEGIN
    SELECT COALESCE(raw_user_meta_data->>'name', 'Piloto Consciente')
    INTO v_user_name
    FROM auth.users WHERE id = NEW.user_id;

    IF NEW.total_pilotajes = 1 AND COALESCE(OLD.total_pilotajes, 0) = 0 THEN
        v_title := '🎉 ¡Bienvenido al viaje cuántico!';
        v_body := 'Has completado tu primer pilotaje consciente. El viaje de transformación comienza.';
        PERFORM public.notify_push_from_db(NEW.user_id, v_title, v_body);
    ELSIF NEW.total_pilotajes > COALESCE(OLD.total_pilotajes, 0) AND NEW.total_pilotajes = ANY(v_milestones) THEN
        v_title := '🏆 ¡Hito Alcanzado!';
        v_body := v_user_name || ', has completado ' || NEW.total_pilotajes || ' pilotajes. ¡Tu compromiso con el campo cuántico es inspirador!';
        PERFORM public.notify_push_from_db(NEW.user_id, v_title, v_body);
    END IF;

    IF NEW.dias_consecutivos > COALESCE(OLD.dias_consecutivos, 0) AND NEW.dias_consecutivos = ANY(v_streak_milestones) THEN
        CASE NEW.dias_consecutivos
            WHEN 3 THEN
                v_title := '🎉 ¡Felicidades!';
                v_body := '3 días consecutivos. Tu energía comienza a estabilizarse.';
            WHEN 7 THEN
                v_title := '🌟 ¡Increíble!';
                v_body := '7 días consecutivos. Estás creando un hábito poderoso.';
            WHEN 14 THEN
                v_title := '💎 ¡Extraordinario!';
                v_body := '14 días consecutivos. Tu disciplina está transformando tu realidad.';
            WHEN 21 THEN
                v_title := '👑 ¡Épico!';
                v_body := '21 días consecutivos. El hábito está formado. Eres un Piloto Consciente.';
            WHEN 30 THEN
                v_title := '🏆 ¡Legendario!';
                v_body := '30 días consecutivos. Has alcanzado Maestría en Constancia.';
        END CASE;
        PERFORM public.notify_push_from_db(NEW.user_id, v_title, v_body);
    END IF;

    IF NEW.nivel_energetico >= 10 AND COALESCE(OLD.nivel_energetico, 1) < 10 THEN
        v_title := '🌟 ¡Nivel Energético Máximo!';
        v_body := 'Has alcanzado el nivel máximo de energía cuántica. Eres una fuente de luz pura.';
        PERFORM public.notify_push_from_db(NEW.user_id, v_title, v_body);
    ELSIF NEW.nivel_energetico > COALESCE(OLD.nivel_energetico, 1) THEN
        v_title := '⚡ ¡Nivel Energético Aumentado!';
        v_body := '¡Felicidades! Tu nivel de energía cuántica ha subido a ' || NEW.nivel_energetico || '.';
        PERFORM public.notify_push_from_db(NEW.user_id, v_title, v_body);
    END IF;

    IF OLD.nivel_energetico IS NOT NULL AND NEW.nivel_energetico < OLD.nivel_energetico THEN
        v_title := '🔋 Tu energía cuántica bajó';
        v_body := 'Tu nivel de energía bajó a ' || NEW.nivel_energetico || '. Un pilotaje hoy te ayuda a recuperarlo.';
        PERFORM public.notify_push_from_db(NEW.user_id, v_title, v_body);
    END IF;

    RETURN NEW;
END;
$function$;
