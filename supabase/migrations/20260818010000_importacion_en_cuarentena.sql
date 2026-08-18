-- El crawler de deep-search estaba escribiendo directo en el catálogo
-- que ven los usuarios, y de ahí salió toda la basura que se limpió el
-- 17 de agosto: fechas, horas, números de página y trozos de nombres de
-- PDF, todo con nombre "Secuencia" y descripción "Secuencia importada
-- desde fuentes externas", sin fuente y en una categoría inventada
-- ("Redes sociales").
--
-- Dos guardas, en dos niveles distintos.

-- ---------------------------------------------------------------
-- 1. Un código no puede entrar dos veces escrito distinto
-- ---------------------------------------------------------------
-- '519_714_812' y '519714812' son el mismo código, pero el unique de
-- codigo los ve como filas distintas: por eso convivían 30 códigos
-- duplicados con significados a veces contradictorios. Este índice lo
-- vuelve imposible, venga de donde venga la inserción.
--
-- Se puede crear ahora porque ya no queda ninguno; si algún día falla al
-- aplicarse, es que volvieron a colarse y hay que limpiarlos antes.
create unique index if not exists idx_codigos_grabovoi_normalizado
  on public.codigos_grabovoi ((replace(codigo, '_', '')));

-- ---------------------------------------------------------------
-- 2. Lo que descubre el crawler ya no entra solo
-- ---------------------------------------------------------------
-- Va a cuarentena. La razón de fondo es que NO se puede distinguir
-- basura de código legítimo mirando solo el número: '121918' es
-- "Permanecer centrado", una secuencia real, y a la vez se lee como la
-- hora 12:19:18. Cualquier heurística que rechace horas se come esa
-- secuencia, y cualquiera que las acepte deja pasar '150749'.
--
-- Por eso decide una persona. No se pierde el hallazgo, pero tampoco
-- llega solo a la pantalla de nadie.
create table if not exists public.codigos_pendientes (
  id uuid primary key default gen_random_uuid(),
  codigo text not null,
  -- Lo que el crawler creyó leer como nombre, si es que leyó algo. Vacío
  -- es señal de que solo encontró un número suelto, que es justo el caso
  -- del que salió toda la basura.
  nombre_detectado text,
  fuente_url text not null,
  fuente_titulo text,
  -- El texto alrededor del número en la página. Es lo que permite juzgar
  -- si era una secuencia o el pie de un PDF, sin volver a abrir la
  -- fuente.
  contexto text,
  estado text not null default 'pendiente',
  motivo_rechazo text,
  detectado_en timestamptz not null default now(),
  revisado_en timestamptz,
  constraint codigos_pendientes_estado_check
    check (estado in ('pendiente', 'aprobado', 'rechazado')),
  -- Mismo código de la misma fuente no se apila cada vez que se rastrea.
  unique (codigo, fuente_url)
);

comment on table public.codigos_pendientes is
  'Cuarentena de códigos descubiertos por el crawler. Nada pasa a codigos_grabovoi sin revisión: ver process-deep-search-queue y la funcion aprobar_codigo_pendiente.';

alter table public.codigos_pendientes enable row level security;
-- Sin políticas: solo service_role y el panel de admin.

create index if not exists idx_codigos_pendientes_estado
  on public.codigos_pendientes(estado, detectado_en desc);

-- Aprobar exige darle nombre y categoría de verdad: es lo que faltaba
-- antes y lo que convirtió el catálogo en una lista de "Secuencia".
create or replace function public.aprobar_codigo_pendiente(
  p_id uuid,
  p_nombre text,
  p_categoria text,
  p_descripcion text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pendiente record;
  v_nuevo_id uuid;
begin
  select * into v_pendiente from public.codigos_pendientes where id = p_id;
  if not found then
    raise exception 'No existe el código pendiente %', p_id;
  end if;

  if coalesce(trim(p_nombre), '') = '' then
    raise exception 'Hay que darle un nombre real, no se aprueba sin eso';
  end if;
  if coalesce(trim(p_categoria), '') = '' then
    raise exception 'Hay que darle una categoría';
  end if;
  if not exists (select 1 from public.codigos_grabovoi where categoria = p_categoria) then
    raise exception 'La categoría % no existe en el catálogo', p_categoria;
  end if;

  insert into public.codigos_grabovoi (codigo, nombre, categoria, descripcion, fuente_url)
  values (v_pendiente.codigo, trim(p_nombre), p_categoria, p_descripcion, v_pendiente.fuente_url)
  returning id into v_nuevo_id;

  update public.codigos_pendientes
     set estado = 'aprobado', revisado_en = now()
   where id = p_id;

  return v_nuevo_id;
end;
$$;

comment on function public.aprobar_codigo_pendiente is
  'Pasa un código de cuarentena al catálogo. Exige nombre y categoría reales: sin eso no se aprueba.';
