#!/bin/bash

# Script para ejecutar la app en Android con variables de entorno
# Uso: ./RUN_ANDROID.sh

set -e

echo "🚀 Iniciando aplicación Android con variables de entorno..."
echo ""

# Cargar variables de entorno desde .env
if [ ! -f .env ]; then
    echo "❌ Error: No se encontró el archivo .env"
    exit 1
fi

echo "📋 Cargando variables de entorno desde .env..."
source .env

# Verificar que las variables existen
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "❌ Error: Faltan variables de entorno en .env"
    exit 1
fi

echo "✅ Variables de entorno cargadas correctamente"
echo ""

echo "📱 Ejecutando aplicación en Android..."
flutter run -d android \
    --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
    --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"

