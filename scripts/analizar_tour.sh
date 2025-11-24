#!/bin/bash

# Script de Análisis del Tour - Grabovoi App
# Este script analiza todos los componentes del tour para identificar problemas

echo "═══════════════════════════════════════════════════════════════"
echo "🔍 ANÁLISIS DEL TOUR - Grabovoi App"
echo "═══════════════════════════════════════════════════════════════"
echo ""

PROJECT_DIR="/Users/ifernandez/development/grabovoi_build"
cd "$PROJECT_DIR" || exit 1

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contador de errores
ERRORS=0
WARNINGS=0

echo "📋 1. VERIFICANDO ARCHIVOS DEL TOUR"
echo "───────────────────────────────────────────────────────────────"

# Verificar archivos principales
FILES=(
    "lib/models/tour_step.dart"
    "lib/services/tour_service.dart"
    "lib/widgets/app_tour.dart"
    "lib/main.dart"
    "lib/screens/home/home_screen.dart"
    "lib/screens/profile/profile_screen.dart"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅${NC} $file existe"
    else
        echo -e "${RED}❌${NC} $file NO EXISTE"
        ((ERRORS++))
    fi
done

echo ""
echo "📦 2. VERIFICANDO DEPENDENCIAS"
echo "───────────────────────────────────────────────────────────────"

# Verificar showcaseview en pubspec.yaml
if grep -q "showcaseview:" pubspec.yaml; then
    VERSION=$(grep "showcaseview:" pubspec.yaml | sed 's/.*showcaseview: *//' | sed 's/^[^0-9]*//')
    echo -e "${GREEN}✅${NC} showcaseview encontrado: $VERSION"
else
    echo -e "${RED}❌${NC} showcaseview NO encontrado en pubspec.yaml"
    ((ERRORS++))
fi

# Verificar shared_preferences
if grep -q "shared_preferences:" pubspec.yaml; then
    echo -e "${GREEN}✅${NC} shared_preferences encontrado"
else
    echo -e "${YELLOW}⚠️${NC} shared_preferences NO encontrado (necesario para TourService)"
    ((WARNINGS++))
fi

echo ""
echo "🔧 3. VERIFICANDO IMPORTS EN MAIN.DART"
echo "───────────────────────────────────────────────────────────────"

# Verificar imports necesarios
IMPORTS=(
    "showcaseview"
    "app_tour"
    "tour_service"
    "tour_step"
)

for import in "${IMPORTS[@]}"; do
    if grep -q "$import" lib/main.dart; then
        echo -e "${GREEN}✅${NC} Import de $import encontrado"
    else
        echo -e "${RED}❌${NC} Import de $import NO encontrado"
        ((ERRORS++))
    fi
done

echo ""
echo "🏗️ 4. VERIFICANDO ShowCaseWidget EN MAIN.DART"
echo "───────────────────────────────────────────────────────────────"

if grep -q "ShowCaseWidget" lib/main.dart; then
    echo -e "${GREEN}✅${NC} ShowCaseWidget encontrado"
    
    # Verificar que esté envolviendo el Scaffold
    if grep -A 5 "ShowCaseWidget" lib/main.dart | grep -q "Scaffold"; then
        echo -e "${GREEN}✅${NC} ShowCaseWidget envuelve Scaffold"
    else
        echo -e "${YELLOW}⚠️${NC} ShowCaseWidget puede no estar envolviendo Scaffold correctamente"
        ((WARNINGS++))
    fi
else
    echo -e "${RED}❌${NC} ShowCaseWidget NO encontrado"
    ((ERRORS++))
fi

echo ""
echo "🚀 5. VERIFICANDO INICIALIZACIÓN DEL TOUR"
echo "───────────────────────────────────────────────────────────────"

# Verificar _initializeTour
if grep -q "_initializeTour" lib/main.dart; then
    echo -e "${GREEN}✅${NC} Método _initializeTour encontrado"
    
    # Verificar que se llame en initState
    if grep -A 10 "initState" lib/main.dart | grep -q "_initializeTour"; then
        echo -e "${GREEN}✅${NC} _initializeTour se llama en initState"
    else
        echo -e "${YELLOW}⚠️${NC} _initializeTour puede no estar siendo llamado en initState"
        ((WARNINGS++))
    fi
else
    echo -e "${RED}❌${NC} Método _initializeTour NO encontrado"
    ((ERRORS++))
fi

# Verificar AppTour.initialize
if grep -q "AppTour.initialize" lib/main.dart; then
    echo -e "${GREEN}✅${NC} AppTour.initialize encontrado"
else
    echo -e "${RED}❌${NC} AppTour.initialize NO encontrado"
    ((ERRORS++))
fi

# Verificar AppTour.startTour
if grep -q "AppTour.startTour" lib/main.dart; then
    echo -e "${GREEN}✅${NC} AppTour.startTour encontrado"
else
    echo -e "${RED}❌${NC} AppTour.startTour NO encontrado"
    ((ERRORS++))
fi

echo ""
echo "🎯 6. VERIFICANDO TourShowcase EN PANTALLAS"
echo "───────────────────────────────────────────────────────────────"

# Verificar en home_screen.dart
if grep -q "TourShowcase" lib/screens/home/home_screen.dart; then
    COUNT=$(grep -c "TourShowcase" lib/screens/home/home_screen.dart)
    echo -e "${GREEN}✅${NC} TourShowcase encontrado en home_screen.dart ($COUNT veces)"
else
    echo -e "${YELLOW}⚠️${NC} TourShowcase NO encontrado en home_screen.dart"
    ((WARNINGS++))
fi

# Verificar en profile_screen.dart
if grep -q "TourShowcase" lib/screens/profile/profile_screen.dart; then
    COUNT=$(grep -c "TourShowcase" lib/screens/profile/profile_screen.dart)
    echo -e "${GREEN}✅${NC} TourShowcase encontrado en profile_screen.dart ($COUNT veces)"
else
    echo -e "${YELLOW}⚠️${NC} TourShowcase NO encontrado en profile_screen.dart"
    ((WARNINGS++))
fi

echo ""
echo "🔑 7. VERIFICANDO GlobalKeys Y REGISTRO"
echo "───────────────────────────────────────────────────────────────"

# Verificar registro de keys en app_tour.dart
if grep -q "registerKey\|getKey" lib/widgets/app_tour.dart; then
    echo -e "${GREEN}✅${NC} Sistema de registro de GlobalKeys encontrado"
else
    echo -e "${RED}❌${NC} Sistema de registro de GlobalKeys NO encontrado"
    ((ERRORS++))
fi

# Verificar que TourShowcase registre keys
if grep -A 10 "class TourShowcase" lib/widgets/app_tour.dart | grep -q "registerKey\|AppTour.registerKey"; then
    echo -e "${GREEN}✅${NC} TourShowcase registra GlobalKeys"
else
    echo -e "${YELLOW}⚠️${NC} TourShowcase puede no estar registrando GlobalKeys correctamente"
    ((WARNINGS++))
fi

echo ""
echo "⚙️ 8. VERIFICANDO disposeOnTap"
echo "───────────────────────────────────────────────────────────────"

if grep -q "disposeOnTap" lib/widgets/app_tour.dart; then
    echo -e "${GREEN}✅${NC} disposeOnTap encontrado"
    
    # Verificar valor
    if grep "disposeOnTap" lib/widgets/app_tour.dart | grep -q "true"; then
        echo -e "${GREEN}✅${NC} disposeOnTap está configurado como true"
    else
        echo -e "${YELLOW}⚠️${NC} disposeOnTap puede no estar configurado correctamente"
        ((WARNINGS++))
    fi
else
    echo -e "${RED}❌${NC} disposeOnTap NO encontrado (puede causar AssertionError)"
    ((ERRORS++))
fi

echo ""
echo "📊 9. VERIFICANDO TourService"
echo "───────────────────────────────────────────────────────────────"

# Verificar métodos del TourService
SERVICE_METHODS=(
    "hasSeenTour"
    "markTourAsSeen"
    "resetTour"
)

for method in "${SERVICE_METHODS[@]}"; do
    if grep -q "$method" lib/services/tour_service.dart; then
        echo -e "${GREEN}✅${NC} Método $method encontrado"
    else
        echo -e "${RED}❌${NC} Método $method NO encontrado"
        ((ERRORS++))
    fi
done

echo ""
echo "🎨 10. VERIFICANDO TourStep ENUM"
echo "───────────────────────────────────────────────────────────────"

# Contar pasos del tour
STEP_COUNT=$(grep -c "TourStep\." lib/models/tour_step.dart | head -1)
if [ "$STEP_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✅${NC} TourStep enum encontrado con $STEP_COUNT pasos"
else
    echo -e "${RED}❌${NC} TourStep enum NO encontrado o vacío"
    ((ERRORS++))
fi

# Verificar pasos específicos
STEPS=(
    "homeCode"
    "homePilotaje"
    "navigationBar"
)

for step in "${STEPS[@]}"; do
    if grep -q "$step" lib/models/tour_step.dart; then
        echo -e "${GREEN}✅${NC} Paso $step definido"
    else
        echo -e "${YELLOW}⚠️${NC} Paso $step NO encontrado"
        ((WARNINGS++))
    fi
done

echo ""
echo "🔍 11. VERIFICANDO ERRORES DE COMPILACIÓN"
echo "───────────────────────────────────────────────────────────────"

# Ejecutar flutter analyze en archivos del tour
echo "Analizando archivos del tour..."
ANALYZE_OUTPUT=$(flutter analyze lib/models/tour_step.dart lib/services/tour_service.dart lib/widgets/app_tour.dart 2>&1)

if echo "$ANALYZE_OUTPUT" | grep -q "No issues found"; then
    echo -e "${GREEN}✅${NC} No se encontraron errores de análisis"
elif echo "$ANALYZE_OUTPUT" | grep -q "error"; then
    echo -e "${RED}❌${NC} Errores encontrados:"
    echo "$ANALYZE_OUTPUT" | grep "error" | head -5
    ((ERRORS++))
else
    echo -e "${YELLOW}⚠️${NC} Análisis completado con advertencias"
    echo "$ANALYZE_OUTPUT" | tail -10
    ((WARNINGS++))
fi

echo ""
echo "📱 12. VERIFICANDO ESTADO DE SharedPreferences"
echo "───────────────────────────────────────────────────────────────"

# Verificar que TourService use SharedPreferences
if grep -q "SharedPreferences" lib/services/tour_service.dart; then
    echo -e "${GREEN}✅${NC} TourService usa SharedPreferences"
    
    # Verificar clave
    if grep -q "has_seen_app_tour\|has_seen_tour" lib/services/tour_service.dart; then
        echo -e "${GREEN}✅${NC} Clave de SharedPreferences encontrada"
    else
        echo -e "${YELLOW}⚠️${NC} Clave de SharedPreferences puede no estar definida"
        ((WARNINGS++))
    fi
else
    echo -e "${RED}❌${NC} TourService NO usa SharedPreferences"
    ((ERRORS++))
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "📊 RESUMEN DEL ANÁLISIS"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ TODO CORRECTO${NC}"
    echo "No se encontraron errores ni advertencias."
    echo ""
    echo "💡 Si el tour no se muestra, puede ser porque:"
    echo "   1. El tour ya fue visto (SharedPreferences tiene 'has_seen_app_tour' = true)"
    echo "   2. El tour se inicializa después del login y puede haber un delay"
    echo "   3. Los GlobalKeys no están correctamente asociados a widgets visibles"
    echo "   4. El ShowCaseWidget no está correctamente configurado"
    echo ""
    echo "🔧 Para probar:"
    echo "   - Reinicia el tour desde Perfil > Configuración > Ver Tour de la App"
    echo "   - O borra los datos de la app para resetear SharedPreferences"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️ ADVERTENCIAS ENCONTRADAS: $WARNINGS${NC}"
    echo "El tour puede funcionar, pero hay advertencias que revisar."
else
    echo -e "${RED}❌ ERRORES ENCONTRADOS: $ERRORS${NC}"
    echo -e "${YELLOW}⚠️ ADVERTENCIAS: $WARNINGS${NC}"
    echo ""
    echo "El tour NO funcionará correctamente hasta corregir los errores."
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Mostrar detalles específicos si hay errores
if [ $ERRORS -gt 0 ]; then
    echo "🔴 DETALLES DE ERRORES:"
    echo "───────────────────────────────────────────────────────────────"
    echo ""
    echo "Revisa los errores marcados arriba y corrige:"
    echo "  1. Archivos faltantes"
    echo "  2. Imports faltantes"
    echo "  3. Métodos no implementados"
    echo "  4. Configuraciones incorrectas"
    echo ""
fi

# Guardar reporte
REPORT_FILE="tour_analysis_report_$(date +%Y%m%d_%H%M%S).txt"
{
    echo "Reporte de Análisis del Tour - $(date)"
    echo "Errores: $ERRORS"
    echo "Advertencias: $WARNINGS"
    echo ""
    echo "Para más detalles, ejecuta este script nuevamente."
} > "$REPORT_FILE"

echo "📄 Reporte guardado en: $REPORT_FILE"
echo ""

exit $ERRORS

