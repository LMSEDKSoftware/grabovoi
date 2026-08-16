-- Estadisticas para la pantalla "Evolucion" de Roku, calculadas igual
-- que en la app movil (lib/screens/evolucion/evolucion_screen.dart via
-- user_progress_service.dart): sobre user_actions, filtrando los mismos
-- 3 action_type ('sesionPilotaje','codigoRepetido','pilotajeCompartido').
--   - total_sesiones: cuenta de filas (== sessionHistory.length)
--   - total_minutos: suma de action_data->>'duration'
--   - secuencias_usadas: codigos DISTINCT en action_data->>'codeId'
-- Se hace en una funcion (no PostgREST directo) porque count-distinct y
-- sum agregados no se piden bien desde el cliente JS sin traer todas las
-- filas.

create or replace function public.roku_estadisticas_evolucion(p_user_id uuid)
returns table (total_sesiones bigint, total_minutos bigint, secuencias_usadas bigint)
language sql
stable
as $$
  select
    count(*) as total_sesiones,
    coalesce(sum((action_data->>'duration')::numeric), 0)::bigint as total_minutos,
    count(distinct action_data->>'codeId') as secuencias_usadas
  from public.user_actions
  where user_id = p_user_id
    and action_type in ('sesionPilotaje', 'codigoRepetido', 'pilotajeCompartido');
$$;

grant execute on function public.roku_estadisticas_evolucion(uuid) to authenticated, service_role;
