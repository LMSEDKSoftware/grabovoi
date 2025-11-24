#!/bin/bash

# Script para lanzar Flutter en Chrome con puerto automático
# Autor: Auto
# Fecha: $(date)

set +e  # No salir automáticamente si hay errores

echo "🚀 Iniciando proceso de lanzamiento de Flutter + Chrome..."

# Variables
PROJECT_DIR="/Users/ifernandez/development/grabovoi_build"
MAX_WAIT=180  # Máximo 3 minutos esperando
LOG_FILE="/tmp/flutter_launch.log"

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
    
    # Limpiar log anterior
    > "${LOG_FILE}"
    
    sleep 2
    echo -e "${GREEN}✅ Limpieza completada${NC}"
}

# Función para extraer el puerto de los logs de Flutter
extract_port() {
    local port=""
    local max_attempts=90
    
    echo -e "${YELLOW}Buscando puerto en logs...${NC}"
    
    for i in $(seq 1 $max_attempts); do
        # Buscar patrones comunes en los logs de Flutter
        # Patrón 1: "Serving at http://localhost:XXXX"
        port=$(grep -oE 'localhost:[0-9]{4,5}' "${LOG_FILE}" 2>/dev/null | grep -oE '[0-9]{4,5}' | head -1)
        
        # Patrón 2: Buscar en procesos que están escuchando
        if [ -z "$port" ]; then
            port=$(lsof -i -P 2>/dev/null | grep LISTEN | grep dart | grep -oE ':[0-9]{4,5}' | grep -oE '[0-9]{4,5}' | grep -vE '^(64659|9109)$' | head -1)
        fi
        
        # Patrón 3: Probar puertos comunes de Flutter
        if [ -z "$port" ]; then
            for test_port in 8080 8081 8082 8083 8084 5000 5001 5002 3000 3001; do
                if curl -s -o /dev/null -w "%{http_code}" "http://localhost:${test_port}" 2>/dev/null | grep -q "200"; then
                    port=$test_port
                    break
                fi
            done
        fi
        
        # Si encontramos un puerto válido, verificar que el servidor responda
        if [ -n "$port" ] && [ "$port" -ge 1024 ] && [ "$port" -le 65535 ]; then
            if curl -s -o /dev/null -w "%{http_code}" "http://localhost:${port}" 2>/dev/null | grep -q "200"; then
                echo "$port"
                return 0
            fi
        fi
        
        if [ $((i % 5)) -eq 0 ]; then
            echo -n "."
        fi
        sleep 2
    done
    
    echo ""
    return 1
}

# Función para verificar si el servidor está respondiendo
check_server() {
    local port=$1
    local url="http://localhost:${port}"
    local response=$(curl -s -o /dev/null -w "%{http_code}" "${url}" 2>/dev/null)
    if [ "$response" = "200" ]; then
        return 0  # Servidor disponible
    else
        return 1  # Servidor no disponible
    fi
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
        exit 1
    fi
    
    echo -e "${GREEN}✅ Variables de entorno cargadas correctamente${NC}"
    echo ""
    
    echo -e "${GREEN}📦 Compilando e iniciando servidor Flutter (puerto automático)...${NC}"
    
    # Iniciar Flutter SIN especificar puerto (dejar que Flutter asigne uno automáticamente)
    # Usamos chrome (no chrome-server) pero capturamos el puerto antes de que abra Chrome
    flutter run -d chrome \
        --dart-define=OPENAI_API_KEY="${OPENAI_API_KEY}" \
        --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
        --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" \
        --dart-define=SB_SERVICE_ROLE_KEY="${SB_SERVICE_ROLE_KEY}" \
        > "${LOG_FILE}" 2>&1 &
    
    FLUTTER_PID=$!
    echo -e "${YELLOW}📝 PID del proceso Flutter: ${FLUTTER_PID}${NC}"
    echo -e "${YELLOW}📝 Logs disponibles en: ${LOG_FILE}${NC}"
    echo ""
    
    # Esperar a detectar el puerto asignado por Flutter
    echo -e "${YELLOW}⏳ Esperando a que Flutter asigne un puerto y compile...${NC}"
    DETECTED_PORT=$(extract_port)
    
    if [ -z "$DETECTED_PORT" ]; then
        echo -e "${RED}❌ Error: No se pudo detectar el puerto asignado por Flutter${NC}"
        echo -e "${YELLOW}📋 Últimas líneas del log:${NC}"
        tail -30 "${LOG_FILE}"
        kill ${FLUTTER_PID} 2>/dev/null || true
        exit 1
    fi
    
    CHROME_URL="http://localhost:${DETECTED_PORT}"
    echo -e "${GREEN}✅ Puerto detectado: ${DETECTED_PORT}${NC}"
    echo -e "${GREEN}✅ Servidor disponible en: ${CHROME_URL}${NC}"
    echo ""
    
    # Abrir Chrome usando AppleScript
    echo -e "${GREEN}🌐 Abriendo Chrome con AppleScript...${NC}"
    sleep 1
    
    osascript <<APPLESCRIPT
tell application "System Events"
    set chromeRunning to (name of processes) contains "Google Chrome"
    if chromeRunning then
        tell application "Google Chrome"
            activate
            if (count of windows) > 0 then
                set URL of active tab of front window to "${CHROME_URL}"
            else
                make new window
                set URL of active tab of front window to "${CHROME_URL}"
            end if
        end tell
    else
        tell application "Google Chrome"
            activate
            make new window
            set URL of active tab of front window to "${CHROME_URL}"
        end tell
    end if
end tell
APPLESCRIPT
    
    sleep 2
    
    # Verificar que Chrome esté abierto y navegando a la URL correcta
    URL_CHECK=$(osascript -e "tell application \"Google Chrome\" to get URL of active tab of front window" 2>/dev/null)
    if echo "$URL_CHECK" | grep -q "localhost:${DETECTED_PORT}"; then
        echo -e "${GREEN}✅ ¡Chrome abierto correctamente y navegando a localhost:${DETECTED_PORT}!${NC}"
    else
        echo -e "${GREEN}✅ Chrome abierto${NC}"
    fi
    echo -e "${GREEN}✅ URL: ${CHROME_URL}${NC}"
    echo ""
    echo -e "${YELLOW}💡 Para detener el servidor: kill ${FLUTTER_PID}${NC}"
    echo -e "${YELLOW}💡 Para ver logs: tail -f ${LOG_FILE}${NC}"
    
    return 0
}

# Ejecutar función principal
main "$@"
