# 🔐 Opciones para Solucionar Recuperación de Contraseña

## 🔴 Problema Actual

El link de recuperación está expirando o dando error `access_denied` / `otp_expired` antes de que el usuario pueda usarlo.

---

## ✅ OPCIÓN 1: Usar `resetPasswordForEmail()` Directo (MÁS SIMPLE)

**Ventajas:**
- ✅ Método oficial de Supabase
- ✅ Sin Edge Functions personalizadas
- ✅ Supabase maneja expiración y validación
- ✅ Menos código, menos puntos de falla

**Desventajas:**
- ⚠️ Requiere que Supabase pueda enviar emails (o usar SMTP configurado)
- ⚠️ Menos control sobre el diseño del email

**Implementación:**
1. Llamar `_supabase.auth.resetPasswordForEmail(email, { redirectTo })` directamente desde Flutter
2. Supabase envía el email automáticamente
3. Usuario hace clic en el link → redirige a tu app
4. Capturar tokens de la URL y procesar en `AuthCallbackScreen`
5. Mostrar pantalla para nueva contraseña
6. Usar `updateUser({ password })` con la sesión activa

**Cambios necesarios:**
- Modificar `resetPassword()` en `auth_service_simple.dart` para usar método directo
- Simplificar o eliminar Edge Functions `send-otp` y `verify-otp`
- Asegurar que SMTP esté configurado en Supabase (o usar el servidor personalizado con webhook)

---

## ✅ OPCIÓN 2: OTP Personalizado Completo (MÁXIMO CONTROL)

**Ventajas:**
- ✅ Control total sobre expiración (puedes hacer tokens más duraderos)
- ✅ Control sobre diseño de email
- ✅ No depende de los links de Supabase que expiran
- ✅ Puedes regenerar tokens fácilmente

**Desventajas:**
- ⚠️ Más código para mantener
- ⚠️ Necesitas manejar seguridad manualmente
- ⚠️ Más complejo

**Implementación:**
1. Generar código OTP de 6-8 dígitos
2. Guardar en BD con hash (no texto plano)
3. Enviar código por email
4. Usuario ingresa código en la app
5. Validar código (verificar no expirado, no usado)
6. Si válido, generar recovery token de Supabase y usarlo inmediatamente
7. O directamente actualizar contraseña usando Admin API (con validaciones)

**Cambios necesarios:**
- Modificar `send-otp` para generar y almacenar OTP
- Crear `verify-otp` que valide código y permita cambio de contraseña
- Actualizar UI para pedir código OTP en lugar de usar link

---

## ✅ OPCIÓN 3: Extraer Token Directamente Sin Verify Endpoint (HÍBRIDO)

**Ventajas:**
- ✅ Usa el sistema oficial de Supabase para generar tokens
- ✅ Evita el problema de expiración del verify endpoint
- ✅ Control sobre el email

**Desventajas:**
- ⚠️ Requiere procesar el token manualmente
- ⚠️ Puede ser más complejo

**Implementación:**
1. Edge Function genera recovery link usando `admin.generateLink()`
2. **NO enviamos el link completo**, extraemos solo el token
3. Construimos nuestra propia URL: `https://tuapp.com/reset?token=XXX`
4. Usuario hace clic → va a tu app directamente (no pasa por Supabase verify)
5. Tu app extrae el token y usa `exchangeCodeForSession(token)` directamente
6. Si funciona, mostrar pantalla de nueva contraseña
7. Usar `updateUser({ password })` con sesión activa

**Cambios necesarios:**
- Modificar `send-otp` para extraer token y construir URL personalizada
- Actualizar `AuthCallbackScreen` para manejar tokens directamente
- No depender del endpoint `/verify` de Supabase

---

## ✅ OPCIÓN 4: Usar Recovery Token con Sesión Temporal (ACTUAL MEJORADO)

**Ventajas:**
- ✅ Similar a lo actual pero con mejor manejo de errores
- ✅ Usa el sistema oficial de Supabase
- ✅ Permite regenerar tokens si expiran

**Desventajas:**
- ⚠️ Aún depende de los tokens de Supabase y su expiración

**Implementación:**
1. Edge Function genera recovery link
2. Enviar link completo en email
3. Usuario hace clic → Supabase redirige a tu app
4. **Si expira, ofrecer regenerar token automáticamente**
5. Procesar token y establecer sesión
6. Cambiar contraseña

**Cambios necesarios:**
- Mejorar manejo de errores en `AuthCallbackScreen`
- Si token expirado, llamar automáticamente a regenerar
- Agregar timeout más largo para tokens
- Mejorar UX mostrando tiempo restante antes de expiración

---

## ✅ OPCIÓN 5: Sistema Mixto OTP + Link (RECOMENDADO)

**Ventajas:**
- ✅ Mejor UX: usuario puede usar código OTP rápido O link del email
- ✅ Flexibilidad: si uno falla, tiene alternativa
- ✅ Más seguro: requiere que el usuario tenga acceso al email

**Desventajas:**
- ⚠️ Más complejo de implementar

**Implementación:**
1. Generar código OTP (6 dígitos) Y recovery link
2. Enviar email con AMBOS: código y link
3. Mostrar pantalla en app con 2 opciones:
   - Opción A: Ingresar código OTP (rápido)
   - Opción B: Hacer clic en link del email
4. Si usa código: validar y generar sesión temporal para cambio
5. Si usa link: procesar normalmente
6. Ambos caminos llevan a pantalla de nueva contraseña

**Cambios necesarios:**
- Modificar `send-otp` para generar ambos
- Actualizar UI para mostrar ambas opciones
- Manejar ambos flujos en el cliente

---

## 📊 Comparación de Opciones

| Opción | Complejidad | Control | Fiabilidad | Recomendación |
|--------|-------------|---------|------------|---------------|
| **1. Directo** | ⭐ Baja | ⭐⭐ Media | ⭐⭐⭐ Alta | ⭐⭐⭐ Muy Recomendado |
| **2. OTP Completo** | ⭐⭐⭐ Alta | ⭐⭐⭐ Alta | ⭐⭐ Media | ⭐⭐ Si necesitas control total |
| **3. Token Directo** | ⭐⭐ Media | ⭐⭐⭐ Alta | ⭐⭐⭐ Alta | ⭐⭐⭐ Recomendado |
| **4. Actual Mejorado** | ⭐⭐ Media | ⭐⭐ Media | ⭐⭐ Media | ⭐ Si quieres mantener flujo actual |
| **5. Mixto** | ⭐⭐⭐ Alta | ⭐⭐⭐ Alta | ⭐⭐⭐ Alta | ⭐⭐ Mejor UX |

---

## 🎯 RECOMENDACIÓN FINAL

**Para solución RÁPIDA:** Opción 1 (Directo con `resetPasswordForEmail()`)
- Es el método oficial
- Menos código
- Supabase maneja todo

**Para solución ROBUSTA:** Opción 3 (Token Directo)
- Evita problemas de expiración
- Control total
- Usa sistema oficial de Supabase

**Para mejor UX:** Opción 5 (Mixto)
- Flexibilidad para el usuario
- Si uno falla, tiene alternativa

---

## 📝 Próximos Pasos

1. Decidir qué opción implementar
2. Revisar código actual
3. Implementar cambios
4. Probar en desarrollo
5. Probar en producción

