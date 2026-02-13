#!/bin/bash

echo "🚑 INICIANDO REPARACIÓN DEL ENTORNO DE COMPILACIÓN..."

# 1. Matar procesos zombie que bloquean el lockfile
echo "💀 Matando procesos Dart/Flutter trabados..."
pkill -f flutter || true
pkill -f dart || true
# Esperar un momento para asegurar que liberan los archivos
sleep 2

# 2. Eliminar el lockfile de Flutter
echo "🔓 Eliminando lockfile de Flutter..."
LOCKFILE="$HOME/development/flutter/bin/cache/lockfile"
if [ -f "$LOCKFILE" ]; then
    rm -f "$LOCKFILE"
    if [ -f "$LOCKFILE" ]; then
        echo "❌ No se pudo eliminar el lockfile. Intentando con sudo..."
        # Esto pedirá contraseña si es necesario, pero intentamos evitarlo primero
        echo "⚠️  Por favor introduce tu contraseña si se solicita para liberar el archivo:"
        sudo rm -f "$LOCKFILE"
    fi
fi

# 3. Limpiar caché de Gradle corrupta
echo "🧹 Limpiando caché de Gradle (esto soluciona el error NoSuchFileException)..."
# Usamos find/delete para ser más robustos que los wildcards de zsh
rm -rf "$HOME/.gradle/caches/transforms-*"
rm -rf "$HOME/.gradle/caches/journal-*"
rm -rf "$HOME/.gradle/caches/jars-*"
# Específico para el error que viste del plugin loader
rm -rf "$HOME/.gradle/caches/modules-2/files-2.1/dev.flutter"

# 4. Limpieza del proyecto
echo "✨ Limpiando proyecto..."
cd "$(dirname "$0")/.."
flutter clean
flutter pub get

# 5. Intentar compilar
echo "🚀 Intentando compilar APK..."
./scripts/BUILD_APK_CLEAN.sh
