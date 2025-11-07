-- Script para agregar el campo estatus a la tabla reportes_codigos
-- Ejecutar este script si la tabla ya existe y necesita agregar el campo estatus

-- Agregar la columna estatus si no existe
ALTER TABLE reportes_codigos
ADD COLUMN IF NOT EXISTS estatus TEXT NOT NULL DEFAULT 'pendiente'
CHECK (estatus IN ('pendiente', 'revisado', 'aceptado', 'rechazado', 'resuelto'));

-- Agregar índice para el campo estatus
CREATE INDEX IF NOT EXISTS idx_reportes_codigos_estatus ON reportes_codigos(estatus);

-- Agregar política de actualización para administradores
DROP POLICY IF EXISTS "Los administradores pueden actualizar todos los reportes" ON reportes_codigos;

CREATE POLICY "Los administradores pueden actualizar todos los reportes"
  ON reportes_codigos
  FOR UPDATE
  TO authenticated
  USING (public.es_admin(auth.uid()));

-- Actualizar comentario del campo estatus
COMMENT ON COLUMN reportes_codigos.estatus IS 'Estatus del reporte: pendiente, revisado, aceptado, rechazado, resuelto';

