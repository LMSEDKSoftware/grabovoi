-- Endurece user_rewards y user_subscriptions contra auto-otorgamiento.
--
-- CONTEXTO IMPORTANTE: estas tablas tienen RLS correctamente acotada a
-- auth.uid() = user_id (un usuario no puede tocar la fila de otro), pero
-- nada valida los VALORES que un usuario autenticado puede escribir en su
-- propia fila. subscription_service.dart escribe is_active/expires_at
-- directamente al cliente confiando en que el SDK de compras in-app (App
-- Store/Play Store) reportó éxito — no hay verificación de recibo
-- server-side en este proyecto todavía. Sin esa verificación (que requiere
-- credenciales reales de App Store Server API / Google Play Developer API
-- que no están disponibles aquí), un usuario autenticado puede llamar
-- directamente a la REST API de Supabase y ponerse premium sin pagar, o
-- inflar sus recompensas.
--
-- Este script NO reemplaza la verificación de recibo (eso requiere una nueva
-- edge function + credenciales de las tiendas, es trabajo aparte). Lo que
-- SÍ hace es acotar los valores a rangos plausibles, para que ese hueco no
-- permita valores absurdos (suscripción hasta el año 2099, product_id
-- inventado, millones de cristales) mientras no exista verificación real.
--
-- Ejecutar en Supabase SQL Editor.

-- ===================== user_subscriptions =====================

CREATE OR REPLACE FUNCTION public.enforce_user_subscriptions_bounds()
RETURNS TRIGGER AS $$
BEGIN
  -- Las escrituras con service_role (edge functions, admin-users) no se acotan:
  -- ya pasaron su propia validación server-side.
  IF auth.role() = 'service_role' THEN
    RETURN NEW;
  END IF;

  IF NEW.product_id NOT IN ('subscription_monthly', 'subscription_yearly', 'manigrab_lovers_monthly', 'manigrab_lovers_yearly') THEN
    RAISE EXCEPTION 'product_id inválido: %', NEW.product_id;
  END IF;

  IF NEW.is_active AND NEW.expires_at > (now() + interval '400 days') THEN
    RAISE EXCEPTION 'expires_at fuera de rango permitido (máx. 400 días)';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trigger_enforce_user_subscriptions_bounds ON public.user_subscriptions;
CREATE TRIGGER trigger_enforce_user_subscriptions_bounds
  BEFORE INSERT OR UPDATE ON public.user_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_user_subscriptions_bounds();

-- ===================== user_rewards =====================

-- luz_cuantica es un porcentaje (0-100 según meditaciones_especiales.luz_cuantica_requerida)
ALTER TABLE public.user_rewards
  DROP CONSTRAINT IF EXISTS user_rewards_luz_cuantica_range;
ALTER TABLE public.user_rewards
  ADD CONSTRAINT user_rewards_luz_cuantica_range CHECK (luz_cuantica >= 0 AND luz_cuantica <= 100);

-- Techos generosos (muy por encima del costo de cualquier ítem premium, que
-- cuesta 100-200 cristales según codigos_premium.costo_cristales) solo para
-- bloquear valores absurdos, no para modelar la economía real del juego.
ALTER TABLE public.user_rewards
  DROP CONSTRAINT IF EXISTS user_rewards_cristales_range;
ALTER TABLE public.user_rewards
  ADD CONSTRAINT user_rewards_cristales_range CHECK (cristales_energia >= 0 AND cristales_energia <= 100000);

ALTER TABLE public.user_rewards
  DROP CONSTRAINT IF EXISTS user_rewards_restauradores_range;
ALTER TABLE public.user_rewards
  ADD CONSTRAINT user_rewards_restauradores_range CHECK (restauradores_armonia >= 0 AND restauradores_armonia <= 10000);

ALTER TABLE public.user_rewards
  DROP CONSTRAINT IF EXISTS user_rewards_anclas_range;
ALTER TABLE public.user_rewards
  ADD CONSTRAINT user_rewards_anclas_range CHECK (anclas_continuidad >= 0 AND anclas_continuidad <= 10000);

-- codigos_premium_desbloqueados solo puede contener códigos que realmente
-- existen en el catálogo de códigos premium (no strings inventados).
CREATE OR REPLACE FUNCTION public.enforce_codigos_premium_desbloqueados()
RETURNS TRIGGER AS $$
DECLARE
  v_invalidos TEXT[];
BEGIN
  IF auth.role() = 'service_role' THEN
    RETURN NEW;
  END IF;

  IF NEW.codigos_premium_desbloqueados IS NOT NULL AND array_length(NEW.codigos_premium_desbloqueados, 1) > 0 THEN
    SELECT array_agg(c) INTO v_invalidos
    FROM unnest(NEW.codigos_premium_desbloqueados) AS c
    WHERE c NOT IN (SELECT codigo FROM public.codigos_premium);

    IF v_invalidos IS NOT NULL THEN
      RAISE EXCEPTION 'codigos_premium_desbloqueados contiene códigos inválidos: %', v_invalidos;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trigger_enforce_codigos_premium_desbloqueados ON public.user_rewards;
CREATE TRIGGER trigger_enforce_codigos_premium_desbloqueados
  BEFORE INSERT OR UPDATE ON public.user_rewards
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_codigos_premium_desbloqueados();
