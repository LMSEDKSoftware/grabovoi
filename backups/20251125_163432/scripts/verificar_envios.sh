#!/bin/bash

# Script para verificar el estado de los envíos de email
# Este script proporciona instrucciones para verificar manualmente en SendGrid

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Verificación de Envíos de Email${NC}"
echo "========================================"
echo ""

# Cargar variables de entorno
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo -e "${RED}❌ Error: No se encontró el archivo .env${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Pasos para verificar si los emails están llegando:${NC}"
echo ""
echo -e "${GREEN}1. SendGrid Dashboard - Activity${NC}"
echo "   URL: https://app.sendgrid.com/activity"
echo "   - Busca los emails enviados en los últimos minutos"
echo "   - Filtra por 'To' con dominio '@manigrab.com'"
echo "   - Verifica el estado de cada email:"
echo "     • Processed ✅ = Email enviado exitosamente"
echo "     • Delivered ✅ = Email entregado al servidor del destinatario"
echo "     • Bounced ⚠️  = Email rebotó (dirección inválida)"
echo "     • Blocked ⚠️  = Email bloqueado por políticas"
echo "     • Failed ❌ = Error al enviar"
echo "     • Dropped ❌ = Email descartado"
echo ""
echo -e "${GREEN}2. Supabase Dashboard - Functions Logs${NC}"
echo "   URL: https://supabase.com/dashboard/project/whtiazgcxdnemrrgjjqf/functions"
echo "   - Selecciona la función 'send-otp'"
echo "   - Ve a la pestaña 'Logs'"
echo "   - Busca mensajes como:"
echo "     • '✅ Email enviado correctamente con SendGrid'"
echo "     • '❌ Error enviando email con SendGrid'"
echo "     • '⚠️ SENDGRID_API_KEY no configurada'"
echo ""
echo -e "${GREEN}3. Verificar Variables de Entorno en Supabase${NC}"
echo "   URL: https://supabase.com/dashboard/project/whtiazgcxdnemrrgjjqf/settings/functions"
echo "   - Ve a 'Edge Functions' → 'Secrets'"
echo "   - Verifica que existan:"
echo "     • SENDGRID_API_KEY (debe estar configurada)"
echo "     • SENDGRID_FROM_EMAIL (ej: noreply@manigrab.com)"
echo "     • SENDGRID_FROM_NAME (ej: ManiGrab)"
echo ""
echo -e "${YELLOW}💡 Notas importantes:${NC}"
echo "   - Los emails de prueba a '@manigrab.com' pueden no llegar si el dominio no está verificado"
echo "   - Para pruebas reales, usa un email válido que puedas verificar"
echo "   - Los emails pueden tardar unos segundos en aparecer en SendGrid Activity"
echo "   - Revisa también la carpeta de spam en el email de destino"
echo ""
echo -e "${BLUE}🔗 Enlaces rápidos:${NC}"
echo "   - SendGrid Activity: https://app.sendgrid.com/activity"
echo "   - Supabase Functions: https://supabase.com/dashboard/project/whtiazgcxdnemrrgjjqf/functions"
echo "   - Supabase Secrets: https://supabase.com/dashboard/project/whtiazgcxdnemrrgjjqf/settings/functions"
echo ""

# Intentar hacer una prueba final con un email real si se proporciona
if [ -n "$1" ]; then
    TEST_EMAIL="$1"
    echo -e "${YELLOW}🧪 Ejecutando prueba final con email real: ${TEST_EMAIL}${NC}"
    echo ""
    
    if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
        echo -e "${RED}❌ Error: Faltan variables de entorno${NC}"
        exit 1
    fi
    
    RESPONSE=$(curl -s -X POST \
      "${SUPABASE_URL}/functions/v1/send-otp" \
      -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
      -H "Content-Type: application/json" \
      -d "{\"email\": \"${TEST_EMAIL}\"}")
    
    if echo "$RESPONSE" | grep -q '"ok":true'; then
        echo -e "${GREEN}✅ Solicitud procesada correctamente${NC}"
        echo -e "${YELLOW}📬 Revisa la bandeja de entrada de ${TEST_EMAIL}${NC}"
        echo -e "${YELLOW}📋 También revisa la carpeta de spam${NC}"
    else
        echo -e "${RED}❌ Error en la solicitud${NC}"
        echo "Respuesta: $RESPONSE"
    fi
fi



