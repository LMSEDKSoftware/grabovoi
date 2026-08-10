#!/bin/bash

# Script consistente para desarrollo web con Flutter
# Siempre ejecuta los mismos pasos en el mismo orden

set -e  # Salir si hay errores

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Obtener directorio del proyecto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_DIR}"

echo -e "${GREEN}🚀 Iniciando desarrollo web Flutter${NC}"
echo ""

# Paso 1: Limpiar procesos anteriores
echo -e "${YELLOW}📋 Paso 1: Limpiando procesos anteriores...${NC}"
pkill -f "flutter run" 2>/dev/null || true
pkill -f "flutter_tools" 2>/dev/null || true
sleep 2
echo -e "${GREEN}✅ Limpieza completada${NC}"
echo ""

# Paso 2: Cargar variables de entorno
echo -e "${YELLOW}📋 Paso 2: Cargando variables de entorno...${NC}"
ENV_FILE="${PROJECT_DIR}/.env"
FALLBACK_ENV="/Users/ifernandez/development/grabovoi_build/.env"

if [ -f "${ENV_FILE}" ]; then
    source "${ENV_FILE}"
elif [ -f "${FALLBACK_ENV}" ]; then
    echo -e "${YELLOW}⚠️  Usando .env de fallback${NC}"
    source "${FALLBACK_ENV}"
else
    echo -e "${RED}❌ ERROR: No se encontró archivo .env${NC}"
    exit 1
fi

# Verificar variables críticas
if [ -z "${SUPABASE_URL}" ] || [ -z "${SUPABASE_ANON_KEY}" ]; then
    echo -e "${RED}❌ ERROR: Variables de entorno incompletas${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Variables de entorno cargadas${NC}"
echo ""

# Paso 3: Iniciar Flutter en Chrome
echo -e "${YELLOW}📋 Paso 3: Iniciando Flutter en Chrome...${NC}"
echo -e "${GREEN}Flutter se abrirá automáticamente en Chrome cuando esté listo${NC}"
echo ""

# Ejecutar Flutter - Chrome se abrirá automáticamente
flutter run -d chrome \
    --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
    --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"
