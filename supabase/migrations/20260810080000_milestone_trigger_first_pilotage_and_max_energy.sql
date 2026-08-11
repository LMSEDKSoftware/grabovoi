-- Cierra dos huecos de la matriz de notificaciones (implementación del plan
-- acordado): firstPilotage y energyMaxReached pasan a ser 100% servidor, en
-- vez de depender del fallback local en onPilotageCompleted() (que se
-- elimina en el cliente en este mismo cambio). Antes total_pilotajes==1 no
-- estaba en el array de milestones, así que SOLO se disparaba localmente;
-- y "nivel máximo" nunca tuvo mensaje propio, solo el genérico de "subió".
CREATE OR REPLACE FUNCTION public.tr_check_pilotage_milestones()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_milestones INT[] := ARRAY[10, 50, 100, 500, 1000];
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
