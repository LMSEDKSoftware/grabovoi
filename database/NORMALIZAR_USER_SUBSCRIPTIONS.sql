-- NORMALIZAR_USER_SUBSCRIPTIONS.sql
-- Objetivo:
--   - Garantizar que haya como máximo UNA fila "principal" por usuario en user_subscriptions
--   - Mantener la suscripción más relevante (la que expira más tarde)
--   - Marcar todas las demás como is_active = false
--   - (Opcional) Eliminar definitivamente duplicados inactivos antiguos
--
-- IMPORTANTE:
--   - Ejecuta este script en el editor SQL de Supabase
--   - Revisa el SELECT previo antes de aplicar los UPDATE/DELETE

BEGIN;

-- 1) Ver qué fila quedaría como principal por usuario
WITH ranked AS (
  SELECT
    id,
    user_id,
    product_id,
    purchase_id,
    expires_at,
    is_active,
    ROW_NUMBER() OVER (
      PARTITION BY user_id
      ORDER BY expires_at DESC, created_at DESC
    ) AS rn
  FROM user_subscriptions
)
SELECT *
FROM ranked
WHERE rn = 1;

-- 2) Desactivar TODAS las filas que NO sean la principal por usuario
WITH ranked AS (
  SELECT
    id,
    user_id,
    ROW_NUMBER() OVER (
      PARTITION BY user_id
      ORDER BY expires_at DESC, created_at DESC
    ) AS rn
  FROM user_subscriptions
)
UPDATE user_subscriptions u
SET is_active = FALSE
FROM ranked r
WHERE u.id = r.id
  AND r.rn > 1  -- todas menos la principal
  AND u.is_active = TRUE;

-- 3) Forzar que la fila principal por usuario quede marcada como activa
WITH ranked AS (
  SELECT
    id,
    user_id,
    ROW_NUMBER() OVER (
      PARTITION BY user_id
      ORDER BY expires_at DESC, created_at DESC
    ) AS rn
  FROM user_subscriptions
)
UPDATE user_subscriptions u
SET is_active = TRUE
FROM ranked r
WHERE u.id = r.id
  AND r.rn = 1;

-- 4) (OPCIONAL) Eliminar duplicados antiguos inactivos
--    Si prefieres conservar histórico, comenta este bloque antes de ejecutar.
-- DELETE FROM user_subscriptions u
-- USING (
--   SELECT
--     id,
--     user_id,
--     ROW_NUMBER() OVER (
--       PARTITION BY user_id
--       ORDER BY expires_at DESC, created_at DESC
--     ) AS rn
--   FROM user_subscriptions
-- ) r
-- WHERE u.id = r.id
--   AND r.rn > 1
--   AND u.is_active = FALSE;

COMMIT;

