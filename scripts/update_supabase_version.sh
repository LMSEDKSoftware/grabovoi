#!/bin/bash
# =============================================================================
# update_supabase_version.sh
# Actualiza automáticamente la versión en Supabase app_config después
# de un build exitoso. Es llamado por BUILD_APK.sh, BUILD_AAB.sh y MASTER_BUILD.sh
#
# Uso directo:  bash scripts/update_supabase_version.sh "2.4.0"
# Uso en build: bash "$SCRIPT_DIR/update_supabase_version.sh" "$NEW_VERSION_NAME"
#
# Flujo:
#   1. Guarda version_actual y version_minima con el nuevo número de versión
#   2. Calcula fecha_visualizacion = ahora + 24 horas (tiempo para que Play Store apruebe)
#   3. Coloca implementada = 'PENDIENTE'
#   4. Un pg_cron en Supabase auto-cambia implementada → 'OK' cuando llega la fecha
#   5. El AppVersionService solo muestra el dialog si implementada = 'OK'
# =============================================================================

set +e  # No abortar el proceso build si este paso falla

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# ─── Leer versión ─────────────────────────────────────────────────────────────
if [ -n "$1" ]; then
    VERSION="$1"
else
    VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | cut -d'+' -f1 | tr -d ' ')
fi

# ─── Cargar .env si las variables no están cargadas ──────────────────────────
if [ -z "$SUPABASE_URL" ] || [ -z "$SB_SERVICE_ROLE_KEY" ]; then
    SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_PATH")"
    ENV_FILE="$PROJECT_ROOT/.env"
    if [ -f "$ENV_FILE" ]; then
        set -a
        source "$ENV_FILE"
        set +a
    else
        echo -e "${RED}⚠️  [Supabase] No se encontró .env — omitiendo actualización de versión${NC}"
        exit 0
    fi
fi

# ─── Validar variables necesarias ────────────────────────────────────────────
if [ -z "$SUPABASE_URL" ] || [ -z "$SB_SERVICE_ROLE_KEY" ]; then
    echo -e "${RED}⚠️  [Supabase] Faltan SUPABASE_URL o SB_SERVICE_ROLE_KEY — omitiendo actualización${NC}"
    exit 0
fi

# ─── Calcular fecha_visualizacion = ahora + 24 horas ─────────────────────────
# Formato ISO 8601 UTC compatible con Supabase TIMESTAMPTZ
FECHA_VIZ=$(date -u -v+24H '+%Y-%m-%dT%H:%M:%S+00:00' 2>/dev/null || \
            date -u -d '+24 hours' '+%Y-%m-%dT%H:%M:%S+00:00' 2>/dev/null || \
            python3 -c "from datetime import datetime, timedelta; print((datetime.utcnow()+timedelta(hours=24)).strftime('%Y-%m-%dT%H:%M:%S+00:00'))")

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🔄 [Supabase] Registrando build v${VERSION} en app_config${NC}"
echo -e "${BLUE}   📅 Fecha de build:          $(date -u '+%Y-%m-%d %H:%M:%S UTC')${NC}"
echo -e "${BLUE}   🕐 Fecha de visualización:  $(echo $FECHA_VIZ | sed 's/T/ /' | sed 's/+00:00/ UTC/')${NC}"
echo -e "${BLUE}   🔐 Estado inicial:           PENDIENTE (auto-activa en ~24h via pg_cron)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# ─── Función para actualizar una clave en app_config ─────────────────────────
update_key() {
    local KEY="$1"
    local PAYLOAD="$2"

    HTTP_STATUS=$(curl -s -o /tmp/supabase_response.json -w "%{http_code}" \
        -X PATCH \
        "${SUPABASE_URL}/rest/v1/app_config?key=eq.${KEY}" \
        -H "apikey: ${SB_SERVICE_ROLE_KEY}" \
        -H "Authorization: Bearer ${SB_SERVICE_ROLE_KEY}" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=minimal" \
        -d "$PAYLOAD")

    if [ "$HTTP_STATUS" -ge 200 ] && [ "$HTTP_STATUS" -lt 300 ]; then
        echo -e "${GREEN}   ✅ $KEY actualizado${NC}"
        return 0
    else
        BODY=$(cat /tmp/supabase_response.json 2>/dev/null)
        echo -e "${RED}   ❌ Error en $KEY (HTTP $HTTP_STATUS) — $BODY${NC}"
        return 1
    fi
}
# ─────────────────────────────────────────────────────────────────────────────

ERRORS=0

# Actualizar version_actual con todos los campos nuevos
update_key "version_actual" "{
  \"value\": \"${VERSION}\",
  \"fecha_visualizacion\": \"${FECHA_VIZ}\",
  \"implementada\": \"PENDIENTE\"
}" || ERRORS=$((ERRORS + 1))

# Actualizar version_minima igualmente
update_key "version_minima" "{
  \"value\": \"${VERSION}\",
  \"fecha_visualizacion\": \"${FECHA_VIZ}\",
  \"implementada\": \"PENDIENTE\"
}" || ERRORS=$((ERRORS + 1))

# ─── Resultado final ──────────────────────────────────────────────────────────
echo ""
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}🎯 [Supabase] Build v${VERSION} registrado correctamente${NC}"
    echo -e "${GREEN}   ✔ implementada = PENDIENTE${NC}"
    echo -e "${GREEN}   ✔ fecha_visualizacion = ${FECHA_VIZ}${NC}"
    echo -e "${YELLOW}   ⏰ El pg_cron la activará automáticamente en ~24h${NC}"
    echo -e "${YELLOW}   📣 Los usuarios con versión < ${VERSION} verán el dialog tras la activación${NC}"
else
    echo -e "${YELLOW}⚠️  [Supabase] ${ERRORS} error(es) al actualizar. Verifica manualmente en Supabase:${NC}"
    echo -e "   → Tabla app_config, clave 'version_actual'"
    echo -e "   → value = '${VERSION}', implementada = 'PENDIENTE', fecha_visualizacion = '${FECHA_VIZ}'"
fi
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

set -e
