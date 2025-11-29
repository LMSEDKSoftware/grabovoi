# ✅ Implementación de la Solución de IVO - Recovery Password

## 🎯 Resumen

Implementación completa de la solución recomendada por IVO para cambiar contraseñas usando Service Role Key desde PHP backend, evitando completamente el bug de Supabase Auth.

## 📋 Cambios Realizados

### 1. Nueva Tabla: `password_reset_sessions`

**Archivo:** `database/password_reset_sessions.sql`

Crea una tabla de seguridad que solo permite cambiar password si el OTP fue validado previamente:

- `email`: Email del usuario
- `allowed_for_reset`: Boolean que indica si está permitido cambiar password
- `expires_at`: Expiración (10 minutos)
- `used`: Si la sesión ya fue usada
- `user_id`: Referencia al usuario
- `otp_id`: Referencia al OTP validado

**Para aplicar:**
```sql
-- Ejecutar en Supabase SQL Editor
-- Archivo: database/password_reset_sessions.sql
```

### 2. Edge Function `verify-otp` Modificada

**Archivo:** `supabase/functions/verify-otp/index.ts`

**Cambios:**
- ✅ Después de validar OTP, crea un registro en `password_reset_sessions`
- ✅ Devuelve `continue_url` en lugar de `recovery_link`
- ✅ La URL apunta a `reset-password.php?email=...`

**Respuesta nueva:**
```json
{
  "ok": true,
  "continue_url": "https://manigrab.app/reset-password.php?email=usuario@email.com"
}
```

**Para aplicar:**
```bash
supabase functions deploy verify-otp
```

### 3. Nueva Página PHP: `reset-password.php`

**Archivo:** `server/reset-password.php`

**Características:**
- ✅ Verifica que existe sesión válida antes de mostrar formulario
- ✅ Cambia password usando Service Role Key (backend)
- ✅ Marca sesión como usada después del cambio
- ✅ Formulario seguro con validaciones
- ✅ Diseño responsive y moderno

**Para desplegar:**
1. Subir `server/reset-password.php` a tu servidor
2. Asegurarse de que esté accesible en: `https://manigrab.app/reset-password.php`

**Variables de entorno requeridas en el servidor:**
```bash
SUPABASE_URL=https://whtiazgcxdnemrrgjjqf.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc... (tu service role key)
APP_URL=https://manigrab.app
```

## 🔄 Flujo Completo

```
1. Usuario solicita OTP
   ↓
2. Edge Function send-otp envía código por email
   ↓
3. Usuario ingresa OTP en la app
   ↓
4. Edge Function verify-otp:
   - Valida OTP
   - Crea sesión en password_reset_sessions
   - Devuelve continue_url
   ↓
5. App abre navegador con continue_url
   ↓
6. Usuario ve reset-password.php
   - PHP verifica sesión válida
   - Muestra formulario si es válido
   ↓
7. Usuario ingresa nueva contraseña
   ↓
8. PHP:
   - Verifica sesión válida
   - Obtiene user_id
   - Cambia password usando Service Role Key
   - Marca sesión como usada
   ↓
9. Usuario puede hacer login con nueva contraseña ✅
```

## 🔒 Seguridad Implementada

1. ✅ **Verificación de sesión**: Solo permite cambiar password si existe sesión válida
2. ✅ **Service Role Key**: Nunca expuesto al cliente, solo en backend PHP
3. ✅ **Expiración**: Sesiones expiran en 10 minutos
4. ✅ **Uso único**: Sesión marcada como usada después del cambio
5. ✅ **HTTPS obligatorio**: Requerido para producción

## 📝 Configuración Requerida

### En Supabase Dashboard

1. **Ejecutar SQL:**
   ```sql
   -- Ejecutar: database/password_reset_sessions.sql
   ```

2. **Variables de entorno en Edge Function `verify-otp`:**
   ```
   APP_URL=https://manigrab.app
   ```

### En tu Servidor (manigrab.app)

1. **Subir archivo:**
   - `server/reset-password.php` → `https://manigrab.app/reset-password.php`

2. **Configurar variables de entorno:**
   
   **📖 Ver guía completa:** `docs/CONFIGURAR_VARIABLES_SERVIDOR.md`
   
   **Método rápido (recomendado):**
   
   Crear archivo `.env` en el mismo directorio que `reset-password.php`:
   ```env
   SUPABASE_URL=https://whtiazgcxdnemrrgjjqf.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=tu_service_role_key_completo_aqui
   APP_URL=https://manigrab.app
   ```
   
   **⚠️ IMPORTANTE:**
   - Reemplaza `tu_service_role_key_completo_aqui` con tu Service Role Key real
   - Obténlo en: Supabase Dashboard → Settings → API → service_role key
   - Configura permisos: `chmod 600 .env`
   
   **Alternativas:**
   - cPanel: Variables de Entorno (si tu hosting lo permite)
   - Apache: `.htaccess` con `SetEnv`
   - Ver `docs/CONFIGURAR_VARIABLES_SERVIDOR.md` para todos los métodos

## ✅ Ventajas de Esta Solución

1. ✅ **Evita bug de Supabase**: Cambio desde backend usando Service Role
2. ✅ **Control total**: Tú controlas todo el proceso
3. ✅ **Seguro**: Service Role Key nunca expuesto
4. ✅ **Elegante**: Flujo claro y simple
5. ✅ **Estable**: No depende de PKCE ni recovery sessions

## 🧪 Prueba del Flujo

1. Solicitar OTP desde la app
2. Ingresar OTP correcto
3. La app debe abrir `reset-password.php?email=...`
4. Ingresar nueva contraseña
5. Verificar que se muestre mensaje de éxito
6. Intentar login en la app con nueva contraseña
7. ✅ Debe funcionar inmediatamente

## 🐛 Troubleshooting

### Error: "No existe una sesión válida"
- **Causa:** El OTP no fue validado o la sesión expiró
- **Solución:** Solicitar nuevo OTP desde la app

### Error: "SUPABASE_SERVICE_ROLE_KEY no está configurado"
- **Causa:** Variable de entorno faltante
- **Solución:** Configurar variable en servidor o archivo .env

### Error: "Usuario no encontrado"
- **Causa:** Email no coincide con usuario en Supabase Auth
- **Solución:** Verificar que el email sea correcto

## 📚 Referencias

- Solución recomendada por IVO (arquitecto de seguridad)
- Documentación Supabase Admin API: https://supabase.com/docs/reference/api/auth-admin-update-user-by-id

