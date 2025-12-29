# 📋 RESUMEN: Implementación de Flujo OTP Híbrido

## ✅ Cambios Realizados

### 1. **Backups Creados**
- ✅ Backups guardados en `backups/20251127_191358/`
- Archivos respaldados:
  - `send-otp/`
  - `verify-otp/`
  - `auth_service_simple.dart`
  - `login_screen.dart`

---

### 2. **Base de Datos**

#### Migración SQL creada: `database/migration_add_recovery_link_to_otp.sql`
- Agrega columna `recovery_link` a tabla `password_reset_otps`
- Crea índice optimizado `idx_otp_email_used_expires`

**⚠️ ACCIÓN REQUERIDA:** Ejecutar esta migración en Supabase SQL Editor.

---

### 3. **Edge Functions**

#### `supabase/functions/send-otp/index.ts`
**Cambios:**
- ✅ Guarda `recovery_link` completo (no solo `recovery_token`)
- ✅ Usa `APP_RECOVERY_URL` en `generateLink` (fallback a `APP_URL`)
- ✅ Mantiene `recovery_token` por compatibilidad

#### `supabase/functions/verify-otp/index.ts`
**Cambios:**
- ✅ **YA NO actualiza contraseña** - Solo verifica OTP y devuelve `recovery_link`
- ✅ Simplificado a solo validar OTP y devolver link
- ✅ Marca OTP como usado

**✅ Edge Functions desplegadas:**
```bash
✓ send-otp deployed
✓ verify-otp deployed
```

---

### 4. **Servicio de Auth**

#### `lib/services/auth_service_simple.dart`
**Cambios:**
- ✅ Nuevo método: `verifyOTPAndGetRecoveryLink()` - Reemplaza el método anterior
- ✅ Método antiguo `verifyOTPAndResetPassword()` marcado como `@Deprecated`

---

### 5. **Pantallas Flutter**

#### `lib/screens/auth/login_screen.dart`
**Cambios:**
- ✅ Diálogo simplificado: Solo pide código OTP (6 dígitos)
- ✅ Después de verificar OTP, abre `recovery_link` con `url_launcher`
- ✅ Importa `url_launcher` y `recovery_set_password_screen.dart`

#### `lib/screens/auth/recovery_set_password_screen.dart` ⭐ NUEVO
**Funcionalidad:**
- ✅ Recibe `accessToken` y `refreshToken` como parámetros
- ✅ Establece sesión de recuperación con `setSession()`
- ✅ Muestra formulario para nueva contraseña
- ✅ Actualiza contraseña usando `updateUser()` con sesión activa
- ✅ Redirige a Login después de éxito

#### `lib/main.dart`
**Cambios:**
- ✅ Ruta `/recovery` agregada para web
- ✅ Parsea `access_token` y `refresh_token` de query params
- ✅ Redirige a `RecoverySetPasswordScreen`

#### `lib/screens/auth/auth_callback_screen.dart`
**Cambios:**
- ✅ Detecta recovery links con `access_token` y `refresh_token`
- ✅ Redirige a `RecoverySetPasswordScreen` cuando detecta recovery

---

## 🔄 Flujo Completo (Nuevo)

1. **Usuario olvida contraseña:**
   - Ingresa email en Login
   - Clic en "¿Olvidaste tu contraseña?"

2. **Envío de OTP:**
   - `send-otp` genera recovery link oficial de Supabase
   - Genera código de 6 dígitos
   - Guarda ambos en `password_reset_otps`
   - Envía código por email

3. **Verificación de OTP:**
   - Usuario ingresa código de 6 dígitos
   - `verify-otp` valida código y devuelve `recovery_link`
   - App abre `recovery_link` en navegador/app

4. **Establecimiento de nueva contraseña:**
   - Supabase procesa recovery link y crea sesión
   - Usuario redirigido a `/recovery` con tokens en URL
   - `RecoverySetPasswordScreen` establece sesión con `setSession()`
   - Usuario ingresa nueva contraseña
   - Se llama `updateUser({ password })` con sesión activa
   - ✅ **Aquí SÍ funciona** porque usa el flujo oficial de Supabase

5. **Login:**
   - Usuario hace logout automático
   - Redirigido a Login
   - Puede hacer login con nueva contraseña ✅

---

## ⚠️ ACCIONES PENDIENTES

### 1. **Ejecutar Migración SQL**
```sql
-- Ejecutar en Supabase SQL Editor:
ALTER TABLE password_reset_otps
ADD COLUMN IF NOT EXISTS recovery_link text;

CREATE INDEX IF NOT EXISTS idx_otp_email_used_expires
ON password_reset_otps (email, used, expires_at DESC);
```

### 2. **Configurar Variable de Entorno**
En Supabase Dashboard → Edge Functions → Settings:
- Agregar: `APP_RECOVERY_URL` = `https://manigrab.app/recovery` (o tu dominio)
- Alternativamente, usar `APP_URL` + `/recovery`

### 3. **Verificar Configuración de Supabase Auth**
En Supabase Dashboard → Authentication → URL Configuration:
- Asegurar que `Site URL` y `Redirect URLs` incluyen tu dominio
- Agregar `https://manigrab.app/recovery` a Redirect URLs si es necesario

### 4. **Probar Flujo Completo**
1. Solicitar OTP
2. Verificar código
3. Abrir recovery link
4. Establecer nueva contraseña
5. Verificar login con nueva contraseña

---

## 🐛 Posibles Problemas y Soluciones

### Problema: `setSession` no funciona
**Solución:** Verificar que los tokens vienen correctamente en la URL. Si Supabase redirige directamente a `/recovery`, los tokens estarán en `queryParameters`.

### Problema: Recovery link no redirige correctamente
**Solución:** 
- Verificar `APP_RECOVERY_URL` en variables de entorno
- Verificar Redirect URLs en Supabase Dashboard
- El link debe apuntar a: `https://tu-dominio.com/recovery`

### Problema: Sesión no se establece
**Solución:** Verificar formato de `setSession()`. En Supabase Flutter puede requerir:
```dart
await Supabase.instance.client.auth.setSession(
  accessToken,
  refreshToken,
);
```

---

## 📚 Referencias

- Documento ChatGPT: `docs/Respuesta_Chatgpt_para_OTP.md`
- Contexto completo: `docs/CONTEXTO_COMPLETO_OTP_SUPABASE.md`

---

**Fecha:** 2025-11-27
**Estado:** ✅ Implementación completa - Pendiente pruebas end-to-end

