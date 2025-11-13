#!/bin/bash

# Script de verificación rápida del sistema de período de prueba
# Este script verifica que los archivos clave tienen las modificaciones correctas

echo "🔍 Verificando implementación del período de prueba de 7 días..."
echo ""

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0

# Función para verificar si un archivo contiene un patrón
check_pattern() {
    local file=$1
    local pattern=$2
    local description=$3
    
    if grep -q "$pattern" "$file" 2>/dev/null; then
        echo -e "${GREEN}✅${NC} $description"
        return 0
    else
        echo -e "${RED}❌${NC} $description"
        echo "   Archivo: $file"
        echo "   Patrón buscado: $pattern"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

echo "📋 Verificando archivos modificados..."
echo ""

# Verificar subscription_service.dart
echo "1. Verificando lib/services/subscription_service.dart:"
check_pattern "lib/services/subscription_service.dart" "await checkSubscriptionStatus()" "initialize() llama a checkSubscriptionStatus incluso sin IAP"
check_pattern "lib/services/subscription_service.dart" "Usuario nuevo - iniciar período de prueba automáticamente" "Lógica para iniciar período de prueba automáticamente"
check_pattern "lib/services/subscription_service.dart" "free_trial_start_" "Usa SharedPreferences con clave free_trial_start_"
check_pattern "lib/services/subscription_service.dart" "Duration(days: freeTrialDays)" "Período de prueba de 7 días"

# Verificar auth_service_simple.dart
echo ""
echo "2. Verificando lib/services/auth_service_simple.dart:"
check_pattern "lib/services/auth_service_simple.dart" "checkSubscriptionStatus" "Verifica suscripción después de registro"
check_pattern "lib/services/auth_service_simple.dart" "checkSubscriptionStatus" "Verifica suscripción después de login"

# Verificar auth_wrapper.dart
echo ""
echo "3. Verificando lib/widgets/auth_wrapper.dart:"
check_pattern "lib/widgets/auth_wrapper.dart" "checkSubscriptionStatus" "Verifica suscripción después de autenticación"

# Verificar main.dart
echo ""
echo "4. Verificando lib/main.dart:"
check_pattern "lib/main.dart" "SubscriptionService().initialize()" "Inicializa SubscriptionService en main"

echo ""
echo "=========================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ TODAS LAS VERIFICACIONES PASARON${NC}"
    echo ""
    echo "📝 Próximos pasos:"
    echo "   1. Ejecuta la app: flutter run"
    echo "   2. Crea un usuario nuevo"
    echo "   3. Verifica los logs en la consola"
    echo "   4. Verifica que el usuario tiene acceso premium"
    echo ""
    echo "📖 Para más detalles, lee: VERIFICACION_PERIODO_PRUEBA.md"
    exit 0
else
    echo -e "${RED}❌ SE ENCONTRARON $ERRORS ERRORES${NC}"
    echo ""
    echo "Por favor, revisa los archivos mencionados arriba."
    exit 1
fi

