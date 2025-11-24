-- Corregir la foreign key de usuario_favoritos para que referencie el campo 'codigo' en lugar de 'id'

-- 1. Eliminar la foreign key existente
ALTER TABLE usuario_favoritos 
DROP CONSTRAINT IF EXISTS usuario_favoritos_codigo_id_fkey;

-- 2. Crear nueva foreign key que referencie el campo 'codigo' de codigos_grabovoi
ALTER TABLE usuario_favoritos 
ADD CONSTRAINT usuario_favoritos_codigo_id_fkey 
FOREIGN KEY (codigo_id) REFERENCES codigos_grabovoi(codigo);

-- 3. Crear índice para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_usuario_favoritos_codigo_id ON usuario_favoritos(codigo_id);

-- 4. Verificar que la foreign key funciona
-- Esto debería funcionar ahora:
-- INSERT INTO usuario_favoritos (user_id, codigo_id, etiqueta) 
-- VALUES ('test-user', '489_712_819_48', 'prueba');
