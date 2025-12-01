# 📧 Servidor de Envío de Emails

Este directorio contiene los endpoints para enviar emails desde tu servidor con IP estática (manigrab.app).

## 🎯 Propósito

Resolver el problema de whitelist de IPs en SendGrid. En lugar de enviar emails directamente desde Supabase Edge Functions (que tienen IPs dinámicas), enviamos a través de tu servidor con IP estática.

## 📁 Archivos

- `email_endpoint.php` - Endpoint PHP para servidores con PHP
- `email_endpoint.js` - Endpoint Node.js/Express para servidores Node.js
- `README.md` - Esta documentación

## 🚀 Configuración

### Paso 1: Elegir el Endpoint

Elige el endpoint según tu stack:
- **PHP**: Usa `email_endpoint.php`
- **Node.js**: Usa `email_endpoint.js`

### Paso 2: Configurar Variables de Entorno

En tu servidor, configura estas variables:

```bash
# Token secreto para autenticación (genera uno seguro)
EMAIL_SERVER_SECRET=tu_token_secreto_muy_seguro_aqui

# Configuración de SendGrid
# ⚠️ IMPORTANTE: Configurar estas variables en el servidor o archivo .env
# No hardcodear claves en el código fuente
SENDGRID_API_KEY=tu_clave_api_sendgrid_aqui
SENDGRID_FROM_EMAIL=hola@em6490.manigrab.app
SENDGRID_FROM_NAME=ManiGrab
```

### Paso 3: Desplegar el Endpoint

#### Para PHP:
1. Sube `email_endpoint.php` a tu servidor
2. Configura la ruta: `https://manigrab.app/api/send-email`
3. Asegúrate de que PHP tenga acceso a `curl`

#### Para Node.js:
1. Instala dependencias: `npm install express node-fetch`
2. Sube `email_endpoint.js` a tu servidor
3. Ejecuta: `node email_endpoint.js` o usa PM2
4. Configura la ruta: `https://manigrab.app/api/send-email`

### Paso 4: Configurar en Supabase

En **Supabase Dashboard → Settings → Edge Functions → Secrets**, agrega:

```
EMAIL_SERVER_URL=https://manigrab.app/api/send-email
EMAIL_SERVER_SECRET=tu_token_secreto_muy_seguro_aqui
```

## 🔒 Seguridad

- ✅ El endpoint requiere autenticación con `EMAIL_SERVER_SECRET`
- ✅ Solo acepta POST requests
- ✅ Valida todos los campos requeridos
- ⚠️ **IMPORTANTE**: Usa HTTPS para proteger el token en tránsito

## 🧪 Probar el Endpoint

```bash
curl -X POST https://manigrab.app/api/send-email \
  -H "Authorization: Bearer tu_token_secreto_muy_seguro_aqui" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "test@ejemplo.com",
    "subject": "Prueba",
    "html": "<h1>Prueba</h1>"
  }'
```

## 📋 Formato de Request

```json
{
  "to": "email@ejemplo.com",
  "subject": "Asunto del email",
  "html": "<html>...</html>",
  "text": "Texto plano (opcional)"
}
```

## 📋 Formato de Response

**Éxito:**
```json
{
  "success": true,
  "message": "Email sent successfully"
}
```

**Error:**
```json
{
  "error": "Error description",
  "details": "..."
}
```

## 🔄 Flujo Completo

```
1. Usuario solicita OTP en la app
   ↓
2. App llama a Supabase Edge Function (send-otp)
   ↓
3. Edge Function genera OTP y lo guarda en BD
   ↓
4. Edge Function llama a tu servidor (manigrab.app/api/send-email)
   ↓
5. Tu servidor envía email usando SendGrid (desde IP estática)
   ↓
6. SendGrid entrega el email ✅
```

## ⚠️ Notas

- Si el servidor propio falla, la función intentará envío directo como fallback
- El OTP siempre se genera y guarda, independientemente del método de envío
- En desarrollo, el OTP se retorna en la respuesta para facilitar pruebas

