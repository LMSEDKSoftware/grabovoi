# ❓ PREGUNTA PARA CHATGPT: Cambio de Contraseña en Supabase

## PROBLEMA

Estoy usando Supabase con un sistema de OTP personalizado para cambio de contraseña. El flujo es:

1. Usuario solicita cambio → Genero OTP de 6 dígitos y lo guardo en tabla `password_reset_otps`
2. Usuario ingresa OTP → Verifico el OTP
3. Usuario ingresa nueva contraseña → Actualizo usando `admin.updateUserById({ password: newPassword })`
4. **PROBLEMA:** El usuario NO puede hacer login con la nueva contraseña (error "Invalid login credentials")

## CÓDIGO ACTUAL

### Edge Function (verify-otp/index.ts)
```typescript
// Después de verificar OTP personalizado:
const updateResult = await supabase.auth.admin.updateUserById(user.id, {
  password: new_password,
});

// Reporta éxito, pero la contraseña no funciona para login
```

### Cliente (Flutter/Dart)
```dart
// Llama a la Edge Function
final res = await _supabase.functions.invoke('verify-otp', body: {
  'email': email,
  'otp_code': token,
  'new_password': newPassword,
});

// Después intenta login y falla
await _supabase.auth.signInWithPassword(
  email: email,
  password: newPassword, // ❌ Error: Invalid login credentials
);
```

## LO QUE HE INTENTADO

1. ✅ `admin.updateUserById({ password })` - Reporta éxito pero no funciona
2. ✅ API REST directa `PUT /auth/v1/admin/users/{id}` - Mismo problema
3. ✅ Esperar propagación (2s, 5s, 10s, 20s) - No ayuda
4. ✅ Reintentos múltiples - No ayuda
5. ✅ Verificar login después de actualizar - Confirma que NO funciona

## PREGUNTA

**¿Cuál es la forma CORRECTA de actualizar la contraseña de un usuario en Supabase usando Admin API cuando se tiene un sistema de OTP personalizado?**

**Requisitos:**
- Mantener el sistema de OTP personalizado (no puedo usar `resetPasswordForEmail()`)
- La contraseña debe funcionar inmediatamente después del cambio
- Usar Admin API (tengo SERVICE_ROLE_KEY)

**¿Hay algún problema conocido con `admin.updateUserById()` para contraseñas?**
**¿Necesito hacer algo adicional después de actualizar?**
**¿Hay alguna forma alternativa que funcione?**


