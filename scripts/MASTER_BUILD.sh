#!/bin/bash
# MASTER_BUILD.sh
# =========================================================================================
# SCRIPT MAESTRO DE COMPILACIÓN - GRABOVOI
# Genera: Web, APK y AAB (Android App Bundle)
# Incluye: Auto-incremento de versión, limpieza profunda, gestión de permisos y notificaciones.
# =========================================================================================

# Detener ante cualquier error
set -e

# Definir colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directorios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env"

cd "$PROJECT_DIR"
echo -e "${GREEN}🚀 INICIANDO MASTER BUILD PROCESS${NC}"
echo "📂 Directorio: $PROJECT_DIR"

# =========================================================================================
# 1. AUTOGESTIÓN DE PERMISOS Y LIMPIEZA PROFUNDA
# =========================================================================================
echo -e "\n${YELLOW}🔒 [Fase 1] Gestión de Permisos y Limpieza${NC}"

# Pedir sudo de forma anticipada para no interrumpir después
if [ "$EUID" -ne 0 ]; then
  echo "🔑 Se requieren permisos de administrador para limpiar cachés del sistema y Gradle."
  sudo -v
  # Mantener sudo vivo
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

echo "🛑 Deteniendo procesos de fondo..."
./android/gradlew --stop 2>/dev/null || true
sudo pkill -9 java 2>/dev/null || true

echo "🧹 Eliminando cachés corruptas..."
# Limpieza de Gradle usuario y proyecto
rm -rf android/.gradle
rm -rf ~/.gradle/caches/journal-1
rm -rf ~/.gradle/caches/transforms-1
rm -rf ~/.gradle/caches/transforms-2
rm -rf ~/.gradle/caches/transforms-3
rm -rf ~/.kotlin/daemon

# Fix permisos de Flutter cache (dinámico)
FLUTTER_BIN_PATH=$(dirname "$(which flutter)")
if [ -d "$FLUTTER_BIN_PATH/cache" ]; then
    echo "🔧 Arreglando permisos de caché de Flutter..."
    sudo chown -R $(whoami) "$FLUTTER_BIN_PATH/cache"
fi

echo "🛠️ Flutter Clean..."
flutter clean
echo "📥 Flutter Pub Get..."
flutter pub get

# =========================================================================================
# 2. CARGA DE VARIABLES
# =========================================================================================
echo -e "\n${YELLOW}📄 [Fase 2] Carga de Entorno (.env)${NC}"

if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
    
    # Validar críticas
    MISSING_VARS=0
    [ -z "$SUPABASE_URL" ] && echo -e "${RED}❌ Falta SUPABASE_URL${NC}" && MISSING_VARS=1
    [ -z "$SUPABASE_ANON_KEY" ] && echo -e "${RED}❌ Falta SUPABASE_ANON_KEY${NC}" && MISSING_VARS=1

    if [ $MISSING_VARS -eq 1 ]; then
        echo -e "${RED}❌ Error: Faltan variables en .env. Abortando.${NC}"
        exit 1
    fi
    echo "✅ Variables cargadas correctamente."
else
    echo -e "${RED}❌ Error: No se encuentra .env${NC}"
    exit 1
fi

DART_DEFINES="--dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"

# =========================================================================================
# 3. VERSIONADO AUTOMÁTICO
# =========================================================================================
echo -e "\n${YELLOW}📝 [Fase 3] Incremento de Versión${NC}"

CURRENT_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
VERSION_NAME=$(echo $CURRENT_VERSION | cut -d'+' -f1)
VERSION_CODE=$(echo $CURRENT_VERSION | cut -d'+' -f2)

# Incrementar
NEW_VERSION_CODE=$((VERSION_CODE + 1))
IFS='.' read -ra V_PARTS <<< "$VERSION_NAME"
NEW_PATCH=$((${V_PARTS[2]} + 1))
NEW_VERSION_NAME="${V_PARTS[0]}.${V_PARTS[1]}.$NEW_PATCH"

# Aplicar cambios
sed -i.bak "s/^version:.*/version: $NEW_VERSION_NAME+$NEW_VERSION_CODE/" pubspec.yaml
rm -f pubspec.yaml.bak

sed -i.bak "s/versionCode = [0-9]*/versionCode = $NEW_VERSION_CODE/" android/app/build.gradle
sed -i.bak "s/versionName = \".*\"/versionName = \"$NEW_VERSION_NAME\"/" android/app/build.gradle
rm -f android/app/build.gradle.bak

echo "🔄 Versión actualizada: $CURRENT_VERSION -> $NEW_VERSION_NAME+$NEW_VERSION_CODE"

# =========================================================================================
# 4. COMPILACIÓN TRIPLE
# =========================================================================================
echo -e "\n${YELLOW}🚀 [Fase 4] Compilación Universal${NC}"

# A. WEB
echo -e "\n🌐 Compilando WEB..."
flutter build web --release $DART_DEFINES
echo "✅ Web OK"

# B. APK
echo -e "\n📱 Compilando APK..."
flutter build apk --release $DART_DEFINES
echo "✅ APK OK"

# C. AAB
echo -e "\n📦 Compilando AAB (Bundle)..."
flutter build appbundle --release $DART_DEFINES
echo "✅ AAB OK"

# =========================================================================================
# 5. FINALIZACIÓN
# =========================================================================================
echo -e "\n${GREEN}✅✅✅ MASTER BUILD COMPLETADO CON ÉXITO ✅✅✅${NC}"
echo -e "📂 Archivos generados:"
echo -e "   👉 WEB: build/web/"
echo -e "   👉 APK: build/app/outputs/flutter-apk/app-release.apk"
echo -e "   👉 AAB: build/app/outputs/bundle/release/app-release.aab"

# Actualizar versión en Supabase automáticamente
bash "$SCRIPT_DIR/update_supabase_version.sh" "$NEW_VERSION_NAME"

# Notificaciones macOS
osascript -e 'display notification "Web, APK y AAB listos para distribución" with title "ManiGrab Build Exitosa" sound name "Glass"'
say "Proceso maestro terminado exitosamente"

