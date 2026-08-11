-- Hallazgo #5 de la auditoría de notificaciones: energyLowAlert,
-- favoriteCode10x, diverseCodes20x y streakPerfectDay estaban en el enum
-- NotificationType pero no tenían ningún disparador real, del cliente ni
-- del servidor.

-- 1) energyLowAlert: simétrico al aviso de subida que ya existe en este
-- mismo trigger — ahora también avisa cuando el nivel baja (p.ej. tras
-- perder la racha, el próximo pilotaje recalcula un nivel más bajo).
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

    IF NEW.total_pilotajes > COALESCE(OLD.total_pilotajes, 0) AND NEW.total_pilotajes = ANY(v_milestones) THEN
        v_title := '🏆 ¡Hito Alcanzado!';
        v_body := v_user_name || ', has completado ' || NEW.total_pilotajes || ' pilotajes. ¡Tu compromiso con el campo cuántico es inspirador!';
        PERFORM public.notify_push_from_db(NEW.user_id, v_title, v_body);
    END IF;

    IF NEW.nivel_energetico > COALESCE(OLD.nivel_energetico, 1) THEN
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

-- 2) favoriteCode10x / diverseCodes20x: logros sobre el historial de
-- códigos usados (user_code_history: una fila por código distinto, con su
-- propio contador de usos).
CREATE OR REPLACE FUNCTION public.tr_check_code_achievements()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_distinct_count INT;
BEGIN
    -- Código favorito: el mismo código usado 10+ veces (se dispara una sola
    -- vez, justo al cruzar el umbral).
    IF NEW.usage_count >= 10 AND (TG_OP = 'INSERT' OR COALESCE(OLD.usage_count, 0) < 10) THEN
        PERFORM public.notify_push_from_db(
            NEW.user_id,
            '❤️ Código Favorito',
            'Has usado "' || COALESCE(NEW.code_name, NEW.code_id) || '" más de 10 veces. ¡Ya es parte de tu rutina!'
        );
    END IF;

    -- Diversidad: 20 códigos distintos probados (solo puede cruzar el
    -- umbral en un INSERT, ya que cada fila es un código distinto).
    IF TG_OP = 'INSERT' THEN
        SELECT count(*) INTO v_distinct_count FROM public.user_code_history WHERE user_id = NEW.user_id;
        IF v_distinct_count = 20 THEN
            PERFORM public.notify_push_from_db(
                NEW.user_id,
                '🌈 Explorador Cuántico',
                'Has probado 20 códigos diferentes. ¡Tu viaje de exploración es admirable!'
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS check_code_achievements_trigger ON public.user_code_history;
CREATE TRIGGER check_code_achievements_trigger
    AFTER INSERT OR UPDATE ON public.user_code_history
    FOR EACH ROW
    EXECUTE FUNCTION public.tr_check_code_achievements();

-- 3) streakPerfectDay: un día en el que el usuario completó las 3
-- categorías de acción (pilotaje, repetición, compartir) más al menos 15
-- minutos activos en la app — un "día completo" de compromiso, no solo el
-- mínimo de un desafío. Dedupe vía notification_logs (una vez por día).
CREATE OR REPLACE FUNCTION public.tr_check_perfect_day()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_types_today INT;
    v_minutes_today INT;
    v_already_sent BOOLEAN;
BEGIN
    IF NEW.action_type NOT IN ('sesionPilotaje', 'codigoRepetido', 'pilotajeCompartido', 'tiempoEnApp') THEN
        RETURN NEW;
    END IF;

    SELECT count(DISTINCT action_type) INTO v_types_today
    FROM public.user_actions
    WHERE user_id = NEW.user_id
      AND action_type IN ('sesionPilotaje', 'codigoRepetido', 'pilotajeCompartido')
      AND recorded_at::date = NEW.recorded_at::date;

    IF v_types_today < 3 THEN
        RETURN NEW;
    END IF;

    SELECT COALESCE(sum((action_data->>'duration')::numeric), 0) INTO v_minutes_today
    FROM public.user_actions
    WHERE user_id = NEW.user_id
      AND action_type = 'tiempoEnApp'
      AND recorded_at::date = NEW.recorded_at::date;

    IF v_minutes_today < 15 THEN
        RETURN NEW;
    END IF;

    SELECT EXISTS(
        SELECT 1 FROM public.notification_logs
        WHERE user_id = NEW.user_id
          AND title = '🌟 ¡Día Perfecto!'
          AND created_at::date = NEW.recorded_at::date
    ) INTO v_already_sent;

    IF NOT v_already_sent THEN
        PERFORM public.notify_push_from_db(
            NEW.user_id,
            '🌟 ¡Día Perfecto!',
            'Hoy completaste pilotaje, repetición, compartir y tiempo en la app. ¡Día cuántico completo!'
        );
    END IF;

    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS check_perfect_day_trigger ON public.user_actions;
CREATE TRIGGER check_perfect_day_trigger
    AFTER INSERT ON public.user_actions
    FOR EACH ROW
    EXECUTE FUNCTION public.tr_check_perfect_day();
