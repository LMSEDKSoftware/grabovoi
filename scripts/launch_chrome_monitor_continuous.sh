#!/bin/bash

# Script para lanzar Chrome y monitorear continuamente hasta que se cierre
# Monitorea en tiempo real y no se detiene hasta que Chrome se cierre

set +e

PROJECT_DIR="/Users/ifernandez/development/grabovoi_build"
LOG_FILE="/tmp/flutter_launch.log"

echo "🚀 Iniciando Flutter + Chrome con monitoreo continuo..."
echo "📊 El monitoreo continuará hasta que Chrome se cierre"
echo ""

# Limpiar procesos anteriores
pkill -f "flutter.*run.*chrome" 2>/dev/null || true
> "${LOG_FILE}"
sleep 2

# Cargar variables de entorno
cd "${PROJECT_DIR}" || exit 1
if [ -f .env ]; then
    set -a
    source .env 2>/dev/null || {
        while IFS='=' read -r key value; do
            [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
            export "${key}=${value}"
        done < .env
    }
    set +a
    echo "✅ Variables de entorno cargadas"
else
    echo "❌ Error: No se encontró .env"
    exit 1
fi

# Función para extraer el puerto de los logs
extract_port() {
    local port=""
    local max_attempts=60
    
    for i in $(seq 1 $max_attempts); do
        port=$(grep -oP 'localhost:\K[0-9]+' "${LOG_FILE}" 2>/dev/null | head -1)
        
        if [ -z "$port" ]; then
            port=$(grep -oE 'localhost:[0-9]{4,5}' "${LOG_FILE}" 2>/dev/null | grep -oE '[0-9]{4,5}' | head -1)
        fi
        
        if [ -n "$port" ] && [ "$port" -ge 1024 ] && [ "$port" -le 65535 ]; then
            if curl -s -o /dev/null -w "%{http_code}" "http://localhost:${port}" 2>/dev/null | grep -q "200"; then
                echo "$port"
                return 0
            fi
        fi
        
        sleep 2
    done
    
    return 1
}

# Función para verificar si Chrome está abierto
is_chrome_running() {
    if pgrep -f "Google Chrome" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Iniciar Flutter
echo "📦 Compilando e iniciando servidor Flutter..."
flutter run -d chrome \
    --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
    --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" \
    > "${LOG_FILE}" 2>&1 &

FLUTTER_PID=$!
echo "📝 Flutter PID: $FLUTTER_PID"
echo ""

# Esperar a detectar el puerto
echo "⏳ Esperando a que Flutter asigne un puerto..."
DETECTED_PORT=$(extract_port)

if [ -z "$DETECTED_PORT" ]; then
    echo "❌ Timeout esperando puerto"
    tail -30 "${LOG_FILE}"
    kill $FLUTTER_PID 2>/dev/null || true
    exit 1
fi

CHROME_URL="http://localhost:${DETECTED_PORT}"
echo "✅ Puerto detectado: ${DETECTED_PORT}"
echo "✅ Servidor activo en: ${CHROME_URL}"
echo ""

# Abrir Chrome usando AppleScript
echo "🌐 Abriendo Chrome..."
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

sleep 3

# Verificar que Chrome esté abierto
if ! is_chrome_running; then
    echo "⚠️ Chrome no se abrió correctamente"
    kill $FLUTTER_PID 2>/dev/null || true
    exit 1
fi

echo "✅ Chrome abierto correctamente"
echo "✅ URL: ${CHROME_URL}"
echo ""
echo "🔍 Iniciando monitoreo continuo..."
echo "📊 El monitoreo continuará hasta que Chrome se cierre"
echo "💡 Para detener manualmente: kill $FLUTTER_PID"
echo ""

# Monitoreo continuo
MONITOR_COUNT=0
LAST_STATUS="running"

while true; do
    # Verificar si Chrome sigue abierto
    if ! is_chrome_running; then
        if [ "$LAST_STATUS" != "closed" ]; then
            echo ""
            echo "🔴 Chrome se ha cerrado"
            echo "🛑 Deteniendo monitoreo..."
            LAST_STATUS="closed"
        fi
        # Esperar un poco más para confirmar que Chrome realmente se cerró
        sleep 2
        if ! is_chrome_running; then
            echo "✅ Monitoreo finalizado"
            kill $FLUTTER_PID 2>/dev/null || true
            exit 0
        fi
    else
        if [ "$LAST_STATUS" != "running" ]; then
            echo "🟢 Chrome está abierto"
            LAST_STATUS="running"
        fi
        
        # Verificar que el servidor siga respondiendo cada 10 segundos
        if [ $((MONITOR_COUNT % 5)) -eq 0 ]; then
            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${CHROME_URL}" 2>/dev/null)
            if [ "$HTTP_CODE" != "200" ]; then
                echo "⚠️ Servidor no responde correctamente (código: $HTTP_CODE)"
            fi
        fi
    fi
    
    MONITOR_COUNT=$((MONITOR_COUNT + 1))
    sleep 2
done

