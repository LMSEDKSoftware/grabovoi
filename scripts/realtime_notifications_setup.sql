
-- 1. Función para invocar la Edge Function 'send-push' desde Postgres
CREATE OR REPLACE FUNCTION public.notify_push_from_db(
    p_user_id UUID,
    p_title TEXT,
    p_body TEXT,
    p_data JSONB DEFAULT '{}'::jsonb
)
RETURNS VOID AS $$
BEGIN
    -- Realizar la llamada HTTP a la Edge Function
    -- Usamos net.http_post (extensión pg_net disponible en Supabase)
    PERFORM
      net.http_post(
        url := 'https://whtiazgcxdnemrrgjjqf.supabase.co/functions/v1/send-push',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || current_setting('request.headers')::jsonb->>'apikey' -- O usar una llave de servicio fija si fallase
        ),
        body := jsonb_build_object(
          'userId', p_user_id,
          'title', p_title,
          'body', p_body,
          'data', p_data
        )
      );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Trigger para Hitos de Pilotaje (Milestones)
CREATE OR REPLACE FUNCTION public.tr_check_pilotage_milestones()
RETURNS TRIGGER AS $$
DECLARE
    v_milestones INT[] := ARRAY[10, 50, 100, 500, 1000];
    v_title TEXT;
    v_body TEXT;
    v_user_name TEXT;
BEGIN
    -- Obtener nombre del usuario si existe
    SELECT COALESCE(raw_user_meta_data->>'name', 'Piloto Consciente') 
    INTO v_user_name 
    FROM auth.users WHERE id = NEW.user_id;

    -- Si se alcanzó un hito
    IF NEW.total_pilotajes > COALESCE(OLD.total_pilotajes, 0) AND NEW.total_pilotajes = ANY(v_milestones) THEN
        v_title := '🏆 ¡Hito Alcanzado!';
        v_body := v_user_name || ', has completado ' || NEW.total_pilotajes || ' pilotajes. ¡Tu compromiso con el campo cuántico es inspirador!';
        
        PERFORM public.notify_push_from_db(NEW.user_id, v_title, v_body);
    END IF;

    -- Si aumentó el nivel energético
    IF NEW.nivel_energetico > COALESCE(OLD.nivel_energetico, 1) THEN
        v_title := '⚡ ¡Nivel Energético Aumentado!';
        v_body := '¡Felicidades! Tu nivel de energía cuántica ha subido a ' || NEW.nivel_energetico || '.';
        
        PERFORM public.notify_push_from_db(NEW.user_id, v_title, v_body);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar el trigger a la tabla de progreso
DROP TRIGGER IF EXISTS check_milestones_trigger ON public.usuario_progreso;
CREATE TRIGGER check_milestones_trigger
AFTER UPDATE ON public.usuario_progreso
FOR EACH ROW
EXECUTE FUNCTION public.tr_check_pilotage_milestones();

-- 3. Función para verificar rachas en riesgo (para Cron)
CREATE OR REPLACE FUNCTION public.check_streaks_at_risk()
RETURNS VOID AS $$
DECLARE
    v_row RECORD;
    v_hours_since_last INT;
    v_user_name TEXT;
BEGIN
    FOR v_row IN 
        SELECT user_id, dias_consecutivos, ultimo_pilotaje 
        FROM public.usuario_progreso 
        WHERE dias_consecutivos >= 1 
          AND (ultimo_pilotaje IS NULL OR (now() - ultimo_pilotaje) > INTERVAL '20 hours')
          AND (ultimo_pilotaje IS NULL OR (now() - ultimo_pilotaje) < INTERVAL '24 hours')
    LOOP
        SELECT COALESCE(raw_user_meta_data->>'name', 'Piloto Consciente') 
        INTO v_user_name 
        FROM auth.users WHERE id = v_row.user_id;

        PERFORM public.notify_push_from_db(
            v_row.user_id, 
            '🔥 ¡Racha en Peligro!', 
            v_user_name || ', tu racha de ' || v_row.dias_consecutivos || ' días está por expirar. Realiza un pilotaje ahora para mantenerla.'
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
