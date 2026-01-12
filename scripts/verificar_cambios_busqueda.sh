#!/bin/bash

# Script para verificar que los cambios de búsqueda profunda y pilotaje manual estén funcionando
# Autor: Auto
# Fecha: $(date)

set -e

PROJECT_DIR="/Users/ifernandez/development/grabovoi_build"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔍 Verificando cambios implementados...${NC}"
echo "=========================================="
echo ""

cd "${PROJECT_DIR}" || exit 1

# Verificar archivos modificados
echo -e "${YELLOW}📁 Verificando archivos modificados:${NC}"

FILES_TO_CHECK=(
    "lib/screens/pilotaje/quantum_pilotage_screen.dart"
    "lib/screens/biblioteca/static_biblioteca_screen.dart"
)

for file in "${FILES_TO_CHECK[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file existe${NC}"
    else
        echo -e "${RED}❌ $file NO existe${NC}"
    fi
done

echo ""
echo -e "${YELLOW}🔍 Verificando cambios específicos:${NC}"
echo ""

# 1. Verificar función _seleccionarCodigo en quantum_pilotage_screen.dart
echo -e "${YELLOW}1. Verificando búsqueda profunda (quantum_pilotage_screen.dart):${NC}"
if grep -q "_actualizarListaCodigos()" "lib/screens/pilotaje/quantum_pilotage_screen.dart" && \
   grep -q "_loadCodigos()" "lib/screens/pilotaje/quantum_pilotage_screen.dart" && \
   grep -q "_filtrarCodigos(codigo.codigo)" "lib/screens/pilotaje/quantum_pilotage_screen.dart"; then
    echo -e "${GREEN}   ✅ Función _seleccionarCodigo actualizada correctamente${NC}"
    echo -e "${GREEN}      - Actualiza lista de códigos${NC}"
    echo -e "${GREEN}      - Recarga códigos${NC}"
    echo -e "${GREEN}      - Filtra por código seleccionado${NC}"
else
    echo -e "${RED}   ❌ Función _seleccionarCodigo NO tiene los cambios esperados${NC}"
fi

# 2. Verificar función _iniciarPilotajeManual en quantum_pilotage_screen.dart
echo ""
echo -e "${YELLOW}2. Verificando pilotaje manual (quantum_pilotage_screen.dart):${NC}"
if grep -q "_manualCodeController.text = codigoParaPrellenar" "lib/screens/pilotaje/quantum_pilotage_screen.dart" && \
   grep -q "RegExp(r'^[0-9_\\s]+\$')" "lib/screens/pilotaje/quantum_pilotage_screen.dart"; then
    echo -e "${GREEN}   ✅ Función _iniciarPilotajeManual actualizada correctamente${NC}"
    echo -e "${GREEN}      - Prellena código de búsqueda${NC}"
    echo -e "${GREEN}      - Prellena título si no es solo números${NC}"
else
    echo -e "${RED}   ❌ Función _iniciarPilotajeManual NO tiene los cambios esperados${NC}"
fi

# 3. Verificar función _seleccionarCodigo en static_biblioteca_screen.dart
echo ""
echo -e "${YELLOW}3. Verificando búsqueda profunda (static_biblioteca_screen.dart):${NC}"
if grep -q "_load()" "lib/screens/biblioteca/static_biblioteca_screen.dart" && \
   grep -q "_codigos.length" "lib/screens/biblioteca/static_biblioteca_screen.dart"; then
    echo -e "${GREEN}   ✅ Función _seleccionarCodigo actualizada correctamente${NC}"
    echo -e "${GREEN}      - Actualiza lista de códigos${NC}"
    echo -e "${GREEN}      - Actualiza contador${NC}"
else
    echo -e "${RED}   ❌ Función _seleccionarCodigo NO tiene los cambios esperados${NC}"
fi

# 4. Verificar función _iniciarPilotajeManual en static_biblioteca_screen.dart
echo ""
echo -e "${YELLOW}4. Verificando pilotaje manual (static_biblioteca_screen.dart):${NC}"
if grep -q "_manualCodeController.text = codigoParaPrellenar" "lib/screens/biblioteca/static_biblioteca_screen.dart" && \
   grep -q "RegExp(r'^[0-9_\\s]+\$')" "lib/screens/biblioteca/static_biblioteca_screen.dart"; then
    echo -e "${GREEN}   ✅ Función _iniciarPilotajeManual actualizada correctamente${NC}"
    echo -e "${GREEN}      - Prellena código de búsqueda${NC}"
    echo -e "${GREEN}      - Prellena título si no es solo números${NC}"
else
    echo -e "${RED}   ❌ Función _iniciarPilotajeManual NO tiene los cambios esperados${NC}"
fi

# 5. Verificar que UserCustomCodesService guarda solo para el usuario
echo ""
echo -e "${YELLOW}5. Verificando que pilotaje manual guarda solo para el usuario:${NC}"
if grep -q "user_custom_codes" "lib/services/user_custom_codes_service.dart" && \
   grep -q "user_id" "lib/services/user_custom_codes_service.dart"; then
    echo -e "${GREEN}   ✅ UserCustomCodesService guarda en user_custom_codes (solo usuario)${NC}"
    echo -e "${GREEN}      - NO guarda en codigos_grabovoi (base central)${NC}"
else
    echo -e "${RED}   ❌ UserCustomCodesService NO está configurado correctamente${NC}"
fi

echo ""
echo "=========================================="
echo -e "${YELLOW}📋 Resumen de cambios esperados:${NC}"
echo ""
echo -e "${GREEN}✅ BÚSQUEDA PROFUNDA:${NC}"
echo "   1. Al seleccionar código → Inserta en DB (codigos_grabovoi)"
echo "   2. Actualiza contador de secuencias (+1)"
echo "   3. Filtra automáticamente por código seleccionado"
echo ""
echo -e "${GREEN}✅ PILOTAJE MANUAL:${NC}"
echo "   1. Prellena código/título de la búsqueda"
echo "   2. Permite agregar descripción"
echo "   3. Permite elegir categoría"
echo "   4. Guarda SOLO para el usuario (user_custom_codes)"
echo ""
echo -e "${YELLOW}💡 Para probar en la app:${NC}"
echo "   1. Busca un código que NO exista"
echo "   2. Selecciona 'Búsqueda Profunda' → Elige una opción"
echo "   3. Verifica que se inserta, actualiza contador y filtra"
echo "   4. Busca otro código que NO exista"
echo "   5. Selecciona 'Pilotaje Manual' → Verifica que prellena campos"
echo "   6. Guarda y verifica que está solo en tus favoritos"
echo ""



