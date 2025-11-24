-- Script para restaurar los datos desde el backup
-- IMPORTANTE: Reemplaza 'BACKUP_SUFFIX' con el sufijo del backup que quieres restaurar
-- Ejemplo: Si el backup es 'codigos_grabovoi_backup_20250115_143022', usa '20250115_143022'

-- INSTRUCCIONES:
-- 1. Primero, verifica qué backups tienes disponibles ejecutando:
--    SELECT table_name FROM information_schema.tables WHERE table_name LIKE '%_backup_%' ORDER BY table_name DESC;
--
-- 2. Copia el sufijo del backup que quieres restaurar (ejemplo: '20250115_143022')
-- 3. Reemplaza 'BACKUP_SUFFIX' en este script con el sufijo real
-- 4. Ejecuta este script

DO $$
DECLARE
    backup_suffix TEXT := 'BACKUP_SUFFIX'; -- ⚠️ CAMBIAR ESTO por el sufijo real del backup
    backup_exists BOOLEAN;
BEGIN
    -- Verificar que el backup existe
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'codigos_grabovoi_backup_' || backup_suffix
        AND table_schema = 'public'
    ) INTO backup_exists;
    
    IF NOT backup_exists THEN
        RAISE EXCEPTION 'Backup no encontrado: codigos_grabovoi_backup_%', backup_suffix;
    END IF;
    
    -- Eliminar datos actuales de las tablas (¡CUIDADO!)
    TRUNCATE TABLE codigos_grabovoi CASCADE;
    TRUNCATE TABLE usuario_favoritos CASCADE;
    TRUNCATE TABLE codigo_popularidad CASCADE;
    
    -- Restaurar datos desde el backup
    EXECUTE format('INSERT INTO codigos_grabovoi SELECT * FROM codigos_grabovoi_backup_%s', backup_suffix);
    EXECUTE format('INSERT INTO usuario_favoritos SELECT * FROM usuario_favoritos_backup_%s', backup_suffix);
    EXECUTE format('INSERT INTO codigo_popularidad SELECT * FROM codigo_popularidad_backup_%s', backup_suffix);
    
    RAISE NOTICE 'Datos restaurados exitosamente desde el backup: %', backup_suffix;
    RAISE NOTICE 'Registros restaurados:';
    
    -- Mostrar conteo de registros restaurados
    EXECUTE format('SELECT COUNT(*) as codigos_restaurados FROM codigos_grabovoi') INTO backup_exists;
    EXECUTE format('SELECT COUNT(*) as favoritos_restaurados FROM usuario_favoritos') INTO backup_exists;
    EXECUTE format('SELECT COUNT(*) as popularidad_restaurada FROM codigo_popularidad') INTO backup_exists;
END $$;

-- Verificar que los datos se restauraron correctamente
SELECT 
    'codigos_grabovoi' as tabla,
    COUNT(*) as registros
FROM codigos_grabovoi
UNION ALL
SELECT 
    'usuario_favoritos' as tabla,
    COUNT(*) as registros
FROM usuario_favoritos
UNION ALL
SELECT 
    'codigo_popularidad' as tabla,
    COUNT(*) as registros
FROM codigo_popularidad;

