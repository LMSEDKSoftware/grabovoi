#!/bin/bash

# Script para lanzar Flutter en Chrome con puerto automático.
# En web, Supabase necesita SUPABASE_URL y SUPABASE_ANON_KEY vía --dart-define;
# este script carga .env y los inyecta. Si ejecutas "Run" desde el IDE sin este
# script, las peticiones a Supabase fallarán (error en Network tab).
set +e  # No salir automáticamente si hay errores

echo "🚀 Iniciando proceso de lanzamiento de Flutter + Chrome..."

# Variables
    # ============================================
    # 1. Definir directorio del script y del proyecto (Método Robusto)
    # ============================================
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
    ENV_FILE="${PROJECT_DIR}/.env"
    
MAX_WAIT=180  # Máximo 3 minutos esperando
LOG_FILE="/tmp/flutter_launch.log"
PID_FILE="/tmp/flutter_launch.pid"
FIXED_PORT=49181  # Puerto fijo para Flutter Web
# En Flutter Web, CanvasKit a veces emite warning de "Noto fonts" al usar emojis/símbolos.
# HTML renderer usa las fuentes del sistema (incluye emojis) y evita ese warning en dev.
WEB_RENDERER="${WEB_RENDERER:-html}"

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

    # Detener PID previo si existe (mejor esfuerzo)
    if [ -f "${PID_FILE}" ]; then
        PREV_PID="$(cat "${PID_FILE}" 2>/dev/null)"
        if [ -n "${PREV_PID}" ]; then
            kill "${PREV_PID}" 2>/dev/null || true
        fi
        rm -f "${PID_FILE}" 2>/dev/null || true
    fi
    
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
    
    if [ -f "${ENV_FILE}" ]; then
        echo -e "📄 Cargando variables desde .env..."
        set -a
        source "${ENV_FILE}"
        set +a
    else
        echo -e "${YELLOW}⚠️ ADVERTENCIA: No se encontró el archivo .env en ${ENV_FILE}. Verificando variables de entorno...${NC}"
    fi
     
    # Verificar que las variables críticas estén cargadas
    # NOTA: SB_SERVICE_ROLE_KEY y OPENAI_API_KEY NO se validan ni se pasan aquí
    # a propósito: nunca deben llegar al build web (quedarían embebidas en el
    # bundle JS público). Viven solo en Edge Functions / server-side.
    if [ -z "${SUPABASE_URL}" ] || [ -z "${SUPABASE_ANON_KEY}" ]; then
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
    
    echo -e "${GREEN}📦 Compilando e iniciando servidor Flutter (web-server) en puerto ${FIXED_PORT}...${NC}"
    
    # Iniciar Flutter como "web-server" (sin depender de la pestaña de depuración de Chrome).
    # Esto evita el estado "Waiting for connection from debug service on Chrome..." y hace el
    # servidor más estable para pruebas manuales.
    nohup flutter run -d web-server \
        --web-renderer="${WEB_RENDERER}" \
        --web-hostname=127.0.0.1 \
        --web-port=${FIXED_PORT} \
        --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
        --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" \
        > "${LOG_FILE}" 2>&1 < /dev/null &
    
    FLUTTER_PID=$!
    echo "${FLUTTER_PID}" > "${PID_FILE}" 2>/dev/null || true
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
    
    # Importante: NO cambiamos la URL del tab de depuración que abrió Flutter.
    # En su lugar, abrimos (o enfocamos) otra pestaña/ventana apuntando al localhost.
    echo -e "${GREEN}🌐 Activando Chrome...${NC}"
    osascript 2>/dev/null <<APPLESCRIPT || true
tell application "Google Chrome"
  activate
  set targetUrl to "${CHROME_URL}/"

  set found to false
  try
    repeat with w in windows
      repeat with t in tabs of w
        if (URL of t as text) starts with targetUrl then
          set active tab index of w to (index of t)
          set index of w to 1
          set found to true
          exit repeat
        end if
      end repeat
      if found then exit repeat
    end repeat
  end try

  if not found then
    make new window
    set URL of active tab of front window to targetUrl
  end if
end tell
APPLESCRIPT
    sleep 1

    # Sanidad: confirmar que el servidor sigue vivo tras abrir/activar Chrome
    if ! ps -p ${FLUTTER_PID} > /dev/null 2>&1; then
        echo -e "${RED}❌ El proceso Flutter terminó inesperadamente tras activar Chrome${NC}"
        echo -e "${YELLOW}📋 Últimas líneas del log:${NC}"
        tail -30 "${LOG_FILE}"
        exit 1
    fi
    if ! curl -fsS -o /dev/null "http://localhost:${FIXED_PORT}/" 2>/dev/null; then
        echo -e "${RED}❌ El servidor dejó de responder en http://localhost:${FIXED_PORT}/${NC}"
        echo -e "${YELLOW}📋 Últimas líneas del log:${NC}"
        tail -30 "${LOG_FILE}"
        exit 1
    fi

    echo -e "${GREEN}✅ Chrome activado; app disponible en ${CHROME_URL}${NC}"
    echo -e "${GREEN}✅ URL: ${CHROME_URL}${NC}"
    echo ""
    echo -e "${YELLOW}💡 Para detener el servidor: kill ${FLUTTER_PID}${NC}"
    echo -e "${YELLOW}💡 Para ver logs: tail -f ${LOG_FILE}${NC}"
    
    return 0
}

# Ejecutar función principal
main "$@"
