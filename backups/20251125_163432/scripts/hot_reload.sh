#!/bin/bash

# Script ultra-rápido para hot reload
# Solo verifica si hay servidor y hace reload, sin reiniciar

set -e

LOG_FILE="/tmp/flutter_launch.log"

# Buscar puerto activo
find_port() {
    # Buscar en logs
    local port=$(grep -oE '[0-9]{4,5}' "$LOG_FILE" 2>/dev/null | grep -E '^[5-9][0-9]{4}$' | tail -1)
    if [ -n "$port" ]; then
        local http_code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port" 2>/dev/null || echo "000")
        if [ "$http_code" = "200" ]; then
            echo "$port"
            return 0
        fi
    fi
    
    # Buscar en puertos comunes
    for port in 8080 55040 63656 63784 63800 63900; do
        local http_code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port" 2>/dev/null || echo "000")
        if [ "$http_code" = "200" ]; then
            echo "$port"
            return 0
        fi
    done
    
    return 1
}

# Abrir Chrome
open_chrome() {
    local port=$1
    osascript -e 'tell application "Google Chrome" to activate' \
              -e "tell application \"Google Chrome\" to open location \"http://localhost:$port\"" 2>/dev/null || true
}

# Main
PORT=$(find_port)

if [ -n "$PORT" ]; then
    echo "✅ Servidor activo en puerto $PORT"
    echo "🔄 Recargando página en Chrome..."
    open_chrome "$PORT"
    echo "✅ Listo! Los cambios deberían verse automáticamente"
    echo "💡 Si no ves cambios, presiona Cmd+Shift+R en Chrome para hard refresh"
else
    echo "❌ No se encontró servidor activo"
    echo "💡 Ejecuta primero: bash scripts/launch_chrome.sh"
    exit 1
fi

