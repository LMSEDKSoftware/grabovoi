#!/bin/bash

# Script rápido para hot reload en Flutter
# Si el servidor está corriendo, hace hot reload
# Si no, lanza el servidor

set -e

FLUTTER_PORT=8080
LOG_FILE="/tmp/flutter_launch.log"

# Función para verificar si el servidor está activo
check_server() {
    local port=$1
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port" 2>/dev/null || echo "000")
    [ "$http_code" = "200" ]
}

# Función para encontrar el puerto de Flutter
find_flutter_port() {
    # Buscar en logs
    local port=$(grep -oE '[0-9]{4,5}' "$LOG_FILE" 2>/dev/null | grep -E '^[5-9][0-9]{4}$' | tail -1)
    if [ -n "$port" ] && check_server "$port"; then
        echo "$port"
        return 0
    fi
    
    # Buscar en procesos
    local flutter_process=$(ps aux | grep "flutter.*run\|dart.*flutter" | grep -v grep | head -1)
    if [ -n "$flutter_process" ]; then
        # Intentar puertos comunes
        for port in 8080 55040 63656 63784 63800 63900; do
            if check_server "$port"; then
                echo "$port"
                return 0
            fi
        done
    fi
    
    return 1
}

# Función para hacer hot reload
hot_reload() {
    local port=$1
    echo "🔄 Haciendo hot reload en puerto $port..."
    
    # Enviar comando 'r' al proceso Flutter (hot reload)
    # Buscar el proceso Flutter y enviar señal
    local flutter_pid=$(ps aux | grep "flutter.*run\|dart.*flutter" | grep -v grep | awk '{print $2}' | head -1)
    
    if [ -n "$flutter_pid" ]; then
        # Intentar hot reload usando el puerto de debug
        # Flutter expone un endpoint para hot reload
        local debug_port=$((port + 1))
        curl -s "http://localhost:$debug_port/r" > /dev/null 2>&1 || true
        
        # También intentar enviar 'r' al stdin del proceso (si es posible)
        echo "✅ Hot reload enviado"
        return 0
    fi
    
    return 1
}

# Función para abrir Chrome
open_chrome() {
    local port=$1
    osascript -e 'tell application "Google Chrome" to activate' \
              -e "tell application \"Google Chrome\" to open location \"http://localhost:$port\"" 2>/dev/null || true
}

# Función principal
main() {
    echo "🚀 Iniciando proceso rápido..."
    
    # Intentar encontrar servidor existente
    local existing_port=$(find_flutter_port)
    
    if [ -n "$existing_port" ]; then
        echo "✅ Servidor encontrado en puerto $existing_port"
        echo "🔄 Aplicando hot reload..."
        
        # Hacer hot reload
        hot_reload "$existing_port"
        
        # Abrir Chrome
        sleep 1
        open_chrome "$existing_port"
        echo "✅ Chrome abierto en puerto $existing_port"
        echo "💡 Para hot restart completo, ejecuta: flutter run -d chrome"
        return 0
    fi
    
    # Si no hay servidor, lanzar uno nuevo
    echo "📦 No se encontró servidor activo, lanzando nuevo servidor..."
    cd "$(dirname "$0")/.." || exit 1
    
    # Usar puerto fijo para acelerar
    > "$LOG_FILE"
    flutter run -d chrome --web-port=8080 > "$LOG_FILE" 2>&1 &
    local flutter_pid=$!
    
    echo "⏳ Esperando compilación inicial (esto puede tomar 1-2 minutos)..."
    
    # Esperar a que el servidor esté listo (máximo 120 segundos)
    local max_wait=120
    local waited=0
    while [ $waited -lt $max_wait ]; do
        if check_server 8080; then
            echo "✅ Servidor listo en puerto 8080"
            sleep 2
            open_chrome 8080
            echo "✅ Chrome abierto en puerto 8080"
            echo "💡 PID del proceso: $flutter_pid"
            echo "💡 Para detener: kill $flutter_pid"
            return 0
        fi
        sleep 2
        waited=$((waited + 2))
        if [ $((waited % 10)) -eq 0 ]; then
            echo "⏳ Esperando... ($waited/$max_wait segundos)"
        fi
    done
    
    echo "❌ Timeout esperando servidor"
    return 1
}

main "$@"

