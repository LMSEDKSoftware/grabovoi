# 📧 Configuración de SendGrid para Envío de Emails

## ✅ Cambios Realizados

1. **Mensaje de registro corregido**: Ahora solo pide iniciar sesión, no confirmar email
2. **Integración de SendGrid**: La función `send-otp` ahora envía emails usando SendGrid

## 🔧 Configuración Requerida en Supabase

Para que SendGrid funcione correctamente, necesitas configurar las siguientes variables de entorno en tu proyecto de Supabase:

### 1. Variables de Entorno en Supabase Dashboard

Ve a: **Supabase Dashboard → Settings → Edge Functions → Secrets**

Agrega las siguientes variables:

```
SENDGRID_API_KEY=SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SENDGRID_FROM_EMAIL=noreply@manigrab.com
SENDGRID_FROM_NAME=ManiGrab
```

**Nota**: El `SENDGRID_API_KEY` debe ser el API Key completo que proporcionaste (debe comenzar con `SG.`)

### 2. Verificar Dominio en SendGrid (Opcional pero Recomendado)

Para mejorar la deliverabilidad de los emails:

1. Ve a **SendGrid Dashboard → Settings → Sender Authentication**
2. Verifica tu dominio `manigrab.com` (o el dominio que uses)
3. Esto mejora la tasa de entrega y evita que los emails vayan a spam

### 3. Configurar Email Remitente

En SendGrid:
1. Ve a **Settings → Sender Authentication → Single Sender Verification**
2. Agrega el email `noreply@manigrab.com` (o el que uses)
3. Verifica el email

### 4. Desplegar la Función Actualizada

Después de configurar las variables de entorno, despliega la función actualizada:

```bash
# Desde la raíz del proyecto
supabase functions deploy send-otp
```

## 📋 Variables Necesarias

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `SENDGRID_API_KEY` | API Key de SendGrid (completo, comienza con SG.) | `SG.xxxxxxxx...` |
| `SENDGRID_FROM_EMAIL` | Email remitente (debe estar verificado en SendGrid) | `noreply@manigrab.com` |
| `SENDGRID_FROM_NAME` | Nombre que aparece como remitente | `ManiGrab` |

## 🧪 Probar el Envío

Una vez configurado:

1. Solicita recuperación de contraseña desde la app
2. Verifica que el email llegue a la bandeja de entrada
3. Si no llega, revisa la carpeta de spam
4. Revisa los logs en SendGrid Dashboard → Activity

## ⚠️ Troubleshooting

### Los emails no llegan

1. **Verifica que las variables estén configuradas correctamente**:
   - Ve a Supabase Dashboard → Settings → Edge Functions → Secrets
   - Confirma que `SENDGRID_API_KEY`, `SENDGRID_FROM_EMAIL` y `SENDGRID_FROM_NAME` estén presentes

2. **Verifica el API Key en SendGrid**:
   - Ve a SendGrid Dashboard → Settings → API Keys
   - Confirma que el API Key tenga permisos de "Mail Send"
   - Si es necesario, crea uno nuevo con permisos completos

3. **Revisa los logs de la función**:
   ```bash
   supabase functions logs send-otp
   ```

4. **Verifica el email remitente**:
   - El email en `SENDGRID_FROM_EMAIL` debe estar verificado en SendGrid
   - Ve a SendGrid Dashboard → Settings → Sender Authentication

### Error: "Unauthorized" o "403 Forbidden"

- Verifica que el API Key tenga permisos de "Mail Send"
- Confirma que el API Key esté activo (no revocado)

### Error: "Invalid email address"

- Verifica que el email remitente esté verificado en SendGrid
- Confirma que el formato del email sea correcto

## 📝 Notas Adicionales

- En desarrollo local, la función aún retorna el OTP en la respuesta para facilitar pruebas
- En producción, el OTP solo se envía por email
- Los emails tienen un diseño HTML profesional con el branding de ManiGrab
- El OTP expira en 10 minutos

