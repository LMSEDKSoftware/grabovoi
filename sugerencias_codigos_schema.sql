-- Tabla para almacenar sugerencias de códigos con temas diferentes
-- Relacionada con busquedas_profundas y usuarios

create table public.sugerencias_codigos (
  id serial primary key,
  busqueda_id integer references public.busquedas_profundas(id) on delete cascade,
  codigo_existente varchar(50) not null,
  tema_en_db text null,
  tema_sugerido text not null,
  descripcion_sugerida text null,
  usuario_id uuid references auth.users(id),
  fuente text default 'IA',
  estado varchar(20) default 'pendiente', -- valores: pendiente, aprobada, rechazada
  fecha_sugerencia timestamptz default now(),
  fecha_resolucion timestamptz null,
  comentario_admin text null
);

-- Índices para optimizar consultas
create index if not exists idx_sugerencias_codigo on public.sugerencias_codigos (codigo_existente);
create index if not exists idx_sugerencias_estado on public.sugerencias_codigos (estado);
create index if not exists idx_sugerencias_usuario on public.sugerencias_codigos (usuario_id);
create index if not exists idx_sugerencias_busqueda on public.sugerencias_codigos (busqueda_id);

-- RLS (Row Level Security) para seguridad
alter table public.sugerencias_codigos enable row level security;

-- Política para que los usuarios solo vean sus propias sugerencias
create policy "Users can view their own suggestions" on public.sugerencias_codigos
  for select using (auth.uid() = usuario_id);

-- Política para que los usuarios puedan insertar sus propias sugerencias
create policy "Users can insert their own suggestions" on public.sugerencias_codigos
  for insert with check (auth.uid() = usuario_id);

-- Política para que los usuarios puedan actualizar sus propias sugerencias
create policy "Users can update their own suggestions" on public.sugerencias_codigos
  for update using (auth.uid() = usuario_id);

-- Comentarios para documentación
comment on table public.sugerencias_codigos is 'Sugerencias de códigos con temas diferentes generadas por IA';
comment on column public.sugerencias_codigos.busqueda_id is 'ID de la búsqueda profunda que originó la sugerencia';
comment on column public.sugerencias_codigos.codigo_existente is 'Código que ya existe en la base de datos';
comment on column public.sugerencias_codigos.tema_en_db is 'Tema actual del código en la base de datos';
comment on column public.sugerencias_codigos.tema_sugerido is 'Nuevo tema sugerido por la IA';
comment on column public.sugerencias_codigos.estado is 'Estado de la sugerencia: pendiente, aprobada, rechazada';

