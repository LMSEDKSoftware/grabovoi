#!/bin/bash

# Script SIMPLE para debug de recovery password
# Ejecuta un test y muestra TODO lo que pasa

set -e

echo "🔍 DEBUG SIMPLE - RECOVERY PASSWORD"
echo "===================================="
echo ""

[ -f ".env" ] && export $(cat .env | grep -v '^#' | xargs)

EMAIL="2005.ivan@mail.com"
SECRET="413e5255f5d41dea06bf1a3d8bd58b0b4b70a5e6b4c72d19572141aab47e8deb"

# Test 1: Servidor PHP directo
echo "TEST 1: Servidor PHP directo"
echo "----------------------------"

PAYLOAD='{"to":"'$EMAIL'","template_id":"d-971362da419640f7be3c3cb7fae9881d","template_data":{"name":"Test","app_name":"ManiGrab","recovery_link":"https://manigrab.app/recovery?token=test123"},"subject":"Test"}'

echo "URLs a probar:"
for URL in \
  "https://manigrab.app/api/send-email/email_endpoint.php" \
  "https://manigrab.app/email_endpoint.php" \
  "https://manigrab.app/api/send-email"
do
  echo ""
  echo "Probando: $URL"
  curl -v -X POST "$URL" \
    -H "Authorization: Bearer $SECRET" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" 2>&1 | grep -E "(HTTP|error|success|{" || echo "Sin respuesta"
done

echo ""
echo ""
echo "TEST 2: Edge Function completa"
echo "------------------------------"

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "⚠️  Variables SUPABASE_URL o SUPABASE_ANON_KEY no configuradas"
  echo "   Carga el .env o configura las variables"
else
  echo "Enviando request a Edge Function..."
  curl -v -X POST "${SUPABASE_URL}/functions/v1/send-otp" \
    -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$EMAIL\",\"action\":\"recovery\"}" 2>&1 | head -50
fi

echo ""
echo "✅ Test completado"
echo ""
echo "INSTRUCCIONES:"
echo "1. Revisa las respuestas HTTP arriba"
echo "2. Si hay errores, copia los logs completos"
echo "3. Revisa los logs en Supabase Dashboard > Edge Functions > send-otp"
echo "4. Revisa los logs del servidor PHP (error_log)"





