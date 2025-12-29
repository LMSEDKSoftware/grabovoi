#!/bin/bash

# Script para probar el registro de usuario y verificar que el email llegue
# Uso: ./scripts/test_user_registration.sh [email] [nombre] [password]

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Generar email único si no se proporciona
TIMESTAMP=$(date +%s)
TEST_EMAIL="${1:-test${TIMESTAMP}@manigrab.app}"
TEST_NAME="${2:-Usuario de Prueba}"
TEST_PASSWORD="${3:-Test123456!}"

echo -e "${CYAN}🧪 Probando Registro de Usuario${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}Datos de prueba:${NC}"
echo "   Email: $TEST_EMAIL"
echo "   Nombre: $TEST_NAME"
echo "   Password: ${TEST_PASSWORD:0:3}***"
echo ""
echo -e "${YELLOW}⚠️  NOTA: Este script solo prueba la función send-email" && echo "   Para probar el registro completo, usa la app o el endpoint de Supabase Auth" && echo ""
echo -e "${YELLOW}📋 Para probar el registro completo desde la app:${NC}"
echo "   1. Abre la app en Chrome (ya está corriendo)"
echo "   2. Ve a la pantalla de registro"
echo "   3. Completa el formulario con:"
echo "      - Email: $TEST_EMAIL"
echo "      - Nombre: $TEST_NAME"
echo "      - Password: $TEST_PASSWORD"
echo "   4. Acepta términos y condiciones"
echo "   5. Haz clic en 'Registrarse'"
echo ""
echo -e "${YELLOW}📧 Después del registro, verifica:${NC}"
echo "   1. Revisa tu bandeja de entrada: $TEST_EMAIL"
echo "   2. Busca el email de bienvenida con el botón 'Activar mi cuenta'"
echo "   3. Revisa los logs en Supabase:"
echo "      https://supabase.com/dashboard/project/whtiazgcxdnemrrgjjqf/functions/send-email/logs"
echo "   4. Deberías ver: '📧 Enviando email a través del servidor propio (IP estática)...'"
echo "   5. Revisa SendGrid Activity:"
echo "      https://app.sendgrid.com/activity"
echo "      Debe mostrar IP: 153.92.215.178"
echo ""


