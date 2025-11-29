# 📋 CONTEXTO COMPLETO - SISTEMA DE RECUPERACIÓN DE CONTRASEÑA

## 🎯 RESUMEN EJECUTIVO

Sistema de recuperación de contraseña implementado con flujo híbrido OTP + PHP. El usuario solicita recuperación, recibe un código OTP de 6 dígitos por email junto con un enlace, ingresa el código en la app, la app verifica el código, crea una sesión segura, y luego abre un enlace PHP donde el usuario puede cambiar su contraseña.

**PROBLEMA ACTUAL:** Cuando el usuario llega a la página PHP (`reset-password.php`), muestra el error "Usuario no encontrado" o "No existe una sesión válida".

---

## 🔄 FLUJO COMPLETO (COMO DEBERÍA FUNCIONAR)

```
1. Usuario en app → Solicita recuperar contraseña
   ↓
2. App llama a Edge Function `send-otp`
   ↓
3. `send-otp` genera código OTP de 6 dígitos
   ↓
4. `send-otp` guarda OTP en tabla `password_reset_otps`
   ↓
5. `send-otp` envía email con:
   - Código OTP de 6 dígitos
   - Link directo a: https://manigrab.app/reset-password.php?email=...
   ↓
6. Usuario recibe email, ve el código OTP
   ↓
7. Usuario abre app, ingresa código OTP
   ↓
8. App llama a Edge Function `verify-otp`
   ↓
9. `verify-otp` verifica que el código OTP sea correcto
   ↓
10. `verify-otp` crea sesión en tabla `password_reset_sessions`
    ↓
11. `verify-otp` devuelve `continue_url`: https://manigrab.app/reset-password.php?email=...
    ↓
12. App muestra mensaje "OTP correcto" y abre navegador con el enlace
    ↓
13. Usuario ve página PHP `reset-password.php`
    ↓
14. PHP verifica que existe sesión válida en `password_reset_sessions`
    ↓
15. PHP muestra formulario para cambiar contraseña
    ↓
16. Usuario ingresa nueva contraseña y confirma
    ↓
17. PHP cambia contraseña usando Service Role Key
    ↓
18. PHP marca sesión como usada
    ↓
19. ✅ Usuario puede hacer login con nueva contraseña
```

---

## ❌ PROBLEMA ACTUAL

En el **PASO 14**, cuando PHP intenta verificar la sesión, NO la encuentra o falla al buscar el usuario. Se muestra:
- "Usuario no encontrado"
- "No existe una sesión válida"

---

## 📁 ARCHIVOS DEL SISTEMA

### 1. EDGE FUNCTION: `send-otp`
**Ubicación:** `supabase/functions/send-otp/index.ts`

**Responsabilidad:**
- Recibe email del usuario
- Genera código OTP de 6 dígitos
- Guarda OTP en tabla `password_reset_otps`
- Envía email con OTP y enlace directo a `reset-password.php`
- Construye URL: `https://manigrab.app/reset-password.php?email={email}`

---

### 2. EDGE FUNCTION: `verify-otp`
**Ubicación:** `supabase/functions/verify-otp/index.ts`

**Responsabilidad:**
- Recibe email y código OTP
- Verifica que el código sea correcto y no esté expirado
- Marca OTP como usado
- Crea sesión en tabla `password_reset_sessions`
- Devuelve `continue_url` con el enlace a `reset-password.php`

**CRÍTICO:** Esta función DEBE crear la sesión exitosamente, de lo contrario devuelve error.

---

### 3. PÁGINA PHP: `reset-password.php`
**Ubicación:** `server/reset-password.php`

**Responsabilidad:**
- Verifica que existe sesión válida en `password_reset_sessions`
- Muestra formulario para cambiar contraseña
- Usa Service Role Key para cambiar contraseña del usuario
- Marca sesión como usada

**PROBLEMA:** No encuentra la sesión o no encuentra el usuario.

---

### 4. APP FLUTTER: `login_screen.dart`
**Ubicación:** `lib/screens/auth/login_screen.dart`

**Responsabilidad:**
- Muestra diálogo para ingresar código OTP
- Llama a `verifyOTPAndGetRecoveryLink` del servicio de autenticación
- Muestra mensaje "OTP correcto"
- Abre navegador con el `continue_url`

---

### 5. SERVICIO DE AUTENTICACIÓN: `auth_service_simple.dart`
**Ubicación:** `lib/services/auth_service_simple.dart`

**Método clave:** `verifyOTPAndGetRecoveryLink`
- Llama a Edge Function `verify-otp`
- Obtiene `continue_url` de la respuesta
- Devuelve la URL al screen

---

### 6. TABLAS DE BASE DE DATOS

#### Tabla: `password_reset_otps`
**Ubicación:** `database/custom_otp_password_reset.sql`

Almacena los códigos OTP generados:
- `id` (uuid)
- `email` (text)
- `otp_code` (text) - código de 6 dígitos
- `recovery_link` (text) - URL a reset-password.php
- `expires_at` (timestamptz)
- `used` (boolean)
- `created_at` (timestamptz)

#### Tabla: `password_reset_sessions`
**Ubicación:** `database/password_reset_sessions.sql`

Almacena sesiones válidas para cambiar contraseña:
- `id` (uuid)
- `email` (text)
- `allowed_for_reset` (boolean)
- `expires_at` (timestamptz)
- `used` (boolean)
- `user_id` (uuid) - ID del usuario en auth.users
- `otp_id` (uuid) - Referencia al OTP validado
- `created_at` (timestamptz)

**IMPORTANTE:** Esta tabla tiene RLS (Row Level Security) habilitado con políticas que bloquean todo acceso. Solo el Service Role Key puede acceder.

---

## 🔍 ANÁLISIS DEL PROBLEMA

### Posibles causas:

1. **La sesión no se está creando en `verify-otp`:**
   - La función puede estar fallando al crear la sesión
   - RLS puede estar bloqueando la inserción
   - El `user_id` puede ser null

2. **PHP no puede leer la sesión:**
   - RLS está bloqueando la lectura
   - El Service Role Key no está haciendo bypass de RLS correctamente
   - El email no coincide exactamente (mayúsculas/minúsculas)

3. **La sesión expiró:**
   - La sesión tiene expiración de 10 minutos
   - Si el usuario tarda, la sesión ya no es válida

4. **El usuario no existe:**
   - La búsqueda del usuario por email falla
   - El `user_id` en la sesión es null y la búsqueda falla

---

## 📝 ARCHIVOS COMPLETOS

---

## ARCHIVO 1: `supabase/functions/send-otp/index.ts`

```typescript
// deno-lint-ignore-file no-explicit-any
import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Helper function para guardar logs en la base de datos
async function saveLog(
  supabase: any,
  email: string,
  action: string,
  message: string,
  logLevel: 'debug' | 'info' | 'warning' | 'error' = 'info',
  metadata?: Record<string, any>,
  otpId?: string,
  userId?: string,
  errorDetails?: Record<string, any>
) {
  try {
    const logData: any = {
      email,
      function_name: 'send-otp',
      action,
      message,
      log_level: logLevel,
      metadata: metadata || {},
    }
    
    if (otpId) logData.otp_id = otpId
    if (userId) logData.user_id = userId
    if (errorDetails) logData.error_details = errorDetails
    
    const { error } = await supabase
      .from('otp_transaction_logs')
      .insert(logData)
    
    if (error) {
      console.error('⚠️ Error guardando log en BD:', error)
    }
  } catch (err) {
    console.error('⚠️ Error en función saveLog:', err)
  }
}

Deno.serve(async (req) => {
  console.log('🚀 Función send-otp invocada')
  console.log('📥 Método:', req.method)
  console.log('📥 URL:', req.url)
  
  let supabase: any = null
  let requestEmail: string = ''
  
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Content-Type': 'application/json',
  }

  if (req.method === 'OPTIONS') {
    console.log('✅ Respondiendo a OPTIONS (CORS)')
    return new Response(null, { status: 204, headers: corsHeaders })
  }
  if (req.method !== 'POST') {
    console.error('❌ Método no permitido:', req.method)
    return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers: corsHeaders })
  }

  console.log('📧 Procesando solicitud POST...')
  const { email, redirectTo: clientRedirectTo } = await req.json().catch(() => ({}))
  console.log('📧 Email recibido:', email)
  console.log('📧 RedirectTo del cliente:', clientRedirectTo || 'no proporcionado')
  if (!email || typeof email !== 'string') {
    return new Response(JSON.stringify({ error: 'email requerido' }), { status: 400, headers: corsHeaders })
  }

  const SUPABASE_URL = Deno.env.get('SB_URL')!
  const SERVICE_ROLE_KEY = Deno.env.get('SB_SERVICE_ROLE_KEY')!
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
    return new Response(JSON.stringify({ error: 'Faltan variables de entorno' }), { status: 500, headers: corsHeaders })
  }

  supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)
  requestEmail = email.toLowerCase().trim()

  // Guardar log inicial
  await saveLog(supabase, requestEmail, 'otp_request_received', `Solicitud de OTP recibida para ${requestEmail}`, 'info', {
    method: req.method,
    url: req.url
  })

  // Verificar que el usuario exista en auth
  console.log('🔍 Buscando usuario en auth...')
  await saveLog(supabase, requestEmail, 'user_lookup_started', `Iniciando búsqueda de usuario en auth`, 'debug')
  const { data: usersData, error: usersErr } = await supabase.auth.admin.listUsers({
    page: 1,
    perPage: 1000,
  } as any)
  
  if (usersErr) {
    console.error('❌ Error listando usuarios:', usersErr)
    await saveLog(supabase, requestEmail, 'user_lookup_error', `Error buscando usuario: ${usersErr.message}`, 'error', {}, undefined, undefined, {
      error: usersErr.message,
      code: usersErr.status
    })
    return new Response(JSON.stringify({ error: 'Error validando usuario' }), { status: 500, headers: corsHeaders })
  }
  
  // Filtrar por email (case-insensitive)
  const normalizedEmail = email.toLowerCase().trim()
  const foundUser = usersData?.users?.find((u: any) => {
    const userEmail = u.email?.toLowerCase().trim()
    return userEmail === normalizedEmail
  })
  const userExists = !!foundUser
  
  console.log('👤 Usuario existe en auth:', userExists)
  console.log('📧 Email buscado:', normalizedEmail)
  
  await saveLog(supabase, requestEmail, 'user_lookup_completed', `Usuario ${userExists ? 'encontrado' : 'NO encontrado'} en auth`, userExists ? 'info' : 'warning', {
    total_users_searched: usersData?.users?.length || 0,
    user_exists: userExists,
    user_id: foundUser?.id || null
  }, undefined, foundUser?.id)
  
  if (!userExists) {
    // Para no filtrar emails válidos, responder 200 siempre
    console.log('⚠️ Usuario no existe, pero respondiendo OK por seguridad')
    await saveLog(supabase, requestEmail, 'otp_request_rejected', `Usuario no existe, respondiendo OK por seguridad`, 'warning', {
      reason: 'user_not_found'
    })
    return new Response(JSON.stringify({ ok: true }), { status: 200, headers: corsHeaders })
  }

  // GENERAR CÓDIGO OTP DE 6 DÍGITOS
  const otpCode = String(Math.floor(100000 + Math.random() * 900000)) // Código de 6 dígitos
  console.log(`   ✅ Código OTP generado: ${otpCode}`)
  
  // CONSTRUIR LINK DIRECTO A reset-password.php
  const baseUrl = Deno.env.get('APP_URL') || 'https://manigrab.app'
  const finalRecoveryUrl = `${baseUrl}/reset-password.php?email=${encodeURIComponent(requestEmail)}`
  
  console.log(`   ✅ Link directo a reset-password.php construido`)
  console.log(`   URL final a enviar: ${finalRecoveryUrl}`)
  
  // Calcular fecha de expiración (1 hora como Supabase)
  const expiresAt = new Date(Date.now() + 60 * 60 * 1000).toISOString()
  console.log(`   Expira en: ${expiresAt}`)
  
  await saveLog(supabase, requestEmail, 'otp_generated', `Código OTP generado correctamente`, 'info', {
    otp_code_length: otpCode.length,
    recovery_link_length: finalRecoveryUrl.length,
    expires_at: expiresAt
  }, undefined, foundUser.id)

  console.log('💾 Guardando OTP y recovery link en base de datos...')
  // Guardar el OTP y recovery_link en la base de datos
  let insertedOtp: any = null
  try {
    const { data, error: insErr } = await supabase.from('password_reset_otps').insert({
      email: requestEmail,
      otp_code: otpCode,
      recovery_link: finalRecoveryUrl,
      expires_at: expiresAt,
      used: false,
    }).select().single()
    
    if (insErr) {
      console.warn('⚠️ Error guardando recovery link en BD (no crítico):', insErr.message)
    } else {
      insertedOtp = data
      console.log('✅ Recovery link guardado en base de datos')
      await saveLog(supabase, requestEmail, 'recovery_link_saved', `Recovery link guardado en base de datos exitosamente`, 'info', {
        otp_id: insertedOtp.id,
        expires_at: expiresAt
      }, insertedOtp.id, foundUser.id)
    }
  } catch (dbError: any) {
    console.warn('⚠️ Error guardando en BD (continuando):', dbError.message)
  }

  // ... (código de envío de email continúa)
  
  // El email se envía con:
  // - Código OTP: ${otpCode}
  // - Link: ${finalRecoveryUrl}
  
  return new Response(JSON.stringify({ ok: true }), { status: 200, headers: corsHeaders })
})
```

---

## ARCHIVO 2: `supabase/functions/verify-otp/index.ts`

```typescript
// deno-lint-ignore-file no-explicit-any
import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Helper function para guardar logs
async function saveLog(
  supabase: any,
  email: string,
  action: string,
  message: string,
  logLevel: 'debug' | 'info' | 'warning' | 'error' = 'info',
  metadata?: Record<string, any>,
  otpId?: string,
  userId?: string,
  errorDetails?: Record<string, any>
) {
  try {
    const logData: any = {
      email,
      function_name: 'verify-otp',
      action,
      message,
      log_level: logLevel,
      metadata: metadata || {},
    }
    
    if (otpId) logData.otp_id = otpId
    if (userId) logData.user_id = userId
    if (errorDetails) logData.error_details = errorDetails
    
    const { error } = await supabase
      .from('otp_transaction_logs')
      .insert(logData)
    
    if (error) {
      console.error('⚠️ Error guardando log en BD:', error)
    }
  } catch (err) {
    console.error('⚠️ Error en función saveLog:', err)
  }
}

Deno.serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Content-Type': 'application/json',
  }

  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders })
  }
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers: corsHeaders })
  }

  const { email, otp_code } = await req.json().catch(() => ({}))
  const requestEmail = email ? (email as string).toLowerCase().trim() : ''
  
  const SUPABASE_URL = Deno.env.get('SB_URL')!
  const SERVICE_ROLE_KEY = Deno.env.get('SB_SERVICE_ROLE_KEY')!
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
    await saveLog(createClient(SUPABASE_URL, SERVICE_ROLE_KEY), requestEmail || 'unknown', 'config_error', 'Faltan variables de entorno', 'error')
    return new Response(JSON.stringify({ error: 'Faltan variables de entorno' }), { status: 500, headers: corsHeaders })
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)
  
  if (!email || !otp_code) {
    await saveLog(supabase, requestEmail || 'unknown', 'validation_error', 'Faltan parámetros requeridos', 'error', {
      has_email: !!email,
      has_otp_code: !!otp_code
    })
    return new Response(JSON.stringify({ error: 'email y otp_code requeridos' }), { status: 400, headers: corsHeaders })
  }

  // Buscar OTP válido
  const now = new Date().toISOString()
  const { data: rows, error: selErr } = await supabase
    .from('password_reset_otps')
    .select('*')
    .eq('email', requestEmail)
    .eq('used', false)
    .gte('expires_at', now)
    .order('created_at', { ascending: false })
    .limit(1)

  if (selErr || !rows || rows.length === 0) {
    await saveLog(supabase, requestEmail, 'otp_not_found', `OTP inválido o expirado`, 'warning', {
      error: selErr?.message,
      rows_found: rows?.length || 0
    })
    return new Response(JSON.stringify({ error: 'OTP inválido o expirado' }), { status: 400, headers: corsHeaders })
  }

  const otpRow = rows[0]
  
  // Verificar que el código corto coincida
  if (String(otpRow.otp_code) !== String(otp_code)) {
    await saveLog(supabase, requestEmail, 'otp_mismatch', `Código OTP no coincide`, 'warning', {
      otp_id: otpRow.id,
    })
    return new Response(JSON.stringify({ error: 'OTP incorrecto' }), { status: 400, headers: corsHeaders })
  }
  
  // Obtener usuario para tener su ID
  const { data: users, error: usersErr } = await supabase.auth.admin.listUsers({
    page: 1,
    perPage: 1000,
  } as any)
  
  let userId: string | undefined = undefined
  if (!usersErr && users?.users?.length) {
    const user = users.users.find((u: any) => u.email?.toLowerCase() === requestEmail)
    if (user) {
      userId = user.id
    }
  }

  // Marcar OTP como usado
  await supabase
    .from('password_reset_otps')
    .update({ used: true })
    .eq('id', otpRow.id)

  // Crear sesión de reset de password (CRÍTICO)
  const APP_URL = Deno.env.get('APP_URL') || 'https://manigrab.app'
  const expiresAt = new Date()
  expiresAt.setMinutes(expiresAt.getMinutes() + 10) // 10 minutos para cambiar password

  const { data: sessionData, error: sessionErr } = await supabase
    .from('password_reset_sessions')
    .insert({
      email: requestEmail,
      allowed_for_reset: true,
      expires_at: expiresAt.toISOString(),
      user_id: userId,
      otp_id: otpRow.id,
      used: false
    })
    .select()
    .single()

  if (sessionErr) {
    console.error('❌ No se pudo crear sesión de reset:', sessionErr)
    await saveLog(supabase, requestEmail, 'reset_session_creation_error', `Error creando sesión de reset: ${sessionErr.message}`, 'error', {
      otp_id: otpRow.id,
      error_details: sessionErr
    }, otpRow.id, {
      error: sessionErr.message
    })
    
    // NO continuar si no se pudo crear la sesión - es crítico para la seguridad
    return new Response(JSON.stringify({ 
      ok: false,
      error: 'Error interno: No se pudo crear la sesión de recuperación. Por favor, solicita un nuevo código OTP.'
    }), { status: 500, headers: corsHeaders })
  }
  
  // Verificar que la sesión se creó correctamente
  if (!sessionData || !sessionData.id) {
    console.error('❌ Sesión creada pero sin datos válidos')
    return new Response(JSON.stringify({ 
      ok: false,
      error: 'Error interno: Sesión de recuperación inválida. Por favor, solicita un nuevo código OTP.'
    }), { status: 500, headers: corsHeaders })
  }
  
  await saveLog(supabase, requestEmail, 'reset_session_created', `Sesión de reset creada exitosamente`, 'info', {
    otp_id: otpRow.id,
    session_id: sessionData.id,
    user_id: sessionData.user_id || userId,
    expires_at: sessionData.expires_at
  }, otpRow.id)
  
  // Regresar URL a la página PHP donde cambiará la contraseña
  console.log('✅ OTP verificado y sesión creada, devolviendo continue_url')
  return new Response(JSON.stringify({ 
    ok: true,
    continue_url: `${APP_URL}/reset-password.php?email=${encodeURIComponent(requestEmail)}`,
  }), { status: 200, headers: corsHeaders })
})
```

---

## ARCHIVO 3: `server/reset-password.php`

```php
<?php
/**
 * Página para reset de contraseña usando Service Role Key
 * Solo permite cambiar password si existe una sesión válida creada después de verificar OTP
 */

header('Content-Type: text/html; charset=utf-8');

// CONFIGURACIÓN
$SUPABASE_URL = getenv('SUPABASE_URL') ?: 'https://whtiazgcxdnemrrgjjqf.supabase.co';
$SERVICE_ROLE_KEY = getenv('SUPABASE_SERVICE_ROLE_KEY');
$APP_URL = getenv('APP_URL') ?: 'https://manigrab.app';

// Cargar desde .env si existe
$envFile = __DIR__ . '/.env';
if (file_exists($envFile)) {
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (strpos(trim($line), '#') === 0) continue;
        if (strpos($line, '=') !== false) {
            list($key, $value) = explode('=', $line, 2);
            $key = trim($key);
            $value = trim($value, '"\'');
            if (!empty($key) && !empty($value)) {
                putenv("$key=$value");
                if ($key === 'SUPABASE_URL') $SUPABASE_URL = $value;
                if ($key === 'SUPABASE_SERVICE_ROLE_KEY') $SERVICE_ROLE_KEY = $value;
                if ($key === 'APP_URL') $APP_URL = $value;
            }
        }
    }
}

// Validar configuración crítica
if (empty($SERVICE_ROLE_KEY)) {
    http_response_code(500);
    die('❌ Error de configuración: SUPABASE_SERVICE_ROLE_KEY no está configurado');
}

// Decodificar email de la URL
$rawEmail = isset($_GET['email']) ? $_GET['email'] : '';
$email = !empty($rawEmail) ? trim(strtolower(urldecode($rawEmail))) : '';
$success = false;
$error = '';
$message = '';

// Log para debugging
error_log("📧 Email recibido en reset-password.php:");
error_log("   Email raw: " . $rawEmail);
error_log("   Email decodificado: " . $email);

/**
 * Verificar si existe sesión válida para reset de password
 */
function verifyResetSession($supabaseUrl, $serviceRoleKey, $email) {
    error_log("🔍 Verificando sesión para email: " . $email);
    
    $endpoint = $supabaseUrl . '/rest/v1/password_reset_sessions';
    $params = http_build_query([
        'email' => 'eq.' . $email,
        'allowed_for_reset' => 'eq.true',
        'used' => 'eq.false',
        'expires_at' => 'gt.' . date('c'),
        'order' => 'created_at.desc',
        'limit' => '1'
    ]);
    
    error_log("🔗 Endpoint: " . $endpoint . '?' . $params);
    
    $ch = curl_init($endpoint . '?' . $params);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'apikey: ' . $serviceRoleKey,
        'Authorization: Bearer ' . $serviceRoleKey,
        'Content-Type: application/json'
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    error_log("📡 Respuesta de verificación de sesión: HTTP " . $httpCode);
    error_log("📡 Response body: " . substr($response, 0, 500));
    
    if ($httpCode !== 200) {
        error_log("❌ Error HTTP al verificar sesión: " . $httpCode);
        return ['valid' => false, 'error' => 'Error verificando sesión. Por favor, intenta nuevamente.'];
    }
    
    $data = json_decode($response, true);
    
    // Log detallado de la respuesta
    error_log("📦 Data completa recibida: " . json_encode($data));
    
    // Verificar si hay error en la respuesta
    if (isset($data['message']) || isset($data['error']) || isset($data['hint'])) {
        error_log("❌ Error en respuesta de Supabase:");
        error_log("   Message: " . ($data['message'] ?? 'N/A'));
        error_log("   Error: " . ($data['error'] ?? 'N/A'));
        error_log("   Hint: " . ($data['hint'] ?? 'N/A'));
    }
    
    // Verificar si es un array vacío o no tiene datos
    if (!is_array($data) || empty($data) || !isset($data[0])) {
        error_log("❌ No se encontró sesión válida");
        error_log("   Tipo de data: " . gettype($data));
        error_log("   Data recibida: " . json_encode($data));
        error_log("   Email buscado: " . $email);
        
        $errorMsg = 'No existe una sesión válida para este email. ';
        $errorMsg .= 'Por favor, asegúrate de: 1) Verificar el código OTP en la app primero, ';
        $errorMsg .= '2) Esperar a que aparezca "OTP correcto", y 3) Luego hacer clic en el enlace del correo.';
        
        return ['valid' => false, 'error' => $errorMsg];
    }
    
    error_log("✅ Sesión válida encontrada:");
    error_log("   Session ID: " . ($data[0]['id'] ?? 'N/A'));
    error_log("   User ID: " . ($data[0]['user_id'] ?? 'N/A'));
    error_log("   Email: " . ($data[0]['email'] ?? 'N/A'));
    error_log("   Expires at: " . ($data[0]['expires_at'] ?? 'N/A'));
    error_log("   Used: " . (isset($data[0]['used']) ? ($data[0]['used'] ? 'true' : 'false') : 'N/A'));
    error_log("   Allowed for reset: " . (isset($data[0]['allowed_for_reset']) ? ($data[0]['allowed_for_reset'] ? 'true' : 'false') : 'N/A'));
    
    return ['valid' => true, 'session' => $data[0]];
}

/**
 * Obtener usuario por email desde Supabase Auth
 */
function getUserByEmail($supabaseUrl, $serviceRoleKey, $email) {
    $endpoint = $supabaseUrl . '/auth/v1/admin/users';
    $normalizedEmail = strtolower(trim($email));
    
    // Buscar en las primeras páginas
    for ($page = 1; $page <= 3; $page++) {
        $ch = curl_init($endpoint . '?page=' . $page . '&per_page=1000');
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'apikey: ' . $serviceRoleKey,
            'Authorization: Bearer ' . $serviceRoleKey,
            'Content-Type: application/json'
        ]);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        if ($httpCode !== 200) {
            error_log("❌ Error obteniendo usuarios de Supabase Auth: HTTP " . $httpCode);
            continue;
        }
        
        $data = json_decode($response, true);
        if (isset($data['users']) && is_array($data['users'])) {
            foreach ($data['users'] as $user) {
                $userEmail = strtolower(trim($user['email'] ?? ''));
                if ($userEmail === $normalizedEmail) {
                    error_log("✅ Usuario encontrado en página " . $page . ": " . ($user['id'] ?? 'sin ID'));
                    return $user;
                }
            }
            
            if (count($data['users']) < 1000) {
                break;
            }
        } else {
            break;
        }
    }
    
    error_log("❌ Usuario no encontrado después de buscar en " . ($page - 1) . " página(s)");
    return null;
}

/**
 * Cambiar password usando Service Role Key
 */
function changePassword($supabaseUrl, $serviceRoleKey, $userId, $newPassword) {
    $endpoint = $supabaseUrl . '/auth/v1/admin/users/' . $userId;
    
    $payload = json_encode([
        'password' => $newPassword
    ]);
    
    $ch = curl_init($endpoint);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');
    curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'apikey: ' . $serviceRoleKey,
        'Authorization: Bearer ' . $serviceRoleKey,
        'Content-Type: application/json'
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    return [
        'success' => $httpCode >= 200 && $httpCode < 300,
        'http_code' => $httpCode,
        'response' => json_decode($response, true)
    ];
}

/**
 * Marcar sesión como usada
 */
function markSessionAsUsed($supabaseUrl, $serviceRoleKey, $sessionId) {
    $endpoint = $supabaseUrl . '/rest/v1/password_reset_sessions';
    $params = http_build_query([
        'id' => 'eq.' . $sessionId
    ]);
    
    $payload = json_encode([
        'used' => true
    ]);
    
    $ch = curl_init($endpoint . '?' . $params);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PATCH');
    curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'apikey: ' . $serviceRoleKey,
        'Authorization: Bearer ' . $serviceRoleKey,
        'Content-Type: application/json',
        'Prefer: return=minimal'
    ]);
    
    curl_exec($ch);
    curl_close($ch);
}

// PROCESAMIENTO DEL FORMULARIO
if ($_SERVER['REQUEST_METHOD'] === 'POST' && !empty($email)) {
    $newPassword = $_POST['new_password'] ?? '';
    $confirmPassword = $_POST['confirm_password'] ?? '';
    
    // Validaciones
    if (empty($newPassword)) {
        $error = 'La nueva contraseña es requerida';
    } elseif (strlen($newPassword) < 6) {
        $error = 'La contraseña debe tener al menos 6 caracteres';
    } elseif ($newPassword !== $confirmPassword) {
        $error = 'Las contraseñas no coinciden';
    } else {
        // Verificar sesión válida
        $sessionCheck = verifyResetSession($SUPABASE_URL, $SERVICE_ROLE_KEY, $email);
        if (!$sessionCheck['valid']) {
            $error = $sessionCheck['error'];
        } else {
            $session = $sessionCheck['session'];
            
            // Usar user_id directamente de la sesión
            $userId = $session['user_id'] ?? null;
            
            if (!$userId) {
                // Fallback: intentar obtener usuario por email
                error_log("⚠️ No hay user_id en la sesión, intentando buscar por email...");
                $user = getUserByEmail($SUPABASE_URL, $SERVICE_ROLE_KEY, $email);
                if (!$user || !isset($user['id'])) {
                    $error = 'Usuario no encontrado. Por favor, solicita un nuevo código OTP.';
                    error_log("❌ Error: No se pudo encontrar usuario por email: " . $email);
                } else {
                    $userId = $user['id'];
                }
            }
            
            if ($userId) {
                // Cambiar password usando el user_id
                error_log("🔑 Cambiando password para user_id: " . $userId);
                $result = changePassword($SUPABASE_URL, $SERVICE_ROLE_KEY, $userId, $newPassword);
                
                if ($result['success']) {
                    // Marcar sesión como usada
                    markSessionAsUsed($SUPABASE_URL, $SERVICE_ROLE_KEY, $session['id']);
                    
                    $success = true;
                    $message = '✅ Contraseña actualizada exitosamente. Ahora puedes iniciar sesión con tu nueva contraseña.';
                } else {
                    $error = 'Error al actualizar la contraseña. Por favor, intenta nuevamente.';
                    error_log("Error cambiando password: HTTP " . $result['http_code'] . " - " . json_encode($result['response']));
                }
            }
        }
    }
}

// Verificar sesión válida antes de mostrar el formulario
$canReset = false;
if (!empty($email)) {
    $sessionCheck = verifyResetSession($SUPABASE_URL, $SERVICE_ROLE_KEY, $email);
    $canReset = $sessionCheck['valid'];
    if (!$canReset && empty($error) && !$success) {
        $error = $sessionCheck['error'];
    }
}

?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recuperar Contraseña - ManiGrab</title>
    <style>
        /* ... estilos CSS ... */
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔐 Recuperar Contraseña</h1>
            <p>Ingresa tu nueva contraseña</p>
        </div>
        
        <?php if ($success): ?>
            <div class="message success">
                <?php echo htmlspecialchars($message); ?>
            </div>
        <?php elseif (!empty($error)): ?>
            <div class="message error">
                <?php echo htmlspecialchars($error); ?>
            </div>
        <?php elseif ($canReset && !empty($email)): ?>
            <div class="email-display">
                📧 <?php echo htmlspecialchars($email); ?>
            </div>
            
            <form method="POST" action="">
                <input type="hidden" name="email" value="<?php echo htmlspecialchars($email); ?>">
                
                <div class="form-group">
                    <label for="new_password">Nueva Contraseña</label>
                    <input 
                        type="password" 
                        id="new_password" 
                        name="new_password" 
                        required 
                        minlength="6"
                        placeholder="Mínimo 6 caracteres"
                    >
                </div>
                
                <div class="form-group">
                    <label for="confirm_password">Confirmar Contraseña</label>
                    <input 
                        type="password" 
                        id="confirm_password" 
                        name="confirm_password" 
                        required 
                        minlength="6"
                        placeholder="Repite tu contraseña"
                    >
                </div>
                
                <button type="submit" class="btn">
                    Cambiar Contraseña
                </button>
            </form>
        <?php else: ?>
            <div class="message error">
                No se puede mostrar el formulario. Por favor, solicita un nuevo código OTP desde la app.
            </div>
        <?php endif; ?>
    </div>
</body>
</html>
```

---

## ARCHIVO 4: `lib/screens/auth/login_screen.dart` (Método relevante)

```dart
// Diálogo para ingresar código OTP y verificar
Future<void> _showResetPasswordDialog(String email) async {
  final tokenController = TextEditingController();
  bool isLoading = false;
  
  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text('Verificar Código'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Paso 1: Ingresa el código de 6 dígitos que recibiste por email.'),
              const SizedBox(height: 20),
              TextField(
                controller: tokenController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isLoading ? null : () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: isLoading ? null : () async {
              if (tokenController.text.isEmpty || tokenController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor ingresa el código de 6 dígitos')),
                );
                return;
              }
              
              setDialogState(() {
                isLoading = true;
              });
              
              try {
                // Verificar el código OTP
                final recoveryLink = await _authService.verifyOTPAndGetRecoveryLink(
                  email: email,
                  token: tokenController.text,
                );
                
                if (context.mounted) {
                  setDialogState(() {
                    isLoading = false;
                  });
                  
                  Navigator.of(context).pop(); // Cerrar diálogo de entrada de OTP
                  
                  // Mostrar diálogo de éxito
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      title: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 32),
                          Text('OTP Correcto'),
                        ],
                      ),
                      content: Text('Tu código de verificación es válido. Te redirigiremos al siguiente paso.'),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Continuar'),
                        ),
                      ],
                    ),
                  );
                  
                  await Future.delayed(const Duration(milliseconds: 500));
                  
                  // Abrir el link para cambiar contraseña
                  final uri = Uri.parse(recoveryLink);
                  
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    throw Exception('No se pudo abrir el enlace de recuperación');
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_getErrorMessage(e.toString()))),
                  );
                  setDialogState(() {
                    isLoading = false;
                  });
                }
              }
            },
            child: Text('Verificar'),
          ),
        ],
      ),
    ),
  );
}
```

---

## ARCHIVO 5: `lib/services/auth_service_simple.dart` (Método relevante)

```dart
// Verificar OTP y obtener recovery_link
Future<String> verifyOTPAndGetRecoveryLink({
  required String email,
  required String token,
}) async {
  try {
    print('🔐 Verificando OTP para obtener recovery link...');
    
    // Llamar a la Edge Function que verifica OTP y devuelve recovery_link
    final res = await _supabase.functions.invoke('verify-otp', body: {
      'email': email,
      'otp_code': token,
    });
    
    dynamic data = res.data;
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {}
    }
    
    if (res.status != 200 || (data is Map && data['ok'] != true)) {
      final err = (data is Map ? (data['error'] ?? 'Verificación OTP fallida') : 'Verificación OTP fallida');
      throw Exception(err);
    }
    
    // Nueva implementación: verificar continue_url
    final continueUrl = (data as Map)['continue_url'] as String?;
    final recoveryLink = (data as Map)['recovery_link'] as String?;
    
    final urlToOpen = continueUrl ?? recoveryLink;
    
    if (urlToOpen == null || urlToOpen.isEmpty) {
      throw Exception('Continue URL no recibida del servidor');
    }
    
    print('✅ OTP verificado, continue URL obtenida: ${urlToOpen.substring(0, 50)}...');
    return urlToOpen;
    
  } catch (e, stackTrace) {
    print('❌ Error en verificación OTP: $e');
    rethrow;
  }
}
```

---

## ARCHIVO 6: `database/password_reset_sessions.sql`

```sql
-- Tabla para sesiones de reset de password (seguridad)
create table if not exists public.password_reset_sessions (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  allowed_for_reset boolean not null default false,
  expires_at timestamptz not null,
  ip_address text,
  used boolean not null default false,
  user_id uuid, -- ID del usuario en auth.users
  otp_id uuid, -- Referencia al OTP que fue validado
  created_at timestamptz not null default now()
);

-- Índices útiles
create index if not exists idx_password_reset_sessions_email on public.password_reset_sessions (email);
create index if not exists idx_password_reset_sessions_allowed on public.password_reset_sessions (allowed_for_reset);
create index if not exists idx_password_reset_sessions_expires on public.password_reset_sessions (expires_at);
create index if not exists idx_password_reset_sessions_used on public.password_reset_sessions (used);

-- Política de seguridad: Solo funciones/servidor pueden acceder
alter table public.password_reset_sessions enable row level security;

drop policy if exists select_none_password_reset_sessions on public.password_reset_sessions;
create policy select_none_password_reset_sessions on public.password_reset_sessions
  for select using (false);

drop policy if exists modify_none_password_reset_sessions on public.password_reset_sessions;
create policy modify_none_password_reset_sessions on public.password_reset_sessions
  for all using (false);
```

---

## ARCHIVO 7: `database/custom_otp_password_reset.sql`

```sql
-- Tabla para OTP de recuperación de contraseña
create table if not exists public.password_reset_otps (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  otp_code text not null, -- Código corto mostrado al usuario (6 dígitos)
  recovery_token text, -- Token completo de Supabase (si se usa sistema oficial)
  recovery_link text, -- URL directa a reset-password.php
  expires_at timestamptz not null,
  used boolean not null default false,
  created_at timestamptz not null default now()
);

-- Índices útiles
create index if not exists idx_password_reset_otps_email on public.password_reset_otps (email);
create index if not exists idx_password_reset_otps_expires_at on public.password_reset_otps (expires_at);
create index if not exists idx_password_reset_otps_used on public.password_reset_otps (used);

-- Política de seguridad (RLS): sólo funciones/servidor deben acceder
alter table public.password_reset_otps enable row level security;
drop policy if exists select_none_password_reset_otps on public.password_reset_otps;
create policy select_none_password_reset_otps on public.password_reset_otps
  for select using (false);
drop policy if exists modify_none_password_reset_otps on public.password_reset_otps;
create policy modify_none_password_reset_otps on public.password_reset_otps
  for all using (false);
```

---

## 🔧 VARIABLES DE ENTORNO REQUERIDAS

### En Supabase Edge Functions:

- `SB_URL`: URL del proyecto Supabase
- `SB_SERVICE_ROLE_KEY`: Service Role Key de Supabase
- `APP_URL`: URL de la aplicación (https://manigrab.app)
- `EMAIL_SERVER_URL`: (opcional) URL del servidor PHP para envío de emails
- `EMAIL_SERVER_SECRET`: (opcional) Token secreto para autenticación
- `SENDGRID_API_KEY`: API Key de SendGrid
- `SENDGRID_FROM_EMAIL`: Email remitente
- `SENDGRID_FROM_NAME`: Nombre remitente
- `SENDGRID_TEMPLATE_RECOVERY`: ID del template de SendGrid

### En el servidor PHP:

- `SUPABASE_URL`: URL del proyecto Supabase
- `SUPABASE_SERVICE_ROLE_KEY`: Service Role Key de Supabase
- `APP_URL`: URL de la aplicación

---

## 🐛 PASOS PARA DIAGNÓSTICO

1. **Verificar que la sesión se crea:**
   - Revisar logs de `verify-otp` en Supabase Dashboard
   - Buscar mensaje "reset_session_created"
   - Verificar que `session_id` y `user_id` estén presentes

2. **Verificar que PHP puede leer la sesión:**
   - Revisar logs del servidor PHP
   - Ver qué respuesta da Supabase REST API
   - Verificar que el Service Role Key esté configurado correctamente

3. **Verificar que el email coincide:**
   - Comparar email en sesión vs email en URL
   - Verificar normalización (lowercase, trim)

4. **Verificar RLS:**
   - Aunque RLS está bloqueado, el Service Role Key debería hacer bypass
   - Si no funciona, puede ser necesario deshabilitar RLS temporalmente para esta tabla

---

## 📊 LOGS A REVISAR

### En Supabase (Edge Functions):
- `otp_transaction_logs` table
- Buscar por email y función `verify-otp`
- Verificar acciones:
  - `reset_session_created`
  - `reset_session_creation_error`
  - `otp_verified`

### En Servidor PHP:
- Logs de error de PHP
- Buscar mensajes que empiecen con:
  - `📧 Email recibido`
  - `🔍 Verificando sesión`
  - `✅ Sesión válida encontrada`
  - `❌ No se encontró sesión válida`

---

## ❓ PREGUNTA PARA CHATGPT/ASISTENTE

**El usuario llega a `reset-password.php` pero PHP no puede encontrar la sesión válida en `password_reset_sessions`. La sesión debería existir porque `verify-otp` la crea después de verificar el OTP.**

**¿Qué puede estar causando este problema y cómo solucionarlo?**

**Consideraciones:**
- RLS está habilitado en `password_reset_sessions` con políticas que bloquean todo acceso
- PHP usa Service Role Key que debería hacer bypass de RLS
- La sesión se crea con `user_id` (puede ser null si no se encuentra el usuario)
- El email se normaliza a lowercase en todos lados
- La sesión expira en 10 minutos

**Posibles causas a investigar:**
1. RLS está bloqueando el acceso incluso con Service Role Key
2. La sesión no se está creando realmente (aunque no hay error)
3. El email no coincide exactamente
4. El Service Role Key no está configurado correctamente en PHP
5. La consulta REST API de Supabase tiene algún problema

**¿Qué debo hacer para solucionarlo?**

---

## 📅 HISTORIAL DE CAMBIOS

- ✅ Implementado sistema de OTP híbrido
- ✅ Creada tabla `password_reset_sessions` para seguridad
- ✅ Implementada función `verify-otp` que crea sesión
- ✅ Implementada página PHP `reset-password.php`
- ✅ Mejorado logging en todas las funciones
- ✅ Añadida validación estricta en `verify-otp` (no devuelve URL si no se crea sesión)
- ✅ Mejorada búsqueda de usuario por email en PHP
- ❌ PROBLEMA: PHP no encuentra la sesión cuando el usuario llega a la página

---

**ÚLTIMA ACTUALIZACIÓN:** Hoy
**ESTADO:** 🔴 PROBLEMA PENDIENTE

