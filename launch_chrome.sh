#!/bin/bash

# Script para lanzar Flutter en Chrome con verificación completa
# Autor: Auto
# Fecha: $(date)

# NO usar set -e aquí porque queremos manejar errores manualmente
set +e  # No salir automáticamente si hay errores

echo "🚀 Iniciando proceso de lanzamiento de Flutter + Chrome..."

# Variables
PROJECT_DIR="/Users/ifernandez/development/grabovoi_build"
PORT=8080
MAX_WAIT=120  # Máximo 2 minutos esperando
CHROME_URL="http://localhost:${PORT}"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para limpiar procesos anteriores
cleanup() {
    echo -e "${YELLOW}🧹 Limpiando procesos anteriores...${NC}"
    
    # Detener procesos Flutter
    pkill -f "flutter run" 2>/dev/null || true
    pkill -f "flutter_tools" 2>/dev/null || true
    
    # Liberar puerto 8080
    lsof -ti:${PORT} | xargs kill -9 2>/dev/null || true
    
    sleep 2
    echo -e "${GREEN}✅ Limpieza completada${NC}"
}

# Función para verificar si el servidor está respondiendo
check_server() {
    local response=$(curl -s -o /dev/null -w "%{http_code}" ${CHROME_URL} 2>/dev/null)
    if [ "$response" = "200" ]; then
        return 0  # Servidor disponible
    else
        return 1  # Servidor no disponible
    fi
}

# Función para esperar a que el servidor esté listo
wait_for_server() {
    echo -e "${YELLOW}⏳ Esperando a que el servidor compile y esté listo...${NC}"
    
    local elapsed=0
    while [ $elapsed -lt $MAX_WAIT ]; do
        if check_server; then
            echo -e "${GREEN}✅ Servidor disponible después de ${elapsed} segundos${NC}"
            return 0
        fi
        
        echo -n "."
        sleep 3
        elapsed=$((elapsed + 3))
    done
    
    echo -e "\n${RED}❌ Error: Servidor no respondió después de ${MAX_WAIT} segundos${NC}"
    return 1
}

# Función principal
main() {
    cd "${PROJECT_DIR}" || exit 1
    
    # Limpiar procesos anteriores
    cleanup
    
    # ============================================
    # CARGAR VARIABLES DE ENTORNO DEL .env
    # ============================================
    echo -e "${YELLOW}📋 Cargando variables de entorno desde .env...${NC}"
    
    ENV_FILE="${PROJECT_DIR}/.env"
    
    if [ ! -f "${ENV_FILE}" ]; then
        echo -e "${RED}❌ ERROR: No se encontró el archivo .env en ${ENV_FILE}${NC}"
        exit 1
    fi
    
    # Cargar variables de forma segura línea por línea
    set -a  # Automáticamente exportar todas las variables
    source "${ENV_FILE}" 2>/dev/null || {
        # Si source falla, usar método alternativo línea por línea
        while IFS='=' read -r key value; do
            # Ignorar líneas vacías y comentarios
            [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
            # Eliminar espacios en blanco al inicio y final
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            # Exportar la variable
            export "${key}=${value}"
        done < "${ENV_FILE}"
    }
    set +a  # Desactivar exportación automática
    
    # Verificar que las variables críticas estén cargadas
    if [ -z "${OPENAI_API_KEY}" ] || [ -z "${SUPABASE_URL}" ] || [ -z "${SUPABASE_ANON_KEY}" ] || [ -z "${SB_SERVICE_ROLE_KEY}" ]; then
        echo -e "${RED}❌ ERROR: Variables de entorno no cargadas correctamente${NC}"
        echo -e "${YELLOW}Verificando variables...${NC}"
        echo "OPENAI_API_KEY: ${OPENAI_API_KEY:0:20}..." 
        echo "SUPABASE_URL: ${SUPABASE_URL}"
        echo "SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:0:20}..."
        echo "SB_SERVICE_ROLE_KEY: ${SB_SERVICE_ROLE_KEY:0:20}..."
        exit 1
    fi
    
    echo -e "${GREEN}✅ Variables de entorno cargadas correctamente${NC}"
    echo -e "${GREEN}   OPENAI_API_KEY: ${OPENAI_API_KEY:0:20}...${NC}"
    echo -e "${GREEN}   SUPABASE_URL: ${SUPABASE_URL}${NC}"
    echo -e "${GREEN}   SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:0:20}...${NC}"
    echo -e "${GREEN}   SB_SERVICE_ROLE_KEY: ${SB_SERVICE_ROLE_KEY:0:20}...${NC}"
    echo ""
    
    echo -e "${GREEN}📦 Compilando e iniciando servidor Flutter...${NC}"
    
    # Iniciar Flutter en background y capturar output
    flutter run -d chrome \
        --web-port=${PORT} \
        --dart-define=OPENAI_API_KEY="${OPENAI_API_KEY}" \
        --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
        --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" \
        --dart-define=SB_SERVICE_ROLE_KEY="${SB_SERVICE_ROLE_KEY}" \
        > /tmp/flutter_launch.log 2>&1 &
    
    FLUTTER_PID=$!
    echo -e "${YELLOW}📝 PID del proceso Flutter: ${FLUTTER_PID}${NC}"
    echo -e "${YELLOW}📝 Logs disponibles en: /tmp/flutter_launch.log${NC}"
    
    # Esperar a que el servidor esté listo
    if wait_for_server; then
        echo -e "${GREEN}🌐 Abriendo Chrome...${NC}"
        sleep 2  # Pequeño delay adicional para asegurar estabilidad
        
        # Abrir Chrome
        open -a "Google Chrome" "${CHROME_URL}"
        
        echo -e "${GREEN}✅ ¡Chrome abierto correctamente!${NC}"
        echo -e "${GREEN}✅ URL: ${CHROME_URL}${NC}"
        echo ""
        echo -e "${YELLOW}💡 Para detener el servidor: kill ${FLUTTER_PID}${NC}"
        echo -e "${YELLOW}💡 Para ver logs: tail -f /tmp/flutter_launch.log${NC}"
        
        return 0
    else
        echo -e "${RED}❌ Error: No se pudo iniciar el servidor${NC}"
        echo -e "${YELLOW}📋 Revisando logs...${NC}"
        tail -50 /tmp/flutter_launch.log
        kill ${FLUTTER_PID} 2>/dev/null || true
        return 1
    fi
}

# Ejecutar función principal
main "$@"

