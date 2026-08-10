#!/bin/bash
# Script robusto para compilar APK evitando errores comunes de entorno
# Uso: ./scripts/BUILD_APK_CLEAN.sh

# 1. Definir directorio del script y del proyecto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env"

echo "📂 Directorio del proyecto: $PROJECT_DIR"
cd "$PROJECT_DIR"

# 2. Función para cargar variables del .env de forma robusta
load_env() {
    if [ -f "$ENV_FILE" ]; then
        echo "📄 Cargando variables desde .env..."
        # Exportar variables ignorando comentarios y líneas vacías
        # Usamos 'set -a' para exportar automáticamente
        set -a
        source "$ENV_FILE"
        set +a
    else
        echo "⚠️  ADVERTENCIA: No se encontró $ENV_FILE. Verificando variables de entorno..."
    fi
}

# Intentar cargar .env
load_env

# 3. Verificar variables críticas
MISSING_VARS=0
if [ -z "$SUPABASE_URL" ]; then echo "❌ Falta SUPABASE_URL"; MISSING_VARS=1; fi
if [ -z "$SUPABASE_ANON_KEY" ]; then echo "❌ Falta SUPABASE_ANON_KEY"; MISSING_VARS=1; fi

if [ $MISSING_VARS -eq 1 ]; then
    echo "❌ Error: Faltan variables de entorno críticas. Asegúrate de tener el archivo .env configurado."
    exit 1
fi

# 4. Verificar estado de Flutter y Lockfile
echo "🔍 Verificando entorno Flutter..."
FLUTTER_BIN="$(which flutter)"

if [ -z "$FLUTTER_BIN" ]; then
    echo "❌ Error: Flutter no encontrado en el PATH."
    exit 1
fi

# Verificar permisos del lockfile si existe
FLUTTER_CACHE_DIR="$(dirname "$FLUTTER_BIN")/cache"
LOCKFILE="$FLUTTER_CACHE_DIR/lockfile"

if [ -f "$LOCKFILE" ]; then
    if [ ! -w "$LOCKFILE" ]; then
        echo "⚠️  ADVERTENCIA DE PERMISOS DETECTADA"
        echo "   El archivo de bloqueo de Flutter no es escribible por el usuario actual."
        echo "   Ubicación: $LOCKFILE"
        echo "   Solución requerida: Ejecuta el siguiente comando con tu contraseña de administrador:"
        echo ""
        echo "   sudo chown -R \$(whoami) \"$(dirname "$FLUTTER_CACHE_DIR")\""
        echo ""
        # Intentamos borrarlo si es posible (a veces funciona si el directorio es escribible)
        rm -f "$LOCKFILE" 2>/dev/null || echo "   (No se pudo eliminar automáticamente el lockfile)"
    fi
fi

# 5. Ejecutar compilación
echo "🚀 Iniciando Flutter Build APK..."
echo "   Versión release..."

flutter build apk --release \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✅ ¡Compilación exitosa!"
    echo "📦 APK generado en: build/app/outputs/flutter-apk/app-release.apk"
    ls -lh build/app/outputs/flutter-apk/app-release.apk
else
    echo ""
    echo "❌ La compilación falló."
    echo "   Si el error es 'lockfile', ejecuta el comando sudo mencionado arriba."
fi

exit $EXIT_CODE
