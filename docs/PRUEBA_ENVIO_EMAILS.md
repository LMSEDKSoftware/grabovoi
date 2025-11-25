# 🧪 Guía para Probar el Envío de Emails

## 📋 Scripts Disponibles

Se han creado dos scripts para probar el envío de emails sin necesidad de usar la APK:

### 1. Prueba a través de la función de Supabase

**Script:** `scripts/test_send_email.sh`

Este script invoca la función `send-otp` desplegada en Supabase, que es la misma que usa la app.

**Uso:**
```bash
./scripts/test_send_email.sh tu-email@ejemplo.com
```

**Qué hace:**
- Llama a la función `send-otp` en Supabase
- La función genera un OTP y lo envía por email usando SendGrid
- Muestra la respuesta de la función

**Requisitos:**
- Variables en `.env`: `SUPABASE_URL` y `SUPABASE_ANON_KEY`
- Variables en Supabase Dashboard: `SENDGRID_API_KEY`, `SENDGRID_FROM_EMAIL`, `SENDGRID_FROM_NAME`

### 2. Prueba directa con SendGrid

**Script:** `scripts/test_send_email_direct.sh`

Este script envía un email directamente usando la API de SendGrid, sin pasar por Supabase. Útil para verificar que SendGrid esté configurado correctamente.

**Uso:**
```bash
./scripts/test_send_email_direct.sh tu-email@ejemplo.com
```

**Qué hace:**
- Envía un email directamente a través de la API de SendGrid
- Usa el API Key del archivo `.env` local
- Genera un email de prueba con un OTP de ejemplo

**Requisitos:**
- Variables en `.env`: `SENDGRID_API_KEY`, `SENDGRID_FROM_EMAIL`, `SENDGRID_FROM_NAME`

## 🔍 Diagnóstico de Problemas

### Si el script 1 falla (función de Supabase):

1. **Verifica las variables en Supabase:**
   - Ve a: Supabase Dashboard → Settings → Edge Functions → Secrets
   - Confirma que existan: `SENDGRID_API_KEY`, `SENDGRID_FROM_EMAIL`, `SENDGRID_FROM_NAME`

2. **Verifica los logs de la función:**
   - Ve a: Supabase Dashboard → Edge Functions → send-otp → Logs
   - Busca errores relacionados con SendGrid

3. **Verifica que la función esté desplegada:**
   ```bash
   supabase functions list
   ```

### Si el script 2 falla (SendGrid directo):

1. **Verifica el API Key:**
   - Confirma que `SENDGRID_API_KEY` en `.env` sea correcto
   - Debe comenzar con `SG.`
   - Debe tener permisos de "Mail Send"

2. **Verifica el email remitente:**
   - El email en `SENDGRID_FROM_EMAIL` debe estar verificado en SendGrid
   - Ve a: SendGrid Dashboard → Settings → Sender Authentication

3. **Revisa la actividad en SendGrid:**
   - Ve a: https://app.sendgrid.com/activity
   - Busca intentos de envío y errores

## 📝 Ejemplo de Uso

```bash
# Prueba 1: A través de la función de Supabase (recomendado)
./scripts/test_send_email.sh demo@ejemplo.com

# Prueba 2: Directo con SendGrid (para verificar configuración)
./scripts/test_send_email_direct.sh demo@ejemplo.com
```

## ✅ Verificación Exitosa

Si todo funciona correctamente:

1. **Script 1 (Supabase):**
   - Deberías ver: `"ok": true` en la respuesta
   - Deberías recibir un email con el código OTP

2. **Script 2 (SendGrid directo):**
   - Deberías ver: `✅ Email enviado exitosamente!`
   - Código HTTP: `202`
   - Deberías recibir un email de prueba

## 🚨 Errores Comunes

### Error: "Unauthorized" o "403 Forbidden"
- **Causa:** API Key inválida o sin permisos
- **Solución:** Verifica el API Key en SendGrid Dashboard

### Error: "Invalid email address"
- **Causa:** Email remitente no verificado
- **Solución:** Verifica el email en SendGrid → Sender Authentication

### Error: "Faltan variables de entorno"
- **Causa:** Variables no configuradas en Supabase
- **Solución:** Agrega las variables en Supabase Dashboard → Edge Functions → Secrets

### El email no llega
- Revisa la carpeta de spam
- Verifica que el email destino sea válido
- Revisa la actividad en SendGrid Dashboard

