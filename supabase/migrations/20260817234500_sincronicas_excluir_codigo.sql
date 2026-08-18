-- La función ya excluía la secuencia recién escuchada por id (p_excluir),
-- que es lo que tiene a mano el canal de Roku. La app móvil trabaja con
-- el código de texto y no con el uuid, así que al llamarla desde Flutter
-- se quedaba sin esa exclusión y una secuencia podía sugerirse a sí
-- misma.
--
-- Ahora también se excluye por código cuando viene p_codigo. Los dos
-- filtros conviven: cada cliente manda el identificador que tiene.

create or replace function public.roku_sincronicas(
  p_categoria text,
  p_excluir uuid default null,
  p_limite int default 2,
  p_codigo text default null
)
returns table (id uuid, codigo text, nombre text, categoria text)
language sql
volatile
as $$
  with curadas as (
    select c.id, c.codigo, c.nombre, c.categoria,
           0 as prioridad, s.orden as rn, 0 as peso
      from public.codigos_sincronicos s
      join public.codigos_grabovoi c on c.codigo = s.codigo_sugerido
     where p_codigo is not null
       and s.codigo_origen = p_codigo
       and (p_excluir is null or c.id <> p_excluir)
       and c.codigo <> p_codigo
  ),
  recomendadas as (
    select s.categoria_recomendada, s.peso
      from public.categorias_sincronicas s
     where s.categoria_principal = p_categoria
       and s.categoria_recomendada <> p_categoria
       and exists (
         select 1 from public.codigos_grabovoi c
          where c.categoria = s.categoria_recomendada
       )
  ),
  por_categoria as (
    select c.id, c.codigo, c.nombre, c.categoria,
           1 as prioridad,
           row_number() over (partition by c.categoria order by random())::int as rn,
           r.peso
      from public.codigos_grabovoi c
      join recomendadas r on r.categoria_recomendada = c.categoria
     where c.nombre is not null
       and (p_excluir is null or c.id <> p_excluir)
       and (p_codigo is null or c.codigo <> p_codigo)
  ),
  respaldo as (
    select c.id, c.codigo, c.nombre, c.categoria,
           2 as prioridad,
           row_number() over (order by random())::int as rn,
           0 as peso
      from public.codigos_grabovoi c
     where c.categoria = p_categoria
       and c.nombre is not null
       and (p_excluir is null or c.id <> p_excluir)
       and (p_codigo is null or c.codigo <> p_codigo)
  ),
  todas as (
    select * from curadas
    union all select * from por_categoria
    union all select * from respaldo
  ),
  unicas as (
    select distinct on (t.id) t.id, t.codigo, t.nombre, t.categoria, t.prioridad, t.rn, t.peso
      from todas t
     order by t.id, t.prioridad, t.rn
  )
  select u.id, u.codigo, u.nombre, u.categoria
    from unicas u
   order by u.prioridad, u.rn, u.peso desc, random()
   limit p_limite;
$$;
