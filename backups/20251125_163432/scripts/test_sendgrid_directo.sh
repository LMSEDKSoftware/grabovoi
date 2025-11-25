#!/bin/bash

# Script para enviar un email directamente usando SendGrid API
# Sin pasar por Supabase, para verificar que SendGrid funciona correctamente
# Uso: ./scripts/test_sendgrid_directo.sh API_KEY FROM_EMAIL FROM_NAME TO_EMAIL

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📧 Envío Directo de Email con SendGrid${NC}"
echo "========================================"
echo ""

# Verificar argumentos
if [ $# -lt 4 ]; then
    echo -e "${RED}❌ Error: Faltan argumentos${NC}"
    echo ""
    echo -e "${YELLOW}Uso:${NC}"
    echo "  ./scripts/test_sendgrid_directo.sh API_KEY FROM_EMAIL FROM_NAME TO_EMAIL"
    echo ""
    echo -e "${YELLOW}Ejemplo:${NC}"
    echo "  ./scripts/test_sendgrid_directo.sh SG.xxxxx noreply@manigrab.com ManiGrab tu-email@ejemplo.com"
    echo ""
    echo -e "${YELLOW}O puedes proporcionar los datos interactivamente:${NC}"
    echo ""
    read -p "SENDGRID_API_KEY: " SENDGRID_API_KEY
    read -p "SENDGRID_FROM_EMAIL: " SENDGRID_FROM_EMAIL
    read -p "SENDGRID_FROM_NAME (opcional, presiona Enter para usar 'ManiGrab'): " SENDGRID_FROM_NAME
    read -p "Email de destino (TO_EMAIL): " TO_EMAIL
    
    SENDGRID_FROM_NAME=${SENDGRID_FROM_NAME:-ManiGrab}
else
    SENDGRID_API_KEY="$1"
    SENDGRID_FROM_EMAIL="$2"
    SENDGRID_FROM_NAME="$3"
    TO_EMAIL="$4"
fi

# Validar que todos los campos estén presentes
if [ -z "$SENDGRID_API_KEY" ] || [ -z "$SENDGRID_FROM_EMAIL" ] || [ -z "$TO_EMAIL" ]; then
    echo -e "${RED}❌ Error: Faltan datos requeridos${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Configuración:${NC}"
echo "   API Key: ${SENDGRID_API_KEY:0:10}...${SENDGRID_API_KEY: -4}"
echo "   From: ${SENDGRID_FROM_EMAIL} (${SENDGRID_FROM_NAME})"
echo "   To: ${TO_EMAIL}"
echo ""

# Generar un OTP de prueba (compatible con macOS y Linux)
if command -v shuf > /dev/null 2>&1; then
    OTP_CODE=$(shuf -i 100000-999999 -n 1)
elif command -v jot > /dev/null 2>&1; then
    OTP_CODE=$(jot -r 1 100000 999999)
else
    # Fallback: usar $RANDOM (funciona en bash)
    OTP_CODE=$((RANDOM % 900000 + 100000))
fi
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo -e "${YELLOW}📧 Preparando email de prueba...${NC}"

# Cuerpo del email en HTML
EMAIL_HTML="
<!DOCTYPE html>
<html>
<head>
  <meta charset=\"utf-8\">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: linear-gradient(135deg, #FFD700 0%, #FFA500 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
    .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
    .otp-code { font-size: 32px; font-weight: bold; color: #FFD700; text-align: center; padding: 20px; background: #1C2541; border-radius: 8px; margin: 20px 0; letter-spacing: 5px; }
    .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
    .info { background: #e3f2fd; padding: 15px; border-radius: 5px; margin: 15px 0; }
  </style>
</head>
<body>
  <div class=\"container\">
    <div class=\"header\">
      <h1 style=\"color: #1C2541; margin: 0;\">ManiGrab</h1>
      <p style=\"color: #1C2541; margin: 10px 0 0 0;\">Manifestaciones Cuánticas Grabovoi</p>
    </div>
    <div class=\"content\">
      <h2 style=\"color: #1C2541;\">Prueba de Envío Directo</h2>
      <p>Este es un email de prueba enviado directamente desde la API de SendGrid para verificar la configuración.</p>
      <div class=\"info\">
        <p><strong>Fecha y hora:</strong> ${TIMESTAMP}</p>
        <p><strong>Método:</strong> Envío directo vía SendGrid API</p>
      </div>
      <p>Tu código de prueba es:</p>
      <div class=\"otp-code\">${OTP_CODE}</div>
      <p>Si recibes este correo, significa que SendGrid está configurado correctamente y funciona sin problemas.</p>
      <p>Este email fue enviado para diagnosticar problemas de entrega de emails.</p>
      <div class=\"footer\">
        <p>© $(date +%Y) ManiGrab. Todos los derechos reservados.</p>
      </div>
    </div>
  </div>
</body>
</html>
"

# Construir el payload JSON
PAYLOAD=$(jq -n \
    --arg to_email "$TO_EMAIL" \
    --arg from_email "$SENDGRID_FROM_EMAIL" \
    --arg from_name "$SENDGRID_FROM_NAME" \
    --arg subject "Prueba de Envío Directo - ManiGrab" \
    --arg html_content "$EMAIL_HTML" \
    '{
        "personalizations": [
            {
                "to": [ {"email": $to_email} ],
                "subject": $subject
            }
        ],
        "from": { "email": $from_email, "name": $from_name },
        "content": [
            {
                "type": "text/html",
                "value": $html_content
            }
        ]
    }')

echo -e "${YELLOW}🚀 Enviando email a través de SendGrid API...${NC}"

# Enviar email usando curl
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "https://api.sendgrid.com/v3/mail/send" \
    -H "Authorization: Bearer ${SENDGRID_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "${PAYLOAD}")

# Separar respuesta y código HTTP
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

# Verificar la respuesta
if [ "$HTTP_CODE" = "202" ]; then
    echo -e "${GREEN}✅ Email enviado exitosamente!${NC}"
    echo ""
    echo -e "${YELLOW}📬 Detalles:${NC}"
    echo "   Código HTTP: 202 (Accepted)"
    echo "   Email de destino: ${TO_EMAIL}"
    echo "   OTP de prueba: ${OTP_CODE}"
    echo ""
    echo -e "${YELLOW}💡 Próximos pasos:${NC}"
    echo "   1. Revisa la bandeja de entrada de ${TO_EMAIL}"
    echo "   2. Revisa también la carpeta de spam"
    echo "   3. Verifica en SendGrid Activity: https://app.sendgrid.com/activity"
    echo ""
    echo -e "${GREEN}✅ Si recibes el email, SendGrid está funcionando correctamente${NC}"
    echo -e "${YELLOW}⚠️  Si no recibes el email, revisa:${NC}"
    echo "   - Que el email remitente esté verificado en SendGrid"
    echo "   - Que el API Key tenga permisos de 'Mail Send'"
    echo "   - Los logs en SendGrid Activity para ver errores específicos"
else
    echo -e "${RED}❌ Error al enviar email${NC}"
    echo ""
    echo -e "${RED}Código HTTP: ${HTTP_CODE}${NC}"
    echo ""
    if [ -n "$BODY" ]; then
        echo -e "${YELLOW}Respuesta de SendGrid:${NC}"
        echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    fi
    echo ""
    echo -e "${YELLOW}💡 Posibles causas:${NC}"
    echo "   - API Key inválida o sin permisos"
    echo "   - Email remitente no verificado en SendGrid"
    echo "   - Dominio no autenticado"
    echo "   - Límite de envío alcanzado"
    exit 1
fi

