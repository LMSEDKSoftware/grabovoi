#!/bin/bash

# Script para verificar la configuración de SendGrid en Supabase
# Este script verifica si las variables de entorno están configuradas

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Verificando configuración de SendGrid en Supabase${NC}"
echo ""

# Cargar variables de entorno
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

echo -e "${YELLOW}📋 Verificando función send-otp...${NC}"

# Probar la función con un email de prueba
RESPONSE=$(curl -s -X POST \
  "${SUPABASE_URL}/functions/v1/send-otp" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"email": "test-verification@manigrab.com"}')

echo -e "${GREEN}✅ Respuesta de la función:${NC}"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
echo ""

# Verificar si hay errores en la respuesta
if echo "$RESPONSE" | grep -q '"error"'; then
    echo -e "${RED}❌ Se detectó un error en la respuesta${NC}"
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error // .details // "Error desconocido"' 2>/dev/null || echo "Error en la respuesta")
    echo -e "${RED}   Error: ${ERROR_MSG}${NC}"
    echo ""
    echo -e "${YELLOW}💡 Posibles soluciones:${NC}"
    echo "   1. Verifica que las variables estén en Supabase Dashboard:"
    echo "      - Settings → Edge Functions → Secrets"
    echo "      - SENDGRID_API_KEY"
    echo "      - SENDGRID_FROM_EMAIL"
    echo "      - SENDGRID_FROM_NAME"
    echo ""
    echo "   2. Verifica que el API Key tenga permisos de 'Mail Send' en SendGrid"
    echo ""
    echo "   3. Verifica que el email remitente esté verificado en SendGrid"
    exit 1
fi

if echo "$RESPONSE" | grep -q '"ok":true'; then
    echo -e "${GREEN}✅ La función responde correctamente${NC}"
    echo ""
    echo -e "${YELLOW}📝 Nota: Si el email no llega, verifica:${NC}"
    echo "   1. Las variables de entorno en Supabase Dashboard"
    echo "   2. Los logs de la función en Supabase Dashboard"
    echo "   3. La actividad en SendGrid Dashboard"
    echo ""
    echo -e "${BLUE}🔗 Enlaces útiles:${NC}"
    echo "   - Supabase Functions: https://supabase.com/dashboard/project/whtiazgcxdnemrrgjjqf/functions"
    echo "   - SendGrid Activity: https://app.sendgrid.com/activity"
fi

