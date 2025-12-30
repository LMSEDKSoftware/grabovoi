#!/bin/bash

# Script para crear backup de archivos antes de modificarlos
# Uso: ./scripts/backup_file.sh <ruta_archivo>

FILE_PATH="$1"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

if [ -z "$FILE_PATH" ]; then
    echo "❌ Error: Debes proporcionar la ruta del archivo"
    echo "Uso: ./scripts/backup_file.sh <ruta_archivo>"
    exit 1
fi

# Convertir a ruta absoluta si es relativa
if [[ ! "$FILE_PATH" = /* ]]; then
    FILE_PATH="$(pwd)/$FILE_PATH"
fi

# Verificar que el archivo existe
if [ ! -f "$FILE_PATH" ]; then
    echo "❌ Error: El archivo no existe: $FILE_PATH"
    exit 1
fi

# Obtener directorio y nombre del archivo
DIR=$(dirname "$FILE_PATH")
FILENAME=$(basename "$FILE_PATH")
BACKUP_DIR="$DIR/.backups"

# Crear directorio de backups si no existe
mkdir -p "$BACKUP_DIR"

# Nombre del backup: bk-<timestamp>_<nombre_original>
BACKUP_NAME="bk-${TIMESTAMP}_${FILENAME}"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

# Copiar el archivo
cp "$FILE_PATH" "$BACKUP_PATH"

if [ $? -eq 0 ]; then
    echo "✅ Backup creado: $BACKUP_PATH"
    # Mantener solo los últimos 10 backups
    ls -t "$BACKUP_DIR"/bk-*_${FILENAME} 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null
else
    echo "❌ Error al crear backup"
    exit 1
fi
