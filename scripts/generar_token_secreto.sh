#!/bin/bash

# Script para generar un token secreto seguro para EMAIL_SERVER_SECRET

echo "🔐 Generando token secreto seguro..."
echo ""

# Generar token aleatorio de 64 caracteres
TOKEN=$(openssl rand -hex 32)

echo "✅ Token generado:"
echo ""
echo "$TOKEN"
echo ""
echo "📋 Copia este token y úsalo en:"
echo "   1. Supabase Dashboard → Settings → Edge Functions → Secrets"
echo "      Variable: EMAIL_SERVER_SECRET"
echo ""
echo "   2. Tu servidor (manigrab.app) - Variables de entorno"
echo "      Variable: EMAIL_SERVER_SECRET"
echo ""
echo "⚠️  IMPORTANTE: Guarda este token en un lugar seguro"
echo "   El mismo token debe usarse en ambos lugares (Supabase y servidor)"


