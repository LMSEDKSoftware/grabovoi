#!/bin/bash

# Script para probar el flujo completo de la aplicación
# Detecta fallas automáticamente

echo "🧪 Iniciando pruebas automatizadas de la aplicación..."
echo ""

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# URL de la aplicación
APP_URL="http://localhost:49181"

# Verificar que el servidor esté corriendo
echo "📡 Verificando que el servidor esté activo..."
if curl -s -o /dev/null -w "%{http_code}" "$APP_URL" | grep -q "200"; then
    echo -e "${GREEN}✅ Servidor activo en $APP_URL${NC}"
else
    echo -e "${RED}❌ Servidor no está activo. Por favor inicia el servidor primero.${NC}"
    exit 1
fi

echo ""
echo "🔍 Verificando funcionalidades clave..."
echo ""

# Lista de verificaciones
FAILURES=0
TOTAL_TESTS=0

# Función para verificar
check_feature() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    local feature_name="$1"
    local check_command="$2"
    
    if eval "$check_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $feature_name${NC}"
        return 0
    else
        echo -e "${RED}❌ $feature_name${NC}"
        FAILURES=$((FAILURES + 1))
        return 1
    fi
}

# Verificar que la página carga
check_feature "Página principal carga correctamente" "curl -s '$APP_URL' | grep -q 'html'"

# Verificar que no hay errores de JavaScript críticos en la consola
echo ""
echo "📋 Verificando errores en consola..."
echo "   (Esto requiere inspección manual en DevTools)"
echo ""

# Verificar archivos clave
echo "📁 Verificando archivos clave..."
check_feature "repetition_session_screen.dart existe" "test -f 'lib/screens/codes/repetition_session_screen.dart'"
check_feature "quantum_pilotage_screen.dart existe" "test -f 'lib/screens/pilotaje/quantum_pilotage_screen.dart'"
check_feature "main.dart existe" "test -f 'lib/main.dart'"

# Verificar código específico
echo ""
echo "🔍 Verificando implementación del código..."
echo ""

# Verificar que _showSequentialSteps existe
if grep -q "_showSequentialSteps" lib/screens/codes/repetition_session_screen.dart; then
    echo -e "${GREEN}✅ Variable _showSequentialSteps encontrada${NC}"
else
    echo -e "${RED}❌ Variable _showSequentialSteps NO encontrada${NC}"
    FAILURES=$((FAILURES + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Verificar que _buildSequentialStepCard existe
if grep -q "_buildSequentialStepCard" lib/screens/codes/repetition_session_screen.dart; then
    echo -e "${GREEN}✅ Método _buildSequentialStepCard encontrado${NC}"
else
    echo -e "${RED}❌ Método _buildSequentialStepCard NO encontrado${NC}"
    FAILURES=$((FAILURES + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Verificar que _nextStep existe
if grep -q "Future<void> _nextStep" lib/screens/codes/repetition_session_screen.dart; then
    echo -e "${GREEN}✅ Método _nextStep encontrado${NC}"
else
    echo -e "${RED}❌ Método _nextStep NO encontrado${NC}"
    FAILURES=$((FAILURES + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Verificar que StreamedMusicController está presente
if grep -q "StreamedMusicController" lib/screens/codes/repetition_session_screen.dart; then
    echo -e "${GREEN}✅ StreamedMusicController encontrado${NC}"
else
    echo -e "${RED}❌ StreamedMusicController NO encontrado${NC}"
    FAILURES=$((FAILURES + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Verificar que el flujo paso a paso se muestra en el Stack
if grep -q "if (_showSequentialSteps) _buildSequentialStepCard()" lib/screens/codes/repetition_session_screen.dart; then
    echo -e "${GREEN}✅ Flujo paso a paso configurado en Stack${NC}"
else
    echo -e "${RED}❌ Flujo paso a paso NO configurado en Stack${NC}"
    FAILURES=$((FAILURES + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Verificar que el audio se inicia en _nextStep
if grep -A 10 "Future<void> _nextStep" lib/screens/codes/repetition_session_screen.dart | grep -q "audioManager.playTrack"; then
    echo -e "${GREEN}✅ Audio se inicia en _nextStep${NC}"
else
    echo -e "${RED}❌ Audio NO se inicia en _nextStep${NC}"
    FAILURES=$((FAILURES + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Verificar que _startRepetition activa el flujo paso a paso
if grep -A 5 "_showSequentialSteps = true" lib/screens/codes/repetition_session_screen.dart | grep -q "_startRepetition\|Mostrar el flujo paso a paso"; then
    echo -e "${GREEN}✅ _startRepetition activa flujo paso a paso${NC}"
else
    echo -e "${YELLOW}⚠️  Verificar que _startRepetition active el flujo paso a paso${NC}"
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Verificar que QuantumPilotageScreen está en main.dart
if grep -q "QuantumPilotageScreen" lib/main.dart; then
    echo -e "${GREEN}✅ QuantumPilotageScreen en main.dart${NC}"
else
    echo -e "${RED}❌ QuantumPilotageScreen NO está en main.dart${NC}"
    FAILURES=$((FAILURES + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Verificar que el botón Cuántico está en la navegación
if grep -q "Cuántico\|Cuantico" lib/main.dart | grep -q "_buildNavItem"; then
    echo -e "${GREEN}✅ Botón Cuántico en navegación${NC}"
else
    echo -e "${RED}❌ Botón Cuántico NO está en navegación${NC}"
    FAILURES=$((FAILURES + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 RESUMEN DE PRUEBAS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total de pruebas: $TOTAL_TESTS"
echo -e "Exitosas: ${GREEN}$((TOTAL_TESTS - FAILURES))${NC}"
echo -e "Fallidas: ${RED}$FAILURES${NC}"
echo ""

if [ $FAILURES -eq 0 ]; then
    echo -e "${GREEN}✅ Todas las pruebas pasaron${NC}"
    exit 0
else
    echo -e "${RED}❌ Se encontraron $FAILURES fallas${NC}"
    echo ""
    echo "💡 Recomendaciones:"
    echo "   1. Revisa los archivos mencionados arriba"
    echo "   2. Verifica la consola del navegador para errores"
    echo "   3. Asegúrate de que el flujo paso a paso se muestre al iniciar repetición"
    echo "   4. Verifica que el audio se inicie después del último paso"
    exit 1
fi

