# Por qué reaparece el registro al borrarlo y validación “suscripción vigente”

## Por qué se “vuelve a crear” el registro

1. **Borras el registro de `subscription_yearly` en Supabase** para probar.
2. En el dispositivo/sesión **sigue existiendo la compra en Google Play** (la licencia anual).
3. Al abrir la app o al hacer **Restaurar compras**, el plugin de In-App Purchase **vuelve a devolver** esa compra desde Play.
4. Nuestro código recibe esa compra (yearly) y:
   - Busca una fila con ese `purchase_id` → no hay (la borraste).
   - Antes: buscaba “cualquier fila del usuario” y **reutilizaba** esa fila actualizándola a yearly (por ejemplo, la mensual pasaba a anual). Por eso “vuelve a aparecer” el yearly: es la misma fila que antes era mensual, ahora sobrescrita a anual.

Es decir: no es que se haga un INSERT nuevo siempre; a veces es un **UPDATE** de la fila que quedó (p. ej. la mensual) convirtiéndola en anual. El efecto es que “vuelve” el yearly aunque hayas borrado su fila.

## Regla que pediste

- Si el usuario **ya tiene una suscripción vigente** (alguna fila con `expires_at` > ahora), **no** se debe:
  - insertar otra fila nueva, ni
  - sobrescribir esa vigente con otra (p. ej. no pasar de monthly vigente a yearly).

Ejemplo:  
`subscription_monthly` vigente hasta 2026-02-28 → **no** se debe insertar ni activar `subscription_yearly` hasta 2027-01-29.

## Cambio implementado en `subscription_service.dart`

1. **Backup:**  
   `backups/20260129_validar_suscripcion_vigente/subscription_service.dart`

2. **Nueva validación (paso 2b):**  
   Cuando **no** existe una fila para el `purchase_id` que llega de Play:
   - Se consulta si el usuario tiene **alguna suscripción vigente**:  
     `user_subscriptions` con `user_id` = usuario y `expires_at` > ahora.
   - Si **sí** hay una vigente:
     - **No** se inserta una nueva fila.
     - **No** se sobrescribe esa fila vigente con el otro producto.
     - Se hace `return` y se mantiene el estado local con la suscripción vigente que ya había.
   - Si **no** hay ninguna vigente:
     - Se sigue como antes: reutilizar una fila existente (expirada) o insertar una nueva si no hay ninguna.

3. **Orden de la lógica:**
   - 2a) Existe fila con este `purchase_id` → actualizar esa fila (refrescar fechas, etc.).
   - 2b) **Nuevo:** Existe alguna fila vigente (`expires_at` > now) → no insertar ni sobrescribir; salir.
   - 2c) No hay vigente → reutilizar una fila existente (expirada) o insertar una sola fila nueva.

Con esto, si ya tienes un registro válido (p. ej. monthly hasta 2026-02-28), no se insertará otro ni se sustituirá por yearly hasta que esa vigencia termine.
