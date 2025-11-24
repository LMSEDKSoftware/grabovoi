-- Tabla para registrar búsquedas profundas con IA
CREATE TABLE IF NOT EXISTS busquedas_profundas (
    id SERIAL PRIMARY KEY,
    codigo_buscado VARCHAR(50) NOT NULL,
    usuario_id UUID REFERENCES auth.users(id),
    prompt_system TEXT NOT NULL,
    prompt_user TEXT NOT NULL,
    respuesta_ia TEXT,
    codigo_encontrado BOOLEAN DEFAULT FALSE,
    codigo_guardado BOOLEAN DEFAULT FALSE,
    error_message TEXT,
    fecha_busqueda TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    duracion_ms INTEGER,
    modelo_ia VARCHAR(50) DEFAULT 'gpt-3.5-turbo',
    tokens_usados INTEGER,
    costo_estimado DECIMAL(10, 6)
);

-- Índices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_busquedas_codigo ON busquedas_profundas(codigo_buscado);
CREATE INDEX IF NOT EXISTS idx_busquedas_usuario ON busquedas_profundas(usuario_id);
CREATE INDEX IF NOT EXISTS idx_busquedas_fecha ON busquedas_profundas(fecha_busqueda);
CREATE INDEX IF NOT EXISTS idx_busquedas_encontrado ON busquedas_profundas(codigo_encontrado);

-- RLS (Row Level Security) para que los usuarios solo vean sus propias búsquedas
ALTER TABLE busquedas_profundas ENABLE ROW LEVEL SECURITY;

-- Política para que los usuarios solo vean sus propias búsquedas
CREATE POLICY "Users can view their own searches" ON busquedas_profundas
    FOR SELECT USING (auth.uid() = usuario_id);

-- Política para que los usuarios puedan insertar sus propias búsquedas
CREATE POLICY "Users can insert their own searches" ON busquedas_profundas
    FOR INSERT WITH CHECK (auth.uid() = usuario_id);

-- Política para que los usuarios puedan actualizar sus propias búsquedas
CREATE POLICY "Users can update their own searches" ON busquedas_profundas
    FOR UPDATE USING (auth.uid() = usuario_id);

-- Comentarios en la tabla
COMMENT ON TABLE busquedas_profundas IS 'Registro de búsquedas profundas realizadas con IA';
COMMENT ON COLUMN busquedas_profundas.codigo_buscado IS 'Código numérico que el usuario buscó';
COMMENT ON COLUMN busquedas_profundas.usuario_id IS 'ID del usuario que realizó la búsqueda';
COMMENT ON COLUMN busquedas_profundas.prompt_system IS 'Prompt del sistema enviado a la IA';
COMMENT ON COLUMN busquedas_profundas.prompt_user IS 'Prompt del usuario enviado a la IA';
COMMENT ON COLUMN busquedas_profundas.respuesta_ia IS 'Respuesta completa de la IA';
COMMENT ON COLUMN busquedas_profundas.codigo_encontrado IS 'Si la IA encontró información del código';
COMMENT ON COLUMN busquedas_profundas.codigo_guardado IS 'Si el código se guardó en la base de datos';
COMMENT ON COLUMN busquedas_profundas.fecha_busqueda IS 'Fecha y hora de la búsqueda';
COMMENT ON COLUMN busquedas_profundas.duracion_ms IS 'Duración de la búsqueda en milisegundos';
COMMENT ON COLUMN busquedas_profundas.modelo_ia IS 'Modelo de IA utilizado';
COMMENT ON COLUMN busquedas_profundas.tokens_usados IS 'Número de tokens utilizados';
COMMENT ON COLUMN busquedas_profundas.costo_estimado IS 'Costo estimado de la búsqueda';
