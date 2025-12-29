#!/bin/bash

# Script para probar la solicitud de OTP y ver los logs
# Uso: ./scripts/test_otp_request.sh <email>

set -e

EMAIL="${1:-2005.ivan@gmail.com}"

echo "🧪 Probando solicitud de OTP para: $EMAIL"
echo ""

# Cargar variables de entorno
if [ -f .env ]; then
  echo "📋 Cargando variables de entorno desde .env..."
  export $(cat .env | grep -v '^#' | xargs)
  echo "✅ Variables cargadas"
else
  echo "⚠️  No se encontró archivo .env"
fi

echo ""
echo "🔍 Verificando configuración..."
echo "   SUPABASE_URL: ${SUPABASE_URL:0:30}..."
echo "   SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:0:30}..."
echo ""

# Verificar si Supabase está corriendo localmente
if curl -s http://127.0.0.1:54321/rest/v1/ > /dev/null 2>&1; then
  echo "✅ Supabase local detectado en puerto 54321"
  SUPABASE_URL="${SUPABASE_URL:-http://127.0.0.1:54321}"
else
  echo "🌐 Usando Supabase remoto"
fi

echo ""
echo "📧 Invocando función send-otp..."
echo ""

# Usar curl para invocar la función directamente y ver la respuesta completa
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  "${SUPABASE_URL}/functions/v1/send-otp" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\"}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "📊 Respuesta HTTP: $HTTP_CODE"
echo "📦 Cuerpo de respuesta:"
echo "$BODY" | jq . 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_CODE" = "200" ]; then
  OTP=$(echo "$BODY" | jq -r '.dev_otp // empty' 2>/dev/null)
  if [ -n "$OTP" ]; then
    echo "🔧 OTP generado (dev): $OTP"
  fi
  echo "✅ Solicitud exitosa"
else
  echo "❌ Error en la solicitud"
fi

echo ""
echo "📋 Para ver los logs de la función Edge, revisa:"
echo "   - Supabase Dashboard > Edge Functions > send-otp > Logs"
echo "   - O ejecuta: supabase functions logs send-otp"

