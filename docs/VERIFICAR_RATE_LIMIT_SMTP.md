# Verificación de Rate Limit y SMTP en Supabase

## Problema
Se está mostrando el error "Se han enviado demasiados correos" aunque el SMTP esté configurado.

## Causas Posibles

### 1. Rate Limit de Supabase
Supabase tiene un límite de **100 emails por hora** por defecto. Si se hacen múltiples intentos de registro, se puede alcanzar este límite rápidamente.

### 2. Configuración de SMTP
Aunque el SMTP esté configurado, el rate limit sigue aplicándose para proteger contra spam.

## Verificaciones en Supabase Dashboard

### 1. Verificar Configuración de SMTP
1. Ve a **Supabase Dashboard → Settings → Auth → SMTP Settings**
2. Verifica que:
   - SMTP esté habilitado
   - Host, puerto, usuario y contraseña estén correctos
   - El email remitente esté verificado

### 2. Verificar Rate Limits
1. Ve a **Supabase Dashboard → Settings → Auth → Rate Limits**
2. Verifica los límites actuales:
   - **Email sent**: 100 por hora (por defecto)
   - **Sign up/Sign in**: 30 por 5 minutos por IP

### 3. Aumentar Rate Limit (si es necesario)
Si necesitas más capacidad, puedes:
1. Ir a **Settings → Auth → Rate Limits**
2. Aumentar el límite de `email_sent` (ej: 200 o 500 por hora)
3. **Nota**: Esto depende de tu plan de Supabase

### 4. Verificar Logs de Auth
1. Ve a **Supabase Dashboard → Logs → Auth Logs**
2. Busca errores relacionados con:
   - Rate limiting
   - SMTP failures
   - Email sending errors

## Solución Implementada en el Código

El código ahora:
1. **Detecta errores de rate limit** y verifica si el usuario se creó
2. **Si el usuario existe**, continúa sin mostrar error
3. **Solo muestra error** si el registro realmente falló

## Recomendaciones

### Opción 1: Aumentar Rate Limit
Si tienes muchos registros, aumenta el límite en Supabase Dashboard.

### Opción 2: Deshabilitar Confirmación de Email (Temporal)
Si no necesitas confirmación de email inmediata:
1. Ve a **Settings → Auth → Email**
2. Deshabilita `Enable email confirmations`
3. Los usuarios podrán iniciar sesión sin confirmar email

### Opción 3: Usar Email de Prueba
Para desarrollo, puedes usar el email testing server de Supabase local.

## Verificar Estado Actual

Para verificar el estado actual del rate limit:
1. Ve a **Supabase Dashboard → Settings → Auth**
2. Revisa la sección "Rate Limits"
3. Verifica cuántos emails se han enviado en la última hora

## Notas Importantes

- El rate limit es una protección contra spam y abuso
- Aunque el SMTP esté configurado, el rate limit sigue aplicándose
- El código ahora maneja el rate limit de manera más inteligente
- Si el usuario se creó exitosamente, no se mostrará error aunque falle el email

