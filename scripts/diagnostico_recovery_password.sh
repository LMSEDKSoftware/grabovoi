#!/bin/bash

# Script de diagnóstico completo para Recovery Password
# Revisa todo el proceso desde Edge Function hasta SendGrid

set -e

echo "🔍 DIAGNÓSTICO COMPLETO - RECOVERY PASSWORD"
echo "============================================"
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables de entorno necesarias
echo "📋 1. VERIFICANDO VARIABLES DE ENTORNO..."
echo "----------------------------------------"

if [ -z "$SUPABASE_URL" ]; then
    echo -e "${RED}❌ SUPABASE_URL no está definida${NC}"
else
    echo -e "${GREEN}✅ SUPABASE_URL: ${SUPABASE_URL}${NC}"
fi

if [ -z "$SUPABASE_ANON_KEY" ]; then
    echo -e "${RED}❌ SUPABASE_ANON_KEY no está definida${NC}"
else
    echo -e "${GREEN}✅ SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:0:20}...${NC}"
fi

EMAIL_TEST="2005.ivan@mail.com"
echo ""
echo "📧 EMAIL DE PRUEBA: ${EMAIL_TEST}"
echo ""

# 2. Verificar Edge Function
echo ""
echo "📋 2. VERIFICANDO EDGE FUNCTION send-otp..."
echo "----------------------------------------"

EDGE_FUNCTION_URL="${SUPABASE_URL}/functions/v1/send-otp"
echo "URL: ${EDGE_FUNCTION_URL}"

# Hacer request de prueba
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${EDGE_FUNCTION_URL}" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"${EMAIL_TEST}\",
    \"action\": \"recovery\"
  }" 2>&1)

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Code: ${HTTP_CODE}"

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Edge Function responde correctamente${NC}"
    echo "Response:"
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
else
    echo -e "${RED}❌ Edge Function falló con código ${HTTP_CODE}${NC}"
    echo "Response:"
    echo "$BODY"
fi

# 3. Verificar logs en Supabase
echo ""
echo "📋 3. VERIFICANDO LOGS EN SUPABASE..."
echo "----------------------------------------"

# Obtener logs recientes
LOG_QUERY="SELECT * FROM email_logs WHERE email = '${EMAIL_TEST}' ORDER BY created_at DESC LIMIT 5"

echo "Consultando logs (requiere SUPABASE_SERVICE_KEY)..."
if [ -z "$SUPABASE_SERVICE_KEY" ]; then
    echo -e "${YELLOW}⚠️  SUPABASE_SERVICE_KEY no está definida, saltando consulta de logs${NC}"
else
    LOGS=$(curl -s -X POST "${SUPABASE_URL}/rest/v1/rpc/get_logs" \
      -H "Authorization: Bearer ${SUPABASE_SERVICE_KEY}" \
      -H "Content-Type: application/json" \
      -H "apikey: ${SUPABASE_SERVICE_KEY}" \
      -d "{\"email\": \"${EMAIL_TEST}\"}" 2>&1) || true
    
    if [ ! -z "$LOGS" ] && [ "$LOGS" != "null" ]; then
        echo -e "${GREEN}✅ Logs encontrados:${NC}"
        echo "$LOGS" | jq '.' 2>/dev/null || echo "$LOGS"
    else
        echo -e "${YELLOW}⚠️  No se encontraron logs recientes${NC}"
    fi
fi

# 4. Verificar servidor PHP
echo ""
echo "📋 4. VERIFICANDO SERVIDOR PHP..."
echo "----------------------------------------"

if [ -z "$EMAIL_SERVER_URL" ]; then
    EMAIL_SERVER_URL="https://manigrab.app/email_endpoint.php"
    echo -e "${YELLOW}⚠️  EMAIL_SERVER_URL no definida, usando: ${EMAIL_SERVER_URL}${NC}"
fi

# Test de conectividad
echo "Test de conectividad al servidor..."
SERVER_TEST=$(curl -s -w "\n%{http_code}" -X POST "${EMAIL_SERVER_URL}" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "'${EMAIL_TEST}'",
    "template_id": "d-971362da419640f7be3c3cb7fae9881d",
    "template_data": {
      "name": "Usuario Test",
      "app_name": "ManiGrab",
      "recovery_link": "https://manigrab.app/recovery?token=test123"
    },
    "subject": "Test Recovery - ManiGrab"
  }' 2>&1)

SERVER_HTTP_CODE=$(echo "$SERVER_TEST" | tail -n1)
SERVER_BODY=$(echo "$SERVER_TEST" | sed '$d')

echo "HTTP Code: ${SERVER_HTTP_CODE}"

if [ "$SERVER_HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Servidor PHP responde correctamente${NC}"
    echo "Response:"
    echo "$SERVER_BODY" | jq '.' 2>/dev/null || echo "$SERVER_BODY"
else
    echo -e "${RED}❌ Servidor PHP falló con código ${SERVER_HTTP_CODE}${NC}"
    echo "Response:"
    echo "$SERVER_BODY"
fi

# 5. Verificar estructura de template_data
echo ""
echo "📋 5. VERIFICANDO ESTRUCTURA DE DATOS..."
echo "----------------------------------------"

echo "Estructura esperada en template_data:"
cat << 'EOF'
{
  "name": "string",
  "app_name": "string",
  "recovery_link": "string (URL completa)"
}
EOF

echo ""
echo "Verificando código TypeScript..."
if [ -f "supabase/functions/send-otp/index.ts" ]; then
    echo -e "${GREEN}✅ Archivo Edge Function existe${NC}"
    
    # Verificar cómo se construye template_data
    echo ""
    echo "Buscando construcción de template_data..."
    grep -A 5 "template_data = {" supabase/functions/send-otp/index.ts | head -10 || echo "No encontrado"
else
    echo -e "${RED}❌ Archivo Edge Function no existe${NC}"
fi

# 6. Verificar PHP endpoint
echo ""
echo "📋 6. VERIFICANDO PHP ENDPOINT..."
echo "----------------------------------------"

if [ -f "server/email_endpoint.php" ]; then
    echo -e "${GREEN}✅ Archivo PHP existe${NC}"
    
    # Verificar cómo se procesa template_data
    echo ""
    echo "Buscando procesamiento de template_data..."
    grep -A 10 "template_data" server/email_endpoint.php | head -15 || echo "No encontrado"
else
    echo -e "${RED}❌ Archivo PHP no existe${NC}"
fi

# 7. Test completo end-to-end
echo ""
echo "📋 7. TEST COMPLETO END-TO-END..."
echo "----------------------------------------"

echo "Ejecutando test completo (esto enviará un email real)..."
echo ""
read -p "¿Deseas continuar? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Enviando request de recovery..."
    
    FULL_RESPONSE=$(curl -s -w "\n\n=== HTTP_CODE: %{http_code} ===" -X POST "${EDGE_FUNCTION_URL}" \
      -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
      -H "Content-Type: application/json" \
      -d "{
        \"email\": \"${EMAIL_TEST}\",
        \"action\": \"recovery\"
      }" 2>&1)
    
    echo "$FULL_RESPONSE"
    
    echo ""
    echo -e "${GREEN}✅ Test completado. Revisa tu email en ${EMAIL_TEST}${NC}"
else
    echo "Test cancelado"
fi

# 8. Resumen y recomendaciones
echo ""
echo "============================================"
echo "📊 RESUMEN"
echo "============================================"
echo ""
echo "Si el test falla, revisa:"
echo "1. Variables de entorno en Supabase Dashboard"
echo "2. Logs en Supabase (tabla email_logs)"
echo "3. Logs del servidor PHP (error_log)"
echo "4. Logs de SendGrid Activity"
echo ""
echo "Para debug detallado:"
echo "- Revisa logs en: supabase/functions/send-otp (console.log)"
echo "- Revisa logs PHP: tail -f /var/log/apache2/error_log (o similar)"
echo "- Revisa SendGrid: https://app.sendgrid.com/activity"





