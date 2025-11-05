-- Script de respaldo de las tablas afectadas antes de modificar codigos_grabovoi
-- Este script crea tablas de respaldo con timestamp para poder restaurar si es necesario

-- Generar timestamp para nombres únicos
DO $$
DECLARE
    backup_suffix TEXT := TO_CHAR(NOW(), 'YYYYMMDD_HH24MISS');
BEGIN
    -- Crear tablas de respaldo con timestamp
    EXECUTE format('CREATE TABLE IF NOT EXISTS codigos_grabovoi_backup_%s AS SELECT * FROM codigos_grabovoi', backup_suffix);
    EXECUTE format('CREATE TABLE IF NOT EXISTS usuario_favoritos_backup_%s AS SELECT * FROM usuario_favoritos', backup_suffix);
    EXECUTE format('CREATE TABLE IF NOT EXISTS codigo_popularidad_backup_%s AS SELECT * FROM codigo_popularidad', backup_suffix);
    
    -- Mostrar información del backup
    RAISE NOTICE 'Backup creado exitosamente con sufijo: %', backup_suffix;
    RAISE NOTICE 'Tablas de respaldo creadas:';
    RAISE NOTICE '  - codigos_grabovoi_backup_%', backup_suffix;
    RAISE NOTICE '  - usuario_favoritos_backup_%', backup_suffix;
    RAISE NOTICE '  - codigo_popularidad_backup_%', backup_suffix;
END $$;

-- Verificar que el backup se creó correctamente
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count,
    (SELECT COUNT(*) FROM pg_class WHERE relname = t.table_name) as row_count_estimate
FROM information_schema.tables t
WHERE table_name LIKE '%_backup_%'
AND table_schema = 'public'
ORDER BY table_name DESC
LIMIT 3;

-- Mostrar el sufijo del backup más reciente para referencia
SELECT 
    'Backup más reciente: ' || MAX(table_name) as backup_info
FROM information_schema.tables
WHERE table_name LIKE 'codigos_grabovoi_backup_%'
AND table_schema = 'public';

