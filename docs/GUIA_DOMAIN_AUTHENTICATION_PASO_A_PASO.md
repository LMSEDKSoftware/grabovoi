# Guía Paso a Paso: Configurar Domain Authentication en SendGrid

## Objetivo
Configurar Domain Authentication para `manigrab.app` en SendGrid, permitiendo enviar emails desde cualquier IP sin necesidad de whitelist.

---

## Paso 1: Acceder a SendGrid Dashboard

1. Abre tu navegador y ve a: **https://app.sendgrid.com**
2. Inicia sesión con tus credenciales de SendGrid
3. Una vez dentro, verás el dashboard principal

---

## Paso 2: Navegar a Sender Authentication

1. En el menú lateral izquierdo, busca y haz clic en **"Settings"** (Configuración)
2. En el submenú que aparece, haz clic en **"Sender Authentication"**
3. O accede directamente a: **https://app.sendgrid.com/settings/sender_auth**

---

## Paso 3: Iniciar Domain Authentication

1. En la página de Sender Authentication, verás varias opciones
2. Busca la sección **"Domain Authentication"** o **"Authenticate Your Domain"**
3. Haz clic en el botón **"Authenticate Your Domain"** o **"Get Started"**

---

## Paso 4: Ingresar Información del Dominio

1. SendGrid te pedirá información sobre tu dominio:
   - **Domain:** Ingresa `manigrab.app` (sin www, sin http/https)
   - **Subdomain:** Deja en blanco (a menos que quieras usar un subdominio específico)
   - **Brand Link:** Opcional, puede ser `manigrab.app`

2. Selecciona el tipo de DNS:
   - **Automatic Security** (Recomendado) - SendGrid configura todo automáticamente
   - **Custom** - Si prefieres configuración manual

3. Haz clic en **"Next"** o **"Continue"**

---

## Paso 5: Obtener Registros DNS

SendGrid te mostrará una lista de registros DNS que debes agregar a tu dominio. **IMPORTANTE:** Copia todos estos registros, los necesitarás en el siguiente paso.

### Tipos de Registros que Verás:

#### 1. CNAME Records (para verificación y tracking)
Ejemplo:
```
Name: em1234.manigrab.app
Value: u1234567.wl123.sendgrid.net
```

#### 2. DKIM Records (CNAME)
Ejemplo:
```
Name: s1._domainkey.manigrab.app
Value: s1.domainkey.u1234567.wl123.sendgrid.net

Name: s2._domainkey.manigrab.app
Value: s2.domainkey.u1234567.wl123.sendgrid.net
```

#### 3. SPF Record (TXT)
Ejemplo:
```
Name: manigrab.app
Value: v=spf1 include:sendgrid.net ~all
```

#### 4. DMARC Record (TXT) - Opcional pero recomendado
Ejemplo:
```
Name: _dmarc.manigrab.app
Value: v=DMARC1; p=none; rua=mailto:dmarc@manigrab.app
```

**⚠️ IMPORTANTE:** Los valores exactos serán diferentes para tu cuenta. Copia los valores que SendGrid te muestre.

---

## Paso 6: Acceder a tu Proveedor de DNS

Necesitas acceder al panel de control donde está configurado el dominio `manigrab.app`.

### ¿Dónde está tu DNS?

- **Cloudflare:** https://dash.cloudflare.com
- **GoDaddy:** https://www.godaddy.com → Mis Productos → DNS
- **Namecheap:** https://www.namecheap.com → Domain List → Manage
- **AWS Route 53:** https://console.aws.amazon.com/route53
- **Google Domains:** https://domains.google.com
- **Otro proveedor:** Busca en tu panel de control la sección "DNS" o "Zone Records"

---

## Paso 7: Agregar Registros DNS

En tu proveedor de DNS, agrega cada registro que SendGrid te proporcionó:

### Para cada CNAME Record:

1. Haz clic en **"Add Record"** o **"Add DNS Record"**
2. Selecciona el tipo: **CNAME**
3. Ingresa:
   - **Name/Host:** El nombre que SendGrid te dio (ej: `em1234` o `em1234.manigrab.app`)
   - **Value/Target:** El valor que SendGrid te dio (ej: `u1234567.wl123.sendgrid.net`)
   - **TTL:** Deja el valor por defecto (usualmente 3600 o Auto)

4. Haz clic en **"Save"** o **"Add Record"**

### Para cada TXT Record (SPF y DMARC):

1. Haz clic en **"Add Record"** o **"Add DNS Record"**
2. Selecciona el tipo: **TXT**
3. Ingresa:
   - **Name/Host:** El nombre que SendGrid te dio (ej: `manigrab.app` o `@`)
   - **Value:** El valor que SendGrid te dio (ej: `v=spf1 include:sendgrid.net ~all`)
   - **TTL:** Deja el valor por defecto

4. Haz clic en **"Save"** o **"Add Record"**

### Ejemplo Visual (Cloudflare):

```
Type: CNAME
Name: em1234
Target: u1234567.wl123.sendgrid.net
Proxy status: DNS only (no proxy)
TTL: Auto
```

---

## Paso 8: Esperar Propagación DNS

Después de agregar los registros DNS:

1. **Espera 5-15 minutos** para que los cambios se propaguen
2. Puedes verificar la propagación usando herramientas online:
   - **https://mxtoolbox.com/SuperTool.aspx**
   - **https://www.whatsmydns.net/**
   - O desde la terminal:
     ```bash
     dig em1234.manigrab.app CNAME
     dig s1._domainkey.manigrab.app CNAME
     dig manigrab.app TXT
     ```

---

## Paso 9: Verificar en SendGrid

1. Regresa a SendGrid Dashboard → Settings → Sender Authentication
2. Encuentra tu dominio `manigrab.app` en la lista
3. Haz clic en el botón **"Verify"** o **"Check DNS"**
4. SendGrid verificará automáticamente todos los registros DNS

### Resultados Posibles:

- ✅ **"Authenticated"** o **"Verified"** - ¡Perfecto! El dominio está listo
- ⚠️ **"Pending"** o **"Verifying"** - Espera unos minutos y vuelve a verificar
- ❌ **"Failed"** - Revisa que todos los registros DNS estén correctamente agregados

---

## Paso 10: Verificar que los Registros Estén Correctos

Si la verificación falla, verifica cada registro:

### Verificar CNAME Records:
```bash
dig em1234.manigrab.app CNAME
# Debe mostrar el valor de SendGrid
```

### Verificar DKIM Records:
```bash
dig s1._domainkey.manigrab.app CNAME
dig s2._domainkey.manigrab.app CNAME
# Deben mostrar los valores de SendGrid
```

### Verificar SPF Record:
```bash
dig manigrab.app TXT
# Debe incluir "include:sendgrid.net"
```

---

## Paso 11: Configurar la Función send-otp (Ya está hecho)

La función `send-otp` ya está configurada para usar `hola@manigrab.app`. No necesitas cambiar nada en el código.

---

## Paso 12: Probar el Envío

Una vez que el dominio esté verificado:

1. Ejecuta la prueba:
   ```bash
   ./scripts/test_send_email.sh 2005.ivan@gmail.com
   ```

2. Revisa los logs de Supabase:
   - Debe aparecer: `✅ Email enviado correctamente con SendGrid`
   - NO debe aparecer: `❌ Error enviando email con SendGrid` o `IP not whitelisted`

3. Revisa SendGrid Activity:
   - Ve a: https://app.sendgrid.com/activity
   - Busca el email enviado
   - Debe aparecer como **"Processed"** o **"Delivered"**

4. Revisa tu bandeja de entrada:
   - El email debe llegar a `2005.ivan@gmail.com`
   - Revisa también spam si no aparece

---

## Paso 13: Desactivar Whitelist (Opcional)

Una vez que Domain Authentication esté funcionando correctamente:

1. Ve a SendGrid Dashboard → Settings → IP Access Management
2. Puedes:
   - **Mantener la whitelist** como respaldo (recomendado)
   - **Desactivar la whitelist** si prefieres (solo si Domain Authentication está completamente verificado)

---

## Troubleshooting

### El dominio no se verifica

**Problema:** SendGrid dice que los registros DNS no están correctos.

**Solución:**
1. Verifica que todos los registros estén agregados correctamente
2. Asegúrate de que los nombres y valores coincidan exactamente con lo que SendGrid te dio
3. Espera más tiempo para la propagación DNS (puede tardar hasta 48 horas, pero usualmente es más rápido)
4. Usa herramientas de verificación DNS para confirmar que los registros están activos

### Los emails aún no llegan

**Problema:** El dominio está verificado pero los emails no llegan.

**Solución:**
1. Verifica que estés usando el email correcto: `hola@manigrab.app`
2. Revisa SendGrid Activity para ver el estado de los envíos
3. Revisa los logs de Supabase para errores
4. Asegúrate de que Domain Authentication esté completamente verificado (debe aparecer como "Authenticated")

### Errores en los logs

**Problema:** Sigue apareciendo "IP not whitelisted" en los logs.

**Solución:**
1. Verifica que Domain Authentication esté completamente verificado
2. Espera unos minutos después de la verificación
3. Prueba de nuevo
4. Si persiste, contacta a SendGrid Support

---

## Resumen de Pasos

1. ✅ Acceder a SendGrid Dashboard
2. ✅ Ir a Sender Authentication
3. ✅ Iniciar Domain Authentication
4. ✅ Ingresar dominio `manigrab.app`
5. ✅ Obtener registros DNS de SendGrid
6. ✅ Acceder a proveedor de DNS
7. ✅ Agregar todos los registros DNS
8. ✅ Esperar propagación DNS (5-15 min)
9. ✅ Verificar en SendGrid
10. ✅ Probar envío de email
11. ✅ Verificar que funciona correctamente

---

## ¿Necesitas Ayuda?

Si tienes problemas en algún paso:

1. Revisa los logs de Supabase para ver errores específicos
2. Revisa SendGrid Activity para ver el estado de los envíos
3. Verifica que todos los registros DNS estén correctamente configurados
4. Contacta a SendGrid Support si el problema persiste

---

## Ventajas de Domain Authentication

Una vez configurado:

- ✅ **No más problemas con IPs dinámicas**
- ✅ **Mejor deliverability** (menos spam)
- ✅ **Más profesional** (usa tu dominio)
- ✅ **Sin mantenimiento** (funciona siempre)
- ✅ **Perfecto para serverless** (Supabase Edge Functions)

¡Buena suerte con la configuración! 🚀



