# Configurar Variables de SendGrid en Supabase

## Problema Identificado

SendGrid funciona correctamente cuando se envía directamente, pero los emails no llegan cuando se envían a través de Supabase. Esto indica que las variables de entorno no están configuradas correctamente en Supabase.

## Solución: Configurar Secrets en Supabase

### Paso 1: Acceder a Supabase Dashboard

1. Ve a: https://supabase.com/dashboard/project/whtiazgcxdnemrrgjjqf/settings/functions
2. O navega: **Settings** → **Edge Functions** → **Secrets**

### Paso 2: Agregar las Variables

Haz clic en **"Add new secret"** y agrega cada una de las siguientes variables:

#### Variable 1: SENDGRID_API_KEY
- **Nombre:** `SENDGRID_API_KEY`
- **Valor:** `[TU_API_KEY_DE_SENDGRID]` (obtener de SendGrid Dashboard, formato: SG.xxxxxxxxxxxxxxxx...)
- **Descripción:** API Key de SendGrid para envío de emails

#### Variable 2: SENDGRID_FROM_EMAIL
- **Nombre:** `SENDGRID_FROM_EMAIL`
- **Valor:** `hola@manigrab.app`
- **Descripción:** Email remitente verificado en SendGrid

#### Variable 3: SENDGRID_FROM_NAME
- **Nombre:** `SENDGRID_FROM_NAME`
- **Valor:** `ManiGrab`
- **Descripción:** Nombre del remitente

### Paso 3: Verificar la Configuración

Después de agregar las variables:

1. Espera unos segundos para que Supabase reinicie la función
2. Ejecuta una prueba:
   ```bash
   ./scripts/test_send_email.sh tu-email@ejemplo.com
   ```
3. Revisa los logs en Supabase Dashboard → Functions → send-otp → Logs
4. Busca mensajes como:
   - `✅ Email enviado correctamente con SendGrid` (éxito)
   - `❌ Error enviando email con SendGrid` (error)
   - `⚠️ SENDGRID_API_KEY no configurada` (falta configuración)

### Paso 4: Verificar en SendGrid Activity

1. Ve a: https://app.sendgrid.com/activity
2. Busca los emails enviados recientemente
3. Verifica el estado:
   - **Processed/Delivered** = ✅ Email enviado correctamente
   - **Bounced** = ⚠️ Email rebotó (dirección inválida)
   - **Blocked/Failed** = ❌ Error al enviar

## Comandos Útiles

### Probar envío a través de Supabase
```bash
./scripts/test_send_email.sh tu-email@ejemplo.com
```

### Probar envío directo con SendGrid (sin Supabase)
```bash
./scripts/test_sendgrid_directo.sh
```

### Verificar configuración
```bash
./scripts/verificar_supabase_sendgrid.sh
```

## Notas Importantes

- Las variables de entorno en Supabase son **secrets** y no se pueden leer desde el código
- Después de agregar/modificar secrets, la función se reinicia automáticamente
- Los secrets son específicos por proyecto de Supabase
- Asegúrate de que el email remitente (`hola@manigrab.app`) esté verificado en SendGrid

## Troubleshooting

### Si los emails no llegan después de configurar:

1. **Verifica los logs de Supabase:**
   - Ve a Functions → send-otp → Logs
   - Busca errores específicos

2. **Verifica SendGrid Activity:**
   - Ve a https://app.sendgrid.com/activity
   - Busca intentos de envío recientes
   - Revisa el estado y los errores

3. **Verifica que las variables estén correctas:**
   - Revisa que no haya espacios extra
   - Verifica que el API Key esté completo
   - Confirma que el email remitente esté verificado

4. **Prueba envío directo:**
   ```bash
   ./scripts/test_sendgrid_directo.sh
   ```
   Si esto funciona pero Supabase no, el problema está en la configuración de Supabase.



