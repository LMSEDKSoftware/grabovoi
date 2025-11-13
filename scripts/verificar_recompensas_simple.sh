#!/bin/bash

# Script simple para verificar recompensas usando curl y Supabase REST API
# Requiere: SUPABASE_URL y SUPABASE_ANON_KEY en .env

# Cargar variables de entorno
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "❌ Error: Archivo .env no encontrado"
    exit 1
fi

EMAIL="${1:-2005.ivan@gmail.com}"
echo "🔍 Verificando recompensas para: $EMAIL"
echo ""

# 1. Buscar usuario (requiere service role key para auth.users)
echo "1️⃣ Buscando usuario..."
USER_ID=$(curl -s -X POST "${SUPABASE_URL}/rest/v1/rpc/get_user_id_by_email" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"${EMAIL}\"}" | jq -r '.id' 2>/dev/null)

if [ -z "$USER_ID" ] || [ "$USER_ID" = "null" ]; then
    echo "⚠️ No se pudo obtener USER_ID directamente"
    echo "   Usa el SQL script en Supabase para obtener el USER_ID"
    exit 1
fi

echo "✅ User ID: $USER_ID"
echo ""

# 2. Verificar user_rewards
echo "2️⃣ Verificando user_rewards..."
curl -s -X GET "${SUPABASE_URL}/rest/v1/user_rewards?user_id=eq.${USER_ID}&select=*" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  | jq '.[0] | {
    cristales_energia,
    luz_cuantica,
    restauradores_armonia,
    anclas_continuidad,
    ultima_actualizacion,
    updated_at
  }'

echo ""
echo "✅ Verificación completada"
echo ""
echo "💡 Para más detalles, ejecuta el script SQL en Supabase:"
echo "   scripts/verificar_recompensas_sql.sql"

