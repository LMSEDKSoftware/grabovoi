#!/bin/bash

# Script para probar el envío de emails directamente usando la API de SendGrid
# Útil para verificar que SendGrid esté configurado correctamente
# Uso: ./scripts/test_send_email_direct.sh email@ejemplo.com

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verificar que se proporcione un email
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Debes proporcionar un email${NC}"
    echo -e "${YELLOW}Uso: ./scripts/test_send_email_direct.sh email@ejemplo.com${NC}"
    exit 1
fi

EMAIL="$1"

# Cargar variables de entorno
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo -e "${RED}❌ Error: No se encontró el archivo .env${NC}"
    exit 1
fi

# Verificar que exista SENDGRID_API_KEY
if [ -z "$SENDGRID_API_KEY" ]; then
    echo -e "${RED}❌ Error: SENDGRID_API_KEY no está configurada en .env${NC}"
    echo -e "${YELLOW}💡 Nota: Esta prueba usa el API Key local.${NC}"
    echo -e "${YELLOW}   Para producción, la función usa las variables de Supabase.${NC}"
    exit 1
fi

echo -e "${BLUE}🧪 Probando envío directo de email con SendGrid${NC}"
echo -e "${YELLOW}📧 Email destino: ${EMAIL}${NC}"
echo ""

# Generar un OTP de prueba
OTP=$(python3 -c "import random; print(''.join([str(random.randint(0, 9)) for _ in range(6)]))" 2>/dev/null || \
     node -e "console.log(Math.floor(100000 + Math.random() * 900000))" 2>/dev/null || \
     echo "123456")

echo -e "${YELLOW}🔑 OTP generado: ${OTP}${NC}"
echo ""

# Preparar el payload para SendGrid
FROM_EMAIL="${SENDGRID_FROM_EMAIL:-noreply@manigrab.com}"
FROM_NAME="${SENDGRID_FROM_NAME:-ManiGrab}"

PAYLOAD=$(cat <<EOF
{
  "personalizations": [{
    "to": [{"email": "${EMAIL}"}],
    "subject": "🧪 Prueba de Email - ManiGrab"
  }],
  "from": {
    "email": "${FROM_EMAIL}",
    "name": "${FROM_NAME}"
  },
  "content": [{
    "type": "text/html",
    "value": "<!DOCTYPE html><html><head><meta charset='utf-8'><style>body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; } .container { max-width: 600px; margin: 0 auto; padding: 20px; } .header { background: linear-gradient(135deg, #FFD700 0%, #FFA500 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0; } .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; } .otp-code { font-size: 32px; font-weight: bold; color: #FFD700; text-align: center; padding: 20px; background: #1C2541; border-radius: 8px; margin: 20px 0; letter-spacing: 5px; } .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }</style></head><body><div class='container'><div class='header'><h1 style='color: #1C2541; margin: 0;'>ManiGrab</h1><p style='color: #1C2541; margin: 10px 0 0 0;'>Manifestaciones Cuánticas Grabovoi</p></div><div class='content'><h2 style='color: #1C2541;'>🧪 Prueba de Email</h2><p>Este es un email de prueba para verificar que SendGrid está configurado correctamente.</p><p>Si recibes este email, significa que la configuración funciona.</p><div class='otp-code'>${OTP}</div><p>Este código es solo para pruebas.</p><div class='footer'><p>© $(date +%Y) ManiGrab. Todos los derechos reservados.</p></div></div></div></body></html>"
  }]
}
EOF
)

echo -e "${YELLOW}📤 Enviando email a través de SendGrid API...${NC}"

# Enviar el email
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  "https://api.sendgrid.com/v3/mail/send" \
  -H "Authorization: Bearer ${SENDGRID_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo ""

if [ "$HTTP_CODE" = "202" ]; then
    echo -e "${GREEN}✅ Email enviado exitosamente!${NC}"
    echo ""
    echo -e "${YELLOW}📬 Verifica tu bandeja de entrada en: ${EMAIL}${NC}"
    echo -e "${YELLOW}📋 También revisa la carpeta de spam${NC}"
    echo ""
    echo -e "${BLUE}💡 Para ver la actividad en SendGrid:${NC}"
    echo "   https://app.sendgrid.com/activity"
    echo ""
    echo -e "${GREEN}✅ Si recibes el email, SendGrid está configurado correctamente${NC}"
else
    echo -e "${RED}❌ Error al enviar email${NC}"
    echo -e "${RED}Código HTTP: ${HTTP_CODE}${NC}"
    echo -e "${RED}Respuesta: ${BODY}${NC}"
    echo ""
    echo -e "${YELLOW}💡 Posibles causas:${NC}"
    echo "   1. API Key inválida o sin permisos"
    echo "   2. Email remitente no verificado en SendGrid"
    echo "   3. Problemas de conectividad"
    exit 1
fi

