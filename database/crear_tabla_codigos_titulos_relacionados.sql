-- Script para crear la tabla de títulos relacionados con códigos
-- Esta tabla permite múltiples títulos/descripciones para el mismo código
-- sin modificar la estructura de codigos_grabovoi

-- Crear tabla de títulos relacionados
CREATE TABLE IF NOT EXISTS codigos_titulos_relacionados (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  codigo_existente TEXT NOT NULL REFERENCES codigos_grabovoi(codigo),
  titulo TEXT NOT NULL,
  descripcion TEXT,
  categoria TEXT,
  fuente TEXT DEFAULT 'sugerencia_aprobada',
  sugerencia_id INTEGER REFERENCES sugerencias_codigos(id),
  usuario_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_titulos_relacionados_codigo ON codigos_titulos_relacionados(codigo_existente);
CREATE INDEX IF NOT EXISTS idx_titulos_relacionados_titulo ON codigos_titulos_relacionados(titulo);
CREATE INDEX IF NOT EXISTS idx_titulos_relacionados_sugerencia ON codigos_titulos_relacionados(sugerencia_id);

-- Índice para búsquedas de texto (mejora búsquedas ILIKE)
-- Nota: Para índices GIN con trigram, necesitarías habilitar la extensión pg_trgm primero
-- CREATE INDEX IF NOT EXISTS idx_titulos_relacionados_titulo_gin ON codigos_titulos_relacionados USING gin(titulo gin_trgm_ops);

-- RLS (Row Level Security) - Permitir lectura pública, escritura autenticada
ALTER TABLE codigos_titulos_relacionados ENABLE ROW LEVEL SECURITY;

-- Política para lectura pública
CREATE POLICY "Allow public read access" ON codigos_titulos_relacionados
  FOR SELECT USING (true);

-- Política para inserción autenticada
CREATE POLICY "Allow authenticated insert" ON codigos_titulos_relacionados
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Política para actualización por administradores o creador
CREATE POLICY "Allow authenticated update" ON codigos_titulos_relacionados
  FOR UPDATE USING (auth.role() = 'authenticated');

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_titulos_relacionados_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para actualizar updated_at
CREATE TRIGGER update_codigos_titulos_relacionados_updated_at 
  BEFORE UPDATE ON codigos_titulos_relacionados 
  FOR EACH ROW EXECUTE FUNCTION update_titulos_relacionados_updated_at();

-- Comentarios para documentación
COMMENT ON TABLE codigos_titulos_relacionados IS 'Títulos y descripciones alternativos relacionados con códigos de Grabovoi. Permite múltiples títulos para el mismo código sin modificar codigos_grabovoi.';
COMMENT ON COLUMN codigos_titulos_relacionados.codigo_existente IS 'Código al que pertenece este título relacionado (FK a codigos_grabovoi.codigo)';
COMMENT ON COLUMN codigos_titulos_relacionados.titulo IS 'Título alternativo para el código';
COMMENT ON COLUMN codigos_titulos_relacionados.descripcion IS 'Descripción alternativa para el código';
COMMENT ON COLUMN codigos_titulos_relacionados.sugerencia_id IS 'ID de la sugerencia que originó este título (si aplica)';
COMMENT ON COLUMN codigos_titulos_relacionados.fuente IS 'Fuente del título: sugerencia_aprobada, manual, etc.';

-- Verificar que la tabla se creó correctamente
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'codigos_titulos_relacionados'
ORDER BY ordinal_position;

