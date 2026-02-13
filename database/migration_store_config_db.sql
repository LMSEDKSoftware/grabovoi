-- ============================================================================
-- Migración: Configuración dinámica de tienda desde Supabase
-- Permite administrar precios, cantidades y visibilidad sin actualizar la app
-- ============================================================================

-- 1. Añadir columna activo a codigos_premium (encendido/apagado sin eliminar)
ALTER TABLE public.codigos_premium 
  ADD COLUMN IF NOT EXISTS activo BOOLEAN DEFAULT true;
UPDATE public.codigos_premium SET activo = true WHERE activo IS NULL;

-- 2. Añadir columna activo a meditaciones_especiales
ALTER TABLE public.meditaciones_especiales 
  ADD COLUMN IF NOT EXISTS activo BOOLEAN DEFAULT true;
UPDATE public.meditaciones_especiales SET activo = true WHERE activo IS NULL;

-- 3. Tabla paquetes_cristales (cantidades, precios MXN, activo)
CREATE TABLE IF NOT EXISTS public.paquetes_cristales (
  id TEXT PRIMARY KEY,
  cantidad_cristales INTEGER NOT NULL,
  precio_mxn INTEGER NOT NULL,
  activo BOOLEAN DEFAULT true,
  orden INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

INSERT INTO public.paquetes_cristales (id, cantidad_cristales, precio_mxn, activo, orden) VALUES
  ('pack_250', 250, 89, true, 1),
  ('pack_700', 700, 199, true, 2),
  ('pack_1600', 1600, 349, true, 3)
ON CONFLICT (id) DO NOTHING;

-- 4. Tabla elementos_tienda (Voz numérica, Ancla de Continuidad, etc.)
CREATE TABLE IF NOT EXISTS public.elementos_tienda (
  id TEXT PRIMARY KEY,
  tipo TEXT NOT NULL UNIQUE,
  nombre TEXT NOT NULL,
  descripcion TEXT,
  costo_cristales INTEGER NOT NULL,
  icono TEXT,
  activo BOOLEAN DEFAULT true,
  orden INTEGER DEFAULT 0,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- tipo: voz_numerica, ancla_continuidad. metadata: { "max_anclas": 2 } para ancla
INSERT INTO public.elementos_tienda (id, tipo, nombre, descripcion, costo_cristales, activo, orden, metadata) VALUES
  ('elem_voz_numerica', 'voz_numerica', 'Voz numérica en pilotajes', 
   'Reproduce la secuencia dígito a dígito durante el pilotaje (voz hombre o mujer).', 
   50, true, 1, '{}'),
  ('elem_ancla_continuidad', 'ancla_continuidad', 'Ancla de Continuidad', 
   'Salva tu racha automáticamente cuando no completes un día (máximo 2 anclas = 2 días seguidos)', 
   200, true, 2, '{"max_anclas": 2}')
ON CONFLICT (id) DO NOTHING;

-- RLS
ALTER TABLE public.paquetes_cristales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.elementos_tienda ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view paquetes cristales" ON public.paquetes_cristales;
CREATE POLICY "Anyone can view paquetes cristales" ON public.paquetes_cristales FOR SELECT USING (true);

DROP POLICY IF EXISTS "Anyone can view elementos tienda" ON public.elementos_tienda;
CREATE POLICY "Anyone can view elementos tienda" ON public.elementos_tienda FOR SELECT USING (true);
