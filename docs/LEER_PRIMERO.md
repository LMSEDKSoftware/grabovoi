# 📋 LEE ESTO PRIMERO - CONTEXTO PARA CHATGPT

## 📁 ARCHIVOS A REVISAR

1. **docs/PREGUNTA_CHATGPT.md** - Pregunta directa con código
2. **docs/CONTEXTO_COMPLETO_CHATGPT.md** - Contexto completo del problema
3. **docs/PROBLEMA_CAMBIO_CONTRASEÑA.md** - Resumen técnico

## 🔴 PROBLEMA EN UNA LÍNEA

`admin.updateUserById({ password })` reporta éxito pero la contraseña NO funciona para login.

## 📂 ARCHIVOS DE CÓDIGO

- `supabase/functions/verify-otp/index.ts` - Edge Function completa
- `lib/services/auth_service_simple.dart` (líneas 548-627) - Método del cliente
- `database/custom_otp_password_reset.sql` - Esquema de tabla OTP

## ❓ PREGUNTA PARA CHATGPT

Copia el contenido de `docs/PREGUNTA_CHATGPT.md` y los archivos de código arriba mencionados.
