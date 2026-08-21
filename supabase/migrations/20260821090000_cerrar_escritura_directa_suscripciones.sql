-- Verificado directo contra las politicas reales de user_subscriptions:
-- INSERT y UPDATE solo exigian auth.uid() = user_id, sin ninguna otra
-- condicion. Eso significa que cualquier usuario autenticado podia
-- mandar la misma peticion que manda la app tras una compra real --
-- insertando is_active=true y expires_at a futuro -- y quedar premium
-- sin pagar. No hacia falta ni rootear el telefono, solo inspeccionar el
-- trafico de red o descompilar el APK.
--
-- El arreglo de verdad va en dos partes: la Edge Function
-- verify-purchase confirma la compra directo con Google Play antes de
-- escribir nada, y esta migracion cierra la puerta que dejaba escribir
-- sin pasar por ahi.

drop policy if exists "Users can insert their own subscriptions" on public.user_subscriptions;
drop policy if exists "Users can update their own subscriptions" on public.user_subscriptions;

-- No hay politica de INSERT para "authenticated": una fila premium nueva
-- solo la puede crear el service_role (verify-purchase, o el admin al
-- otorgar Founders Edition tras confirmar el pago en Hotmart).

-- UPDATE se deja, pero acotado a lo unico que subscription_service.dart
-- de verdad necesita hacer del lado del cliente: apagar una fila SUYA
-- que YA vencio (limpieza de checkSubscriptionStatus). using() exige que
-- la fila ya este vencida, with_check() exige que el resultado sea
-- is_active=false -- no hay forma de usar esto para extender una fecha
-- ni para reactivar nada.
create policy "Users can only deactivate their own expired subscriptions"
on public.user_subscriptions
for update
using (auth.uid() = user_id and expires_at < now())
with check (auth.uid() = user_id and is_active = false);
