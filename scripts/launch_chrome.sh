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
FIXED_PORT=49181  # Puerto fijo para Flutter Web

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
    
    # Liberar el puerto si está en uso
    lsof -ti:${FIXED_PORT} | xargs kill -9 2>/dev/null || true
    
    # Limpiar log anterior
    > "${LOG_FILE}"
    
    sleep 2
    echo -e "${GREEN}✅ Limpieza completada${NC}"
}

# Función para verificar si un puerto está libre
is_port_free() {
    local port=$1
    if lsof -ti:${port} >/dev/null 2>&1; then
        return 1  # Puerto ocupado
    else
        return 0  # Puerto libre
    fi
}

# Función para esperar a que el servidor esté listo
wait_for_server() {
    local port=$1
    local max_attempts=60  # Máximo 2 minutos (60 * 2 segundos)
    local attempt=0
    
    echo -e "${YELLOW}⏳ Esperando a que el servidor esté listo en puerto ${port}...${NC}"
    
    while [ $attempt -lt $max_attempts ]; do
        # Verificar si el proceso Flutter sigue corriendo
        if ! ps -p ${FLUTTER_PID} > /dev/null 2>&1; then
            echo -e "${RED}❌ El proceso Flutter terminó inesperadamente${NC}"
            return 1
        fi
        
        # Verificar si el servidor está respondiendo
        local response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${port}" 2>/dev/null)
        if [ "$response" = "200" ] || [ "$response" = "404" ]; then
            # 200 es ideal, pero 404 también indica que el servidor está activo
            echo -e "${GREEN}✅ Servidor respondiendo (HTTP ${response})${NC}"
            return 0
        fi
        
        if [ $((attempt % 5)) -eq 0 ] && [ $attempt -gt 0 ]; then
            echo -n "."
        fi
        
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}❌ Timeout: El servidor no respondió en el tiempo esperado${NC}"
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
    # Usamos método línea por línea para evitar problemas con source en macOS
    while IFS='=' read -r key value || [ -n "$key" ]; do
        # Ignorar líneas vacías y comentarios
        [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
        
        # Eliminar espacios en blanco al inicio y final
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        # Ignorar si key está vacío después de limpiar
        [[ -z "$key" ]] && continue
        
        # Manejar valores con comillas
        value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
        
        # Exportar la variable
        export "${key}=${value}"
    done < "${ENV_FILE}"
    
    # Verificar que las variables críticas estén cargadas
    if [ -z "${OPENAI_API_KEY}" ] || [ -z "${SUPABASE_URL}" ] || [ -z "${SUPABASE_ANON_KEY}" ] || [ -z "${SB_SERVICE_ROLE_KEY}" ]; then
        echo -e "${RED}❌ ERROR: Variables de entorno no cargadas correctamente${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Variables de entorno cargadas correctamente${NC}"
    echo ""
    
    # Verificar que el puerto esté libre
    if ! is_port_free ${FIXED_PORT}; then
        echo -e "${YELLOW}⚠️ Puerto ${FIXED_PORT} está en uso, intentando liberarlo...${NC}"
        lsof -ti:${FIXED_PORT} | xargs kill -9 2>/dev/null || true
        sleep 2
        if ! is_port_free ${FIXED_PORT}; then
            echo -e "${RED}❌ Error: No se pudo liberar el puerto ${FIXED_PORT}${NC}"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}📦 Compilando e iniciando servidor Flutter en puerto ${FIXED_PORT}...${NC}"
    
    # Iniciar Flutter con puerto fijo usando --web-port
    # Usamos nohup y & para mantener el proceso en background pero activo
    # Redirigimos salida a log pero mantenemos el proceso vivo
    nohup flutter run -d chrome \
        --web-port=${FIXED_PORT} \
        --dart-define=OPENAI_API_KEY="${OPENAI_API_KEY}" \
        --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
        --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" \
        --dart-define=SB_SERVICE_ROLE_KEY="${SB_SERVICE_ROLE_KEY}" \
        > "${LOG_FILE}" 2>&1 &
    
    FLUTTER_PID=$!
    echo -e "${YELLOW}📝 PID del proceso Flutter: ${FLUTTER_PID}${NC}"
    echo -e "${YELLOW}📝 Logs disponibles en: ${LOG_FILE}${NC}"
    echo ""
    
    # Esperar a que el servidor esté listo y respondiendo
    if ! wait_for_server ${FIXED_PORT}; then
        echo -e "${YELLOW}📋 Últimas líneas del log:${NC}"
        tail -30 "${LOG_FILE}"
        kill ${FLUTTER_PID} 2>/dev/null || true
        exit 1
    fi
    
    CHROME_URL="http://localhost:${FIXED_PORT}"
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
    if echo "$URL_CHECK" | grep -q "localhost:${FIXED_PORT}"; then
        echo -e "${GREEN}✅ ¡Chrome abierto correctamente y navegando a localhost:${FIXED_PORT}!${NC}"
    else
        echo -e "${GREEN}✅ Chrome abierto${NC}"
        echo -e "${YELLOW}⚠️ Si la página está en blanco, espera unos segundos más a que compile${NC}"
    fi
    echo -e "${GREEN}✅ URL: ${CHROME_URL}${NC}"
    echo ""
    echo -e "${YELLOW}💡 Para detener el servidor: kill ${FLUTTER_PID}${NC}"
    echo -e "${YELLOW}💡 Para ver logs: tail -f ${LOG_FILE}${NC}"
    
    return 0
}

# Ejecutar función principal
main "$@"
