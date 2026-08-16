-- Bug reportado: la pantalla de categorias de Roku mostraba "Salud: 504
-- secuencias" cuando en realidad hay 627. Causa raiz: /roku-catalog (sin
-- filtro) traia TODAS las filas de codigos_grabovoi al cliente y contaba
-- por categoria en JS -- pero Supabase/PostgREST tiene un tope por
-- defecto de 1000 filas por consulta, y la tabla ya tiene 1191. El
-- conteo se calculaba sobre un subconjunto incompleto, asi que TODAS las
-- categorias quedaban subestimadas, no solo Salud.
--
-- Con GROUP BY hecho en el propio Postgres (esta funcion) el conteo es
-- exacto sin importar cuantas filas tenga la tabla: se agregan del lado
-- del servidor y solo se devuelve una fila por categoria (~15-20 filas),
-- muy por debajo de cualquier tope.

create or replace function public.roku_categorias_resumen()
returns table (categoria text, total bigint, color text, imagen_url text)
language sql
stable
as $$
  select
    c.categoria,
    count(*) as total,
    -- mismo criterio que antes calculaba roku-catalog.js en JS: el color
    -- mas frecuente de esa categoria.
    mode() within group (order by c.color) as color,
    -- primera imagen no nula (por id, para que sea deterministico).
    (array_agg(c.imagen_url order by c.id) filter (where c.imagen_url is not null))[1] as imagen_url
  from public.codigos_grabovoi c
  where c.categoria is not null
  group by c.categoria
  order by count(*) desc;
$$;

grant execute on function public.roku_categorias_resumen() to authenticated, service_role, anon;
