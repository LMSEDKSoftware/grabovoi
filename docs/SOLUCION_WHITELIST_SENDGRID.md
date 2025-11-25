# Solución para Whitelist de IPs en SendGrid

## Problema Identificado

SendGrid está rechazando las solicitudes porque la IP de Supabase Edge Functions no está en la whitelist. El error es:
```
"The requestor's IP Address is not whitelisted"
```

## Soluciones Posibles

### Solución 1: Agregar IPs de Supabase a la Whitelist (Recomendada)

Supabase Edge Functions se ejecutan desde IPs específicas de AWS. Necesitas agregar estas IPs a la whitelist de SendGrid.

**Pasos:**

1. **Obtener las IPs de Supabase:**
   - Las Edge Functions de Supabase se ejecutan en AWS en la región `us-east-2` (según los logs)
   - Necesitas obtener el rango de IPs de AWS para esa región

2. **Agregar IPs en SendGrid:**
   - Ve a SendGrid Dashboard → Settings → IP Access Management
   - Haz clic en "Add IP Address" o "Add IP Range"
   - Agrega las IPs de Supabase/AWS

**Nota:** Las IPs de Supabase pueden cambiar. Es mejor usar un rango de IPs de AWS.

### Solución 2: Usar Autenticación de Dominio (Alternativa)

En lugar de depender solo de IP whitelist, puedes usar Domain Authentication de SendGrid:

1. Ve a SendGrid Dashboard → Settings → Sender Authentication
2. Configura Domain Authentication para `manigrab.app`
3. Esto permite enviar desde cualquier IP siempre que uses el dominio autenticado

### Solución 3: Servicio Intermedio/Proxy

Crear un servicio intermedio que:
- Esté en una IP whitelisted
- Reciba solicitudes de Supabase
- Reenvíe los emails a través de SendGrid

**Desventaja:** Requiere infraestructura adicional.

### Solución 4: Desactivar Whitelist (No Recomendado)

Solo si es absolutamente necesario y con otras medidas de seguridad:
- Ve a SendGrid Dashboard → Settings → IP Access Management
- Desactiva la whitelist temporalmente
- Implementa otras medidas de seguridad (rate limiting, etc.)

## Solución Recomendada: Obtener IPs de Supabase

### Paso 1: Identificar IPs de Supabase Edge Functions

Las Edge Functions de Supabase se ejecutan en AWS. Necesitas:

1. **Contactar a Supabase Support** para obtener el rango de IPs
2. **O usar un servicio de detección:**
   - Crear una función temporal que registre su IP
   - Ejecutarla y revisar los logs

### Paso 2: Agregar IPs a SendGrid

1. Ve a: https://app.sendgrid.com/settings/ip_access_management
2. Haz clic en "Add IP Address" o "Add IP Range"
3. Agrega las IPs obtenidas
4. Guarda los cambios

### Paso 3: Verificar

Después de agregar las IPs, ejecuta una prueba:
```bash
./scripts/test_send_email.sh 2005.ivan@gmail.com
```

## Solución Temporal: Usar Domain Authentication

Si no puedes obtener las IPs inmediatamente:

1. Ve a SendGrid Dashboard → Settings → Sender Authentication
2. Configura Domain Authentication para `manigrab.app`
3. Verifica el dominio siguiendo las instrucciones de SendGrid
4. Una vez verificado, puedes enviar desde cualquier IP usando ese dominio

## Script para Detectar IP de Supabase

Puedo crear una función temporal que registre la IP desde la cual se ejecuta Supabase Edge Functions.



