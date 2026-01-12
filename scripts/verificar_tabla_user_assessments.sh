#!/bin/bash

# Script para verificar si la tabla user_assessments existe en Supabase
# Este script muestra instrucciones para verificar manualmente

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  VERIFICACIÓN DE TABLA user_assessments EN SUPABASE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}📋 INSTRUCCIONES:${NC}"
echo ""
echo -e "${GREEN}1. Abre Supabase Dashboard${NC}"
echo "   - Ve a tu proyecto en https://supabase.com/dashboard"
echo "   - Selecciona tu proyecto"
echo ""
echo -e "${GREEN}2. Abre el SQL Editor${NC}"
echo "   - En el menú lateral, haz clic en 'SQL Editor'"
echo "   - O ve a: https://supabase.com/dashboard/project/[TU_PROJECT]/sql/new"
echo ""
echo -e "${GREEN}3. Ejecuta el script de verificación${NC}"
echo "   - Copia y pega el contenido de:"
echo -e "   ${BLUE}database/verify_user_assessments_table.sql${NC}"
echo "   - Haz clic en 'Run' o presiona Cmd/Ctrl + Enter"
echo ""
echo -e "${GREEN}4. Revisa los resultados${NC}"
echo "   - Deberías ver si la tabla existe o no"
echo "   - Si existe, verás su estructura, políticas RLS, índices, etc."
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}📝 QUERY RÁPIDA (copia y pega en SQL Editor):${NC}"
echo ""
echo -e "${BLUE}-- Verificar si la tabla existe${NC}"
echo "SELECT"
echo "  CASE"
echo "    WHEN EXISTS ("
echo "      SELECT FROM information_schema.tables"
echo "      WHERE table_schema = 'public'"
echo "      AND table_name = 'user_assessments'"
echo "    )"
echo "    THEN '✅ La tabla user_assessments EXISTE'"
echo "    ELSE '❌ La tabla user_assessments NO EXISTE'"
echo "  END as tabla_status;"
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}🔧 SI LA TABLA NO EXISTE:${NC}"
echo ""
echo "Ejecuta el script de creación:"
echo -e "${BLUE}database/user_assessment_schema.sql${NC}"
echo ""
echo "Este script creará:"
echo "  ✅ La tabla user_assessments"
echo "  ✅ Los índices necesarios"
echo "  ✅ Las políticas RLS"
echo "  ✅ El trigger para updated_at"
echo ""



