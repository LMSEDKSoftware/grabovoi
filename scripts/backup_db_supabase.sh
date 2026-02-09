#!/bin/bash
# Respaldo completo de la base de datos Supabase (schema + datos)
# Uso: ./scripts/backup_db_supabase.sh [nombre_opcional]
# Requiere: Supabase CLI enlazado al proyecto (supabase link) O conexión directa con psql

set -e
BACKUP_ROOT="backups/db"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
NAME="${1:-supabase_backup}"
OUT_DIR="${BACKUP_ROOT}/${TIMESTAMP}_${NAME}"
mkdir -p "$OUT_DIR"

echo "📦 Respaldo de base de datos Supabase"
echo "   Destino: $OUT_DIR"
echo ""

# Opción 1: Supabase CLI (si el proyecto está enlazado)
if command -v supabase &>/dev/null; then
  echo "Usando Supabase CLI..."
  if supabase db dump -f "$OUT_DIR/full_dump.sql" 2>/dev/null; then
    echo "✅ Dump guardado en $OUT_DIR/full_dump.sql"
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) Supabase CLI dump" > "$OUT_DIR/backup_info.txt"
    exit 0
  fi
  echo "⚠️ supabase db dump falló o proyecto no enlazado. Usa el método manual abajo."
fi

# Opción 2: Sin CLI - generar script de migración de respaldo (solo schema user_rewards)
echo "⚠️ Supabase CLI no disponible o no enlazado."
echo ""
echo "BACKUP MANUAL RECOMENDADO:"
echo "1. Dashboard Supabase: https://supabase.com/dashboard → tu proyecto"
echo "2. Database → Backups: los backups diarios ya están ahí."
echo "3. Para exportar ahora: Database → Tables → exportar tablas necesarias (CSV/SQL)."
echo "4. O conectar con psql usando la connection string de Settings → Database y ejecutar:"
echo "   pg_dump -h db.XXX.supabase.co -U postgres -d postgres -F c -f $OUT_DIR/manual.dump"
echo ""
echo "Se ha creado la carpeta $OUT_DIR para que guardes ahí el dump manual si lo haces."
echo "Schema actual de user_rewards (para referencia) guardado en $OUT_DIR/user_rewards_schema_ref.sql"
cat > "$OUT_DIR/user_rewards_schema_ref.sql" << 'REF'
-- Referencia de schema user_rewards (para respaldo/restauración)
-- Ejecutar en Supabase SQL Editor para ver estructura actual
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'user_rewards'
ORDER BY ordinal_position;
REF
echo "✅ Carpeta de respaldo lista: $OUT_DIR"
