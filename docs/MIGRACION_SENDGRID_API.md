# Migración a SendGrid API para envío de correos (ManiGrab)

## Backups creados (punto de retorno)

- `lib/services/auth_service_simple.dart` → `backups/20251126_sendgrid_migracion/lib/services/auth_service_simple.dart`
- `lib/screens/auth/register_screen.dart` → `backups/20251126_sendgrid_migracion/lib/screens/auth/register_screen.dart`

> Si algo falla, puedes restaurar copiando estos archivos de vuelta a su ruta original.

## Objetivo de la maniobra

- Supabase **solo** crea usuarios en `auth.users`.
- Se **desactivan** los correos automáticos de Supabase Auth (confirmación, magic link, etc.).
- Todos los correos (bienvenida/confirmación, OTP, etc.) se envían vía **SendGrid API** usando Edge Functions.

## Edge Function nueva: `send-email`

- Archivo: `supabase/functions/send-email/index.ts`
- Responsabilidad: enviar correos de bienvenida/confirmación u otros, usando plantillas dinámicas de SendGrid.
- Variables usadas dentro de la función:
  - `SENDGRID_API_KEY`
  - `SENDGRID_FROM_EMAIL`
  - `SENDGRID_FROM_NAME`
  - `SENDGRID_TEMPLATE_WELCOME`
  - `SENDGRID_TEMPLATE_OTP`

## Pasos que debes hacer en Supabase Dashboard (manual)

1. **Authentication → Email**
   - Apagar:
     - `Enable email confirmations`
     - `Enable magic link login`
     - `Enable email verification`
     - `Enable email change confirmations`

2. **Project Settings → Functions → Environment Variables**
   - Definir:
     - `SENDGRID_API_KEY=...`
     - `SENDGRID_FROM_EMAIL=hola@manigrab.app`
     - `SENDGRID_FROM_NAME=ManiGrab`
     - `SENDGRID_TEMPLATE_WELCOME=<ID_PLANTILLA_SENDGRID>`
     - `SENDGRID_TEMPLATE_OTP=<ID_PLANTILLA_SENDGRID>`

3. Desplegar la función (desde tu terminal local):

```bash
supabase functions deploy send-email
```

## Cambios previstos en código

- `AuthServiceSimple.signUp` (archivo `lib/services/auth_service_simple.dart`)
  - Mantener la llamada a `supabase.auth.signUp`.
  - Después de crear correctamente el usuario:
    - Llamar a `supabase.functions.invoke('send-email', {...})` con:
      - `to`: email del usuario
      - `template`: `"welcome_or_confirm"`
      - `userId`: `response.user!.id`
  - Si la Edge Function devuelve error, lanzar una excepción controlada (`email_send_failed`) para que la UI muestre un mensaje genérico.

- `RegisterScreen` (archivo `lib/screens/auth/register_screen.dart`)
  - En `_signUp()`:
    - Si `signUp()` lanza `email_send_failed` → mostrar: `"Ocurrió un error enviando el correo. Intenta nuevamente."`.
    - Para otros errores, mantener el comportamiento actual (validaciones de email, contraseña, usuario existente, etc.).
  - En `_getErrorMessage`:
    - Eliminar mensajes específicos de SMTP / rate limit de Supabase.

## Estado actual

- Edge Function `send-email` ya creada en `supabase/functions/send-email/index.ts`.
- Backups de los archivos críticos generados.
- Pendiente (en código):
  - Ajustar `AuthServiceSimple.signUp` para usar `send-email`.
  - Simplificar manejo de errores en `RegisterScreen`.

