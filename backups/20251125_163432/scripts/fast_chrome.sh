#!/bin/bash

# Script ULTRA-RÁPIDO para Chrome
# Si hay servidor activo: solo abre Chrome (1 segundo)
# Si no hay servidor: lanza con puerto fijo 8080 (más rápido)

set -e

PORT=8080
LOG_FILE="/tmp/flutter_launch.log"
PROJECT_DIR="/Users/ifernandez/development/grabovoi_build"

# Función para verificar servidor
check_server() {
    curl -s -o /dev/null -w "%{http_code}" "http://localhost:$1" 2>/dev/null | grep -q "200"
}

# Función para abrir Chrome
open_chrome() {
    osascript -e 'tell application "Google Chrome" to activate' \
              -e "tell application \"Google Chrome\" to open location \"http://localhost:$1\"" 2>/dev/null || true
}

cd "$PROJECT_DIR" || exit 1

# Verificar si ya hay servidor en puerto 8080
if check_server 8080; then
    echo "✅ Servidor activo en puerto 8080"
    open_chrome 8080
    echo "✅ Chrome abierto - Listo en 1 segundo!"
    exit 0
fi

# Buscar en otros puertos comunes
for port in 55040 63656 63784 63800 63900; do
    if check_server "$port"; then
        echo "✅ Servidor activo en puerto $port"
        open_chrome "$port"
        echo "✅ Chrome abierto - Listo en 1 segundo!"
        exit 0
    fi
done

# Si no hay servidor, lanzar uno nuevo con puerto fijo (más rápido)
echo "📦 Lanzando servidor en puerto fijo 8080 (esto toma ~1-2 min la primera vez)..."

# Cargar variables de entorno
if [ -f .env ]; then
    set -a
    source .env 2>/dev/null || {
        while IFS='=' read -r key value; do
            [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
            export "${key}=${value}"
        done < .env
    }
    set +a
fi

# Limpiar procesos anteriores
pkill -f "flutter.*run" 2>/dev/null || true
sleep 1

# Lanzar con puerto fijo (más rápido que buscar puerto automático)
> "$LOG_FILE"
flutter run -d chrome --web-port=8080 \
    --dart-define=OPENAI_API_KEY="${OPENAI_API_KEY}" \
    --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
    --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" \
    --dart-define=SB_SERVICE_ROLE_KEY="${SB_SERVICE_ROLE_KEY}" \
    > "$LOG_FILE" 2>&1 &

FLUTTER_PID=$!
echo "⏳ Esperando compilación (PID: $FLUTTER_PID)..."

# Esperar máximo 120 segundos
for i in {1..60}; do
    if check_server 8080; then
        echo "✅ Servidor listo!"
        sleep 1
        open_chrome 8080
        echo "✅ Chrome abierto en puerto 8080"
        echo "💡 Para detener: kill $FLUTTER_PID"
        exit 0
    fi
    sleep 2
    if [ $((i % 10)) -eq 0 ]; then
        echo "⏳ Esperando... ($((i*2))/120 segundos)"
    fi
done

echo "❌ Timeout esperando servidor"
tail -10 "$LOG_FILE"
exit 1

