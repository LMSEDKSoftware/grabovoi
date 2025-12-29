#!/bin/bash

# Script de diagnóstico COMPLETO que verifica TODO el proceso
# Compara lo que funcionaba vs lo que no funciona ahora

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  DIAGNÓSTICO COMPLETO RECOVERY EMAIL  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Cargar .env si existe
[ -f ".env" ] && export $(cat .env | grep -v '^#' | xargs)

EMAIL_TEST="2005.ivan@mail.com"
EMAIL_SERVER_URLS=(
    "https://manigrab.app/api/send-email/email_endpoint.php"
    "https://manigrab.app/email_endpoint.php"
    "https://manigrab.app/api/send-email"
)
EMAIL_SERVER_SECRET="413e5255f5d41dea06bf1a3d8bd58b0b4b70a5e6b4c72d19572141aab47e8deb"

echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo -e "${YELLOW}PASO 1: VERIFICAR CÓDIGO ACTUAL${NC}"
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo ""

# Verificar estructura de datos en Edge Function
echo "1.1 Verificando construcción de template_data en Edge Function..."
if [ -f "supabase/functions/send-otp/index.ts" ]; then
    echo ""
    echo "Construcción actual de serverPayload.template_data:"
    grep -A 5 "serverPayload.template_data = {" supabase/functions/send-otp/index.ts | head -8
    echo ""
    
    echo "Verificando que recovery_link se asigne:"
    if grep -q "recovery_link:.*templateDataRecoveryLink" supabase/functions/send-otp/index.ts; then
        echo -e "${GREEN}✅ recovery_link se asigna correctamente${NC}"
    else
        echo -e "${RED}❌ recovery_link NO se asigna correctamente${NC}"
    fi
else
    echo -e "${RED}❌ Edge Function no existe${NC}"
fi

echo ""
echo "1.2 Verificando procesamiento en PHP..."
if [ -f "server/email_endpoint.php" ]; then
    echo ""
    echo "Línea donde se obtiene template_data:"
    grep -B 2 -A 3 "template_data = \$data\['template_data'\]" server/email_endpoint.php | head -6
    echo ""
    
    echo "Línea donde se usa en dynamic_template_data:"
    grep -B 2 -A 1 "'dynamic_template_data' =>" server/email_endpoint.php | head -4
    echo ""
    
    # Verificar sintaxis PHP
    if php -l server/email_endpoint.php 2>&1 | grep -q "No syntax errors"; then
        echo -e "${GREEN}✅ Sintaxis PHP correcta${NC}"
    else
        echo -e "${RED}❌ Error de sintaxis PHP:${NC}"
        php -l server/email_endpoint.php
    fi
else
    echo -e "${RED}❌ PHP endpoint no existe${NC}"
fi

echo ""
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo -e "${YELLOW}PASO 2: TEST DIRECTO DEL SERVIDOR PHP${NC}"
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo ""

# Preparar payload EXACTO como lo envía la Edge Function
TEST_PAYLOAD=$(cat <<'EOF'
{
  "to": "2005.ivan@mail.com",
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

echo "Payload a enviar (exactamente como lo envía Edge Function):"
echo "$TEST_PAYLOAD" | jq '.' 2>/dev/null || echo "$TEST_PAYLOAD"
echo ""

# Probar cada URL posible
for URL in "${EMAIL_SERVER_URLS[@]}"; do
    echo "Probando URL: ${URL}"
    echo "----------------------------------------"
    
    RESPONSE=$(curl -s -w "\n===HTTP_CODE===%{http_code}" \
      -X POST "${URL}" \
      -H "Authorization: Bearer ${EMAIL_SERVER_SECRET}" \
      -H "Content-Type: application/json" \
      -d "${TEST_PAYLOAD}" 2>&1)
    
    HTTP_CODE=$(echo "$RESPONSE" | grep "===HTTP_CODE===" | cut -d'=' -f4)
    BODY=$(echo "$RESPONSE" | sed '/===HTTP_CODE===/d')
    
    echo "HTTP Code: ${HTTP_CODE}"
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✅ URL FUNCIONA: ${URL}${NC}"
        echo "Response:"
        echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
        echo ""
        break
    else
        echo -e "${RED}❌ URL falló: ${HTTP_CODE}${NC}"
        echo "Response:"
        echo "$BODY" | head -20
        echo ""
    fi
done

echo ""
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo -e "${YELLOW}PASO 3: VERIFICAR DIFERENCIAS${NC}"
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo ""

echo "3.1 Comparando estructura de datos..."
echo ""
echo "Estructura que envía Edge Function (TypeScript):"
cat << 'EOF'
serverPayload.template_data = {
  name: userName || 'Usuario',
  app_name: 'ManiGrab',
  recovery_link: templateDataRecoveryLink
}
EOF

echo ""
echo "Estructura que espera PHP:"
cat << 'EOF'
$templateData = $data['template_data'] ?? [];
'dynamic_template_data' => $templateData
EOF

echo ""
echo "Estructura que envía PHP a SendGrid:"
cat << 'EOF'
'dynamic_template_data' => $templateData
EOF

echo ""
echo "3.2 Verificando posibles problemas..."
echo ""

# Verificar si hay algún problema de encoding
echo "Verificando encoding del archivo PHP..."
if file server/email_endpoint.php | grep -q "UTF-8"; then
    echo -e "${GREEN}✅ Encoding correcto${NC}"
else
    echo -e "${YELLOW}⚠️  Encoding puede ser un problema${NC}"
    file server/email_endpoint.php
fi

# Verificar si hay espacios en blanco antes de <?php
if head -1 server/email_endpoint.php | grep -q "^<?php"; then
    echo -e "${GREEN}✅ No hay espacios antes de <?php${NC}"
else
    echo -e "${RED}❌ Hay espacios antes de <?php${NC}"
fi

echo ""
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo -e "${YELLOW}PASO 4: GENERAR REPORTE${NC}"
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo ""

REPORT_FILE="diagnostico_recovery_$(date +%Y%m%d_%H%M%S).txt"
{
    echo "REPORTE DE DIAGNÓSTICO - RECOVERY PASSWORD"
    echo "Fecha: $(date)"
    echo ""
    echo "=== CÓDIGO EDGE FUNCTION ==="
    echo ""
    grep -A 10 "serverPayload.template_data = {" supabase/functions/send-otp/index.ts | head -12
    echo ""
    echo "=== CÓDIGO PHP ==="
    echo ""
    grep -A 10 "template_data = \$data\['template_data'\]" server/email_endpoint.php | head -12
    echo ""
    echo "=== ESTRUCTURA JSON ENVIADA ==="
    echo ""
    echo "$TEST_PAYLOAD" | jq '.'
} > "$REPORT_FILE"

echo -e "${GREEN}✅ Reporte guardado en: ${REPORT_FILE}${NC}"
echo ""
echo "Para revisar el reporte completo:"
echo "  cat ${REPORT_FILE}"

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}RESUMEN${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""
echo "Si el servidor PHP responde 200, entonces el problema está en:"
echo "1. La URL configurada en Supabase Edge Function"
echo "2. La estructura de datos que se envía desde Edge Function"
echo ""
echo "Si el servidor PHP NO responde 200, entonces el problema está en:"
echo "1. La URL del servidor (probablemente la ruta está mal)"
echo "2. El servidor web (nginx/apache) bloqueando el request"
echo ""
echo "Para debug adicional:"
echo "- Revisa logs de PHP: error_log en el servidor"
echo "- Revisa logs de Edge Function: Supabase Dashboard"
echo "- Revisa Activity en SendGrid: https://app.sendgrid.com/activity"





