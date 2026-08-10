-- Permite a los administradores ver y resolver (aprobar/rechazar) sugerencias de
-- CUALQUIER usuario, no solo las propias. Las políticas existentes (auth.uid() =
-- usuario_id) se mantienen intactas para usuarios normales; estas se suman como
-- políticas permisivas adicionales (Postgres las combina con OR).
--
-- Contexto: approve_suggestions_screen.dart y sugerencia_codigo_widget.dart llaman
-- SugerenciasCodigosService.getSugerenciasPendientes()/actualizarEstadoSugerencia()
-- para moderar sugerencias de todos los usuarios. Antes usaban el service_role key
-- desde el cliente para saltarse RLS; ahora usan el cliente normal + estas políticas.
--
-- Ejecutar en Supabase SQL Editor.

alter table public.sugerencias_codigos enable row level security;

drop policy if exists "Admins can view all suggestions" on public.sugerencias_codigos;
create policy "Admins can view all suggestions" on public.sugerencias_codigos
  for select
  using (public.es_admin(auth.uid()));

drop policy if exists "Admins can update all suggestions" on public.sugerencias_codigos;
create policy "Admins can update all suggestions" on public.sugerencias_codigos
  for update
  using (public.es_admin(auth.uid()));
