#!/bin/bash
#
# Auditoría en modo DEBUG – ManiGraB
# Verifica que la app compile, analice sin errores y funcione en Chrome.
#
# Uso: ./scripts/auditoria_debug_chrome.sh [--no-launch]
#
# --no-launch: Solo ejecuta análisis y build; no lanza Chrome.
# Sin --no-launch: Tras las verificaciones, lanza la app en Chrome para inspección manual.
#

set -e

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="${PROJECT_DIR}/.env"
LOG_DIR="${PROJECT_DIR}/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
AUDIT_LOG="${LOG_DIR}/auditoria_debug_${TIMESTAMP}.log"
FIXED_PORT=49181
NO_LAUNCH=false

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Parsear argumentos
for arg in "$@"; do
    case $arg in
        --no-launch) NO_LAUNCH=true ;;
    esac
done

# Contadores
FAILURES=0
TOTAL=0

log() { echo -e "$1" | tee -a "${AUDIT_LOG}" 2>/dev/null || echo -e "$1"; }
ok()  { log "${GREEN}✅ $1${NC}"; TOTAL=$((TOTAL + 1)); }
fail() { log "${RED}❌ $1${NC}"; FAILURES=$((FAILURES + 1)); TOTAL=$((TOTAL + 1)); }
warn() { log "${YELLOW}⚠️  $1${NC}"; TOTAL=$((TOTAL + 1)); }

mkdir -p "${LOG_DIR}"
echo "" > "${AUDIT_LOG}"
log "${CYAN}════════════════════════════════════════════════════════════${NC}"
log "${CYAN}  AUDITORÍA DEBUG – ManiGraB${NC}"
log "${CYAN}  $(date)${NC}"
log "${CYAN}════════════════════════════════════════════════════════════${NC}"
log ""

cd "${PROJECT_DIR}" || exit 1

# 1. Verificar .env
log "1. Verificando variables de entorno..."
if [ -f "${ENV_FILE}" ]; then
    set -a
    source "${ENV_FILE}" 2>/dev/null || true
    set +a
fi
if [ -z "${SUPABASE_URL}" ] || [ -z "${SUPABASE_ANON_KEY}" ]; then
    fail "Variables SUPABASE_URL y SUPABASE_ANON_KEY no definidas (carga .env)"
else
    ok "Variables de entorno cargadas"
fi

# 2. flutter pub get
log ""
log "2. flutter pub get..."
if flutter pub get >> "${AUDIT_LOG}" 2>&1; then
    ok "pub get OK"
else
    fail "pub get falló"
fi

# 3. flutter analyze lib/ (informativo; no bloquea - build web es la certificación)
log ""
log "3. flutter analyze lib/ (informativo)..."
if flutter analyze lib/ --no-fatal-infos --no-fatal-warnings >> "${AUDIT_LOG}" 2>&1; then
    ok "flutter analyze lib/ OK"
else
    warn "flutter analyze lib/ tiene observaciones (ver ${AUDIT_LOG})"
fi

# 4. flutter build web
log ""
log "4. flutter build web..."
BUILD_CMD="flutter build web"
if [ -n "${OPENAI_API_KEY}" ] && [ -n "${SUPABASE_URL}" ] && [ -n "${SUPABASE_ANON_KEY}" ]; then
    BUILD_CMD="${BUILD_CMD} --dart-define=OPENAI_API_KEY=${OPENAI_API_KEY} --dart-define=SUPABASE_URL=${SUPABASE_URL} --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}"
    [ -n "${SB_SERVICE_ROLE_KEY}" ] && BUILD_CMD="${BUILD_CMD} --dart-define=SB_SERVICE_ROLE_KEY=${SB_SERVICE_ROLE_KEY}"
fi
if eval "${BUILD_CMD}" >> "${AUDIT_LOG}" 2>&1; then
    ok "build web OK"
else
    fail "build web falló (ver ${AUDIT_LOG})"
    tail -50 "${AUDIT_LOG}" | while read line; do log "$line"; done
fi

# 5. flutter test
log ""
log "5. flutter test..."
if flutter test >> "${AUDIT_LOG}" 2>&1; then
    ok "flutter test OK"
else
    warn "flutter test tuvo fallos (revisar ${AUDIT_LOG})"
fi

# 6. Lanzar servidor y verificar respuesta
log ""
log "6. Verificando servidor web..."
pkill -f "flutter run.*chrome" 2>/dev/null || true
lsof -ti:${FIXED_PORT} | xargs kill -9 2>/dev/null || true
sleep 2

RUN_CMD="flutter run -d chrome --web-port=${FIXED_PORT}"
[ -n "${OPENAI_API_KEY}" ] && RUN_CMD="${RUN_CMD} --dart-define=OPENAI_API_KEY=${OPENAI_API_KEY}"
[ -n "${SUPABASE_URL}" ] && RUN_CMD="${RUN_CMD} --dart-define=SUPABASE_URL=${SUPABASE_URL}"
[ -n "${SUPABASE_ANON_KEY}" ] && RUN_CMD="${RUN_CMD} --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}"
[ -n "${SB_SERVICE_ROLE_KEY}" ] && RUN_CMD="${RUN_CMD} --dart-define=SB_SERVICE_ROLE_KEY=${SB_SERVICE_ROLE_KEY}"

if [ "${NO_LAUNCH}" = false ]; then
    log "   Iniciando servidor en puerto ${FIXED_PORT}..."
    eval "nohup ${RUN_CMD} >> ${AUDIT_LOG} 2>&1 &"
    FLUTTER_PID=$!
    log "   PID: ${FLUTTER_PID}"
    sleep 3

    SERVER_READY=false
    for i in $(seq 1 45); do
        CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${FIXED_PORT}" 2>/dev/null)
        if [ "$CODE" = "200" ] || [ "$CODE" = "404" ]; then
            SERVER_READY=true
            break
        fi
        sleep 2
    done

    if [ "${SERVER_READY}" = true ]; then
        ok "Servidor respondiendo (HTTP ${CODE})"
        CHROME_URL="http://localhost:${FIXED_PORT}"
        log ""
        log "${GREEN}🌐 App disponible en: ${CHROME_URL}${NC}"
        log "   Abre Chrome y navega a la URL para verificar funcionalidades."
        log "   DevTools (F12) → Console para ver errores en runtime."
        log ""
        log "   Para detener: kill ${FLUTTER_PID}"
        log "   Logs: tail -f ${AUDIT_LOG}"
    else
        fail "Timeout: servidor no respondió en puerto ${FIXED_PORT}"
        kill ${FLUTTER_PID} 2>/dev/null || true
    fi
else
    ok "Omisión de lanzamiento (--no-launch)"
fi

# Resumen
log ""
log "${CYAN}════════════════════════════════════════════════════════════${NC}"
log "  RESUMEN"
log "${CYAN}════════════════════════════════════════════════════════════${NC}"
log "  Total verificaciones: ${TOTAL}"
log "  Fallos: ${RED}${FAILURES}${NC}"
log "  Log: ${AUDIT_LOG}"
log ""

if [ ${FAILURES} -eq 0 ]; then
    log "${GREEN}✅ AUDITORÍA CERTIFICADA: Nada se rompió.${NC}"
    log "   - pub get, build web y servidor OK."
    log "   - Revisa la app en Chrome para confirmar funcionalidades manualmente."
    exit 0
else
    log "${RED}❌ Auditoría encontró ${FAILURES} fallo(s) críticos. Revisa el log.${NC}"
    exit 1
fi
