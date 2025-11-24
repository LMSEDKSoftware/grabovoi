-- Tabla para almacenar reportes de códigos
-- Esta tabla permite a los administradores visualizar los reportes realizados por los usuarios

CREATE TABLE IF NOT EXISTS reportes_codigos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  codigo_id TEXT NOT NULL,
  tipo_reporte TEXT NOT NULL CHECK (tipo_reporte IN ('codigo_incorrecto', 'descripcion_incorrecta', 'categoria_incorrecta')),
  estatus TEXT NOT NULL DEFAULT 'pendiente' CHECK (estatus IN ('pendiente', 'revisado', 'aceptado', 'rechazado', 'resuelto')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para mejorar el rendimiento de las consultas
CREATE INDEX IF NOT EXISTS idx_reportes_codigos_usuario_id ON reportes_codigos(usuario_id);
CREATE INDEX IF NOT EXISTS idx_reportes_codigos_codigo_id ON reportes_codigos(codigo_id);
CREATE INDEX IF NOT EXISTS idx_reportes_codigos_tipo_reporte ON reportes_codigos(tipo_reporte);
CREATE INDEX IF NOT EXISTS idx_reportes_codigos_estatus ON reportes_codigos(estatus);
CREATE INDEX IF NOT EXISTS idx_reportes_codigos_created_at ON reportes_codigos(created_at DESC);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para actualizar updated_at
CREATE TRIGGER update_reportes_codigos_updated_at
  BEFORE UPDATE ON reportes_codigos
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Políticas de seguridad (RLS)
ALTER TABLE reportes_codigos ENABLE ROW LEVEL SECURITY;

-- Los usuarios pueden insertar sus propios reportes
CREATE POLICY "Los usuarios pueden insertar sus propios reportes"
  ON reportes_codigos
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = usuario_id);

-- Los usuarios pueden ver sus propios reportes
CREATE POLICY "Los usuarios pueden ver sus propios reportes"
  ON reportes_codigos
  FOR SELECT
  TO authenticated
  USING (auth.uid() = usuario_id);

-- Los administradores pueden ver todos los reportes
-- Usa la función es_admin() que es security definer para evitar recursión infinita
CREATE POLICY "Los administradores pueden ver todos los reportes"
  ON reportes_codigos
  FOR SELECT
  TO authenticated
  USING (public.es_admin(auth.uid()));

-- Los administradores pueden actualizar todos los reportes
CREATE POLICY "Los administradores pueden actualizar todos los reportes"
  ON reportes_codigos
  FOR UPDATE
  TO authenticated
  USING (public.es_admin(auth.uid()));

-- Comentarios para documentación
COMMENT ON TABLE reportes_codigos IS 'Almacena los reportes de códigos realizados por los usuarios';
COMMENT ON COLUMN reportes_codigos.usuario_id IS 'ID del usuario que realizó el reporte';
COMMENT ON COLUMN reportes_codigos.email IS 'Email del usuario que realizó el reporte';
COMMENT ON COLUMN reportes_codigos.codigo_id IS 'ID del código reportado (ej: 514_812_919_81)';
COMMENT ON COLUMN reportes_codigos.tipo_reporte IS 'Tipo de reporte: codigo_incorrecto, descripcion_incorrecta, categoria_incorrecta';
COMMENT ON COLUMN reportes_codigos.estatus IS 'Estatus del reporte: pendiente, revisado, aceptado, rechazado, resuelto';
COMMENT ON COLUMN reportes_codigos.created_at IS 'Fecha y hora en que se creó el reporte';

