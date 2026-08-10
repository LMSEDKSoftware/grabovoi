#!/bin/bash

# Script para lanzar Chrome y monitorear hasta que esté completamente listo e interactivo
# Usa puerto automático asignado por Flutter
set +e

PROJECT_DIR="/Users/ifernandez/development/grabovoi_build"
LOG_FILE="/tmp/flutter_launch.log"
WEB_RENDERER="${WEB_RENDERER:-html}"

echo "🚀 Iniciando Flutter + Chrome con monitoreo completo (puerto automático)..."

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
        # Buscar patrones comunes en los logs de Flutter
        port=$(grep -oP 'localhost:\K[0-9]+' "${LOG_FILE}" 2>/dev/null | head -1)
        
        if [ -z "$port" ]; then
            port=$(grep -oE 'localhost:[0-9]{4,5}' "${LOG_FILE}" 2>/dev/null | grep -oE '[0-9]{4,5}' | head -1)
        fi
        
        # Si encontramos un puerto válido, verificar que el servidor responda
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

# Iniciar Flutter SIN especificar puerto
echo "📦 Compilando e iniciando servidor Flutter (puerto automático)..."
flutter run -d chrome \
    --web-renderer="${WEB_RENDERER}" \
    --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
    --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" \
    > "${LOG_FILE}" 2>&1 &

FLUTTER_PID=$!
echo "📝 Flutter PID: $FLUTTER_PID"

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

# Abrir Chrome usando AppleScript
echo "🌐 Abriendo Chrome con AppleScript..."
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

# Monitorear hasta que Chrome esté completamente listo
echo "🔍 Monitoreando Chrome hasta que esté completamente listo..."
for i in {1..30}; do
    if ps aux | grep -i "Google Chrome" | grep -v grep | grep -q "Chrome"; then
        if curl -s "${CHROME_URL}" > /dev/null 2>&1; then
            URL_CHECK=$(osascript -e "tell application \"Google Chrome\" to get URL of active tab of front window" 2>/dev/null)
            if echo "$URL_CHECK" | grep -q "localhost:${DETECTED_PORT}"; then
                echo "✅ Chrome está abierto y navegando a localhost:${DETECTED_PORT}"
                echo "✅ Servidor respondiendo correctamente"
                echo "✅ URL: ${CHROME_URL}"
                echo "✅ Listo para interactuar"
                echo ""
                echo "💡 Para detener: kill $FLUTTER_PID"
                echo "💡 Para ver logs: tail -f ${LOG_FILE}"
                exit 0
            fi
        fi
    fi
    sleep 2
done

echo "⚠️ Chrome puede estar abriéndose aún..."
echo "✅ Servidor activo en: ${CHROME_URL}"
osascript -e 'tell application "Google Chrome" to activate' 2>/dev/null
