#!/bin/bash

# Script para revisar logs después de una solicitud de OTP
# Uso: ./scripts/revisar_logs_otp.sh

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}📋 Revisión de Logs de OTP${NC}"
echo "=========================================="
echo ""

# Hacer una solicitud de OTP primero
echo -e "${YELLOW}1. Haciendo solicitud de OTP de prueba...${NC}"
echo ""

EMAIL="2005.ivan@gmail.com"
RESULT=$(dart run scripts/test_otp_request.dart "$EMAIL" 2>&1)

echo "$RESULT"
echo ""

# Extraer el OTP si está disponible (compatible con macOS)
OTP=$(echo "$RESULT" | grep -o 'OTP generado (dev): [0-9]*' | grep -o '[0-9]*' || echo "")

if [ -n "$OTP" ]; then
    echo -e "${GREEN}✅ OTP generado: $OTP${NC}"
    echo ""
fi

echo -e "${BLUE}2. Instrucciones para revisar logs en Supabase Dashboard:${NC}"
echo ""
echo -e "${CYAN}   URL:${NC} https://supabase.com/dashboard/project/whtiazgcxdnemrrgjjqf/functions"
echo ""
echo -e "${YELLOW}   Pasos:${NC}"
echo "   1. Selecciona la función 'send-otp'"
echo "   2. Ve a la pestaña 'Logs'"
echo "   3. Busca los logs más recientes (últimos 5-10 minutos)"
echo "   4. Busca estos mensajes clave:"
echo ""
echo -e "${GREEN}   Mensajes de éxito:${NC}"
echo "      • '✅ Email enviado correctamente con SendGrid'"
echo "      • '✅ Función completada exitosamente. OTP generado: [número]'"
echo ""
echo -e "${RED}   Mensajes de error:${NC}"
echo "      • '❌ Error enviando email con SendGrid'"
echo "      • '⚠️ SENDGRID_API_KEY no configurada'"
echo "      • '❌ Error en envío de email:'"
echo ""
echo -e "${YELLOW}   Mensajes informativos:${NC}"
echo "      • '🔍 Verificando configuración SendGrid...'"
echo "      • '📧 Email recibido: $EMAIL'"
echo "      • '🔑 OTP generado: [número]'"
echo "      • '💾 Guardando OTP en base de datos...'"
echo ""

echo -e "${BLUE}3. Verificar variables de entorno en Supabase:${NC}"
echo ""
echo -e "${CYAN}   URL:${NC} https://supabase.com/dashboard/project/whtiazgcxdnemrrgjjqf/settings/functions"
echo ""
echo -e "${YELLOW}   Verifica que existan estas variables:${NC}"
echo "      • SENDGRID_API_KEY (debe estar configurada)"
echo "      • SENDGRID_FROM_EMAIL (debe ser: hola@em6490.manigrab.app o similar)"
echo "      • SENDGRID_FROM_NAME (opcional, puede ser: ManiGrab)"
echo ""

echo -e "${BLUE}4. Revisar SendGrid Activity:${NC}"
echo ""
echo -e "${CYAN}   URL:${NC} https://app.sendgrid.com/activity"
echo ""
echo -e "${YELLOW}   Busca:${NC}"
echo "      • Emails enviados a: $EMAIL"
echo "      • En los últimos 10 minutos"
echo "      • Estados posibles:"
echo "        - Processed/Delivered = ✅ Email enviado"
echo "        - Bounced = ⚠️ Email rebotó"
echo "        - Blocked/Failed = ❌ Error"
echo ""

if [ -n "$OTP" ]; then
    echo -e "${GREEN}5. OTP de prueba generado: $OTP${NC}"
    echo -e "${YELLOW}   Puedes usar este código para probar el flujo completo${NC}"
    echo ""
fi

echo -e "${CYAN}💡 Tips:${NC}"
echo "   • Los logs en Supabase pueden tardar unos segundos en aparecer"
echo "   • Si ves '✅ Email enviado' pero no llega el email:"
echo "     - Revisa la carpeta de spam"
echo "     - Verifica que el dominio remitente esté verificado en SendGrid"
echo "     - Revisa SendGrid Activity para ver el estado real"
echo ""

