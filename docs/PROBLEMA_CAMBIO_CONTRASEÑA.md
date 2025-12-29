# 🔴 PROBLEMA: Cambio de Contraseña No Funciona

## Resumen del Problema

**Síntoma:** Después de cambiar la contraseña usando OTP, el usuario no puede hacer login con la nueva contraseña. Recibe error de "credenciales inválidas".

**Flujo actual:**
1. ✅ Usuario solicita cambio de contraseña → OTP se envía correctamente
2. ✅ Usuario ingresa OTP correcto → OTP se verifica
3. ✅ Usuario ingresa nueva contraseña → Sistema confirma cambio
4. ❌ Usuario intenta login con nueva contraseña → Error "credenciales inválidas"

**Tiempo de espera probado:** Más de 20 segundos después del cambio

## Stack Tecnológico

- **Backend:** Supabase (PostgreSQL + Auth)
- **Frontend:** Flutter (Dart)
- **Edge Functions:** Deno/TypeScript
- **Email:** SendGrid (vía servidor propio con IP estática)

## Arquitectura Actual

### Sistema de OTP Personalizado

No estamos usando el flujo estándar de Supabase `resetPasswordForEmail()`. En su lugar:

1. **Tabla personalizada:** `password_reset_otps` (almacena OTPs)
2. **Edge Function `send-otp`:** Genera OTP y lo envía por email
3. **Edge Function `verify-otp`:** Verifica OTP y actualiza contraseña usando `admin.updateUserById()`

### Problema Identificado

El método `admin.updateUserById()` parece actualizar la contraseña en la base de datos, pero cuando el usuario intenta hacer login, Supabase rechaza las credenciales.

## Archivos Relevantes

### 1. Edge Function: `supabase/functions/verify-otp/index.ts`
- Verifica OTP personalizado
- Intenta actualizar contraseña usando `admin.updateUserById()`
- También intenta generar token de recuperación estándar de Supabase

### 2. Cliente: `lib/services/auth_service_simple.dart`
- Método `verifyOTPAndResetPassword()` que llama a la Edge Function
- Intenta usar método estándar si recibe token de recuperación

### 3. Tabla: `password_reset_otps`
- Almacena OTPs personalizados
- Campos: `email`, `otp_code`, `expires_at`, `used`

## Intentos Realizados

1. ✅ Usar `admin.updateUserById()` directamente
2. ✅ Agregar esperas de propagación (2s, 5s, 10s)
3. ✅ Usar API REST directa (`PUT /auth/v1/admin/users/{id}`)
4. ✅ Sistema de reintentos (3 intentos)
5. ✅ Verificación de login después de actualizar
6. ✅ Generar token de recuperación estándar y usar `updateUser()`

**Ninguno de estos métodos ha funcionado.**

## Logs de Supabase

Los logs de `verify-otp` muestran:
- ✅ OTP verificado correctamente
- ✅ Contraseña actualizada exitosamente (según `admin.updateUserById()`)
- ⚠️ Verificación de login falla (la contraseña no funciona)

## Pregunta para ChatGPT

**¿Cómo implementar correctamente el cambio de contraseña en Supabase cuando se usa un sistema de OTP personalizado en lugar del flujo estándar `resetPasswordForEmail()`?**

**Requisitos:**
- Mantener el sistema de OTP personalizado (tabla `password_reset_otps`)
- La contraseña debe funcionar inmediatamente después del cambio
- No usar el flujo estándar de Supabase (no podemos cambiar a `resetPasswordForEmail()`)

**Problema específico:**
- `admin.updateUserById({ password: newPassword })` actualiza la contraseña pero no funciona para login
- ¿Hay algún paso adicional necesario?
- ¿Hay algún problema conocido con este método?
- ¿Cuál es la forma correcta de actualizar contraseñas usando Admin API?


