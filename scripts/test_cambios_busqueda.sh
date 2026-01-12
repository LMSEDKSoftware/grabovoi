#!/bin/bash

# Script para probar que los cambios de búsqueda profunda y pilotaje manual funcionan
# Este script verifica el código y muestra instrucciones para probar manualmente

PROJECT_DIR="/Users/ifernandez/development/grabovoi_build"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

cd "${PROJECT_DIR}" || exit 1

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  VERIFICACIÓN DE CAMBIOS - BÚSQUEDA PROFUNDA Y PILOTAJE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Verificar cambios en _seleccionarCodigo
echo -e "${YELLOW}1. BÚSQUEDA PROFUNDA - Función _seleccionarCodigo:${NC}"
echo ""

if grep -q "_actualizarListaCodigos()" "lib/screens/pilotaje/quantum_pilotage_screen.dart"; then
    echo -e "${GREEN}   ✅ Línea encontrada: _actualizarListaCodigos()${NC}"
    LINE=$(grep -n "_actualizarListaCodigos()" "lib/screens/pilotaje/quantum_pilotage_screen.dart" | head -1 | cut -d: -f1)
    echo -e "      Ubicación: línea $LINE"
else
    echo -e "   ❌ NO encontrado: _actualizarListaCodigos()"
fi

if grep -q "_loadCodigos()" "lib/screens/pilotaje/quantum_pilotage_screen.dart"; then
    echo -e "${GREEN}   ✅ Línea encontrada: _loadCodigos()${NC}"
    LINE=$(grep -n "_loadCodigos()" "lib/screens/pilotaje/quantum_pilotage_screen.dart" | head -1 | cut -d: -f1)
    echo -e "      Ubicación: línea $LINE"
else
    echo -e "   ❌ NO encontrado: _loadCodigos()"
fi

if grep -q "_filtrarCodigos(codigo.codigo)" "lib/screens/pilotaje/quantum_pilotage_screen.dart"; then
    echo -e "${GREEN}   ✅ Línea encontrada: _filtrarCodigos(codigo.codigo)${NC}"
    LINE=$(grep -n "_filtrarCodigos(codigo.codigo)" "lib/screens/pilotaje/quantum_pilotage_screen.dart" | head -1 | cut -d: -f1)
    echo -e "      Ubicación: línea $LINE"
else
    echo -e "   ❌ NO encontrado: _filtrarCodigos(codigo.codigo)"
fi

echo ""
echo -e "${YELLOW}2. PILOTAJE MANUAL - Función _iniciarPilotajeManual:${NC}"
echo ""

if grep -q "codigoParaPrellenar" "lib/screens/pilotaje/quantum_pilotage_screen.dart"; then
    echo -e "${GREEN}   ✅ Línea encontrada: codigoParaPrellenar${NC}"
    LINE=$(grep -n "codigoParaPrellenar" "lib/screens/pilotaje/quantum_pilotage_screen.dart" | head -1 | cut -d: -f1)
    echo -e "      Ubicación: línea $LINE"
    echo -e "      Contexto:"
    grep -A 3 -B 3 "codigoParaPrellenar" "lib/screens/pilotaje/quantum_pilotage_screen.dart" | head -7 | sed 's/^/      /'
else
    echo -e "   ❌ NO encontrado: codigoParaPrellenar"
fi

if grep -q "RegExp.*0-9" "lib/screens/pilotaje/quantum_pilotage_screen.dart"; then
    echo -e "${GREEN}   ✅ Línea encontrada: Validación RegExp para título${NC}"
    LINE=$(grep -n "RegExp.*0-9" "lib/screens/pilotaje/quantum_pilotage_screen.dart" | head -1 | cut -d: -f1)
    echo -e "      Ubicación: línea $LINE"
else
    echo -e "   ❌ NO encontrado: Validación RegExp"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 INSTRUCCIONES PARA PROBAR EN LA APP:${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}PRUEBA 1: BÚSQUEDA PROFUNDA${NC}"
echo "   1. Ve a la pantalla de Pilotaje Cuántico o Biblioteca"
echo "   2. Busca un código que NO exista (ej: '999999999')"
echo "   3. Cuando aparezca el modal, selecciona 'Búsqueda Profunda'"
echo "   4. Espera a que aparezcan las opciones de códigos"
echo "   5. Selecciona uno de los códigos sugeridos"
echo "   ${YELLOW}VERIFICAR:${NC}"
echo "      ✓ El código se inserta en la base de datos"
echo "      ✓ El contador de secuencias aumenta (+1)"
echo "      ✓ Se filtra automáticamente mostrando solo ese código"
echo ""
echo -e "${GREEN}PRUEBA 2: PILOTAJE MANUAL${NC}"
echo "   1. Busca otro código que NO exista (ej: '888888888')"
echo "   2. Cuando aparezca el modal, selecciona 'Pilotaje Manual'"
echo "   ${YELLOW}VERIFICAR:${NC}"
echo "      ✓ El campo 'Código' está prellenado con lo que buscaste"
echo "      ✓ Si buscaste un título (no solo números), también se prellena 'Título'"
echo "   3. Completa descripción y elige categoría"
echo "   4. Guarda el código"
echo "   ${YELLOW}VERIFICAR:${NC}"
echo "      ✓ El código se guarda en TUS favoritos (no en la base central)"
echo "      ✓ Solo tú puedes ver ese código personalizado"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"



