# ✅ Checklist de Verificación - Flujo Recovery Password

## 📋 Estado Actual del Flujo

### 1. ✅ Edge Function `send-otp`
**Estado:** DESPLEGADO ✅
- Envía link directo a: `https://manigrab.app/reset-password.php?email=...`
- Link va en el correo al usuario

### 2. ✅ Edge Function `verify-otp`
**Estado:** DESPLEGADO ✅
- Valida OTP
- Crea sesión en `password_reset_sessions`
- Devuelve `continue_url`

### 3. ✅ App Flutter
**Estado:** CONFIGURADO ✅
- Verifica OTP
- Abre `continue_url` después de verificar

### 4. ⚠️ Tabla `password_reset_sessions`
**Estado:** NECESITA VERIFICACIÓN ⚠️

**Archivo:** `database/password_reset_sessions.sql`

**Acción requerida:**
1. Ve a Supabase Dashboard → SQL Editor
2. Ejecuta el archivo: `database/password_reset_sessions.sql`
3. Verifica que la tabla existe:
   ```sql
   SELECT * FROM password_reset_sessions LIMIT 1;
   ```

### 5. ⚠️ Archivo PHP `reset-password.php`
**Estado:** NECESITA VERIFICACIÓN ⚠️

**Archivo:** `server/reset-password.php`

**Acción requerida:**
1. Verifica que el archivo está en tu servidor: `https://manigrab.app/reset-password.php`
2. Si NO está, súbelo desde: `server/reset-password.php`

**Variables de entorno requeridas en el servidor:**
```bash
SUPABASE_URL=https://whtiazgcxdnemrrgjjqf.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc... (tu service role key)
APP_URL=https://manigrab.app
```

Puedes agregarlas en:
- Archivo `.env` en el servidor
- O variables de entorno del servidor

### 6. ✅ Edge Function `verify-otp` - Variable de entorno
**Estado:** NECESITA VERIFICACIÓN ⚠️

**Variable requerida:**
```
APP_URL=https://manigrab.app
```

**Acción requerida:**
1. Ve a Supabase Dashboard → Edge Functions → verify-otp → Settings → Secrets
2. Agrega o verifica: `APP_URL=https://manigrab.app`

---

## 🔄 Flujo Completo

```
1. Usuario solicita recuperación de contraseña
   ↓
2. Edge Function send-otp:
   - Genera OTP
   - Envía correo con link: https://manigrab.app/reset-password.php?email=...
   ↓
3. Usuario recibe correo con link
   ↓
4. Usuario ingresa OTP en la app
   ↓
5. Edge Function verify-otp:
   - Valida OTP
   - Crea sesión en password_reset_sessions
   - Devuelve continue_url: https://manigrab.app/reset-password.php?email=...
   ↓
6. App abre el continue_url en el navegador
   ↓
7. Usuario ve reset-password.php:
   - PHP verifica que existe sesión válida en password_reset_sessions
   - Si existe sesión válida → muestra formulario
   - Si NO existe → muestra error
   ↓
8. Usuario ingresa nueva contraseña
   ↓
9. PHP:
   - Verifica sesión válida nuevamente
   - Obtiene user_id desde la sesión
   - Cambia password usando Service Role Key
   - Marca sesión como usada
   ↓
10. Usuario puede hacer login con nueva contraseña ✅
```

---

## ⚠️ IMPORTANTE: Comportamiento del Link en el Correo

**El link en el correo (`reset-password.php?email=...`) solo funcionará DESPUÉS de que el usuario verifique el OTP en la app.**

Si el usuario hace clic directamente en el link del correo SIN verificar el OTP primero:
- ❌ No funcionará (no hay sesión válida)
- ❌ Verá un error: "No existe una sesión válida. Por favor, solicita un nuevo código OTP."

**Flujo correcto:**
1. Usuario recibe correo con link
2. Usuario ingresa OTP en la app
3. Usuario puede usar el link del correo (ahora hay sesión válida)

O alternativamente:
1. Usuario ingresa OTP en la app
2. App abre automáticamente el link (no necesita hacer clic en el correo)

---

## ✅ Resumen de Acciones Necesarias

1. [ ] **Verificar/Crear tabla `password_reset_sessions` en Supabase**
   - Ejecutar: `database/password_reset_sessions.sql`

2. [ ] **Verificar que `reset-password.php` está en el servidor**
   - Accesible en: `https://manigrab.app/reset-password.php`
   - Si no está, subir desde: `server/reset-password.php`

3. [ ] **Configurar variables de entorno en el servidor:**
   ```
   SUPABASE_URL=https://whtiazgcxdnemrrgjjqf.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=tu_service_role_key
   APP_URL=https://manigrab.app
   ```

4. [ ] **Verificar variable de entorno en Edge Function `verify-otp`:**
   ```
   APP_URL=https://manigrab.app
   ```

---

## 🧪 Prueba del Flujo

Después de verificar todo lo anterior:

1. Solicita recuperación de contraseña desde la app
2. Verifica que recibes el correo con el link a `reset-password.php`
3. Ingresa el OTP en la app
4. Verifica que la app abre automáticamente `reset-password.php`
5. Verifica que puedes cambiar la contraseña
6. Verifica que puedes hacer login con la nueva contraseña

---

## 📞 Si Algo No Funciona

1. **El link del correo no funciona:**
   - Verifica que existe sesión en `password_reset_sessions` después de verificar OTP
   - Revisa logs de `verify-otp` en Supabase

2. **El PHP muestra error:**
   - Verifica que las variables de entorno están configuradas
   - Revisa logs del servidor PHP

3. **No se puede cambiar la contraseña:**
   - Verifica que la sesión existe y no está expirada
   - Verifica que el Service Role Key es correcto
   - Revisa logs del servidor PHP

