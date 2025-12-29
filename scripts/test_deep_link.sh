#!/bin/bash

# Script para probar el deep link de confirmación de email en Android
# Uso: ./scripts/test_deep_link.sh [token] [type]

TOKEN=${1:-"test_token_123"}
TYPE=${2:-"signup"}

echo "🔗 Probando deep link de confirmación..."
echo ""
echo "Deep link: com.manifestacion.grabovoi://login-callback?token=$TOKEN&type=$TYPE"
echo ""

# Verificar que adb esté disponible
if ! command -v adb &> /dev/null; then
    echo "❌ Error: adb no está disponible. Asegúrate de tener Android SDK instalado."
    exit 1
fi

# Verificar que haya un dispositivo conectado
DEVICES=$(adb devices | grep -v "List" | grep "device" | wc -l)
if [ "$DEVICES" -eq 0 ]; then
    echo "❌ Error: No hay dispositivos Android conectados."
    echo "   Conecta un dispositivo o inicia un emulador."
    exit 1
fi

echo "✅ Dispositivo Android detectado"
echo ""

# Construir el deep link completo
DEEP_LINK="com.manifestacion.grabovoi://login-callback?token=$TOKEN&type=$TYPE"

echo "📱 Enviando deep link al dispositivo..."
adb shell am start -a android.intent.action.VIEW -d "$DEEP_LINK"

echo ""
echo "✅ Deep link enviado. La app debería abrirse y procesar el callback."
echo ""
echo "💡 Para probar con un link real de Supabase, copia el link del email y extrae:"
echo "   - token: parámetro 'token' de la URL"
echo "   - type: parámetro 'type' de la URL (generalmente 'signup' o 'recovery')"
echo ""
echo "   Ejemplo:"
echo "   ./scripts/test_deep_link.sh abc123xyz signup"


