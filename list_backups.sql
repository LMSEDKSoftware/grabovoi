-- Script para listar todos los backups disponibles

SELECT 
    table_name as backup_table,
    pg_size_pretty(pg_total_relation_size(quote_ident(table_name))) as size,
    (SELECT COUNT(*) 
     FROM information_schema.columns 
     WHERE table_name = t.table_name 
     AND table_schema = 'public') as column_count
FROM information_schema.tables t
WHERE table_name LIKE '%_backup_%'
AND table_schema = 'public'
ORDER BY table_name DESC;

-- Mostrar el conteo de registros en cada backup (si es posible)
SELECT 
    'Backups disponibles' as info,
    COUNT(*) as total_backups
FROM information_schema.tables
WHERE table_name LIKE '%_backup_%'
AND table_schema = 'public';

