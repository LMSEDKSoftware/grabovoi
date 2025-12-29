# Solución: Subject Faltante y Token Expirado

## Problemas Identificados

### 1. Email sin Subject
**Síntoma**: El email llega pero no tiene subject.
**Causa**: El subject no se estaba pasando correctamente en el payload de SendGrid cuando se usa template dinámico.
**Solución**: ✅ Se agregó el subject tanto en `personalizations` como en el nivel raíz del payload.

### 2. Error: `otp_expired` / `access_denied`
**Síntoma**: El link redirige a `https://manigrab.app/auth/callback#error=access_denied&error_code=otp_expired`
**Causas Posibles**:
- El token de recuperación de Supabase expiró (válido por 1 hora)
- El token ya fue usado (los tokens de Supabase son de un solo uso)
- El `redirectTo` no está en la lista de URLs permitidas en Supabase Dashboard

## Cambios Realizados

### 1. Subject en Email (server/email_endpoint.php)
```php
// Ahora el subject se pasa tanto en personalizations como en nivel raíz
'subject' => $subject  // En personalizations (prioridad)
'subject' => $subject  // En nivel raíz (fallback)
```

### 2. Manejo de Errores en AuthCallbackScreen
- ✅ Detecta errores tanto en query parameters como en fragment (hash)
- ✅ Muestra mensaje claro cuando el token expiró
- ✅ Instruye al usuario a solicitar un nuevo link

### 3. Logging Mejorado
- ✅ Más logs en `send-otp` para debug del redirectTo
- ✅ Logs en PHP para verificar qué se envía a SendGrid

## Configuración Requerida en Supabase

### ⚠️ IMPORTANTE: Verificar Redirect URLs

1. Ve a **Supabase Dashboard** → **Authentication** → **URL Configuration**
2. Verifica que `https://manigrab.app/auth/callback` esté en **Redirect URLs**
3. Si no está, agrégalo:
   ```
   https://manigrab.app/auth/callback
   ```

### Verificar Site URL
1. En **Authentication** → **URL Configuration**
2. Verifica que **Site URL** sea: `https://manigrab.app`

## Verificar SendGrid Template

1. Ve a SendGrid Dashboard → **Email API** → **Dynamic Templates**
2. Abre el template `d-971362da419640f7be3c3cb7fae9881d`
3. Verifica que tenga configurado un **Subject** (puede ser estático o variable `{{subject}}`)

## Testing

1. **Prueba el flujo completo**:
   - Solicita recuperación de contraseña
   - Revisa que el email tenga subject
   - Haz clic en el link **inmediatamente** (antes de que expire)
   - Verifica que no aparezca el error de expiración

2. **Si aparece el error de expiración**:
   - Verifica que el `redirectTo` esté en la lista de URLs permitidas
   - Verifica que no hayas usado el link dos veces
   - Solicita un nuevo link y úsalo inmediatamente

## Notas

- Los tokens de recuperación de Supabase **expiran después de 1 hora**
- Los tokens son de **un solo uso** (una vez usado, no se puede usar de nuevo)
- Si el usuario solicita múltiples links, solo el **más reciente** es válido

