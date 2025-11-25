# Configurar Domain Authentication en SendGrid

## ¿Por qué Domain Authentication?

Domain Authentication es más robusta que IP whitelist porque:
- ✅ Permite enviar desde cualquier IP usando el dominio autenticado
- ✅ Mejora la reputación del dominio
- ✅ Reduce la probabilidad de que los emails vayan a spam
- ✅ No requiere mantener una lista de IPs que pueden cambiar

## Pasos para Configurar Domain Authentication

### Paso 1: Acceder a SendGrid Dashboard

1. Ve a: https://app.sendgrid.com
2. Inicia sesión en tu cuenta

### Paso 2: Ir a Sender Authentication

1. En el menú lateral, ve a **Settings** → **Sender Authentication**
2. O accede directamente: https://app.sendgrid.com/settings/sender_auth

### Paso 3: Configurar Domain Authentication

1. Haz clic en **"Authenticate Your Domain"** o **"Add Domain"**
2. Selecciona el tipo de autenticación:
   - **Domain Authentication** (recomendado)
   - **Single Sender Verification** (alternativa más simple)

### Paso 4: Ingresar Información del Dominio

1. **Domain Name:** Ingresa `manigrab.app`
2. **Subdomain:** Deja en blanco o usa `mail` (opcional)
3. **Brand Link:** Opcional, puede ser `manigrab.app`

### Paso 5: Verificar el Dominio

SendGrid te proporcionará registros DNS que debes agregar a tu dominio:

**Registros DNS típicos:**
- **CNAME Records** para verificación
- **SPF Record** (TXT)
- **DKIM Records** (CNAME)
- **DMARC Record** (TXT) - opcional pero recomendado

**Ejemplo de registros:**
```
Type: CNAME
Name: em1234.manigrab.app
Value: u1234567.wl123.sendgrid.net

Type: CNAME
Name: s1._domainkey.manigrab.app
Value: s1.domainkey.u1234567.wl123.sendgrid.net

Type: CNAME
Name: s2._domainkey.manigrab.app
Value: s2.domainkey.u1234567.wl123.sendgrid.net

Type: TXT
Name: manigrab.app
Value: v=spf1 include:sendgrid.net ~all
```

### Paso 6: Agregar Registros DNS

1. Accede a tu proveedor de DNS (donde está configurado `manigrab.app`)
2. Agrega los registros DNS proporcionados por SendGrid
3. Espera a que se propaguen (puede tardar de minutos a horas)

### Paso 7: Verificar en SendGrid

1. Regresa a SendGrid Dashboard
2. Haz clic en **"Verify"** o **"Check DNS"**
3. SendGrid verificará automáticamente los registros DNS
4. Una vez verificado, el dominio aparecerá como **"Authenticated"**

### Paso 8: Actualizar la Función send-otp

Una vez que el dominio esté autenticado, asegúrate de que la función use el email correcto:

```typescript
const SENDGRID_FROM_EMAIL = Deno.env.get('SENDGRID_FROM_EMAIL') || 'hola@manigrab.app'
```

### Paso 9: Probar

Después de configurar Domain Authentication:

1. **Desactiva temporalmente la IP whitelist** (si es necesario)
2. O **agrega las IPs de Supabase** a la whitelist como respaldo
3. Prueba el envío:
   ```bash
   ./scripts/test_send_email.sh 2005.ivan@gmail.com
   ```

## Alternativa: Single Sender Verification

Si Domain Authentication es muy complejo, puedes usar **Single Sender Verification**:

1. Ve a SendGrid Dashboard → Settings → Sender Authentication
2. Haz clic en **"Verify a Single Sender"**
3. Ingresa:
   - **From Email:** `hola@manigrab.app`
   - **From Name:** `ManiGrab`
   - **Reply To:** `hola@manigrab.app`
4. Verifica el email siguiendo las instrucciones
5. Una vez verificado, puedes enviar desde esa dirección

**Nota:** Single Sender Verification es más simple pero menos robusta que Domain Authentication.

## Troubleshooting

### El dominio no se verifica

1. Verifica que los registros DNS estén correctamente configurados
2. Usa herramientas como `dig` o `nslookup` para verificar los registros:
   ```bash
   dig em1234.manigrab.app CNAME
   dig s1._domainkey.manigrab.app CNAME
   ```
3. Espera más tiempo para la propagación DNS (puede tardar hasta 48 horas)

### Los emails aún no llegan

1. Verifica que estés usando el email correcto (`hola@manigrab.app`)
2. Revisa SendGrid Activity para ver el estado de los envíos
3. Verifica que Domain Authentication esté completamente verificado
4. Revisa los logs de Supabase para errores

## Ventajas de Domain Authentication

- ✅ No requiere whitelist de IPs
- ✅ Mejora la deliverability
- ✅ Permite enviar desde cualquier IP
- ✅ Más profesional y confiable
- ✅ Reduce la probabilidad de spam



