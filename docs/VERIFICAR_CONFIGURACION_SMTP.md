# ✅ Verificación de Configuración SMTP en Supabase

## Configuración Actual (Según Dashboard)

### ✅ Datos Correctos:
- **Host**: `smtp.sendgrid.net` ✅ (Correcto)
- **Port**: `587` ✅ (Correcto para TLS/STARTTLS)
- **Minimum interval per user**: `60 seconds` ✅ (Razonable)
- **SMTP habilitado**: ✅ (Toggle verde)

### ⚠️ Datos a Verificar:

1. **Sender email**: `hola@em6490.manigrab.app` ✅ (Ya está funcionando)
   - ✅ **Este email ya está verificado en SendGrid**
   - Ve a SendGrid Dashboard → Settings → Sender Authentication → Single Sender Verification
   - Verifica que `hola@em6490.manigrab.app` esté en la lista y esté verificado

2. **Sender name**: `ManiGrab`
   - ✅ Correcto

3. **Credenciales SMTP** (No visibles en la captura):
   - Debes tener configurado:
     - **Username**: `apikey` (para SendGrid)
     - **Password/API Key**: Tu API Key de SendGrid (debe comenzar con `SG.`)

## 🔍 Verificaciones Necesarias en SendGrid

### 1. Verificar Email Remitente
1. Ve a **SendGrid Dashboard → Settings → Sender Authentication**
2. Busca en **Single Sender Verification**
3. Verifica que `hola@em6490.manigrab.app` esté:
   - ✅ Agregado
   - ✅ Verificado (debe tener un check verde)
   - ✅ Activo

### 2. Verificar Dominio (Recomendado)
1. Ve a **SendGrid Dashboard → Settings → Sender Authentication**
2. Busca en **Domain Authentication**
3. Verifica que `manigrab.app` esté:
   - ✅ Verificado
   - ✅ Con todos los registros DNS configurados correctamente

### 3. Verificar API Key
1. Ve a **SendGrid Dashboard → Settings → API Keys**
2. Verifica que tengas un API Key con:
   - ✅ Permisos de "Mail Send" (Full Access o al menos Mail Send)
   - ✅ Estado activo (no revocado)
   - ✅ Este es el que debes usar como password en Supabase

## 📋 Configuración Completa en Supabase

En **Supabase Dashboard → Settings → Auth → SMTP Settings**, debes tener:

```
✅ Enable custom SMTP: ON (verde)
✅ Sender email address: hola@em6490.manigrab.app ✅ (Ya está funcionando)
✅ Sender name: ManiGrab
✅ Host: smtp.sendgrid.net
✅ Port number: 587
✅ Username: apikey
✅ Password: [Tu API Key de SendGrid que comienza con SG.]
✅ Minimum interval per user: 60 seconds
```

## ⚠️ Problemas Comunes

### Error: "Email not verified"
- **Solución**: Verifica el email `hola@manigrab.app` en SendGrid
- Ve a SendGrid → Sender Authentication → Single Sender Verification
- Si no está, agrégalo y verifícalo

### Error: "Authentication failed"
- **Solución**: Verifica que:
  - Username sea exactamente `apikey` (en minúsculas)
  - Password sea tu API Key completo de SendGrid (comienza con `SG.`)
  - El API Key tenga permisos de "Mail Send"

### Error: "Rate limit exceeded"
- **Solución**: 
  - El intervalo mínimo de 60 segundos está bien
  - Considera aumentar el rate limit en Supabase Dashboard → Settings → Auth → Rate Limits
  - Verifica cuántos emails se han enviado en la última hora

## 🧪 Probar la Configuración

1. **Desde Supabase Dashboard**:
   - Ve a **Settings → Auth → Email Templates**
   - Haz clic en "Send test email"
   - Verifica que llegue el email

2. **Desde la App**:
   - Intenta registrar un nuevo usuario
   - Verifica que llegue el email de confirmación
   - Revisa los logs en SendGrid Dashboard → Activity

## 📝 Notas Importantes

- El email remitente (`hola@manigrab.app`) **DEBE** estar verificado en SendGrid
- El API Key debe tener permisos de "Mail Send"
- El puerto 587 es correcto para TLS/STARTTLS
- El intervalo de 60 segundos previene spam pero puede causar rate limits si hay muchos registros

## 🔗 Referencias

- [SendGrid SMTP Settings](https://docs.sendgrid.com/for-developers/sending-email/getting-started-smtp)
- [Supabase SMTP Configuration](https://supabase.com/docs/guides/auth/auth-smtp)

