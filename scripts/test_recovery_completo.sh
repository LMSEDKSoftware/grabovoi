#!/bin/bash

# Script completo de diagnóstico y test de Recovery Password
# Prueba cada paso del proceso para identificar dónde falla

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}DIAGNÓSTICO COMPLETO RECOVERY PASSWORD${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

EMAIL_TEST="2005.ivan@mail.com"
EMAIL_SERVER_URL="https://manigrab.app/api/send-email/email_endpoint.php"
EMAIL_SERVER_SECRET="413e5255f5d41dea06bf1a3d8bd58b0b4b70a5e6b4c72d19572141aab47e8deb"

# Cargar variables de entorno si existen
if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

echo -e "${YELLOW}PASO 1: Verificando variables de entorno...${NC}"
echo "----------------------------------------"

if [ -z "$SUPABASE_URL" ]; then
    echo -e "${RED}❌ SUPABASE_URL no definida${NC}"
    exit 1
else
    echo -e "${GREEN}✅ SUPABASE_URL: $SUPABASE_URL${NC}"
fi

if [ -z "$SUPABASE_ANON_KEY" ]; then
    echo -e "${RED}❌ SUPABASE_ANON_KEY no definida${NC}"
    exit 1
else
    echo -e "${GREEN}✅ SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:0:20}...${NC}"
fi

echo ""
echo -e "${YELLOW}PASO 2: Test directo del servidor PHP con datos completos...${NC}"
echo "----------------------------------------"

# Preparar payload exacto como lo envía la Edge Function
TEST_PAYLOAD=$(cat <<EOF
{
  "to": "${EMAIL_TEST}",
  "template_id": "d-971362da419640f7be3c3cb7fae9881d",
  "template_data": {
    "name": "Usuario Test",
    "app_name": "ManiGrab",
    "recovery_link": "https://manigrab.app/recovery?token=test_token_12345"
  },
  "subject": "Test Recovery - ManiGrab"
}
EOF
)

echo "Payload a enviar:"
echo "$TEST_PAYLOAD" | jq '.' 2>/dev/null || echo "$TEST_PAYLOAD"
echo ""

echo "Enviando a servidor PHP..."
PHP_RESPONSE=$(curl -s -w "\n\n=== HTTP_CODE: %{http_code} ===" \
  -X POST "${EMAIL_SERVER_URL}" \
  -H "Authorization: Bearer ${EMAIL_SERVER_SECRET}" \
  -H "Content-Type: application/json" \
  -d "${TEST_PAYLOAD}" 2>&1)

HTTP_CODE=$(echo "$PHP_RESPONSE" | grep "HTTP_CODE" | awk '{print $3}')
BODY=$(echo "$PHP_RESPONSE" | sed '/HTTP_CODE/d')

echo "HTTP Code: $HTTP_CODE"
echo "Response:"
echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Servidor PHP responde correctamente${NC}"
else
    echo -e "${RED}❌ Servidor PHP falló${NC}"
fi

echo ""
echo -e "${YELLOW}PASO 3: Verificando estructura de datos en Edge Function...${NC}"
echo "----------------------------------------"

if [ -f "supabase/functions/send-otp/index.ts" ]; then
    echo "Buscando construcción de serverPayload.template_data..."
    echo ""
    
    # Extraer la parte relevante del código
    grep -A 10 "serverPayload.template_data = {" supabase/functions/send-otp/index.ts | head -15
    
    echo ""
    echo "Verificando que recovery_link se asigne correctamente..."
    RECOVERY_LINK_LINES=$(grep -n "recovery_link:" supabase/functions/send-otp/index.ts | head -3)
    if [ ! -z "$RECOVERY_LINK_LINES" ]; then
        echo -e "${GREEN}✅ recovery_link encontrado en código${NC}"
        echo "$RECOVERY_LINK_LINES"
    else
        echo -e "${RED}❌ recovery_link NO encontrado${NC}"
    fi
else
    echo -e "${RED}❌ Archivo Edge Function no existe${NC}"
fi

echo ""
echo -e "${YELLOW}PASO 4: Verificando procesamiento en PHP...${NC}"
echo "----------------------------------------"

if [ -f "server/email_endpoint.php" ]; then
    echo "Buscando procesamiento de template_data..."
    echo ""
    
    # Verificar que template_data se procese correctamente
    TEMPLATE_DATA_LINES=$(grep -A 5 "template_data = \$data\['template_data'\]" server/email_endpoint.php)
    if [ ! -z "$TEMPLATE_DATA_LINES" ]; then
        echo -e "${GREEN}✅ Procesamiento de template_data encontrado${NC}"
        echo "$TEMPLATE_DATA_LINES"
    else
        echo -e "${YELLOW}⚠️  Procesamiento específico no encontrado${NC}"
    fi
    
    echo ""
    echo "Verificando construcción de dynamic_template_data..."
    DYNAMIC_TEMPLATE_LINES=$(grep -A 3 "'dynamic_template_data' =>" server/email_endpoint.php | head -5)
    if [ ! -z "$DYNAMIC_TEMPLATE_LINES" ]; then
        echo -e "${GREEN}✅ dynamic_template_data encontrado${NC}"
        echo "$DYNAMIC_TEMPLATE_LINES"
    else
        echo -e "${RED}❌ dynamic_template_data NO encontrado${NC}"
    fi
else
    echo -e "${RED}❌ Archivo PHP no existe${NC}"
fi

echo ""
echo -e "${YELLOW}PASO 5: Comparando estructura esperada vs actual...${NC}"
echo "----------------------------------------"

echo "Estructura ESPERADA por SendGrid:"
cat << 'EOF'
{
  "personalizations": [{
    "to": [{"email": "user@example.com"}],
    "dynamic_template_data": {
      "name": "string",
      "app_name": "string",
      "recovery_link": "string (URL completa)"
    },
    "subject": "string"
  }],
  "from": {
    "email": "sender@example.com",
    "name": "string"
  },
  "template_id": "d-xxxxx"
}
EOF

echo ""
echo -e "${YELLOW}PASO 6: Test end-to-end completo (OPCIONAL)${NC}"
echo "----------------------------------------"
echo "Este paso enviará un email real de recovery."
read -p "¿Deseas continuar con el test completo? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    EDGE_FUNCTION_URL="${SUPABASE_URL}/functions/v1/send-otp"
    
    echo "Enviando request a Edge Function..."
    FULL_RESPONSE=$(curl -s -w "\n\n=== HTTP_CODE: %{http_code} ===" \
      -X POST "${EDGE_FUNCTION_URL}" \
      -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
      -H "Content-Type: application/json" \
      -d "{
        \"email\": \"${EMAIL_TEST}\",
        \"action\": \"recovery\"
      }" 2>&1)
    
    RESPONSE_HTTP_CODE=$(echo "$FULL_RESPONSE" | grep "HTTP_CODE" | awk '{print $3}')
    RESPONSE_BODY=$(echo "$FULL_RESPONSE" | sed '/HTTP_CODE/d')
    
    echo "HTTP Code: $RESPONSE_HTTP_CODE"
    echo "Response:"
    echo "$RESPONSE_BODY" | jq '.' 2>/dev/null || echo "$RESPONSE_BODY"
    
    if [ "$RESPONSE_HTTP_CODE" = "200" ]; then
        echo ""
        echo -e "${GREEN}✅ Test completado. Revisa tu email en ${EMAIL_TEST}${NC}"
    else
        echo ""
        echo -e "${RED}❌ Test falló. Revisa los logs arriba.${NC}"
    fi
else
    echo "Test end-to-end cancelado"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}RESUMEN${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Si algo falló, revisa:"
echo "1. Los logs del servidor PHP (error_log)"
echo "2. Los logs de la Edge Function (Supabase Dashboard)"
echo "3. Los logs de SendGrid Activity"
echo ""
echo "Para debug detallado:"
echo "- PHP: tail -f /var/log/apache2/error_log"
echo "- Edge Function: Supabase Dashboard > Edge Functions > send-otp > Logs"
echo "- SendGrid: https://app.sendgrid.com/activity"

