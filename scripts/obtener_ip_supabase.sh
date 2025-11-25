#!/bin/bash

# Script para obtener la IP desde la cual se ejecuta Supabase Edge Functions
# Esto ayuda a agregar la IP correcta a la whitelist de SendGrid

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🌐 Obteniendo IP de Supabase Edge Functions${NC}"
echo "=================================================="
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

echo -e "${YELLOW}📧 Invocando función detect-ip...${NC}"

RESPONSE=$(curl -s -X GET \
  "${SUPABASE_URL}/functions/v1/detect-ip" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  -H "Content-Type: application/json")

echo ""
echo -e "${GREEN}✅ Respuesta:${NC}"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
echo ""

# Extraer la IP si está disponible
PUBLIC_IP=$(echo "$RESPONSE" | jq -r '.info.publicIP' 2>/dev/null || echo "")

if [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "unknown" ]; then
    echo -e "${GREEN}🌐 IP Pública detectada: ${PUBLIC_IP}${NC}"
    echo ""
    echo -e "${YELLOW}📝 Próximos pasos:${NC}"
    echo "   1. Ve a SendGrid Dashboard → Settings → IP Access Management"
    echo "      URL: https://app.sendgrid.com/settings/ip_access_management"
    echo ""
    echo "   2. Haz clic en 'Add IP Address'"
    echo ""
    echo "   3. Agrega la IP: ${PUBLIC_IP}"
    echo ""
    echo "   4. Guarda los cambios"
    echo ""
    echo "   5. Prueba de nuevo:"
    echo "      ./scripts/test_send_email.sh 2005.ivan@gmail.com"
    echo ""
    echo -e "${YELLOW}⚠️  Nota:${NC}"
    echo "   - Las IPs de Supabase pueden cambiar"
    echo "   - Es mejor usar Domain Authentication si es posible"
    echo "   - Revisa también los logs de Supabase para más detalles"
else
    echo -e "${YELLOW}⚠️  No se pudo detectar la IP automáticamente${NC}"
    echo ""
    echo -e "${YELLOW}💡 Alternativas:${NC}"
    echo "   1. Revisa los logs de Supabase para la función 'detect-ip'"
    echo "   2. Contacta a Supabase Support para obtener el rango de IPs"
    echo "   3. Usa Domain Authentication en SendGrid (recomendado)"
fi



