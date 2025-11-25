# Cambios Finales para Domain Authentication

## Estado Actual

✅ Domain Authentication configurado y verificado:
- Dominio: `em6490.manigrab.app`
- Todos los registros DNS verificados

✅ Código actualizado:
- La función ahora usa `hola@em6490.manigrab.app` por defecto

## Cambios Necesarios

### Cambio 1: Actualizar Variable de Entorno en Supabase

**Ubicación:** Supabase Dashboard → Settings → Edge Functions → Secrets

**Pasos:**

1. Ve a: https://supabase.com/dashboard/project/whtiazgcxdnemrrgjjqf/settings/functions
2. Busca la variable `SENDGRID_FROM_EMAIL` en la lista de Secrets
3. Haz clic en el ícono de edición (o elimínala y créala de nuevo)
4. Actualiza el valor a: `hola@em6490.manigrab.app`
5. Guarda los cambios

**Nota:** Si la variable no existe, créala:
- Nombre: `SENDGRID_FROM_EMAIL`
- Valor: `hola@em6490.manigrab.app`

### Cambio 2: Desactivar o Ajustar Whitelist en SendGrid

**Ubicación:** SendGrid Dashboard → Settings → IP Access Management

**Opción A: Desactivar Whitelist (Recomendado)**

1. Ve a: https://app.sendgrid.com/settings/ip_access_management
2. Si hay una whitelist activa, haz clic en ella
3. Desactívala o elimínala temporalmente
4. Domain Authentication debería tener prioridad ahora

**Opción B: Mantener Whitelist como Respaldo**

Si prefieres mantener la whitelist:
1. Agrega todos los rangos de AWS us-east-2 (como respaldo)
2. Domain Authentication debería funcionar incluso con whitelist activa

### Cambio 3: Verificar que el Código Esté Actualizado

El código ya está actualizado para usar `hola@em6490.manigrab.app` por defecto, pero verifica:

**Archivo:** `supabase/functions/send-otp/index.ts`

**Línea ~101:**
```typescript
const SENDGRID_FROM_EMAIL = Deno.env.get('SENDGRID_FROM_EMAIL') || 'hola@em6490.manigrab.app'
```

Si la variable de entorno está configurada en Supabase, usará esa. Si no, usará el valor por defecto.

## Resumen de Cambios

1. ✅ **Código actualizado** - Ya está hecho
2. ⚠️ **Variable en Supabase** - Necesitas actualizarla
3. ⚠️ **Whitelist en SendGrid** - Necesitas desactivarla o ajustarla

## Pasos a Seguir

### Paso 1: Actualizar Variable en Supabase

1. Ve a Supabase Dashboard → Settings → Edge Functions → Secrets
2. Actualiza `SENDGRID_FROM_EMAIL` a `hola@em6490.manigrab.app`
3. Espera unos segundos para que se aplique

### Paso 2: Desactivar Whitelist en SendGrid

1. Ve a SendGrid Dashboard → Settings → IP Access Management
2. Desactiva la whitelist temporalmente
3. O elimínala si prefieres

### Paso 3: Probar

```bash
./scripts/test_send_email.sh 2005.ivan@gmail.com
```

### Paso 4: Verificar Logs

1. Revisa los logs de Supabase
2. Debe aparecer: `✅ Email enviado correctamente con SendGrid`
3. NO debe aparecer: `❌ Error enviando email con SendGrid` o `IP not whitelisted`

## Verificación Final

Después de hacer los cambios:

1. **Logs de Supabase:**
   - ✅ `✅ Email enviado correctamente con SendGrid`
   - ✅ `From Email: hola@em6490.manigrab.app`

2. **SendGrid Activity:**
   - ✅ Email aparece como "Processed" o "Delivered"
   - ✅ No hay errores de whitelist

3. **Bandeja de entrada:**
   - ✅ Email recibido en `2005.ivan@gmail.com`

## Notas Importantes

- El email remitente **DEBE** coincidir exactamente con el dominio verificado
- Domain Authentication debería permitir enviar desde cualquier IP
- Si la whitelist está activa, puede tener prioridad sobre Domain Authentication
- Una vez que funcione, puedes mantener la whitelist desactivada o como respaldo



