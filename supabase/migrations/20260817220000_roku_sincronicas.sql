-- Secuencias sincrónicas: las 2 que se sugieren al terminar una sesión,
-- bajo "Combínalo con las siguientes secuencias para amplificar la
-- resonancia".
--
-- Antes esto se resolvía en el endpoint con
--   .in('categoria', recomendadas).limit(2)
-- sin ORDER BY, así que Postgres devolvía siempre las mismas dos filas:
-- no es que se repitieran a veces, eran constantes por categoría desde
-- el primer día. Además metía todas las categorías recomendadas en un
-- mismo saco, ignorando el peso, y por eso las dos sugerencias solían
-- salir de la misma categoría.
--
-- Aquí se resuelve del lado del servidor porque hace falta random() y
-- una ventana por categoría, y eso PostgREST no lo expresa.

create or replace function public.roku_sincronicas(
  p_categoria text,
  p_excluir uuid default null,
  p_limite int default 2
)
returns table (id uuid, codigo text, nombre text, categoria text)
-- volatile, no stable: usa random() y debe dar algo distinto en cada
-- llamada. Marcarla stable dejaría que el planner cachee el resultado
-- dentro de una misma consulta y volveríamos al problema original.
language sql
volatile
as $$
  with recomendadas as (
    select s.categoria_recomendada, s.peso
      from public.categorias_sincronicas s
     where s.categoria_principal = p_categoria
       and s.categoria_recomendada <> p_categoria
       -- La tabla arrastra nombres de una versión anterior del catálogo
       -- ("Armonización", "Maestría", "Energía", "Manifestacion" sin
       -- tilde...). Sin este filtro esas reglas cuentan como válidas y
       -- se traducen en cero sugerencias.
       and exists (
         select 1 from public.codigos_grabovoi c
          where c.categoria = s.categoria_recomendada
       )
  ),
  candidatas as (
    -- Prioridad 0: una secuencia al azar de cada categoría recomendada.
    select c.id, c.codigo, c.nombre, c.categoria, r.peso, 0 as prioridad,
           row_number() over (partition by c.categoria order by random()) as rn
      from public.codigos_grabovoi c
      join recomendadas r on r.categoria_recomendada = c.categoria
     where c.nombre is not null
       and (p_excluir is null or c.id <> p_excluir)

    union all

    -- Prioridad 1: respaldo dentro de la misma categoría. Hoy 12 de las
    -- 21 categorías no tienen ninguna regla, y sin esto la pantalla
    -- final se queda sin nada que ofrecer.
    select c.id, c.codigo, c.nombre, c.categoria, 0 as peso, 1 as prioridad,
           row_number() over (order by random()) as rn
      from public.codigos_grabovoi c
     where c.categoria = p_categoria
       and c.nombre is not null
       and (p_excluir is null or c.id <> p_excluir)
  )
  select cd.id, cd.codigo, cd.nombre, cd.categoria
    from candidatas cd
   -- rn primero: agota una de cada categoría recomendada (la de mayor
   -- peso antes) antes de repetir categoría. Así las dos sugerencias
   -- salen de categorías distintas siempre que se pueda.
   order by cd.prioridad, cd.rn, cd.peso desc, random()
   limit p_limite;
$$;

comment on function public.roku_sincronicas is
  'Sugerencias al terminar una secuencia: una al azar por categoría recomendada, ordenadas por peso, sin repetir la recién escuchada. Con respaldo a la misma categoría si no hay reglas. Ver roku-complete.js.';
