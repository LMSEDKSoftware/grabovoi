#!/bin/bash

# Script para ejecutar múltiples pruebas de envío de emails automáticamente
# Uso: ./scripts/test_email_batch.sh [número_de_pruebas] [email_base]

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

NUM_TESTS=${1:-5}
EMAIL_BASE=${2:-"prueba-auto"}

echo -e "${BLUE}🧪 Ejecutando ${NUM_TESTS} pruebas automáticas de envío de emails${NC}"
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

SUCCESS_COUNT=0
FAIL_COUNT=0
TIMESTAMP=$(date +%s)

for i in $(seq 1 $NUM_TESTS); do
    TEST_EMAIL="${EMAIL_BASE}-${TIMESTAMP}-${i}@manigrab.com"
    echo -e "${YELLOW}📧 Prueba ${i}/${NUM_TESTS}: ${TEST_EMAIL}${NC}"
    
    RESPONSE=$(curl -s -X POST \
      "${SUPABASE_URL}/functions/v1/send-otp" \
      -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
      -H "Content-Type: application/json" \
      -d "{\"email\": \"${TEST_EMAIL}\"}")
    
    if echo "$RESPONSE" | grep -q '"ok":true'; then
        echo -e "${GREEN}  ✅ Éxito${NC}"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo -e "${RED}  ❌ Error${NC}"
        echo "  Respuesta: $RESPONSE"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
    
    # Pequeña pausa entre pruebas
    sleep 1
done

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ Pruebas exitosas: ${SUCCESS_COUNT}/${NUM_TESTS}${NC}"
if [ $FAIL_COUNT -gt 0 ]; then
    echo -e "${RED}❌ Pruebas fallidas: ${FAIL_COUNT}/${NUM_TESTS}${NC}"
fi
echo ""
echo -e "${YELLOW}💡 Para verificar si los emails llegaron:${NC}"
echo "   1. Revisa SendGrid Activity: https://app.sendgrid.com/activity"
echo "   2. Revisa los logs de Supabase: supabase functions logs send-otp"
echo "   3. Busca los emails en las bandejas de entrada (o spam)"



