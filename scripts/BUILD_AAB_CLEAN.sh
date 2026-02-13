#!/bin/bash
# Script robusto para compilar AAB evitando errores comunes de entorno
# Uso: ./scripts/BUILD_AAB_CLEAN.sh

# 1. Definir directorio del script y del proyecto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env"

echo "📂 Directorio del proyecto: $PROJECT_DIR"
cd "$PROJECT_DIR"

# 2. Función para cargar variables del .env de forma robusta
load_env() {
    if [ -f "$ENV_FILE" ]; then
        echo "📄 Cargando variables desde .env..."
        # Exportar variables ignorando comentarios y líneas vacías
        set -a
        source "$ENV_FILE"
        set +a
    else
        echo "⚠️  ADVERTENCIA: No se encontró $ENV_FILE. Verificando variables de entorno..."
    fi
}

# 3. Función para incrementar versionado
increment_version() {
    echo "📝 Actualizando versión..."
    
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
    
    echo "   Versión anterior: $VERSION_NAME+$VERSION_CODE"
    echo "   Versión nueva: $NEW_VERSION_NAME+$NEW_VERSION_CODE"
    echo ""
}


# Intentar cargar .env
load_env

# 3. Verificar variables críticas
MISSING_VARS=0
if [ -z "$OPENAI_API_KEY" ]; then echo "❌ Falta OPENAI_API_KEY"; MISSING_VARS=1; fi
if [ -z "$SUPABASE_URL" ]; then echo "❌ Falta SUPABASE_URL"; MISSING_VARS=1; fi
if [ -z "$SUPABASE_ANON_KEY" ]; then echo "❌ Falta SUPABASE_ANON_KEY"; MISSING_VARS=1; fi
if [ -z "$SB_SERVICE_ROLE_KEY" ]; then echo "❌ Falta SB_SERVICE_ROLE_KEY"; MISSING_VARS=1; fi

if [ $MISSING_VARS -eq 1 ]; then
    echo "❌ Error: Faltan variables de entorno críticas. Asegúrate de tener el archivo .env configurado."
    exit 1
fi

# 4. Verificar permisos (simular la lógica del script FIX)
echo "🔍 Verificando entorno Flutter..."
FLUTTER_BIN="$(which flutter)"

if [ -z "$FLUTTER_BIN" ]; then
    echo "❌ Error: Flutter no encontrado en el PATH."
    exit 1
fi

# Verificar permisos del lockfile si existe
FLUTTER_CACHE_DIR="$(dirname "$FLUTTER_BIN")/cache"
LOCKFILE="$FLUTTER_CACHE_DIR/lockfile"

if [ -f "$LOCKFILE" ]; then
    if [ ! -w "$LOCKFILE" ]; then
        echo "⚠️  ADVERTENCIA DE PERMISOS DETECTADA"
        echo "   El archivo de bloqueo de Flutter no es escribible por el usuario actual."
        echo "   Intentando eliminarlo..."
        rm -f "$LOCKFILE" 2>/dev/null || echo "   (No se pudo eliminar automáticamente, podría fallar la compilación)"
    fi
fi

# 5. Incrementar versión
increment_version

# 6. Ejecutar compilación
echo "🚀 Iniciando Flutter Build AppBundle (AAB)..."
echo "   Versión release..."

flutter build appbundle --release \
    --dart-define=OPENAI_API_KEY="$OPENAI_API_KEY" \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    --dart-define=SB_SERVICE_ROLE_KEY="$SB_SERVICE_ROLE_KEY"

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✅ ¡Compilación exitosa!"
    echo "📦 AAB generado en: build/app/outputs/bundle/release/app-release.aab"
    ls -lh build/app/outputs/bundle/release/app-release.aab
    
    # Verificar versión
    echo ""
    echo "🔍 Verificando versión del AAB..."
    if [ -f "./scripts/verificar_version_aab.sh" ]; then
        ./scripts/verificar_version_aab.sh build/app/outputs/bundle/release/app-release.aab
    else
        echo "⚠️ Script de verificación no encontrado."
    fi
else
    echo ""
    echo "❌ La compilación falló."
fi

exit $EXIT_CODE
