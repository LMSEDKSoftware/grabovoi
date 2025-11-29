<?php
/**
 * Página para reset de contraseña usando Service Role Key
 * Solo permite cambiar password si existe una sesión válida creada después de verificar OTP
 * 
 * Seguridad implementada según recomendaciones de IVO:
 * - Verifica que existe sesión válida en password_reset_sessions
 * - Cambia password usando Service Role Key desde backend
 * - Nunca expone Service Role Key al cliente
 */

header('Content-Type: text/html; charset=utf-8');

// ============================================
// CONFIGURACIÓN
// ============================================
$SUPABASE_URL = getenv('SUPABASE_URL') ?: 'https://whtiazgcxdnemrrgjjqf.supabase.co';
$SERVICE_ROLE_KEY = getenv('SUPABASE_SERVICE_ROLE_KEY');
$APP_URL = getenv('APP_URL') ?: 'https://manigrab.app';

// Si no están en variables de entorno, cargar desde .env
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

// Decodificar email de la URL (puede venir codificado como %40 para @)
$rawEmail = isset($_GET['email']) ? $_GET['email'] : '';
$email = !empty($rawEmail) ? trim(strtolower(urldecode($rawEmail))) : '';
$success = false;
$error = '';
$message = '';

// Log para debugging
error_log("📧 Email recibido en reset-password.php:");
error_log("   Email raw: " . $rawEmail);
error_log("   Email decodificado: " . $email);

// ============================================
// FUNCIONES HELPER
// ============================================

/**
 * Verificar si existe un OTP usado recientemente (SOLUCIÓN IVO)
 * Validamos directamente contra password_reset_otps en vez de password_reset_sessions
 */
function verifyResetSessionUsingOtp($supabaseUrl, $serviceRoleKey, $email) {
    error_log("🔍 Verificando OTP usado para email: " . $email);
    
    $endpoint = $supabaseUrl . '/rest/v1/password_reset_otps';
    
    // OTP debe estar usado=true, no expirado, y creado recientemente (15 minutos)
    $now = new DateTime();
    $since = new DateTime('-15 minutes');
    $sinceFormatted = $since->format('c'); // Formato ISO 8601
    $nowFormatted = $now->format('c');
    
    $params = http_build_query([
        'email' => 'eq.' . $email,
        'used' => 'eq.true',
        'expires_at' => 'gt.' . $nowFormatted, // No expirado
        'created_at' => 'gte.' . $sinceFormatted, // Creado en los últimos 15 minutos
        'order' => 'created_at.desc',
        'limit' => '1'
    ]);
    
    error_log("🔗 Endpoint: " . $endpoint . '?' . $params);
    error_log("   Buscando OTP usado desde: " . $sinceFormatted);
    error_log("   OTP no expirado antes de: " . $nowFormatted);
    
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
    
    error_log("📡 Respuesta de verificación de OTP usado: HTTP " . $httpCode);
    error_log("📡 Response body: " . substr($response, 0, 500));
    
    if ($httpCode !== 200) {
        error_log("❌ Error HTTP al verificar OTP usado: " . $httpCode);
        return ['valid' => false, 'error' => 'Error verificando código. Intenta de nuevo.'];
    }
    
    $data = json_decode($response, true);
    
    // Verificar si hay error en la respuesta
    if (isset($data['message']) || isset($data['error']) || isset($data['hint'])) {
        error_log("❌ Error en respuesta de Supabase:");
        error_log("   Message: " . ($data['message'] ?? 'N/A'));
        error_log("   Error: " . ($data['error'] ?? 'N/A'));
        error_log("   Hint: " . ($data['hint'] ?? 'N/A'));
    }
    
    // Verificar si es un array vacío o no tiene datos
    if (!is_array($data) || empty($data) || !isset($data[0])) {
        error_log("❌ No se encontró OTP usado reciente para " . $email);
        error_log("   Data recibida: " . json_encode($data));
        return ['valid' => false, 'error' => 'No existe una verificación válida para este correo. Primero ingresa el código OTP en la app.'];
    }
    
    error_log("✅ OTP usado y válido encontrado:");
    error_log("   OTP ID: " . ($data[0]['id'] ?? 'N/A'));
    error_log("   Email: " . ($data[0]['email'] ?? 'N/A'));
    error_log("   Created at: " . ($data[0]['created_at'] ?? 'N/A'));
    error_log("   Used: " . (isset($data[0]['used']) ? ($data[0]['used'] ? 'true' : 'false') : 'N/A'));
    
    return ['valid' => true, 'otp' => $data[0]];
}

/**
 * Obtener usuario por email desde Supabase Auth
 * Busca en múltiples páginas si es necesario
 */
function getUserByEmail($supabaseUrl, $serviceRoleKey, $email) {
    $endpoint = $supabaseUrl . '/auth/v1/admin/users';
    $normalizedEmail = strtolower(trim($email));
    
    // Buscar en las primeras páginas (hasta 3 páginas de 1000 usuarios cada una)
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
            
            // Si no hay más usuarios en esta página, salir del loop
            if (count($data['users']) < 1000) {
                break;
            }
        } else {
            break; // No hay más usuarios
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

// ============================================
// PROCESAMIENTO DEL FORMULARIO
// ============================================

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
        // Verificar que existe un OTP usado recientemente (SOLUCIÓN IVO)
        $otpCheck = verifyResetSessionUsingOtp($SUPABASE_URL, $SERVICE_ROLE_KEY, $email);
        if (!$otpCheck['valid']) {
            $error = $otpCheck['error'];
        } else {
            // Obtener usuario por email para tener su user_id
            error_log("🔍 Buscando usuario por email para obtener user_id...");
            $user = getUserByEmail($SUPABASE_URL, $SERVICE_ROLE_KEY, $email);
            
            if (!$user || !isset($user['id'])) {
                $error = 'Usuario no encontrado. Por favor, solicita un nuevo código OTP.';
                error_log("❌ Error: No se pudo encontrar usuario por email: " . $email);
            } else {
                $userId = $user['id'];
                
                // Cambiar password usando el user_id
                error_log("🔑 Cambiando password para user_id: " . $userId);
                $result = changePassword($SUPABASE_URL, $SERVICE_ROLE_KEY, $userId, $newPassword);
                
                if ($result['success']) {
                    // No necesitamos marcar nada como usado - el OTP ya está usado
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

// Verificar que existe un OTP usado recientemente antes de mostrar el formulario (SOLUCIÓN IVO)
$canReset = false;
if (!empty($email)) {
    $otpCheck = verifyResetSessionUsingOtp($SUPABASE_URL, $SERVICE_ROLE_KEY, $email);
    $canReset = $otpCheck['valid'];
    if (!$canReset && empty($error) && !$success) {
        $error = $otpCheck['error'];
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
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #FFD700 0%, #FFA500 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        
        .container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            max-width: 450px;
            width: 100%;
            padding: 40px;
        }
        
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        
        .header h1 {
            color: #1C2541;
            font-size: 28px;
            margin-bottom: 10px;
        }
        
        .header p {
            color: #666;
            font-size: 14px;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            color: #1C2541;
            font-weight: 600;
            margin-bottom: 8px;
            font-size: 14px;
        }
        
        .form-group input {
            width: 100%;
            padding: 12px 16px;
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            font-size: 16px;
            transition: border-color 0.3s;
        }
        
        .form-group input:focus {
            outline: none;
            border-color: #FFD700;
        }
        
        .btn {
            width: 100%;
            padding: 14px;
            background: linear-gradient(135deg, #FFD700 0%, #FFA500 100%);
            color: #1C2541;
            border: none;
            border-radius: 10px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(255, 215, 0, 0.4);
        }
        
        .btn:disabled {
            opacity: 0.5;
            cursor: not-allowed;
            transform: none;
        }
        
        .message {
            padding: 12px 16px;
            border-radius: 10px;
            margin-bottom: 20px;
            font-size: 14px;
        }
        
        .message.success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        
        .message.error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        
        .info {
            background: #e7f3ff;
            color: #004085;
            padding: 12px 16px;
            border-radius: 10px;
            margin-bottom: 20px;
            font-size: 13px;
            line-height: 1.5;
        }
        
        .email-display {
            background: #f8f9fa;
            padding: 12px;
            border-radius: 8px;
            text-align: center;
            margin-bottom: 20px;
            font-weight: 600;
            color: #1C2541;
        }
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
            <div class="info">
                <strong>Próximo paso:</strong> Vuelve a la app e inicia sesión con tu nueva contraseña.
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
                        autocomplete="new-password"
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
                        autocomplete="new-password"
                    >
                </div>
                
                <button type="submit" class="btn">
                    Cambiar Contraseña
                </button>
            </form>
            
            <div class="info" style="margin-top: 20px;">
                <strong>⚠️ Importante:</strong> Este enlace expira en 10 minutos. Si no puedes cambiar tu contraseña, solicita un nuevo código OTP.
            </div>
        <?php else: ?>
            <div class="message error">
                No se puede mostrar el formulario. Por favor, solicita un nuevo código OTP desde la app.
            </div>
        <?php endif; ?>
    </div>
    
    <script>
        // Validar que las contraseñas coincidan antes de enviar
        document.querySelector('form')?.addEventListener('submit', function(e) {
            const password = document.getElementById('new_password')?.value;
            const confirm = document.getElementById('confirm_password')?.value;
            
            if (password !== confirm) {
                e.preventDefault();
                alert('Las contraseñas no coinciden');
                return false;
            }
            
            if (password && password.length < 6) {
                e.preventDefault();
                alert('La contraseña debe tener al menos 6 caracteres');
                return false;
            }
        });
    </script>
</body>
</html>


