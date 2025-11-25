#!/bin/bash

# Script para ayudar a verificar los logs de Supabase
# Nota: La CLI de Supabase no tiene un comando directo para logs,
# pero podemos proporcionar instrucciones y verificar el estado

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Instrucciones para Verificar Logs de Supabase${NC}"
echo "=================================================="
echo ""
echo -e "${YELLOW}La función respondió: {\"ok\": true}${NC}"
echo ""
echo -e "${GREEN}Para verificar si el email realmente se envió:${NC}"
echo ""
echo -e "${BLUE}1. Revisa los Logs en Supabase Dashboard:${NC}"
echo "   URL: https://supabase.com/dashboard/project/whtiazgcxdnemrrgjjqf/functions"
echo "   - Selecciona la función 'send-otp'"
echo "   - Ve a la pestaña 'Logs'"
echo "   - Busca los logs más recientes"
echo "   - Busca mensajes como:"
echo "     • '✅ Email enviado correctamente con SendGrid'"
echo "     • '❌ Error enviando email con SendGrid'"
echo "     • '⚠️ SENDGRID_API_KEY no configurada'"
echo "     • '🔍 Verificando configuración SendGrid...'"
echo ""
echo -e "${BLUE}2. Revisa SendGrid Activity:${NC}"
echo "   URL: https://app.sendgrid.com/activity"
echo "   - Busca emails enviados a '2005.ivan@gmail.com'"
echo "   - Verifica el estado:"
echo "     • Processed/Delivered = ✅ Email enviado"
echo "     • Bounced = ⚠️ Email rebotó"
echo "     • Blocked/Failed = ❌ Error"
echo ""
echo -e "${YELLOW}💡 Nota:${NC}"
echo "   Si los logs muestran '✅ Email enviado correctamente con SendGrid'"
echo "   pero no aparece en SendGrid Activity, puede ser que:"
echo "   - El email esté en proceso de envío (espera unos segundos)"
echo "   - Haya un problema con el dominio remitente"
echo "   - El email haya sido bloqueado por políticas"
echo ""
echo -e "${GREEN}3. Revisa tu bandeja de entrada:${NC}"
echo "   - Email: 2005.ivan@gmail.com"
echo "   - Revisa también la carpeta de spam"
echo "   - El email puede tardar unos minutos en llegar"
echo ""



