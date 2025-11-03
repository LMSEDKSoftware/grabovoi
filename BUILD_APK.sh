#!/bin/bash

# 🚀 Script para generar APK con todas las variables necesarias
# Uso: ./BUILD_APK.sh

echo "🔨 Generando APK con todas las variables de entorno..."
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Ejecuta este script desde la raíz del proyecto"
    exit 1
fi

# Variables de entorno (lee desde .env o variables de entorno del sistema)
# ⚠️ IMPORTANTE: Configura estas variables en un archivo .env (no se sube a git)
# o exporta las variables de entorno antes de ejecutar este script

# Intentar cargar desde .env si existe
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Usar variables de entorno o valores por defecto vacíos
OPENAI_API_KEY="${OPENAI_API_KEY:-}"
SUPABASE_URL="${SUPABASE_URL:-}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"
SB_SERVICE_ROLE_KEY="${SB_SERVICE_ROLE_KEY:-}"

echo "📋 Variables configuradas:"
echo "  ✅ OPENAI_API_KEY"
echo "  ✅ SUPABASE_URL"
echo "  ✅ SUPABASE_ANON_KEY"
if [ "$SB_SERVICE_ROLE_KEY" = "TU_SERVICE_ROLE_KEY_AQUI" ]; then
    echo "  ⚠️  SB_SERVICE_ROLE_KEY: NO CONFIGURADA"
    echo ""
    echo "💡 Para obtener la Service Role Key:"
    echo "   1. Ve a https://app.supabase.com"
    echo "   2. Selecciona tu proyecto"
    echo "   3. Ve a Settings -> API"
    echo "   4. Copia el 'service_role' key"
    echo "   5. Reemplaza 'TU_SERVICE_ROLE_KEY_AQUI' en este script"
    echo ""
    read -p "¿Deseas continuar sin la Service Role Key? (puede dar error 401) [y/N]: " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Cancelado. Configura la Service Role Key primero."
        exit 1
    fi
else
    echo "  ✅ SB_SERVICE_ROLE_KEY: Configurada"
fi

echo ""
echo "🔨 Iniciando build del APK..."
echo ""

# Compilar APK con todas las variables
flutter build apk --release \
  --dart-define=OPENAI_API_KEY="$OPENAI_API_KEY" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=SB_SERVICE_ROLE_KEY="$SB_SERVICE_ROLE_KEY"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅✅✅ APK GENERADO EXITOSAMENTE ✅✅✅"
    echo ""
    echo "📦 Ubicación: build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "📱 Para instalar en tu dispositivo Android:"
    echo "   adb install build/app/outputs/flutter-apk/app-release.apk"
else
    echo ""
    echo "❌ Error al generar el APK"
    exit 1
fi

