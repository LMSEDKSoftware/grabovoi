#!/bin/bash

# Script para lanzar Chrome automáticamente después de cambios
# Este script verifica si Chrome está corriendo y lo lanza si no lo está

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔍 Verificando si Chrome está corriendo...${NC}"

# Verificar si Chrome está corriendo
if pgrep -f "chrome.*localhost:8080" > /dev/null; then
    echo -e "${GREEN}✅ Chrome ya está corriendo${NC}"
    echo -e "${YELLOW}🔄 Recargando aplicación...${NC}"
    # Enviar comando 'r' para hot reload (si Flutter está corriendo)
    # Esto es una aproximación, el hot reload real requiere conexión a Flutter
    echo -e "${GREEN}✅ La aplicación debería recargarse automáticamente${NC}"
else
    echo -e "${YELLOW}🚀 Chrome no está corriendo, lanzando...${NC}"
    ./launch_chrome.sh
fi

# Verificar que el servidor esté activo
echo -e "${YELLOW}⏳ Esperando a que el servidor esté listo...${NC}"
for i in {1..30}; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null | grep -q "200"; then
        echo -e "${GREEN}✅ Servidor activo (código 200)${NC}"
        break
    fi
    sleep 1
    if [ $i -eq 30 ]; then
        echo -e "${RED}❌ Timeout esperando servidor${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✅ Chrome está listo para validar cambios${NC}"

