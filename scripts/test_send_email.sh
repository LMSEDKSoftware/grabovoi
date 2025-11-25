#!/bin/bash

# Script para probar el envío de emails desde SendGrid
# Uso: ./scripts/test_send_email.sh email@ejemplo.com

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar que se proporcione un email
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Debes proporcionar un email${NC}"
    echo -e "${YELLOW}Uso: ./scripts/test_send_email.sh email@ejemplo.com${NC}"
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

# Verificar que existan las variables necesarias
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo -e "${RED}❌ Error: Faltan variables de entorno (SUPABASE_URL o SUPABASE_ANON_KEY)${NC}"
    exit 1
fi

echo -e "${YELLOW}🧪 Probando envío de email a: ${EMAIL}${NC}"
echo ""

# Llamar a la función send-otp
echo -e "${YELLOW}📧 Invocando función send-otp...${NC}"

RESPONSE=$(curl -s -X POST \
  "${SUPABASE_URL}/functions/v1/send-otp" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"${EMAIL}\"}")

echo -e "${GREEN}✅ Respuesta de la función:${NC}"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
echo ""

# Verificar si fue exitoso
if echo "$RESPONSE" | grep -q '"ok":true'; then
    echo -e "${GREEN}✅ Solicitud procesada correctamente${NC}"
    echo ""
    echo -e "${YELLOW}📬 Verifica tu bandeja de entrada en: ${EMAIL}${NC}"
    echo -e "${YELLOW}📋 También revisa la carpeta de spam${NC}"
    echo ""
    echo -e "${YELLOW}💡 Para ver los logs de la función:${NC}"
    echo "   supabase functions logs send-otp"
    echo ""
    echo -e "${YELLOW}💡 Para ver la actividad en SendGrid:${NC}"
    echo "   Ve a: https://app.sendgrid.com/activity"
else
    echo -e "${RED}❌ Error en la respuesta de la función${NC}"
    exit 1
fi

