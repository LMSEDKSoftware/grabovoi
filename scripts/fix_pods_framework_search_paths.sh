#!/bin/bash

# Script para agregar Flutter a FRAMEWORK_SEARCH_PATHS en los archivos .xcconfig de Pods

set -e

IOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../ios" && pwd)"

echo "🔧 Agregando Flutter a FRAMEWORK_SEARCH_PATHS en archivos .xcconfig..."

# Buscar y modificar todos los archivos Pods-Runner.*.xcconfig
for xcconfig_file in "${IOS_DIR}/Pods/Target Support Files/Pods-Runner/"*.xcconfig; do
  if [ -f "$xcconfig_file" ]; then
    echo "   Procesando: $(basename "$xcconfig_file")"
    
    # Verificar si Flutter ya está en FRAMEWORK_SEARCH_PATHS
    if ! grep -q '\${PODS_CONFIGURATION_BUILD_DIR}/Flutter' "$xcconfig_file"; then
      # Agregar Flutter a FRAMEWORK_SEARCH_PATHS después de la última entrada
      # Usar sed para agregar al final de la línea FRAMEWORK_SEARCH_PATHS
      sed -i '' 's|\(FRAMEWORK_SEARCH_PATHS = .*workmanager"\)|\1 "${PODS_CONFIGURATION_BUILD_DIR}/Flutter"|' "$xcconfig_file"
      echo "     ✅ Agregado Flutter a FRAMEWORK_SEARCH_PATHS"
    else
      echo "     ✓ Flutter ya está presente"
    fi
  fi
done

echo "✅ Proceso completado"
