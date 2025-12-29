# Sistema de Autenticación Nuevo - Implementación Completa

## ✅ Sistema Implementado desde Cero

Se ha creado un sistema robusto y confiable de autenticación usando el **flujo oficial de Supabase**, evitando los problemas conocidos con `admin.updateUserById()`.

---

## 🔐 Flujo de Recuperación de Contraseña

### 1. Usuario solicita recuperación
- **Pantalla:** `LoginScreen`
- **Método:** `AuthServiceSimple.resetPassword(email)`
- **Edge Function:** `auth-reset-password`

### 2. Edge Function `auth-reset-password`
- Verifica que el usuario existe
- Genera un **link de recuperación oficial** usando `admin.generateLink({ type: 'recovery' })`
- Extrae el `recovery_token` del link
- Envía email con el link usando el servidor con IP estática (SendGrid)
- **NO actualiza la contraseña directamente** (evita problemas conocidos)

### 3. Usuario hace clic en el link del email
- El link redirige a `https://manigrab.app/auth/callback?token=XXX&type=recovery`
- **Pantalla:** `AuthCallbackScreen` detecta `type=recovery`
- Redirige a `ResetPasswordScreen` con el `recovery_token`

### 4. Usuario establece nueva contraseña
- **Pantalla:** `ResetPasswordScreen`
- Usuario ingresa nueva contraseña y confirmación
- **Método:** `AuthServiceSimple.updatePasswordWithRecoveryToken()`
- **Edge Function:** `auth-update-password`

### 5. Edge Function `auth-update-password`
- Usa `exchangeCodeForSession(recovery_token)` para crear sesión temporal
- Usa `updateUser({ password })` (método oficial que SIEMPRE funciona)
- Verifica que la contraseña funciona haciendo re-login
- Cierra sesión para que el usuario haga login normalmente

---

## 📧 Flujo de Registro de Usuario

### 1. Usuario se registra
- **Pantalla:** `RegisterScreen`
- **Método:** `AuthServiceSimple.signUp()`
- Crea usuario en Supabase Auth
- Crea usuario en tabla `users`
- Envía email de bienvenida/confirmación usando `send-email` Edge Function

### 2. Usuario hace clic en link de confirmación
- El link redirige a `https://manigrab.app/auth/callback?token=XXX&type=signup`
- **Pantalla:** `AuthCallbackScreen` detecta `type=signup`
- Verifica el email automáticamente
- Redirige a la app

---

## 🛠️ Archivos Creados/Modificados

### Edge Functions Nuevas
1. **`supabase/functions/auth-reset-password/index.ts`**
   - Genera link de recuperación oficial
   - Envía email usando servidor con IP estática

2. **`supabase/functions/auth-update-password/index.ts`**
   - Actualiza contraseña usando método oficial
   - Verifica que funciona con re-login

### Pantallas Nuevas
1. **`lib/screens/auth/reset_password_screen.dart`**
   - Pantalla para establecer nueva contraseña
   - Recibe `recovery_token` del email

### Servicios Modificados
1. **`lib/services/auth_service_simple.dart`**
   - `resetPassword()` - Usa nuevo sistema
   - `updatePasswordWithRecoveryToken()` - Nuevo método
   - `verifyOTPAndResetPassword()` - Mantenido para compatibilidad

### Pantallas Modificadas
1. **`lib/screens/auth/auth_callback_screen.dart`**
   - Detecta `type=recovery` y redirige a `ResetPasswordScreen`
   - Maneja `type=signup` para verificación de email

2. **`lib/screens/auth/login_screen.dart`**
   - Actualizado mensaje de recuperación
   - Ya no muestra diálogo de OTP

---

## 🔑 Ventajas del Nuevo Sistema

1. **Usa el flujo oficial de Supabase**
   - `generateLink()` + `exchangeCodeForSession()` + `updateUser()`
   - Evita problemas conocidos con `admin.updateUserById()`

2. **Verificación automática**
   - Re-login después de actualizar contraseña
   - Confirma que la contraseña funciona antes de terminar

3. **Integración con servidor IP estática**
   - Todos los emails se envían a través de `manigrab.app`
   - IP `153.92.215.178` está en whitelist de SendGrid

4. **UX mejorada**
   - Usuario hace clic en link del email
   - Establece nueva contraseña en pantalla dedicada
   - No necesita recordar códigos OTP

---

## 📋 Configuración Requerida

### Variables de Entorno en Supabase Secrets
- `EMAIL_SERVER_URL` - URL del servidor con IP estática
- `EMAIL_SERVER_SECRET` - Token de autenticación
- `APP_NAME` - Nombre de la aplicación
- `APP_URL` - URL de la app (para redirects)

### Servidor con IP Estática
- Archivo PHP/Node.js en `manigrab.app`
- IP `153.92.215.178` en whitelist de SendGrid
- Variables de entorno configuradas

---

## 🧪 Pruebas

1. **Recuperación de contraseña:**
   - Solicitar recuperación desde Login
   - Revisar email y hacer clic en link
   - Establecer nueva contraseña
   - Hacer login con nueva contraseña

2. **Registro de usuario:**
   - Registrar nuevo usuario
   - Revisar email de bienvenida
   - Hacer clic en link de confirmación
   - Verificar que el email se confirma

---

## ✅ Estado

- ✅ Sistema de recuperación implementado
- ✅ Sistema de registro implementado
- ✅ Integración con SendGrid y servidor IP estática
- ✅ Edge Functions desplegadas
- ✅ APK generado

**El sistema está listo para pruebas.**


