#!/bin/bash

# Script para ayudar a obtener y configurar la API Key de SendGrid
# Este script NO muestra la clave, solo proporciona instrucciones

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}📋 Guía para Obtener y Configurar SendGrid API Key${NC}"
echo "=================================================="
echo ""

echo -e "${YELLOW}⚠️  IMPORTANTE: Por seguridad, nunca compartas tu API Key públicamente${NC}"
echo ""

echo -e "${BLUE}1. Obtener API Key desde SendGrid Dashboard:${NC}"
echo ""
echo -e "${CYAN}   URL:${NC} https://app.sendgrid.com/settings/api_keys"
echo ""
echo -e "${YELLOW}   Pasos:${NC}"
echo "   1. Inicia sesión en SendGrid"
echo "   2. Ve a: Settings → API Keys"
echo "   3. Haz clic en 'Create API Key'"
echo "   4. Elige 'Full Access' o 'Restricted Access' con permisos de 'Mail Send'"
echo "   5. Dale un nombre (ej: 'ManiGrab Production')"
echo "   6. Copia la API Key (comienza con SG. y tiene ~70 caracteres)"
echo "   7. ⚠️  IMPORTANTE: Guárdala en un lugar seguro, solo se muestra una vez"
echo ""

echo -e "${BLUE}2. Configurar en Supabase (Edge Functions):${NC}"
echo ""
echo -e "${CYAN}   URL:${NC} https://supabase.com/dashboard/project/whtiazgcxdnemrrgjjqf/settings/functions"
echo ""
echo -e "${YELLOW}   Pasos:${NC}"
echo "   1. Ve a: Settings → Edge Functions → Secrets"
echo "   2. Haz clic en 'Add new secret'"
echo "   3. Nombre: SENDGRID_API_KEY"
echo "   4. Valor: [Pega tu API Key completa que comienza con SG.]"
echo "   5. Haz clic en 'Save'"
echo ""

echo -e "${BLUE}3. Configurar otras variables necesarias:${NC}"
echo ""
echo -e "${YELLOW}   También agrega estas variables en Supabase Secrets:${NC}"
echo ""
echo "   • SENDGRID_FROM_EMAIL"
echo "     Valor: hola@em6490.manigrab.app (o el email verificado en SendGrid)"
echo ""
echo "   • SENDGRID_FROM_NAME"
echo "     Valor: ManiGrab"
echo ""

echo -e "${BLUE}4. Verificar configuración:${NC}"
echo ""
echo -e "${YELLOW}   Después de configurar, prueba con:${NC}"
echo "   ./scripts/test_otp_request.dart 2005.ivan@gmail.com"
echo ""
echo -e "${YELLOW}   Y revisa los logs en:${NC}"
echo "   https://supabase.com/dashboard/project/whtiazgcxdnemrrgjjqf/functions/send-otp/logs"
echo ""

echo -e "${GREEN}5. Formato de la API Key:${NC}"
echo ""
echo "   • Debe comenzar con: SG."
echo "   • Longitud aproximada: 70 caracteres"
echo "   • Ejemplo de formato: SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
echo ""

echo -e "${RED}⚠️  SEGURIDAD:${NC}"
echo "   • Nunca subas la API Key a Git"
echo "   • No la compartas en mensajes públicos"
echo "   • Si la comprometes, revócala inmediatamente en SendGrid y crea una nueva"
echo ""

