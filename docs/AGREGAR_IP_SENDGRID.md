# Agregar IP de Supabase a SendGrid Whitelist

## IP Detectada
- **IP:** `18.222.161.29`
- **Proveedor:** AWS (Amazon Web Services)
- **Región:** us-east-2 (Ohio)

## Pasos para Agregar la IP

### Paso 1: Acceder a SendGrid Dashboard

1. Ve a: https://app.sendgrid.com
2. Inicia sesión en tu cuenta

### Paso 2: Ir a IP Access Management

1. En el menú lateral, ve a **Settings** → **IP Access Management**
2. O accede directamente: https://app.sendgrid.com/settings/ip_access_management

### Paso 3: Agregar la IP

1. Haz clic en **"Add IP Address"** o **"Add IP"**
2. Selecciona **"Single IP Address"**
3. Ingresa la IP: `18.222.161.29`
4. (Opcional) Agrega una descripción: `Supabase Edge Functions - us-east-2`
5. Haz clic en **"Add"** o **"Save"**

### Paso 4: Verificar

Después de agregar la IP, espera unos segundos y prueba:
```bash
./scripts/test_send_email.sh 2005.ivan@gmail.com
```

## ¿Agregar el Rango Completo?

### Opción A: Solo la IP Específica (Recomendado para empezar)

**Ventajas:**
- ✅ Más seguro (solo permite esa IP específica)
- ✅ Fácil de probar rápidamente
- ✅ Si funciona, no necesitas agregar más

**Desventajas:**
- ⚠️ Si Supabase cambia de IP, dejará de funcionar
- ⚠️ Puede haber múltiples IPs en uso

### Opción B: Rango de IPs de AWS

Si necesitas agregar un rango, estos son los rangos de IPs de AWS para us-east-2:

**Rangos CIDR de AWS us-east-2:**
- `18.188.0.0/16` (18.188.0.0 - 18.188.255.255)
- `18.189.0.0/16` (18.189.0.0 - 18.189.255.255)
- `18.216.0.0/14` (18.216.0.0 - 18.219.255.255)
- `18.220.0.0/14` (18.220.0.0 - 18.223.255.255) ← **Tu IP está aquí**
- `18.224.0.0/14` (18.224.0.0 - 18.227.255.255)
- `3.16.0.0/14` (3.16.0.0 - 3.19.255.255)
- `3.20.0.0/14` (3.20.0.0 - 3.23.255.255)

**Nota:** Agregar rangos completos puede ser menos seguro. Es mejor agregar solo las IPs necesarias.

### Opción C: Rango Específico de la IP Detectada

Si quieres un rango más pequeño alrededor de tu IP:
- `18.222.0.0/16` (18.222.0.0 - 18.222.255.255) - Rango de clase B
- `18.222.160.0/20` (18.222.160.0 - 18.222.175.255) - Rango más pequeño

## Recomendación

1. **Primero:** Agrega solo la IP específica `18.222.161.29` y prueba
2. **Si funciona:** Mantén solo esa IP
3. **Si falla con otras IPs:** Considera agregar el rango `18.222.0.0/16` o `18.220.0.0/14`

## Verificar Rangos de IPs de AWS

Para obtener los rangos oficiales de AWS:

1. Ve a: https://ip-ranges.amazonaws.com/ip-ranges.json
2. Busca `"region": "us-east-2"`
3. Filtra por `"service": "EC2"` o `"service": "AMAZON"`

O usa este comando:
```bash
curl -s https://ip-ranges.amazonaws.com/ip-ranges.json | jq '.prefixes[] | select(.region=="us-east-2") | .ip_prefix'
```

## Troubleshooting

### La IP no funciona después de agregarla

1. Verifica que la IP esté correctamente agregada en SendGrid
2. Espera unos minutos para que los cambios se propaguen
3. Revisa los logs de Supabase para ver si hay otras IPs intentando conectarse
4. Considera agregar un rango más amplio si hay múltiples IPs

### Necesitas agregar múltiples IPs

Si ves múltiples IPs diferentes en los logs:
1. Agrega cada IP individualmente, o
2. Identifica el rango común y agrega el rango CIDR completo

## Alternativa: Domain Authentication

Si agregar IPs se vuelve complicado, considera usar **Domain Authentication**:
- Permite enviar desde cualquier IP
- Más robusta y profesional
- Mejora la deliverability

Ver: `docs/CONFIGURAR_DOMAIN_AUTHENTICATION.md`



