-- Políticas RLS necesarias para poder quitar el service_role key del cliente
-- Flutter (ver lib/services/supabase_service.dart). Estas operaciones ya eran
-- posibles para cualquier usuario logueado (la app las exponía en pantallas de
-- usuario normal, no de admin) pero se hacían con el service_role key
-- directamente desde el cliente, saltándose RLS por completo.
--
-- Ejecutar en Supabase SQL Editor.

-- codigos_grabovoi: cualquier usuario autenticado puede agregar un código nuevo
-- (flujo de "guardar código encontrado por IA" en static_biblioteca_screen.dart).
-- Ya existía "Allow public read access" (SELECT). No se agrega UPDATE/DELETE:
-- eso sigue reservado a admins (ver codigos_titulos_relacionados más abajo y
-- migration_admin_rls_sugerencias_codigos.sql para el patrón equivalente).
alter table public.codigos_grabovoi enable row level security;

drop policy if exists "Authenticated users can insert codigos" on public.codigos_grabovoi;
create policy "Authenticated users can insert codigos" on public.codigos_grabovoi
  for insert
  to authenticated
  with check (true);

-- codigo_popularidad: contador compartido (no pertenece a un usuario específico),
-- cualquier usuario autenticado puede crear/incrementar el contador de un código.
alter table public.codigo_popularidad enable row level security;

drop policy if exists "Authenticated users can insert popularidad" on public.codigo_popularidad;
create policy "Authenticated users can insert popularidad" on public.codigo_popularidad
  for insert
  to authenticated
  with check (true);

drop policy if exists "Authenticated users can update popularidad" on public.codigo_popularidad;
create policy "Authenticated users can update popularidad" on public.codigo_popularidad
  for update
  to authenticated
  using (true)
  with check (true);
