-- Founders Edition (Origen 369) es un pago único vitalicio otorgado por el
-- admin (grant_founder en admin-users) tras confirmar el pago por Hotmart.
-- El trigger enforce_user_subscriptions_bounds() solo permitía 4 product_id
-- y limitaba expires_at a 400 días, lo que bloqueaba tanto el product_id
-- 'founders_edition_369' como su fecha de expiración lejana (2099, vitalicio).
CREATE OR REPLACE FUNCTION public.enforce_user_subscriptions_bounds()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- Las escrituras con service_role (edge functions, admin-users) no se acotan:
  -- ya pasaron su propia validación server-side.
  IF auth.role() = 'service_role' THEN
    RETURN NEW;
  END IF;

  IF NEW.product_id NOT IN ('subscription_monthly', 'subscription_yearly', 'manigrab_lovers_monthly', 'manigrab_lovers_yearly', 'founders_edition_369') THEN
    RAISE EXCEPTION 'product_id inválido: %', NEW.product_id;
  END IF;

  -- Founders Edition es vitalicio por diseño; el resto de productos siguen
  -- acotados a 400 días.
  IF NEW.is_active AND NEW.product_id <> 'founders_edition_369' AND NEW.expires_at > (now() + interval '400 days') THEN
    RAISE EXCEPTION 'expires_at fuera de rango permitido (máx. 400 días)';
  END IF;

  RETURN NEW;
END;
$function$;
