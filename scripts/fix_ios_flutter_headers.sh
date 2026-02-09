#!/bin/bash

# Script para resolver errores de compilación de iOS relacionados con Flutter/Flutter.h

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IOS_DIR="${PROJECT_DIR}/ios"

echo "🔧 Iniciando reparación de headers de Flutter para iOS..."
echo "📁 Directorio del proyecto: ${PROJECT_DIR}"
echo ""

# Paso 1: Limpiar Flutter
echo "🧹 Paso 1/5: Limpiando Flutter..."
cd "${PROJECT_DIR}"
flutter clean
echo "✅ Flutter limpio"
echo ""

# Paso 2: Obtener dependencias de Flutter
echo "📦 Paso 2/5: Obteniendo dependencias de Flutter..."
flutter pub get
echo "✅ Dependencias de Flutter obtenidas"
echo ""

# Paso 3: Limpiar Pods
echo "🧹 Paso 3/5: Limpiando Pods..."
cd "${IOS_DIR}"
if [ -d "Pods" ]; then
    echo "   Eliminando directorio Pods..."
    rm -rf Pods
fi
if [ -f "Podfile.lock" ]; then
    echo "   Eliminando Podfile.lock..."
    rm -f Podfile.lock
fi
if [ -d ".symlinks" ]; then
    echo "   Eliminando .symlinks..."
    rm -rf .symlinks
fi
echo "✅ Pods limpio"
echo ""

# Paso 4: Limpiar cache de CocoaPods (opcional pero recomendado)
echo "🗑️  Paso 4/5: Limpiando cache de CocoaPods..."
pod cache clean --all 2>/dev/null || echo "   (Cache de CocoaPods no disponible o ya limpio)"
echo "✅ Cache limpio"
echo ""

# Paso 5: Reinstalar Pods
echo "📥 Paso 5/5: Reinstalando Pods..."
pod install --repo-update
echo "✅ Pods reinstalados"
echo ""

# Paso 6: Agregar Flutter a FRAMEWORK_SEARCH_PATHS
echo "🔧 Paso 6/6: Agregando Flutter a FRAMEWORK_SEARCH_PATHS..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/fix_pods_framework_search_paths.sh"
echo ""

# Verificación final
echo "🔍 Verificando instalación..."
if [ -f "${IOS_DIR}/Flutter/Generated.xcconfig" ]; then
    echo "✅ Generated.xcconfig encontrado"
else
    echo "❌ ERROR: Generated.xcconfig no encontrado"
    exit 1
fi

if [ -d "${IOS_DIR}/Pods/Target Support Files/Flutter" ]; then
    echo "✅ Target Support Files/Flutter encontrado"
else
    echo "⚠️  ADVERTENCIA: Target Support Files/Flutter no encontrado"
fi

if [ -f "${IOS_DIR}/Runner.xcworkspace/contents.xcworkspacedata" ]; then
    echo "✅ Runner.xcworkspace encontrado"
    echo ""
    echo "⚠️  IMPORTANTE: Asegúrate de abrir Runner.xcworkspace (NO Runner.xcodeproj) en Xcode"
else
    echo "❌ ERROR: Runner.xcworkspace no encontrado"
    exit 1
fi

echo ""
echo "✨ Reparación completada!"
echo ""
echo "📋 Próximos pasos:"
echo "   1. Abre Runner.xcworkspace en Xcode (NO Runner.xcodeproj)"
echo "   2. Selecciona el esquema 'Runner'"
echo "   3. Selecciona un simulador iOS o dispositivo"
echo "   4. Intenta compilar (⌘+B)"
echo ""
echo "🔍 Si aún hay errores, verifica:"
echo "   - Que el esquema esté configurado para Debug/Release según corresponda"
echo "   - Que la plataforma (simulador vs dispositivo) coincida con los binarios generados"
echo "   - Que FRAMEWORK_SEARCH_PATHS incluya \$(PODS_CONFIGURATION_BUILD_DIR)/Flutter"
