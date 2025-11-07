#!/bin/bash

# Script para compilar APK con todas las variables de entorno
# Uso: ./build_apk.sh

set -e

echo "🚀 Iniciando compilación de APK con variables de entorno..."
echo ""

# Cargar variables de entorno desde .env
if [ ! -f .env ]; then
    echo "❌ Error: No se encontró el archivo .env"
    exit 1
fi

echo "📋 Cargando variables de entorno desde .env..."
source .env

# Verificar que las variables existen
if [ -z "$OPENAI_API_KEY" ] || [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ] || [ -z "$SB_SERVICE_ROLE_KEY" ]; then
    echo "❌ Error: Faltan variables de entorno en .env"
    exit 1
fi

echo "✅ Variables de entorno cargadas correctamente"
echo "   OPENAI_API_KEY: ${OPENAI_API_KEY:0:20}..."
echo "   SUPABASE_URL: $SUPABASE_URL"
echo "   SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:0:30}..."
echo "   SB_SERVICE_ROLE_KEY: ${SB_SERVICE_ROLE_KEY:0:30}..."
echo ""

echo "📦 Compilando APK en modo release..."
flutter build apk --release \
    --dart-define=OPENAI_API_KEY="${OPENAI_API_KEY}" \
    --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
    --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" \
    --dart-define=SB_SERVICE_ROLE_KEY="${SB_SERVICE_ROLE_KEY}"

echo ""
echo "✅ ¡APK compilada exitosamente!"
echo "📍 Ubicación: $(pwd)/build/app/outputs/flutter-apk/app-release.apk"
echo ""
ls -lh build/app/outputs/flutter-apk/app-release.apk
