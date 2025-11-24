-- Esquema para códigos sincrónicos
-- Ejecutar este script en el SQL Editor de Supabase

-- Tabla de categorías sincrónicas
CREATE TABLE IF NOT EXISTS categorias_sincronicas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  categoria_principal TEXT NOT NULL,
  categoria_recomendada TEXT NOT NULL,
  rationale TEXT NOT NULL,
  peso INTEGER DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(categoria_principal, categoria_recomendada)
);

-- Índices para optimización
CREATE INDEX IF NOT EXISTS idx_categorias_sincronicas_principal ON categorias_sincronicas(categoria_principal);
CREATE INDEX IF NOT EXISTS idx_categorias_sincronicas_peso ON categorias_sincronicas(peso);

-- Insertar datos de ejemplo para categorías sincrónicas
INSERT INTO categorias_sincronicas (categoria_principal, categoria_recomendada, rationale, peso) VALUES
-- Salud
('Salud', 'Protección', 'La salud se potencia con códigos de protección energética', 3),
('Salud', 'Limpieza', 'La limpieza energética complementa la sanación física', 2),
('Salud', 'Equilibrio', 'El equilibrio energético es fundamental para la salud', 1),

-- Prosperidad
('Prosperidad', 'Abundancia', 'La abundancia amplifica los efectos de la prosperidad', 3),
('Prosperidad', 'Dinero', 'Los códigos de dinero potencian la manifestación de prosperidad', 2),
('Prosperidad', 'Éxito', 'El éxito profesional complementa la prosperidad', 1),

-- Amor
('Amor', 'Pareja', 'El amor se potencia con códigos específicos para relaciones', 3),
('Amor', 'Conexión', 'La conexión profunda amplifica el amor', 2),
('Amor', 'Armonía', 'La armonía en las relaciones potencia el amor', 1),

-- Espiritualidad
('Espiritualidad', 'Elevación', 'La elevación espiritual se potencia con códigos de ascensión', 3),
('Espiritualidad', 'Conciencia', 'La expansión de conciencia complementa el crecimiento espiritual', 2),
('Espiritualidad', 'Iluminación', 'La iluminación es el resultado de la práctica espiritual', 1),

-- Protección
('Protección', 'Defensa', 'La defensa energética se potencia con códigos de blindaje', 3),
('Protección', 'Escudo', 'Los escudos energéticos complementan la protección', 2),
('Protección', 'Limpieza', 'La limpieza energética es fundamental para la protección', 1),

-- Curación
('Curación', 'Sanación', 'La sanación se potencia con códigos de regeneración', 3),
('Curación', 'Regeneración', 'La regeneración celular complementa la curación', 2),
('Curación', 'Equilibrio', 'El equilibrio energético es esencial para la curación', 1),

-- Dinero
('Dinero', 'Abundancia', 'La abundancia amplifica los efectos del dinero', 3),
('Dinero', 'Prosperidad', 'La prosperidad complementa la manifestación de dinero', 2),
('Dinero', 'Éxito', 'El éxito financiero se potencia con códigos de abundancia', 1),

-- Trabajo
('Trabajo', 'Éxito', 'El éxito profesional se potencia con códigos de logros', 3),
('Trabajo', 'Prosperidad', 'La prosperidad laboral complementa el éxito profesional', 2),
('Trabajo', 'Abundancia', 'La abundancia se manifiesta en el ámbito laboral', 1),

-- Familia
('Familia', 'Armonía', 'La armonía familiar se potencia con códigos de unión', 3),
('Familia', 'Amor', 'El amor familiar se amplifica con códigos de conexión', 2),
('Familia', 'Protección', 'La protección familiar es fundamental para la armonía', 1),

-- Desarrollo Personal
('Desarrollo Personal', 'Crecimiento', 'El crecimiento personal se potencia con códigos de evolución', 3),
('Desarrollo Personal', 'Conciencia', 'La expansión de conciencia complementa el desarrollo', 2),
('Desarrollo Personal', 'Iluminación', 'La iluminación es el resultado del desarrollo personal', 1);

-- Comentarios sobre la tabla
COMMENT ON TABLE categorias_sincronicas IS 'Tabla que define las relaciones sincrónicas entre categorías de códigos Grabovoi';
COMMENT ON COLUMN categorias_sincronicas.categoria_principal IS 'Categoría principal del código';
COMMENT ON COLUMN categorias_sincronicas.categoria_recomendada IS 'Categoría recomendada que potencia la principal';
COMMENT ON COLUMN categorias_sincronicas.rationale IS 'Explicación del por qué estas categorías se potencian mutuamente';
COMMENT ON COLUMN categorias_sincronicas.peso IS 'Peso de la recomendación (1-3, donde 3 es más importante)';
