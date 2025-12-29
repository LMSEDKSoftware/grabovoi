# 📋 CONTEXTO COMPLETO: Problema de Cambio de Contraseña en Supabase

## 🔴 PROBLEMA PRINCIPAL

**Síntoma:** Después de cambiar la contraseña usando OTP personalizado, el usuario NO puede hacer login con la nueva contraseña. Recibe error "credenciales inválidas".

**Flujo:**
1. ✅ Usuario solicita cambio → OTP se envía por email (funciona)
2. ✅ Usuario ingresa OTP correcto → OTP se verifica (funciona)
3. ✅ Usuario ingresa nueva contraseña → Sistema confirma cambio (funciona)
4. ❌ Usuario intenta login con nueva contraseña → **ERROR "credenciales inválidas"**

**Tiempo de espera probado:** Más de 20 segundos después del cambio

---

## 🏗️ ARQUITECTURA

### Stack
- **Backend:** Supabase (PostgreSQL + Auth)
- **Frontend:** Flutter (Dart)
- **Edge Functions:** Deno/TypeScript
- **Email:** SendGrid (vía servidor PHP con IP estática)

### Sistema de OTP Personalizado

**NO estamos usando el flujo estándar de Supabase** (`resetPasswordForEmail()`). En su lugar:

1. **Tabla personalizada:** `password_reset_otps`
2. **Edge Function `send-otp`:** Genera OTP de 6 dígitos y lo envía por email
3. **Edge Function `verify-otp`:** Verifica OTP y actualiza contraseña usando Admin API

---

## 📁 ARCHIVOS RELEVANTES

### 1. Edge Function: `supabase/functions/verify-otp/index.ts`

Esta función:
- Verifica el OTP personalizado en la tabla `password_reset_otps`
- Obtiene el usuario por email usando `admin.listUsers()`
- Intenta actualizar la contraseña usando `admin.updateUserById({ password: new_password })`
- También intenta generar un token de recuperación estándar de Supabase
- Hace un test de login para verificar que la contraseña funciona

**Problema:** El test de login FALLA, indicando que la contraseña no funciona después de actualizarla.

### 2. Cliente: `lib/services/auth_service_simple.dart`

Método `verifyOTPAndResetPassword()`:
- Llama a la Edge Function `verify-otp`
- Si recibe un `recovery_token`, intenta usar el método estándar de Supabase
- Usa `exchangeCodeForSession()` y luego `updateUser()`

### 3. Tabla: `password_reset_otps`

```sql
CREATE TABLE IF NOT EXISTS public.password_reset_otps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  otp_code TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 🔧 MÉTODOS INTENTADOS (TODOS FALLARON)

1. ✅ `admin.updateUserById({ password: newPassword })` - Actualiza pero no funciona para login
2. ✅ API REST directa `PUT /auth/v1/admin/users/{id}` - Mismo problema
3. ✅ Agregar esperas de propagación (2s, 5s, 10s, 20s) - No ayuda
4. ✅ Sistema de reintentos (3 intentos) - No ayuda
5. ✅ Verificación de login después de actualizar - Confirma que NO funciona
6. ✅ Generar token de recuperación estándar y usar `updateUser()` - El token se genera pero `exchangeCodeForSession()` falla

---

## 📊 LOGS DE SUPABASE

### Logs de `verify-otp` muestran:
```
✅ Contraseña actualizada exitosamente (intento X)
✅ Usuario verificado después de actualizar
⚠️ ADVERTENCIA: La verificación de contraseña falló
   Error: Invalid login credentials
   Status: 400
```

Esto confirma que:
- La contraseña se "actualiza" según Supabase
- Pero NO funciona para hacer login

---

## ❓ PREGUNTA PARA CHATGPT

**¿Cómo implementar correctamente el cambio de contraseña en Supabase cuando se usa un sistema de OTP personalizado?**

**Contexto:**
- Usamos tabla personalizada `password_reset_otps` (no podemos cambiar a `resetPasswordForEmail()`)
- El OTP se verifica correctamente
- `admin.updateUserById({ password: newPassword })` reporta éxito pero la contraseña no funciona para login
- Hemos esperado más de 20 segundos - no es problema de propagación

**Preguntas específicas:**
1. ¿Hay algún problema conocido con `admin.updateUserById()` para actualizar contraseñas?
2. ¿Hay algún paso adicional necesario después de actualizar la contraseña?
3. ¿Necesitamos invalidar sesiones o hacer algo más?
4. ¿Cuál es la forma CORRECTA de actualizar contraseñas usando Admin API en Supabase?
5. ¿Hay alguna diferencia entre actualizar contraseña para usuarios existentes vs nuevos?

---

## 🔍 INFORMACIÓN ADICIONAL

- **Versión de Supabase:** Cloud (no self-hosted)
- **Versión de SDK:** `supabase_flutter` (última)
- **Método de login:** `signInWithPassword(email, password)`
- **Error específico:** "Invalid login credentials" (código 400)

---

## 📝 NOTAS

- El problema NO es con el envío de OTP (funciona perfectamente)
- El problema NO es con la verificación de OTP (funciona perfectamente)
- El problema ES que después de "actualizar" la contraseña, no funciona para login
- Hemos probado múltiples métodos y ninguno funciona


