#!/bin/bash
# CLEAN_BUILD_APK.sh
# =========================================================================================
# SCRIPT DE COMPILACIÓN LIMPIA PARA APK - GRABOVOI
# Realiza una limpieza profunda local y compila con todas las variables de entorno.
# =========================================================================================

# Detener ante cualquier error
set -e

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PROJECT_DIR/.env"

cd "$PROJECT_DIR"

echo -e "${GREEN}🚀 INICIANDO PROCESO DE COMPILACIÓN LIMPIA (APK)${NC}"

# 1. Limpieza Profunda Local (Sin sudo para evitar bloqueos)
echo -e "\n${YELLOW}🧹 [1/4] Limpieza profunda local...${NC}"
flutter clean
rm -rf build/
rm -rf .dart_tool/
rm -rf android/.gradle/
rm -rf android/app/build/

# 2. Carga de Variables de Entorno
echo -e "\n${YELLOW}📄 [2/4] Cargando configuración (.env)...${NC}"
if [ -f "$ENV_FILE" ]; then
    # Leer variables ignorando comentarios y líneas vacías
    export $(grep -v '^#' "$ENV_FILE" | xargs)
    
    # Validar variables necesarias
    if [ -z "$OPENAI_API_KEY" ] || [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
        echo -e "${RED}❌ Error: Faltan variables críticas en .env (OPENAI_API_KEY, SUPABASE_URL o SUPABASE_ANON_KEY)${NC}"
        exit 1
    fi
    echo "✅ Variables cargadas."
else
    echo -e "${RED}❌ Error: Archivo .env no encontrado en $ENV_FILE${NC}"
    exit 1
fi

# 3. Preparación de dependencias
echo -e "\n${YELLOW}📥 [3/4] Obteniendo dependencias...${NC}"
flutter pub get

# 4. Compilación de APK
echo -e "\n${YELLOW}📱 [4/4] Compilando APK Release...${NC}"
flutter build apk --release \
    --dart-define=OPENAI_API_KEY=$OPENAI_API_KEY \
    --dart-define=SUPABASE_URL=$SUPABASE_URL \
    --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
    --dart-define=SB_SERVICE_ROLE_KEY=$SB_SERVICE_ROLE_KEY

echo -e "\n${GREEN}✅ APK GENERADA EXITOSAMENTE${NC}"
echo -e "📍 Ubicación: ${YELLOW}build/app/outputs/flutter-apk/app-release.apk${NC}"

# Notificación (solo en macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    osascript -e 'display notification "El APK de Grabovoi está listo" with title "Build Exitosa" sound name "Glass"'
fi
