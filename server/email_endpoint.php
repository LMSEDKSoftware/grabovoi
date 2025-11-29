<?php
/**
 * Endpoint para envío de emails usando SendGrid
 * Este endpoint se ejecuta desde manigrab.app con IP estática
 * 
 * Uso: POST https://manigrab.app/api/send-email
 * 
 * Headers:
 *   Authorization: Bearer [EMAIL_SERVER_SECRET]
 *   Content-Type: application/json
 * 
 * Body:
 * {
 *   "to": "email@ejemplo.com",
 *   "subject": "Asunto del email",
 *   "html": "<html>...</html>",
 *   "text": "Texto plano (opcional)"
 * }
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Authorization, Content-Type');

// Manejar preflight OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// ============================================
// CONFIGURACIÓN DE VARIABLES DE ENTORNO
// ============================================
// Si las variables no están configuradas en el servidor,
// se pueden definir aquí directamente (menos seguro pero funcional)

// Intentar cargar desde archivo .env si existe
$envFile = __DIR__ . '/.env';
if (file_exists($envFile)) {
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (strpos(trim($line), '#') === 0) continue; // Ignorar comentarios
        if (strpos($line, '=') !== false) {
            list($key, $value) = explode('=', $line, 2);
            $key = trim($key);
            $value = trim($value);
            // Remover comillas si existen
            $value = trim($value, '"\'');
            if (!empty($key) && !empty($value)) {
                putenv("$key=$value");
            }
        }
    }
}

// Si no están en variables de entorno, usar valores por defecto
// ⚠️ IMPORTANTE: Cambia estos valores o configura las variables de entorno
$emailServerSecret = getenv('EMAIL_SERVER_SECRET');
if (empty($emailServerSecret)) {
    $emailServerSecret = 'REQUIRES_ENV_VAR_EMAIL_SERVER_SECRET';
    putenv('EMAIL_SERVER_SECRET=' . $emailServerSecret);
}

$sendgridApiKey = getenv('SENDGRID_API_KEY');
if (empty($sendgridApiKey)) {
    $sendgridApiKey = 'REQUIRES_ENV_VAR_SENDGRID_API_KEY';
    putenv('SENDGRID_API_KEY=' . $sendgridApiKey);
}

$sendgridFromEmail = getenv('SENDGRID_FROM_EMAIL');
if (empty($sendgridFromEmail)) {
    $sendgridFromEmail = 'hola@em6490.manigrab.app';
    putenv('SENDGRID_FROM_EMAIL=' . $sendgridFromEmail);
}

$sendgridFromName = getenv('SENDGRID_FROM_NAME');
if (empty($sendgridFromName)) {
    $sendgridFromName = 'ManiGrab';
    putenv('SENDGRID_FROM_NAME=' . $sendgridFromName);
}

$sendgridTemplateRecovery = getenv('SENDGRID_TEMPLATE_RECOVERY');
if (empty($sendgridTemplateRecovery)) {
    $sendgridTemplateRecovery = 'd-971362da419640f7be3c3cb7fae9881d'; // Template ID por defecto para recovery
    putenv('SENDGRID_TEMPLATE_RECOVERY=' . $sendgridTemplateRecovery);
}

// Solo permitir POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

// Obtener token de autorización
$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
$expectedSecret = getenv('EMAIL_SERVER_SECRET') ?: $emailServerSecret;

if (empty($expectedSecret)) {
    http_response_code(500);
    echo json_encode(['error' => 'Server configuration error: EMAIL_SERVER_SECRET not set']);
    exit;
}

// Validar token
$token = str_replace('Bearer ', '', $authHeader);
if ($token !== $expectedSecret) {
    http_response_code(401);
    echo json_encode(['error' => 'Unauthorized']);
    exit;
}

// Obtener datos del request
$input = file_get_contents('php://input');
$data = json_decode($input, true);

if (!$data) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid JSON']);
    exit;
}

// Validar campos requeridos
// Si viene template_id, no requiere html/subject
// Si viene html, requiere subject
$hasTemplateId = !empty($data['template_id']);
$hasHtml = !empty($data['html']);

if (!$hasTemplateId && !$hasHtml) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing required: template_id or html']);
    exit;
}

if (!$hasTemplateId && empty($data['subject'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing required: subject (required when using html)']);
    exit;
}

// Obtener configuración de SendGrid (usar variables ya cargadas)
$sendgridApiKey = getenv('SENDGRID_API_KEY') ?: $sendgridApiKey;
$fromEmail = getenv('SENDGRID_FROM_EMAIL') ?: $sendgridFromEmail;
$fromName = getenv('SENDGRID_FROM_NAME') ?: $sendgridFromName;
$templateRecovery = getenv('SENDGRID_TEMPLATE_RECOVERY') ?: $sendgridTemplateRecovery;

if (empty($sendgridApiKey)) {
    http_response_code(500);
    echo json_encode(['error' => 'Server configuration error: SENDGRID_API_KEY not set']);
    exit;
}

// Determinar si usar template o HTML directo
$useTemplate = !empty($data['template_id']) || (!empty($templateRecovery) && !empty($data['template_data']));
$templateId = $data['template_id'] ?? $templateRecovery;

if ($useTemplate && $templateId) {
    // USAR TEMPLATE DE SENDGRID
    $templateData = $data['template_data'] ?? [];
    
    // Log para debugging
    error_log("SENDGRID DEBUG: Usando template_id: " . $templateId);
    error_log("SENDGRID DEBUG: template_data RAW: " . print_r($templateData, true));
    error_log("SENDGRID DEBUG: template_data JSON: " . json_encode($templateData, JSON_PRETTY_PRINT));
    error_log("SENDGRID DEBUG: recovery_link en template_data: " . (isset($templateData['recovery_link']) ? $templateData['recovery_link'] : 'NO EXISTE'));
    error_log("SENDGRID DEBUG: name en template_data: " . (isset($templateData['name']) ? $templateData['name'] : 'NO EXISTE'));
    error_log("SENDGRID DEBUG: app_name en template_data: " . (isset($templateData['app_name']) ? $templateData['app_name'] : 'NO EXISTE'));
    error_log("SENDGRID DEBUG: From: " . $fromEmail);
    error_log("SENDGRID DEBUG: To: " . $data['to']);
    
    // El subject debe estar en personalizations Y también podemos ponerlo en el nivel raíz
    $subject = $data['subject'] ?? 'Recuperación de Contraseña - ManiGrab';
    
    // VALIDACIÓN: Asegurar que recovery_link existe y no está vacío
    if (empty($templateData['recovery_link'])) {
        error_log("❌ ERROR CRÍTICO: recovery_link está vacío en templateData antes de enviar a SendGrid");
        error_log("   templateData completo: " . json_encode($templateData, JSON_PRETTY_PRINT));
    } else {
        error_log("✅ recovery_link válido antes de construir emailData");
        error_log("   recovery_link: " . $templateData['recovery_link']);
    }
    
    $emailData = [
        'personalizations' => [
            [
                'to' => [
                    ['email' => $data['to']]
                ],
                'dynamic_template_data' => $templateData,
                // Subject en personalizations (prioridad)
                'subject' => $subject
            ]
        ],
        'from' => [
            'email' => $fromEmail,
            'name' => $fromName
        ],
        // Subject también en nivel raíz (fallback si el template no tiene uno configurado)
        'subject' => $subject,
        'template_id' => $templateId
    ];
    
    // Log final antes de enviar
    error_log("SENDGRID DEBUG: emailData['personalizations'][0]['dynamic_template_data'] recovery_link: " . 
        (isset($emailData['personalizations'][0]['dynamic_template_data']['recovery_link']) 
            ? $emailData['personalizations'][0]['dynamic_template_data']['recovery_link'] 
            : 'NO EXISTE'));
    
    // Log del JSON completo que se enviará a SendGrid
    error_log("SENDGRID DEBUG: JSON completo a enviar: " . json_encode($emailData, JSON_PRETTY_PRINT));
    error_log("SENDGRID DEBUG: dynamic_template_data que se enviará: " . json_encode($templateData, JSON_PRETTY_PRINT));
} else {
    // USAR HTML DIRECTO (fallback)
    // IMPORTANTE: SendGrid requiere que text/plain esté ANTES de text/html
    $content = [];
    
    // Agregar texto plano primero si está disponible
    if (!empty($data['text'])) {
        $content[] = [
            'type' => 'text/plain',
            'value' => $data['text']
        ];
    }
    
    // Agregar HTML después
    $content[] = [
        'type' => 'text/html',
        'value' => $data['html']
    ];
    
    $emailData = [
        'personalizations' => [
            [
                'to' => [
                    ['email' => $data['to']]
                ],
                'subject' => $data['subject']
            ]
        ],
        'from' => [
            'email' => $fromEmail,
            'name' => $fromName
        ],
        'content' => $content
    ];
}

// Log final antes de enviar
error_log("SENDGRID DEBUG: Enviando request a SendGrid API...");
error_log("SENDGRID DEBUG: Request body size: " . strlen(json_encode($emailData)) . " bytes");

// Enviar email usando SendGrid
$ch = curl_init('https://api.sendgrid.com/v3/mail/send');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($emailData));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $sendgridApiKey,
    'Content-Type: application/json'
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError = curl_error($ch);
curl_close($ch);

// Log de respuesta de SendGrid para debugging
error_log("SENDGRID DEBUG: HTTP Code: " . $httpCode);
error_log("SENDGRID DEBUG: Response: " . $response);
error_log("SENDGRID DEBUG: Payload enviado: " . json_encode($emailData));

// Manejar respuesta
if ($curlError) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Error sending email',
        'details' => $curlError
    ]);
    exit;
}

if ($httpCode >= 200 && $httpCode < 300) {
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Email sent successfully'
    ]);
} else {
    http_response_code($httpCode);
    $errorData = json_decode($response, true);
    echo json_encode([
        'error' => 'SendGrid error',
        'details' => $errorData ?: $response
    ]);
}
?>

