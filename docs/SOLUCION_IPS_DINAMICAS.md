# Solución para IPs Dinámicas en Supabase Edge Functions

## Problema

Las Edge Functions de Supabase se ejecutan en AWS Lambda, que usa IPs dinámicas. Cada vez que se ejecuta la función, puede usar una IP diferente del rango de AWS. Esto hace que mantener una whitelist de IPs sea inviable.

## Solución: Domain Authentication (Recomendada)

Domain Authentication permite enviar emails desde cualquier IP usando el dominio autenticado. Es la solución perfecta para servicios serverless.

### Pasos para Configurar Domain Authentication

#### Paso 1: Acceder a SendGrid Dashboard

1. Ve a: https://app.sendgrid.com
2. Inicia sesión

#### Paso 2: Ir a Sender Authentication

1. Ve a **Settings** → **Sender Authentication**
2. O directamente: https://app.sendgrid.com/settings/sender_auth

#### Paso 3: Configurar Domain Authentication

1. Haz clic en **"Authenticate Your Domain"** o **"Add Domain"**
2. Selecciona **"Domain Authentication"** (no Single Sender)
3. Ingresa el dominio: `manigrab.app`
4. Selecciona el tipo de DNS:
   - **Automatic Security** (recomendado) - SendGrid configura todo automáticamente
   - **Custom** - Configuración manual

#### Paso 4: Obtener Registros DNS

SendGrid te proporcionará registros DNS que debes agregar. Ejemplo:

**CNAME Records:**
```
em1234.manigrab.app → u1234567.wl123.sendgrid.net
s1._domainkey.manigrab.app → s1.domainkey.u1234567.wl123.sendgrid.net
s2._domainkey.manigrab.app → s2.domainkey.u1234567.wl123.sendgrid.net
```

**TXT Record (SPF):**
```
manigrab.app → v=spf1 include:sendgrid.net ~all
```

#### Paso 5: Agregar Registros DNS

1. Accede a tu proveedor de DNS (donde está configurado `manigrab.app`)
2. Agrega todos los registros DNS que SendGrid te proporcionó
3. Guarda los cambios

#### Paso 6: Verificar en SendGrid

1. Regresa a SendGrid Dashboard
2. Haz clic en **"Verify"** o **"Check DNS"**
3. SendGrid verificará automáticamente los registros
4. Una vez verificado, el dominio aparecerá como **"Authenticated"** ✅

#### Paso 7: Desactivar o Mantener Whitelist (Opcional)

Después de configurar Domain Authentication:

- **Opción A:** Mantener la whitelist como respaldo (recomendado)
- **Opción B:** Desactivar la whitelist (solo si Domain Authentication está completamente verificado)

#### Paso 8: Probar

```bash
./scripts/test_send_email.sh 2005.ivan@gmail.com
```

## Alternativa: Agregar Todos los Rangos de AWS us-east-2

Si prefieres mantener la whitelist, necesitas agregar TODOS los rangos de IPs de AWS para us-east-2:

### Rangos Completos de AWS us-east-2:

```
3.16.0.0/14
3.20.0.0/14
18.188.0.0/16
18.189.0.0/16
18.216.0.0/14
18.220.0.0/14
18.224.0.0/14
52.14.0.0/16
52.15.0.0/16
```

**Nota:** Esto es menos seguro y requiere mantenimiento constante.

## ¿Por qué Domain Authentication es Mejor?

✅ **No requiere whitelist de IPs** - Funciona desde cualquier IP
✅ **Mejora la deliverability** - Los emails tienen mejor reputación
✅ **Más profesional** - Usa tu dominio autenticado
✅ **Sin mantenimiento** - Una vez configurado, funciona siempre
✅ **Perfecto para serverless** - Ideal para servicios con IPs dinámicas

## Troubleshooting

### El dominio no se verifica

1. Verifica que todos los registros DNS estén correctamente agregados
2. Usa herramientas para verificar:
   ```bash
   dig em1234.manigrab.app CNAME
   dig s1._domainkey.manigrab.app CNAME
   dig manigrab.app TXT
   ```
3. Espera la propagación DNS (puede tardar hasta 48 horas, pero usualmente es más rápido)

### Los emails aún no llegan después de Domain Authentication

1. Verifica que Domain Authentication esté completamente verificado (debe aparecer como "Authenticated")
2. Asegúrate de usar el email correcto: `hola@manigrab.app`
3. Revisa SendGrid Activity para ver el estado de los envíos
4. Revisa los logs de Supabase para errores

## Comandos Útiles

### Verificar registros DNS
```bash
# Verificar CNAME
dig em1234.manigrab.app CNAME

# Verificar DKIM
dig s1._domainkey.manigrab.app CNAME

# Verificar SPF
dig manigrab.app TXT
```

### Probar envío
```bash
./scripts/test_send_email.sh 2005.ivan@gmail.com
```

## Conclusión

**Domain Authentication es la solución definitiva** para servicios serverless como Supabase Edge Functions. Una vez configurado, no tendrás más problemas con IPs dinámicas.



