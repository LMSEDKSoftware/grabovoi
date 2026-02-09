#!/bin/bash
#
# Lanza Flutter web + Chrome con depuración habilitada para analizar
# audio, red y consola (voz numérica, sesión de repetición, etc.).
#
# Uso: ./scripts/launch_chrome_debug.sh
#
# Después de abrir la app:
# - F12 o Cmd+Option+I → DevTools
# - Pestaña Network: filtrar por "mp3" o "voice" para ver peticiones de voz
# - Pestaña Console: ver errores de AudioContext o audioplayers
# - chrome://inspect → inspeccionar la página si hace falta
#

set +e

echo "🔧 Iniciando Flutter + Chrome en modo depuración..."

PROJECT_DIR="/Users/ifernandez/development/grabovoi_build"
FIXED_PORT=49181
REMOTE_DEBUG_PORT=9222
LOG_FILE="/tmp/flutter_launch.log"
DEBUG_LOG_DIR="${PROJECT_DIR}/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DEBUG_LOG="${DEBUG_LOG_DIR}/flutter_debug_${TIMESTAMP}.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

mkdir -p "${DEBUG_LOG_DIR}"

# Limpiar procesos y puertos anteriores
echo -e "${YELLOW}🧹 Limpiando procesos anteriores...${NC}"
pkill -f "flutter run" 2>/dev/null || true
pkill -f "flutter_tools" 2>/dev/null || true
lsof -ti:${FIXED_PORT} | xargs kill -9 2>/dev/null || true
lsof -ti:${REMOTE_DEBUG_PORT} | xargs kill -9 2>/dev/null || true
sleep 2
echo -e "${GREEN}✅ Limpieza completada${NC}"

# Cargar .env
ENV_FILE="${PROJECT_DIR}/.env"
if [ ! -f "${ENV_FILE}" ]; then
    echo -e "${RED}❌ No se encontró .env en ${ENV_FILE}${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Cargando .env...${NC}"
while IFS='=' read -r key value || [ -n "$key" ]; do
    [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)
    [[ -z "$key" ]] && continue
    value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
    export "${key}=${value}"
done < "${ENV_FILE}"

if [ -z "${SUPABASE_URL}" ] || [ -z "${SUPABASE_ANON_KEY}" ]; then
    echo -e "${RED}❌ Variables de entorno no cargadas${NC}"
    exit 1
fi
echo -e "${GREEN}✅ .env cargado${NC}"

cd "${PROJECT_DIR}" || exit 1

# Flutter en modo verbose; salida a log y copia a debug log
echo -e "${GREEN}📦 Iniciando Flutter (verbose) en puerto ${FIXED_PORT}...${NC}"
nohup flutter run -d chrome \
    --web-port=${FIXED_PORT} \
    --verbose \
    --dart-define=OPENAI_API_KEY="${OPENAI_API_KEY}" \
    --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
    --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" \
    --dart-define=SB_SERVICE_ROLE_KEY="${SB_SERVICE_ROLE_KEY}" \
    > "${LOG_FILE}" 2>&1 &

FLUTTER_PID=$!
echo -e "${YELLOW}📝 Flutter PID: ${FLUTTER_PID}${NC}"
echo -e "${YELLOW}📝 Log: ${LOG_FILE}${NC}"
echo -e "${YELLOW}📝 Copia para análisis: ${DEBUG_LOG}${NC}"

# Esperar servidor
echo -e "${YELLOW}⏳ Esperando servidor en :${FIXED_PORT}...${NC}"
for i in {1..60}; do
    if ! kill -0 ${FLUTTER_PID} 2>/dev/null; then
        echo -e "${RED}❌ Flutter terminó inesperadamente${NC}"
        tail -50 "${LOG_FILE}"
        exit 1
    fi
    CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${FIXED_PORT}" 2>/dev/null)
    if [ "$CODE" = "200" ] || [ "$CODE" = "404" ]; then
        echo -e "${GREEN}✅ Servidor listo (HTTP ${CODE})${NC}"
        break
    fi
    sleep 2
done

CHROME_URL="http://localhost:${FIXED_PORT}"

# Copiar log actual para análisis
cp "${LOG_FILE}" "${DEBUG_LOG}" 2>/dev/null || true

# Abrir Chrome con depuración remota (puerto 9222)
echo -e "${GREEN}🌐 Abriendo Chrome con depuración remota (puerto ${REMOTE_DEBUG_PORT})...${NC}"
if [[ "$OSTYPE" == "darwin"* ]]; then
    open -a "Google Chrome" --args \
        --remote-debugging-port=${REMOTE_DEBUG_PORT} \
        --auto-open-devtools-for-tabs \
        "${CHROME_URL}"
else
    google-chrome --remote-debugging-port=${REMOTE_DEBUG_PORT} \
        --auto-open-devtools-for-tabs \
        "${CHROME_URL}" 2>/dev/null &
fi

sleep 2

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  MODO DEBUG – CÓMO ANALIZAR${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}1.${NC} DevTools debería abrirse solo (pestaña Console o Elements)."
echo -e "  ${GREEN}2.${NC} Pestaña ${YELLOW}Network${NC}: filtra por \"mp3\" o \"voice\" para ver audios de voz."
echo -e "  ${GREEN}3.${NC} Pestaña ${YELLOW}Console${NC}: revisa errores de AudioContext o audioplayers."
echo -e "  ${GREEN}4.${NC} Inspección remota: abre en otro navegador ${YELLOW}chrome://inspect${NC} → Open dedicated DevTools."
echo -e "  ${GREEN}5.${NC} Logs Flutter: ${YELLOW}tail -f ${LOG_FILE}${NC}"
echo -e "  ${GREEN}6.${NC} Copia del log para esta sesión: ${YELLOW}${DEBUG_LOG}${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "  URL app: ${GREEN}${CHROME_URL}${NC}"
echo -e "  Detener: ${YELLOW}kill ${FLUTTER_PID}${NC}"
echo ""
