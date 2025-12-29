# 📧 Actualización: Plantillas SendGrid con Datos Dinámicos

## ✅ Resumen

Se actualizó la Edge Function `send-email` y el código de Flutter para enviar todos los datos dinámicos requeridos por las plantillas HTML de SendGrid.

---

## 📋 Datos Dinámicos Requeridos

### Correo de Bienvenida (`welcome_or_confirm`):
- `{{app_name}}` → "ManiGrab"
- `{{name}}` → Nombre del usuario
- `{{action_url}}` → URL de confirmación con token

### Correo OTP:
- `{{app_name}}` → "ManiGrab"
- `{{name}}` → Nombre del usuario
- `{{otp_code}}` → Código OTP de 6 dígitos

---

## 🔧 Cambios Realizados

### 1. Edge Function `send-email/index.ts`

**Cambios:**
- ✅ Ahora recibe: `to`, `template`, `userId`, `name`, `actionUrl`, `otpCode`
- ✅ Genera `action_url` con token de confirmación usando `supabaseAdmin.auth.admin.generateLink()`
- ✅ Envía todos los datos dinámicos a SendGrid en `dynamic_template_data`:
  - `app_name`: Desde variable de entorno `APP_NAME` (default: "ManiGrab")
  - `name`: Nombre del usuario
  - `action_url`: Link de confirmación generado (para welcome)
  - `otp_code`: Código OTP (para OTP)

**Variables de entorno requeridas:**
- `SENDGRID_API_KEY` ✅
- `SENDGRID_FROM_EMAIL` ✅
- `SENDGRID_FROM_NAME` ✅
- `SENDGRID_TEMPLATE_WELCOME` ✅
- `SENDGRID_TEMPLATE_OTP` ✅
- `SUPABASE_URL` ✅
- `SUPABASE_SERVICE_ROLE_KEY` ✅
- `APP_NAME` (opcional, default: "ManiGrab") ⚠️ **NUEVA**

---

### 2. Flutter `auth_service_simple.dart`

**Cambios:**
- ✅ En `signUp()`, ahora envía `name` y `actionUrl` a la Edge Function
- ✅ Construye `actionUrl` según el entorno (desarrollo vs producción)
- ✅ En desarrollo: `http://localhost/auth/callback`
- ✅ En producción: `https://manigrab.app/auth/callback`
- ✅ En móvil: `com.manifestacion.grabovoi://login-callback`

**Código actualizado:**
```dart
final res = await _supabase.functions.invoke('send-email', body: {
  'to': email,
  'template': 'welcome_or_confirm',
  'userId': user.id,
  'name': name,  // ✅ NUEVO
  'actionUrl': actionUrl,  // ✅ NUEVO
});
```

---

## 📝 Configuración en SendGrid

### Plantilla de Bienvenida

Asegúrate de que tu plantilla en SendGrid tenga estos placeholders:

```html
{{app_name}}
{{name}}
{{action_url}}
```

### Plantilla de OTP

Asegúrate de que tu plantilla en SendGrid tenga estos placeholders:

```html
{{app_name}}
{{name}}
{{otp_code}}
```

---

## 🔧 Variables de Entorno en Supabase

**IMPORTANTE:** Agrega esta variable en Supabase Dashboard → Project Settings → Edge Functions → Environment Variables:

```
APP_NAME=ManiGrab
```

O déjalo sin configurar y usará "ManiGrab" por defecto.

---

## ✅ Flujo Completo

### Registro de Usuario:

1. Usuario se registra con email, password y nombre
2. Supabase crea el usuario en `auth.users`
3. Flutter llama a `send-email` Edge Function con:
   - `to`: email del usuario
   - `template`: "welcome_or_confirm"
   - `userId`: ID del usuario
   - `name`: Nombre del usuario
   - `actionUrl`: URL de callback según entorno
4. Edge Function:
   - Genera link de confirmación con token usando `generateLink()`
   - Prepara `dynamic_template_data` con todos los datos
   - Envía email a SendGrid con el template ID
5. SendGrid reemplaza los placeholders y envía el correo
6. Usuario recibe correo con botón "Activar mi cuenta"
7. Usuario hace clic → redirige a `/auth/callback` con token
8. `AuthCallbackScreen` procesa el token y confirma el email

---

## 🧪 Pruebas

### Probar Correo de Bienvenida:

1. Registra un nuevo usuario
2. Verifica que recibas el correo con:
   - ✅ Tu nombre en el saludo
   - ✅ "ManiGrab" como nombre de la app
   - ✅ Botón "Activar mi cuenta" funcional
   - ✅ Link de confirmación válido

### Probar Correo OTP:

1. Solicita recuperación de contraseña
2. Verifica que recibas el correo con:
   - ✅ Tu nombre en el saludo
   - ✅ "ManiGrab" como nombre de la app
   - ✅ Código OTP de 6 dígitos visible

---

## 📅 Fecha de Implementación

26 de Noviembre, 2024

---

## 🐛 Troubleshooting

### El correo no muestra el nombre del usuario
- Verifica que estés enviando `name` desde Flutter
- Revisa los logs de la Edge Function

### El botón "Activar mi cuenta" no funciona
- Verifica que `action_url` se esté generando correctamente
- Revisa los logs de `generateLink()` en la Edge Function
- Verifica que la URL de callback esté en las URLs permitidas de Supabase

### El código OTP no aparece
- Verifica que estés enviando `otpCode` a la Edge Function
- Revisa que el template de SendGrid tenga `{{otp_code}}`

