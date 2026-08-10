#!/bin/bash

# Script para compilar AAB (Android App Bundle) con todas las variables de entorno
# Uso: ./BUILD_AAB.sh

set -e

echo "🚀 Iniciando compilación de AAB con variables de entorno..."
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

# Incrementar versionado automáticamente
increment_version

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
echo "   SUPABASE_URL: $SUPABASE_URL"
echo "   SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:0:30}..."
echo ""

echo "📦 Compilando AAB en modo release..."
flutter build appbundle --release \
    --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
    --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"

echo ""
echo "✅ ¡AAB compilado exitosamente!"
echo "📍 Ubicación: $(pwd)/build/app/outputs/bundle/release/app-release.aab"
echo ""
ls -lh build/app/outputs/bundle/release/app-release.aab
echo ""
echo "🔍 Verificando que la versión del AAB coincida con el proyecto..."
./scripts/verificar_version_aab.sh build/app/outputs/bundle/release/app-release.aab

# Actualizar versión en Supabase automáticamente
bash "$(dirname "$0")/update_supabase_version.sh" "$NEW_VERSION_NAME"
