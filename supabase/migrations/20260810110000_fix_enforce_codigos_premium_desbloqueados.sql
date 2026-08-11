-- El trigger enforce_codigos_premium_desbloqueados() validaba cada entrada
-- de user_rewards.codigos_premium_desbloqueados contra la columna
-- codigos_premium.codigo (el string de la secuencia, ej. "777_777_777"),
-- pero la app SIEMPRE guarda y compara codigos_premium.id (ej. "premium_3")
-- en ese arreglo (ver RewardsService.comprarCodigoPremium y
-- PremiumStoreScreen, que usan codigo.id en todo el flujo). El resultado:
-- CUALQUIER compra de código premium fallaba con
-- "codigos_premium_desbloqueados contiene códigos inválidos: {premium_X}".
-- Se corrige el trigger para validar contra la columna id, que es lo que
-- la app realmente escribe y lee.
CREATE OR REPLACE FUNCTION public.enforce_codigos_premium_desbloqueados()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_invalidos TEXT[];
BEGIN
  IF auth.role() = 'service_role' THEN
    RETURN NEW;
  END IF;

  IF NEW.codigos_premium_desbloqueados IS NOT NULL AND array_length(NEW.codigos_premium_desbloqueados, 1) > 0 THEN
    SELECT array_agg(c) INTO v_invalidos
    FROM unnest(NEW.codigos_premium_desbloqueados) AS c
    WHERE c NOT IN (SELECT id FROM public.codigos_premium);

    IF v_invalidos IS NOT NULL THEN
      RAISE EXCEPTION 'codigos_premium_desbloqueados contiene códigos inválidos: %', v_invalidos;
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;
