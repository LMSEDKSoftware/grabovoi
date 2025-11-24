#!/bin/bash
# Script para hacer backup de archivos antes de modificarlos
# Uso: ./backup_file.sh ruta/al/archivo

if [ -z "$1" ]; then
    echo "❌ Error: Debes proporcionar la ruta del archivo a respaldar"
    exit 1
fi

FILE_PATH="$1"
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"

# Crear directorio de backup si no existe
mkdir -p "$BACKUP_DIR"

# Obtener el directorio del archivo
FILE_DIR=$(dirname "$FILE_PATH")
FILE_NAME=$(basename "$FILE_PATH")

# Crear la estructura de directorios en el backup
mkdir -p "$BACKUP_DIR/$FILE_DIR"

# Copiar el archivo
if [ -f "$FILE_PATH" ]; then
    cp "$FILE_PATH" "$BACKUP_DIR/$FILE_PATH"
    echo "✅ Backup creado: $BACKUP_DIR/$FILE_PATH"
else
    echo "⚠️  Archivo no encontrado: $FILE_PATH"
    exit 1
fi

