-- Agregar campo etiqueta a la tabla usuario_favoritos
ALTER TABLE usuario_favoritos 
ADD COLUMN IF NOT EXISTS etiqueta TEXT;

-- Crear índice para búsquedas por etiqueta
CREATE INDEX IF NOT EXISTS idx_favoritos_etiqueta ON usuario_favoritos(etiqueta);

-- Actualizar etiquetas existentes con valor por defecto
UPDATE usuario_favoritos 
SET etiqueta = 'Favorito' 
WHERE etiqueta IS NULL;

-- Hacer el campo etiqueta NOT NULL con valor por defecto
ALTER TABLE usuario_favoritos 
ALTER COLUMN etiqueta SET DEFAULT 'Favorito';

-- Comentario para documentar el campo
COMMENT ON COLUMN usuario_favoritos.etiqueta IS 'Etiqueta personalizada del usuario para organizar favoritos (ej: trabajo, hijo mayor, mi perro, etc.)';
