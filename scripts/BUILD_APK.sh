#!/bin/bash

# Script para compilar APK con todas las variables de entorno
# Uso: ./build_apk.sh

set -e

echo "🚀 Iniciando compilación de APK con variables de entorno..."
echo ""

# Función para incrementar versionado
increment_version() {
    # Leer versión actual de pubspec.yaml
    CURRENT_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
    
    # Separar versionName y versionCode
    VERSION_NAME=$(echo $CURRENT_VERSION | cut -d'+' -f1)
    VERSION_CODE=$(echo $CURRENT_VERSION | cut -d'+' -f2)
    
    # Incrementar versionCode
    NEW_VERSION_CODE=$((VERSION_CODE + 1))
    
    # Incrementar versionName (patch version)
    IFS='.' read -ra VERSION_PARTS <<< "$VERSION_NAME"
    MAJOR=${VERSION_PARTS[0]}
    MINOR=${VERSION_PARTS[1]}
    PATCH=${VERSION_PARTS[2]}
    
    # Incrementar patch
    NEW_PATCH=$((PATCH + 1))
    NEW_VERSION_NAME="$MAJOR.$MINOR.$NEW_PATCH"
    
    # Actualizar pubspec.yaml
    sed -i.bak "s/^version:.*/version: $NEW_VERSION_NAME+$NEW_VERSION_CODE/" pubspec.yaml
    rm -f pubspec.yaml.bak
    
    # Actualizar build.gradle
    sed -i.bak "s/versionCode = [0-9]*/versionCode = $NEW_VERSION_CODE/" android/app/build.gradle
    sed -i.bak "s/versionName = \".*\"/versionName = \"$NEW_VERSION_NAME\"/" android/app/build.gradle
    rm -f android/app/build.gradle.bak
    
    echo "📝 Versionado actualizado:"
    echo "   Versión anterior: $VERSION_NAME+$VERSION_CODE"
    echo "   Versión nueva: $NEW_VERSION_NAME+$NEW_VERSION_CODE"
    echo ""
}

# Definir directorio del proyecto (el directorio padre de scripts/)
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

# Incrementar versionado automáticamente
increment_version

# Cargar variables de entorno desde .env
if [ ! -f "${PROJECT_DIR}/.env" ]; then
    echo "❌ Error: No se encontró el archivo .env en $PROJECT_DIR"
    exit 1
fi

echo "📋 Cargando variables de entorno desde .env..."
set -a # Exportar automáticamente
source "${PROJECT_DIR}/.env"
set +a

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
