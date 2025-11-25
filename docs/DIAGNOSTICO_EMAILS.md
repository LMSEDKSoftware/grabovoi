# Diagnóstico de Problemas con Envío de Emails

## Problema Actual
- ✅ SendGrid funciona correctamente (prueba directa exitosa)
- ✅ Variables configuradas en Supabase Secrets
- ✅ Función responde `{"ok": true}`
- ❌ Emails no llegan al destinatario

## Posibles Causas

### 1. Usuario no existe en Supabase Auth
La función verifica si el usuario existe antes de enviar el email. Si el email no está registrado en Supabase Auth, la función responde `{"ok": true}` pero no envía el email.

**Solución:** Asegúrate de que el email esté registrado en Supabase Auth.

### 2. Variables de entorno incorrectas
Aunque las variables estén configuradas, pueden tener valores incorrectos o incompletos.

**Verificación:**
- Revisa los logs de Supabase para ver:
  - `🔍 Verificando configuración SendGrid...`
  - `API Key presente: true/false`
  - `From Email: ...`
  - `From Name: ...`

### 3. Dominio remitente no verificado
El dominio `manigrab.app` debe estar completamente verificado en SendGrid.

**Verificación en SendGrid:**
1. Ve a SendGrid Dashboard → Settings → Sender Authentication
2. Verifica que `manigrab.app` esté autenticado
3. Verifica que `hola@manigrab.app` esté verificado como Single Sender

### 4. Logs no muestran ejecución
Si solo ves logs de "booted" y "shutdown" pero no de ejecución, puede ser que:
- La función se esté cerrando antes de completar
- Los logs de ejecución no se estén capturando

**Solución:** La función ahora tiene logging mejorado. Revisa los logs después de ejecutar una prueba.

## Pasos de Diagnóstico

### Paso 1: Verificar Logs de Ejecución
1. Ve a Supabase Dashboard → Functions → send-otp → Logs
2. Ejecuta una prueba: `./scripts/test_send_email.sh 2005.ivan@gmail.com`
3. Busca en los logs:
   - `🚀 Función send-otp invocada`
   - `📧 Email recibido: ...`
   - `👤 Usuario existe en auth: true/false`
   - `🔍 Verificando configuración SendGrid...`
   - `✅ Email enviado correctamente con SendGrid` o `❌ Error enviando email`

### Paso 2: Verificar Usuario en Supabase Auth
1. Ve a Supabase Dashboard → Authentication → Users
2. Busca el email `2005.ivan@gmail.com`
3. Si no existe, créalo o usa un email que sí esté registrado

### Paso 3: Verificar SendGrid Activity
1. Ve a https://app.sendgrid.com/activity
2. Busca intentos de envío recientes
3. Verifica el estado de cada intento

### Paso 4: Probar con Email Registrado
Si el email de prueba no está registrado, prueba con uno que sí lo esté:
```bash
./scripts/test_send_email.sh email-registrado@ejemplo.com
```

## Comandos Útiles

### Probar envío a través de Supabase
```bash
./scripts/test_send_email.sh tu-email@ejemplo.com
```

### Probar envío directo (sin Supabase)
```bash
./scripts/test_sendgrid_directo.sh
```

### Verificar configuración
```bash
./scripts/verificar_supabase_sendgrid.sh
```

## Próximos Pasos

1. Revisa los logs de Supabase después de ejecutar una prueba
2. Verifica si el email está registrado en Supabase Auth
3. Si el email no está registrado, prueba con uno que sí lo esté
4. Revisa SendGrid Activity para ver si hay intentos de envío



