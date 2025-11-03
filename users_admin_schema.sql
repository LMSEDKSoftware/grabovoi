-- Tabla para almacenar usuarios administradores
-- Ejecutar este script en el SQL Editor de Supabase
-- Solo almacena el UUID del usuario, el resto de datos se obtiene de la tabla users

create table if not exists public.users_admin (
  id serial primary key,
  user_id uuid not null unique references auth.users(id) on delete cascade
);

-- Índice para optimización
create index if not exists idx_users_admin_user_id on public.users_admin (user_id);

-- RLS (Row Level Security) para seguridad
alter table public.users_admin enable row level security;

-- Política: Solo los admins pueden ver la tabla completa
create policy "Admins can view all admin users" on public.users_admin
  for select
  using (
    exists (
      select 1 from public.users_admin
      where user_id = auth.uid()
    )
  );

-- Política: Solo los admins pueden insertar nuevos admins (usando service client)
-- Esta operación normalmente se hace con service client para bypass RLS

-- Política: Solo los admins pueden eliminar
create policy "Admins can delete admin users" on public.users_admin
  for delete
  using (
    exists (
      select 1 from public.users_admin
      where user_id = auth.uid()
    )
  );

-- Función helper para verificar si un usuario es admin
create or replace function public.es_admin(user_uuid uuid)
returns boolean
language plpgsql
security definer
as $$
begin
  return exists (
    select 1 from public.users_admin
    where user_id = user_uuid
  );
end;
$$;

-- Comentarios para documentación
comment on table public.users_admin is 'Tabla de usuarios administradores de la aplicación. Solo almacena el UUID del usuario, el resto de datos se obtiene de la tabla users';
comment on column public.users_admin.user_id is 'ID del usuario en auth.users';
comment on function public.es_admin is 'Función helper para verificar si un usuario es administrador';

