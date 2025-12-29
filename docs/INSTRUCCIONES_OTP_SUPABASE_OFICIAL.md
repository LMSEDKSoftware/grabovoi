# 🔐 Instrucciones: Configurar OTP Oficial de Supabase

Este documento explica cómo migrar del sistema OTP personalizado al sistema oficial de Supabase para el cambio de contraseña.

---

## ✅ Paso 1: Ejecutar SQL de Migración en Supabase

### 1.1 Agregar columna `recovery_token` a la tabla existente

1. Ve a **Supabase Dashboard** → **SQL Editor**
2. Crea una nueva consulta
3. Ejecuta el siguiente SQL:

```sql
-- Agregar columna recovery_token si no existe
do $$
begin
  if not exists (
    select 1 
    from information_schema.columns 
    where table_schema = 'public' 
    and table_name = 'password_reset_otps' 
    and column_name = 'recovery_token'
  ) then
    alter table public.password_reset_otps 
    add column recovery_token text;
    
    raise notice '✅ Columna recovery_token agregada exitosamente';
  else
    raise notice '⚠️ Columna recovery_token ya existe';
  end if;
end $$;
```

**O ejecuta directamente el archivo:**
- `database/migration_add_recovery_token_to_otp.sql`

### 1.2 Crear tabla de logs (opcional pero recomendado)

1. En el mismo **SQL Editor** de Supabase
2. Ejecuta el archivo completo:
- `database/otp_transaction_logs_schema.sql`

Esto creará la tabla `otp_transaction_logs` para ver todos los logs del proceso.

---

## ✅ Paso 2: Verificar Variables de Entorno en Supabase

### 2.1 Configurar en Supabase Dashboard

1. Ve a **Supabase Dashboard** → **Project Settings** → **Edge Functions** → **Secrets**
2. Verifica que estén configuradas estas variables:

**Variables requeridas:**
- `SB_URL` - URL de tu proyecto Supabase (ej: `https://xxxxx.supabase.co`)
- `SB_SERVICE_ROLE_KEY` o `SERVICE_ROLE_KEY` - Service Role Key
- `SUPABASE_ANON_KEY` o `SB_ANON_KEY` - Anon Key (para verify-otp)

**Variables opcionales para envío de email:**
- `EMAIL_SERVER_URL` - URL de tu servidor de email (ej: `https://manigrab.app/api/send-email`)
- `EMAIL_SERVER_SECRET` - Token secreto para autenticación
- `SENDGRID_API_KEY` - API Key de SendGrid (si usas envío directo)
- `SENDGRID_FROM_EMAIL` - Email remitente
- `SENDGRID_FROM_NAME` - Nombre del remitente
- `APP_URL` - URL de tu app (ej: `https://manigrab.app`)
- `ENV` - `production` o `development`

---

## ✅ Paso 3: Desplegar Edge Functions Actualizadas

### 3.1 Actualizar función `send-otp`

1. Abre **Supabase Dashboard** → **Edge Functions** → `send-otp`
2. O usa el CLI de Supabase:

```bash
cd /Users/ifernandez/development/grabovoi_build
supabase functions deploy send-otp
```

**Cambios en `send-otp`:**
- ✅ Ahora genera token oficial de Supabase usando `admin.generateLink({ type: 'recovery' })`
- ✅ Extrae el token del link
- ✅ Genera código corto de 6 dígitos para mostrar al usuario
- ✅ Guarda ambos: código corto (`otp_code`) y token completo (`recovery_token`)
- ✅ Envía el código corto por email
- ✅ Guarda logs detallados en `otp_transaction_logs`

### 3.2 Actualizar función `verify-otp`

1. En **Supabase Dashboard** → **Edge Functions** → `verify-otp`
2. O usa el CLI:

```bash
supabase functions deploy verify-otp
```

**Cambios en `verify-otp`:**
- ✅ Verifica el código corto ingresado por el usuario
- ✅ Obtiene el token completo de Supabase desde la BD
- ✅ Usa `exchangeCodeForSession(recoveryToken)` para crear sesión temporal
- ✅ Usa `updateUser({ password })` (método oficial) para actualizar contraseña
- ✅ Verifica que la contraseña funcione haciendo login de prueba
- ✅ Guarda logs detallados en `otp_transaction_logs`

---

## ✅ Paso 4: Verificar que el Flujo Funciona

### 4.1 Probar el flujo completo

1. **Solicitar cambio de contraseña:**
   - En la app, haz clic en "¿Olvidaste tu contraseña?"
   - Ingresa tu email
   - Deberías recibir un código de 6 dígitos por email

2. **Ingresar código y nueva contraseña:**
   - Debería aparecer automáticamente el diálogo
   - Ingresa el código de 6 dígitos recibido
   - Ingresa nueva contraseña y confirmación
   - Haz clic en "Restablecer"

3. **Verificar que funciona:**
   - Debería mostrar mensaje de éxito
   - Intenta hacer login con la nueva contraseña
   - **Debería funcionar correctamente** ✅

### 4.2 Verificar logs en Supabase

1. Ve a **Supabase Dashboard** → **Table Editor** → `otp_transaction_logs`
2. Ordena por `created_at DESC` para ver los más recientes
3. Verifica que todos los pasos estén registrados:
   - `otp_request_received`
   - `supabase_token_generated`
   - `otp_saved`
   - `otp_email_sent`
   - `otp_verification_requested`
   - `otp_verified`
   - `session_created`
   - `password_updated`
   - `password_verification_success` ← **Este es el más importante**

4. **Si `password_verification_success` aparece**: ✅ La contraseña funciona correctamente
5. **Si `password_verification_failed` aparece**: ❌ Hay un problema (revisa los detalles del error)

---

## 📊 Consultas SQL Útiles para Debugging

### Ver todos los logs de un email específico

```sql
SELECT 
  created_at,
  function_name,
  action,
  message,
  log_level,
  metadata,
  error_details
FROM otp_transaction_logs 
WHERE email = 'usuario@email.com' 
ORDER BY created_at DESC;
```

### Ver solo errores

```sql
SELECT 
  created_at,
  email,
  function_name,
  action,
  message,
  error_details
FROM otp_transaction_logs 
WHERE log_level = 'error' 
ORDER BY created_at DESC
LIMIT 50;
```

### Ver verificación de contraseñas

```sql
SELECT 
  created_at,
  email,
  action,
  message,
  metadata,
  error_details
FROM otp_transaction_logs 
WHERE action LIKE '%password_verification%' 
ORDER BY created_at DESC;
```

### Ver tokens de Supabase generados

```sql
SELECT 
  created_at,
  email,
  action,
  message,
  metadata->>'user_code' as codigo_usuario,
  metadata->>'token_length' as longitud_token
FROM otp_transaction_logs 
WHERE action = 'supabase_token_generated' 
ORDER BY created_at DESC;
```

### Ver OTPs activos (no usados)

```sql
SELECT 
  id,
  email,
  otp_code,
  recovery_token IS NOT NULL as tiene_token_supabase,
  expires_at,
  used,
  created_at
FROM password_reset_otps 
WHERE used = false 
  AND expires_at > NOW()
ORDER BY created_at DESC;
```

---

## 🔍 Troubleshooting

### Problema: "Columna recovery_token no existe"

**Solución:** Ejecuta el SQL del Paso 1.1 para agregar la columna.

### Problema: "No se pudo generar token de recuperación"

**Solución:** 
- Verifica que `SB_URL` y `SB_SERVICE_ROLE_KEY` estén configuradas correctamente
- Verifica que el email del usuario exista en `auth.users`

### Problema: "Token de recuperación inválido o expirado"

**Solución:**
- Los tokens de Supabase expiran en 1 hora
- Verifica que el código ingresado corresponda al token más reciente
- Cada vez que se solicita un nuevo código, se genera un nuevo token

### Problema: "La contraseña no funciona después del cambio"

**Solución:**
- Revisa los logs en `otp_transaction_logs`
- Busca el action `password_verification_failed` para ver el error específico
- Verifica que se esté usando `updateUser()` y no `admin.updateUserById()`

---

## 📝 Resumen del Flujo

1. **Usuario solicita cambio** → `send-otp`
   - Genera token oficial de Supabase con `admin.generateLink()`
   - Crea código corto de 6 dígitos
   - Guarda ambos en `password_reset_otps`
   - Envía código por email

2. **Usuario ingresa código** → `verify-otp`
   - Verifica código corto
   - Obtiene token completo de Supabase
   - Usa `exchangeCodeForSession()` para sesión temporal
   - Usa `updateUser()` para actualizar contraseña (método oficial)
   - Verifica que funcione con login de prueba

3. **Usuario hace login** → ✅ Funciona porque usamos método oficial

---

## ✅ Checklist Final

- [ ] SQL de migración ejecutado (columna `recovery_token` agregada)
- [ ] Tabla de logs creada (`otp_transaction_logs`)
- [ ] Variables de entorno configuradas en Supabase
- [ ] Edge Function `send-otp` desplegada
- [ ] Edge Function `verify-otp` desplegada
- [ ] Probar flujo completo de cambio de contraseña
- [ ] Verificar logs en `otp_transaction_logs`
- [ ] Confirmar que login funciona después del cambio

---

**Fecha de creación:** $(date)
**Última actualización:** $(date)

