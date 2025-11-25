#!/bin/bash

# Script para verificar la configuración de SendGrid en Supabase
# Compara las variables configuradas con las que funcionan directamente

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Verificación de Configuración SendGrid en Supabase${NC}"
echo "=================================================="
echo ""

# Cargar variables de entorno locales
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo -e "${RED}❌ Error: No se encontró el archivo .env${NC}"
    exit 1
fi

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo -e "${RED}❌ Error: Faltan variables de entorno (SUPABASE_URL o SUPABASE_ANON_KEY)${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Variables que funcionan directamente con SendGrid:${NC}"
echo "   API Key: [Configurar desde SendGrid Dashboard]"
echo "   From Email: hola@manigrab.app"
echo "   From Name: ManiGrab"
echo ""

echo -e "${YELLOW}🔍 Verificando función send-otp en Supabase...${NC}"
echo ""

# Probar la función con un email de prueba
TEST_EMAIL="test-supabase-$(date +%s)@manigrab.app"
echo -e "${BLUE}📧 Enviando prueba a través de Supabase: ${TEST_EMAIL}${NC}"

RESPONSE=$(curl -s -X POST \
  "${SUPABASE_URL}/functions/v1/send-otp" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"${TEST_EMAIL}\"}")

echo ""
echo -e "${YELLOW}📥 Respuesta de Supabase:${NC}"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
echo ""

# Verificar si hay errores
if echo "$RESPONSE" | grep -q '"error"'; then
    echo -e "${RED}❌ Se detectó un error en la respuesta${NC}"
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error // .details // "Error desconocido"' 2>/dev/null || echo "Error en la respuesta")
    echo -e "${RED}   Error: ${ERROR_MSG}${NC}"
else
    echo -e "${GREEN}✅ La función responde correctamente${NC}"
fi

echo ""
echo -e "${YELLOW}📝 Instrucciones para verificar variables en Supabase:${NC}"
echo ""
echo -e "${GREEN}1. Ve a Supabase Dashboard → Settings → Edge Functions → Secrets${NC}"
echo "   URL: https://supabase.com/dashboard/project/whtiazgcxdnemrrgjjqf/settings/functions"
echo ""
echo -e "${YELLOW}   Verifica que existan estas variables:${NC}"
echo "   • SENDGRID_API_KEY = [Configurar desde SendGrid Dashboard]"
echo "   • SENDGRID_FROM_EMAIL = hola@manigrab.app"
echo "   • SENDGRID_FROM_NAME = ManiGrab"
echo ""
echo -e "${GREEN}2. Revisa los logs de la función:${NC}"
echo "   URL: https://supabase.com/dashboard/project/whtiazgcxdnemrrgjjqf/functions"
echo "   - Selecciona 'send-otp'"
echo "   - Ve a la pestaña 'Logs'"
echo "   - Busca mensajes recientes:"
echo "     • '✅ Email enviado correctamente con SendGrid'"
echo "     • '❌ Error enviando email con SendGrid'"
echo "     • '⚠️ SENDGRID_API_KEY no configurada'"
echo ""
echo -e "${GREEN}3. Si las variables no están configuradas, agrégalas:${NC}"
echo "   - En Supabase Dashboard → Settings → Edge Functions → Secrets"
echo "   - Haz clic en 'Add new secret'"
echo "   - Agrega cada variable con su valor correspondiente"
echo "   - Después de agregar, la función se reiniciará automáticamente"
echo ""
echo -e "${BLUE}🔗 Enlaces útiles:${NC}"
echo "   - Supabase Secrets: https://supabase.com/dashboard/project/whtiazgcxdnemrrgjjqf/settings/functions"
echo "   - Supabase Functions: https://supabase.com/dashboard/project/whtiazgcxdnemrrgjjqf/functions"
echo "   - SendGrid Activity: https://app.sendgrid.com/activity"



