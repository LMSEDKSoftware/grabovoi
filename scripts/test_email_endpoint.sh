#!/bin/bash

# Script para probar el endpoint de email en el servidor
# Uso: ./scripts/test_email_endpoint.sh [EMAIL_SERVER_SECRET]

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

EMAIL_SERVER_URL="https://manigrab.app/api/send-email/email_endpoint.php"
EMAIL_SERVER_SECRET="${1:-}"

if [ -z "$EMAIL_SERVER_SECRET" ]; then
    echo -e "${YELLOW}⚠️  No se proporcionó EMAIL_SERVER_SECRET${NC}"
    echo -e "${CYAN}Uso:${NC} ./scripts/test_email_endpoint.sh [EMAIL_SERVER_SECRET]"
    echo ""
    echo -e "${YELLOW}O configura la variable de entorno:${NC}"
    echo "export EMAIL_SERVER_SECRET=tu_token_secreto"
    exit 1
fi

TEST_EMAIL="2005.ivan@gmail.com"

echo -e "${CYAN}🧪 Probando endpoint de email${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}Configuración:${NC}"
echo "   URL: $EMAIL_SERVER_URL"
echo "   Email de prueba: $TEST_EMAIL"
echo "   Secret: ${EMAIL_SERVER_SECRET:0:10}..."
echo ""

echo -e "${YELLOW}Enviando solicitud...${NC}"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$EMAIL_SERVER_URL" \
  -H "Authorization: Bearer $EMAIL_SERVER_SECRET" \
  -H "Content-Type: application/json" \
  -d "{
    \"to\": \"$TEST_EMAIL\",
    \"subject\": \"Prueba de Endpoint - $(date +%Y-%m-%d\ %H:%M:%S)\",
    \"html\": \"<h1>Prueba de Endpoint</h1><p>Este es un email de prueba enviado desde el servidor con IP estática.</p><p>Si recibes este email, significa que el endpoint funciona correctamente.</p>\",
    \"text\": \"Prueba de Endpoint - Este es un email de prueba enviado desde el servidor con IP estática.\"
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo -e "${BLUE}Respuesta HTTP:${NC} $HTTP_CODE"
echo -e "${BLUE}Cuerpo de respuesta:${NC}"
echo "$BODY" | jq . 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Endpoint funcionando correctamente${NC}"
    echo ""
    echo -e "${YELLOW}📧 Revisa tu bandeja de entrada:${NC} $TEST_EMAIL"
    echo -e "${YELLOW}📋 También revisa SendGrid Activity:${NC} https://app.sendgrid.com/activity"
else
    echo -e "${RED}❌ Error en el endpoint${NC}"
    echo ""
    echo -e "${YELLOW}Posibles causas:${NC}"
    echo "  - EMAIL_SERVER_SECRET incorrecto"
    echo "  - Variables de entorno no configuradas en el servidor"
    echo "  - Error en el código PHP"
    echo "  - Problema de conectividad"
fi


