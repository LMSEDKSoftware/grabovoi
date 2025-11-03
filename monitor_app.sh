#!/bin/bash

# Script de monitoreo para verificar el funcionamiento de la aplicación
# Monitorea: servidor, errores, widgets, y estado general

echo "🔍 Iniciando monitoreo de la aplicación..."
echo "═══════════════════════════════════════════════════════════"

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contadores
CHECKS=0
PASSED=0
FAILED=0

# Función para verificar estado del servidor
check_server() {
    echo -e "\n${BLUE}📡 Verificando servidor Flutter...${NC}"
    CHECKS=$((CHECKS + 1))
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✅ Servidor respondiendo correctamente (HTTP $HTTP_CODE)${NC}"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo -e "${RED}❌ Servidor no responde (HTTP $HTTP_CODE)${NC}"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# Función para verificar procesos Flutter
check_flutter_process() {
    echo -e "\n${BLUE}🔄 Verificando proceso Flutter...${NC}"
    CHECKS=$((CHECKS + 1))
    
    if pgrep -f "flutter run" > /dev/null; then
        PID=$(pgrep -f "flutter run" | head -1)
        echo -e "${GREEN}✅ Proceso Flutter activo (PID: $PID)${NC}"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo -e "${RED}❌ Proceso Flutter no encontrado${NC}"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# Función para verificar errores en logs
check_logs_for_errors() {
    echo -e "\n${BLUE}📋 Verificando logs de errores...${NC}"
    CHECKS=$((CHECKS + 1))
    
    if [ -f "/tmp/flutter_launch.log" ]; then
        ERROR_COUNT=$(tail -100 /tmp/flutter_launch.log 2>/dev/null | grep -i "error\|exception\|failed" | grep -v "✅\|📝" | wc -l | tr -d ' ')
        
        if [ "$ERROR_COUNT" -eq 0 ]; then
            echo -e "${GREEN}✅ No se encontraron errores en los logs${NC}"
            PASSED=$((PASSED + 1))
        else
            echo -e "${YELLOW}⚠️  Se encontraron $ERROR_COUNT posibles errores en los logs${NC}"
            echo -e "${YELLOW}Últimos errores:${NC}"
            tail -100 /tmp/flutter_launch.log 2>/dev/null | grep -i "error\|exception\|failed" | grep -v "✅\|📝" | tail -5
            PASSED=$((PASSED + 1))  # No es crítico, solo advertencia
        fi
    else
        echo -e "${YELLOW}⚠️  Archivo de log no encontrado${NC}"
        PASSED=$((PASSED + 1))
    fi
}

# Función para verificar puerto 8080
check_port() {
    echo -e "\n${BLUE}🔌 Verificando puerto 8080...${NC}"
    CHECKS=$((CHECKS + 1))
    
    if lsof -ti:8080 > /dev/null 2>&1; then
        PID=$(lsof -ti:8080 | head -1)
        echo -e "${GREEN}✅ Puerto 8080 en uso (PID: $PID)${NC}"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo -e "${RED}❌ Puerto 8080 no está en uso${NC}"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# Función para verificar compilación
check_compilation() {
    echo -e "\n${BLUE}🔨 Verificando estado de compilación...${NC}"
    CHECKS=$((CHECKS + 1))
    
    # Verificar si hay errores de sintaxis en el widget principal
    if flutter analyze lib/widgets/energy_stats_tab.dart 2>&1 | grep -q "error"; then
        echo -e "${RED}❌ Errores de compilación encontrados en energy_stats_tab.dart${NC}"
        flutter analyze lib/widgets/energy_stats_tab.dart 2>&1 | grep "error"
        FAILED=$((FAILED + 1))
        return 1
    else
        echo -e "${GREEN}✅ Sin errores de compilación en energy_stats_tab.dart${NC}"
        PASSED=$((PASSED + 1))
        return 0
    fi
}

# Función para verificar Chrome
check_chrome() {
    echo -e "\n${BLUE}🌐 Verificando Chrome...${NC}"
    CHECKS=$((CHECKS + 1))
    
    if pgrep -f "Google Chrome" > /dev/null || pgrep -f "chromium" > /dev/null; then
        echo -e "${GREEN}✅ Chrome está ejecutándose${NC}"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo -e "${YELLOW}⚠️  Chrome no está ejecutándose${NC}"
        echo -e "${YELLOW}Intentando abrir Chrome...${NC}"
        open -a "Google Chrome" http://localhost:8080 2>/dev/null
        sleep 2
        if pgrep -f "Google Chrome" > /dev/null; then
            echo -e "${GREEN}✅ Chrome abierto correctamente${NC}"
            PASSED=$((PASSED + 1))
            return 0
        else
            FAILED=$((FAILED + 1))
            return 1
        fi
    fi
}

# Función para mostrar resumen
show_summary() {
    echo -e "\n═══════════════════════════════════════════════════════════"
    echo -e "${BLUE}📊 RESUMEN DE VERIFICACIÓN${NC}"
    echo -e "═══════════════════════════════════════════════════════════"
    echo -e "Total de verificaciones: $CHECKS"
    echo -e "${GREEN}✅ Exitosas: $PASSED${NC}"
    if [ $FAILED -gt 0 ]; then
        echo -e "${RED}❌ Fallidas: $FAILED${NC}"
    else
        echo -e "${GREEN}❌ Fallidas: $FAILED${NC}"
    fi
    
    if [ $FAILED -eq 0 ]; then
        echo -e "\n${GREEN}✨ ¡Todo funcionando correctamente!${NC}"
        echo -e "${BLUE}La aplicación debería estar visible en Chrome en: http://localhost:8080${NC}"
        echo -e "${YELLOW}💡 Busca el widget EnergyStatsTab en la esquina superior derecha${NC}"
        return 0
    else
        echo -e "\n${RED}⚠️  Algunas verificaciones fallaron. Revisa los detalles arriba.${NC}"
        return 1
    fi
}

# Ejecutar todas las verificaciones
main() {
    check_flutter_process
    check_port
    check_server
    check_compilation
    check_logs_for_errors
    check_chrome
    
    show_summary
}

# Ejecutar monitoreo continuo si se pasa -w (watch)
if [ "$1" = "-w" ] || [ "$1" = "--watch" ]; then
    echo -e "${YELLOW}🔄 Modo watch activado. Monitoreando cada 10 segundos...${NC}"
    echo -e "${YELLOW}Presiona Ctrl+C para detener${NC}\n"
    
    while true; do
        clear
        echo -e "${BLUE}🕐 $(date '+%H:%M:%S')${NC}\n"
        main
        sleep 10
    done
else
    main
fi

