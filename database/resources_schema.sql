-- Tabla para almacenar recursos educativos
-- Ejecutar este script en el SQL Editor de Supabase

-- Eliminar tabla si existe (solo si quieres empezar desde cero)
-- DROP TABLE IF EXISTS public.resources CASCADE;

-- Crear tabla de recursos
CREATE TABLE IF NOT EXISTS public.resources (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  content TEXT NOT NULL, -- Contenido principal del recurso (texto, HTML, etc.)
  type TEXT NOT NULL DEFAULT 'text', -- 'text', 'image', 'video', 'mixed'
  image_url TEXT, -- URL de imagen principal
  video_url TEXT, -- URL de video (si aplica)
  category TEXT NOT NULL DEFAULT 'General', -- Categoría del recurso
  "order" INTEGER NOT NULL DEFAULT 0, -- Orden de visualización
  is_active BOOLEAN NOT NULL DEFAULT true, -- Si está activo y visible
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_resources_category ON public.resources(category);
CREATE INDEX IF NOT EXISTS idx_resources_is_active ON public.resources(is_active);
CREATE INDEX IF NOT EXISTS idx_resources_order ON public.resources("order");
CREATE INDEX IF NOT EXISTS idx_resources_created_at ON public.resources(created_at DESC);

-- Políticas RLS (Row Level Security)
ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si existen (para poder re-ejecutar el script)
DROP POLICY IF EXISTS "Users can view active resources" ON public.resources;
DROP POLICY IF EXISTS "Admins can insert resources" ON public.resources;
DROP POLICY IF EXISTS "Admins can update resources" ON public.resources;
DROP POLICY IF EXISTS "Admins can delete resources" ON public.resources;

-- Política: Todos los usuarios autenticados pueden leer recursos activos
CREATE POLICY "Users can view active resources" ON public.resources
  FOR SELECT
  USING (is_active = true);

-- Política: Solo administradores pueden insertar recursos
CREATE POLICY "Admins can insert resources" ON public.resources
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users_admin
      WHERE user_id = auth.uid()
    )
  );

-- Política: Solo administradores pueden actualizar recursos
CREATE POLICY "Admins can update resources" ON public.resources
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.users_admin
      WHERE user_id = auth.uid()
    )
  );

-- Política: Solo administradores pueden eliminar recursos
CREATE POLICY "Admins can delete resources" ON public.resources
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.users_admin
      WHERE user_id = auth.uid()
    )
  );

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_resources_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Eliminar trigger existente si existe (para poder re-ejecutar el script)
DROP TRIGGER IF EXISTS update_resources_updated_at_trigger ON public.resources;

-- Trigger para actualizar updated_at
CREATE TRIGGER update_resources_updated_at_trigger
  BEFORE UPDATE ON public.resources
  FOR EACH ROW
  EXECUTE FUNCTION update_resources_updated_at();

-- Insertar primer recurso de ejemplo (solo si no existe)
-- Verificar si ya existe un recurso con el mismo título antes de insertar
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.resources 
    WHERE title = 'Introducción a los Números de Grabovoi'
  ) THEN
    INSERT INTO public.resources (
      title,
      description,
      content,
      type,
      category,
      "order",
      is_active
    ) VALUES (
  'Introducción a los Números de Grabovoi',
  'Aprende los fundamentos de cómo funcionan los números de manifestación de Grigori Grabovoi y cómo utilizarlos en tu vida diaria.',
  '<p>Los números de Grabovoi son secuencias numéricas específicas diseñadas por el científico ruso Grigori Grabovoi para ayudar en la manifestación y sanación. Cada número tiene un propósito único y puede ser utilizado a través de la visualización, repetición o meditación.</p>

<p><b>¿Cómo funcionan?</b></p>

<p>Los números de Grabovoi actúan como códigos de programación para la realidad. Cuando los visualizas o repites, estás enviando una señal específica al campo cuántico que puede influir en la manifestación de tus deseos.</p>

<p><b>Métodos de uso:</b></p>

<ol>
<li><b>Visualización</b>: Visualiza el número en tu mente durante 5-10 minutos al día</li>
<li><b>Repetición</b>: Repite el número mentalmente o en voz alta</li>
<li><b>Meditación</b>: Incorpora el número en tu práctica meditativa</li>
<li><b>Escritura</b>: Escribe el número varias veces en un papel</li>
</ol>

<p><b>Ejemplo práctico:</b></p>

<p>El número 5197148 es conocido como el código de armonización. Puedes usarlo cuando sientas desequilibrio emocional o necesites restaurar la armonía en tu vida.</p>

<p><b>Consejos importantes:</b></p>

<ul>
<li>Sé consistente: usa el número diariamente durante al menos 21 días</li>
<li>Mantén una intención clara mientras trabajas con el número</li>
<li>Confía en el proceso y permite que la manifestación ocurra naturalmente</li>
<li>Combina el uso de números con otras prácticas espirituales para mejores resultados</li>
</ul>',
  'text',
  'Fundamentos',
  1,
  true
    );
  END IF;
END $$;

-- Mensaje de confirmación
DO $$
BEGIN
  RAISE NOTICE '✅ Tabla de recursos creada exitosamente';
  RAISE NOTICE '✅ Primer recurso insertado';
  RAISE NOTICE '📚 Puedes agregar más recursos desde el dashboard de Supabase o mediante la API';
END $$;

