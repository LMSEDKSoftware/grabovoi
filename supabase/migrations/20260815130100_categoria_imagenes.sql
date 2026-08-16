-- Imagen dedicada por categoria (para CategoryScreen.brs en Roku). Antes
-- roku_categorias_resumen() tomaba el imagen_url de una secuencia
-- cualquiera dentro de la categoria (la primera por id) -- una portada de
-- secuencia individual, no un "arte de categoria" real. Esta tabla guarda
-- la imagen generada especificamente por categoria (mismo diseño de
-- portada: fondo esfera + barra del color de la categoria + logo, sin
-- texto horneado porque SequenceCard.brs ya dibuja el nombre encima).

create table if not exists public.categoria_imagenes (
  categoria text primary key,
  imagen_url text not null,
  updated_at timestamptz not null default now()
);

create or replace function public.roku_categorias_resumen()
returns table (categoria text, total bigint, color text, imagen_url text)
language sql
stable
as $$
  select
    c.categoria,
    count(*) as total,
    mode() within group (order by c.color) as color,
    ci.imagen_url
  from public.codigos_grabovoi c
  left join public.categoria_imagenes ci on ci.categoria = c.categoria
  where c.categoria is not null
  group by c.categoria, ci.imagen_url
  order by count(*) desc;
$$;

grant execute on function public.roku_categorias_resumen() to authenticated, service_role, anon;
grant select on public.categoria_imagenes to authenticated, service_role, anon;
