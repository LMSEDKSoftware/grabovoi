-- Auditoria previa (ver conversacion): el color de codigos_grabovoi no
-- viene de una sola fuente, y dentro de una misma categoria conviven
-- varios colores distintos (ej. Protección tenia 4, Avanzados 6). De las
-- 4 categorias con color "oficial" en la app (supabase_service.dart,
-- _getCategoryColor), 2 no coincidian con lo guardado (Amor tenia
-- #FF3B3B en vez de #FF69B4; Manifestación tenia #1E90FF en vez de
-- #FF8C00).
--
-- Esta migracion pareja cada categoria a UN solo color:
--   - Amor y Manifestación: al color oficial de la app (la mayoria
--     actual esta mal, se sobreescribe).
--   - Todas las demas: a su propio color mayoritario ya existente (no
--     se inventa ningun color nuevo para categorias sin definicion
--     oficial -- eso mantiene la variedad visual entre categorias en
--     vez de aplanarlas todas al dorado por defecto de la app).
--   - Categorias sin NINGUN color guardado (Mental, Dinero, Social,
--     Espiritual, General) quedan intactas: no hay mayoria de la cual
--     partir.

-- 1) Datos mal formados: 4 filas tenian el color guardado sin el "#"
--    inicial ("FFD700" en vez de "#FFD700").
update public.codigos_grabovoi
set color = '#' || color
where color is not null and color !~ '^#';

-- 2) Parejar cada categoria a un solo color.
with moda as (
  select
    categoria,
    mode() within group (order by color) filter (where color is not null) as color_moda
  from public.codigos_grabovoi
  where categoria is not null
  group by categoria
)
update public.codigos_grabovoi c
set color = case
  when c.categoria = 'Amor' then '#FF69B4'
  when c.categoria = 'Manifestación' then '#FF8C00'
  else m.color_moda
end
from moda m
where c.categoria = m.categoria
  and m.color_moda is not null;
