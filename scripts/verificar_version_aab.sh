#!/bin/bash
# Verifica que la versión del proyecto coincida con la del AAB generado.
# Uso: ./scripts/verificar_version_aab.sh

set -e

AAB="${1:-build/app/outputs/bundle/release/app-release.aab}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "════════════════════════════════════════"
echo "  Verificación de versión (proyecto vs AAB)"
echo "════════════════════════════════════════"
echo ""

# Versión en el proyecto
VERSION_PUBSPEC=$(grep "^version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
VERSION_CODE_GRADLE=$(grep "versionCode = " android/app/build.gradle | sed 's/.*= *//' | tr -d ' ')
VERSION_NAME_GRADLE=$(grep "versionName = " android/app/build.gradle | sed 's/.*= *"\(.*\)".*/\1/')

echo "📋 En el proyecto:"
echo "   pubspec.yaml:     version $VERSION_PUBSPEC"
echo "   build.gradle:     versionCode=$VERSION_CODE_GRADLE  versionName=$VERSION_NAME_GRADLE"
echo ""

if [ ! -f "$AAB" ]; then
  echo "⚠️  No se encontró AAB en: $AAB"
  echo "   Genera uno con: flutter build appbundle --release"
  exit 1
fi

# Extraer versionName y versionCode del AAB (manifest binario)
MANIFEST=$(mktemp)
unzip -p "$AAB" base/manifest/AndroidManifest.xml > "$MANIFEST" 2>/dev/null
# versionName aparece como "2.3.25(" en strings
VERSION_NAME_AAB=$(strings "$MANIFEST" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+' | head -1 | tr -d '("')
# versionCode en el manifest binario aparece como "versionCode..38" en xxd (parte ASCII)
VERSION_CODE_AAB=$(xxd "$MANIFEST" | grep "versionCode" | head -1 | sed 's/.*versionCode\.\.//' | grep -oE '^[0-9]+' | head -1)
rm -f "$MANIFEST"

echo "📦 En el AAB ($AAB):"
echo "   versionName:  $VERSION_NAME_AAB"
echo "   versionCode:  $VERSION_CODE_AAB"
echo ""

# Comparar
OK=0
if [ "$VERSION_CODE_GRADLE" = "$VERSION_CODE_AAB" ]; then
  echo "✅ versionCode coincide: $VERSION_CODE_GRADLE"
else
  echo "❌ versionCode NO coincide: proyecto=$VERSION_CODE_GRADLE  AAB=$VERSION_CODE_AAB"
  OK=1
fi
if [ "$VERSION_NAME_GRADLE" = "$VERSION_NAME_AAB" ]; then
  echo "✅ versionName coincide: $VERSION_NAME_GRADLE"
else
  echo "❌ versionName NO coincide: proyecto=$VERSION_NAME_GRADLE  AAB=$VERSION_NAME_AAB"
  OK=1
fi
echo ""
if [ $OK -eq 0 ]; then
  echo "✅ El AAB está generado con la versión actual del proyecto."
else
  echo "⚠️  Regenera el AAB después de cambiar la versión: flutter build appbundle --release"
  exit 1
fi
