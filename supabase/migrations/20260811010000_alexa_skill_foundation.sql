-- Base de datos para el skill de Alexa de ManiGraB (repetición del código
-- del día por voz). Ver docs/ALEXA_SKILL_PLAN.md para el diseño completo.

-- ============================================================================
-- 1. Account linking (OAuth2 Authorization Code Grant, propio)
-- ============================================================================

-- Vincula un usuario de ManiGraB con el access_token opaco que Alexa manda
-- en cada request tras el account linking. No reutilizamos JWT de Supabase
-- (expiran en ~1h): Alexa necesita un token de larga duración bajo nuestro
-- control, así que emitimos uno propio y lo resolvemos nosotros mismos.
create table public.alexa_account_links (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  access_token text not null unique,
  refresh_token text not null unique,
  access_token_expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_alexa_account_links_user_id on public.alexa_account_links(user_id);

-- Códigos de autorización de un solo uso (paso intermedio del OAuth, vida
-- útil corta — se valida y expira en el edge function, no aquí).
create table public.alexa_auth_codes (
  code text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  redirect_uri text not null,
  created_at timestamptz not null default now(),
  used boolean not null default false
);

alter table public.alexa_account_links enable row level security;
alter table public.alexa_auth_codes enable row level security;
-- Sin políticas para 'authenticated'/'anon': solo el service_role (edge
-- functions) puede leer/escribir estas tablas. El cliente Flutter nunca las
-- toca directamente.

-- ============================================================================
-- 2. Endurecer el dedupe de recompensas (necesario para que la nueva función
--    de abajo sea segura ante llamadas concurrentes — mismo patrón de
--    "doble-toque" que ya corregimos en la Tienda Cuántica esta sesión).
-- ============================================================================
alter table public.user_rewarded_actions
  add constraint user_rewarded_actions_unico
  unique (user_id, codigo_id, tipo_accion, fecha_dia);

-- ============================================================================
-- 3. Función central: registra una repetición y otorga su recompensa.
--    Replica fielmente, del lado del servidor, lo que hoy hacen en conjunto
--    UserProgressService.recordSession() + RewardsService.recompensarPorRepeticion()
--    en el cliente Flutter — para que una repetición hecha por Alexa cuente
--    igual para racha, nivel energético y cristales que una hecha en la app.
--    Pensada para ser la única fuente de verdad a futuro (también invocable
--    desde el cliente, no solo desde Alexa).
-- ============================================================================
create or replace function public.otorgar_recompensa_repeticion(
  p_user_id uuid,
  p_codigo text,
  p_codigo_nombre text default null,
  p_origen text default 'app'
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_fecha_dia date := current_date;
  v_ya_otorgada boolean := false;
  v_cristales_ganados int := 0;
  v_cristales_por_repeticion constant int := 3;
  v_now timestamptz := now();
  v_progress record;
  v_diff int;
  v_dias_consecutivos int;
  v_total_pilotajes int;
  v_total_repeticiones int;
  v_total_compartidos int;
  v_total_minutos int;
  v_nivel int;
  v_luz_cuantica double precision;
begin
  if p_codigo is null or btrim(p_codigo) = '' then
    raise exception 'p_codigo es requerido';
  end if;

  -- Solo el propio usuario (o un caller con service_role, ej. el edge
  -- function de Alexa) puede otorgarse esta recompensa — evita que un
  -- usuario autenticado se la otorgue a otro pasando su user_id.
  if auth.role() <> 'service_role' and p_user_id is distinct from auth.uid() then
    raise exception 'No autorizado para otorgar recompensa a otro usuario';
  end if;

  -- 1) Registrar la sesión en user_actions — misma fuente de verdad que usa
  --    _obtenerEstadisticasCompletas() en el cliente para calcular racha/nivel.
  insert into public.user_actions (id, user_id, challenge_id, action_type, action_data, recorded_at)
  values (
    gen_random_uuid(), p_user_id, null, 'codigoRepetido',
    jsonb_build_object(
      'codeId', p_codigo,
      'codeName', coalesce(p_codigo_nombre, p_codigo),
      'duration', 2,
      'origen', p_origen,
      'timestamp', v_now
    ),
    v_now
  );

  select
    count(*) filter (where action_type = 'sesionPilotaje'),
    count(*) filter (where action_type = 'codigoRepetido'),
    count(*) filter (where action_type = 'pilotajeCompartido'),
    coalesce(sum((action_data->>'duration')::numeric) filter (where action_type = 'tiempoEnApp'), 0)::int
  into v_total_pilotajes, v_total_repeticiones, v_total_compartidos, v_total_minutos
  from public.user_actions
  where user_id = p_user_id;

  -- 2) Racha: mismo cálculo de diffDays que recordSession() en el cliente.
  select * into v_progress from public.usuario_progreso where user_id = p_user_id;
  if v_progress.user_id is null or v_progress.ultimo_pilotaje is null then
    v_dias_consecutivos := 1;
  else
    v_diff := v_fecha_dia - (v_progress.ultimo_pilotaje at time zone 'utc')::date;
    if v_diff = 1 then
      v_dias_consecutivos := coalesce(v_progress.dias_consecutivos, 0) + 1;
    elsif v_diff = 0 then
      v_dias_consecutivos := coalesce(v_progress.dias_consecutivos, 0);
    else
      v_dias_consecutivos := 1;
    end if;
  end if;

  -- 3) Nivel energético: mismo cálculo ponderado que
  --    _calcularNivelEnergeticoDesdeAcciones() en el cliente.
  v_nivel := 1
    + case
        when v_dias_consecutivos >= 21 then 4
        when v_dias_consecutivos >= 14 then 3
        when v_dias_consecutivos >= 7 then 2
        when v_dias_consecutivos >= 3 then 1
        else 0
      end
    + case
        when v_total_pilotajes >= 100 then 3
        when v_total_pilotajes >= 50 then 2
        when v_total_pilotajes >= 20 then 1
        when v_total_pilotajes >= 5 then 1
        else 0
      end
    + case
        when v_total_repeticiones >= 200 then 2
        when v_total_repeticiones >= 100 then 1
        when v_total_repeticiones >= 50 then 1
        else 0
      end
    + case
        when v_total_compartidos >= 100 then 2
        when v_total_compartidos >= 50 then 1
        when v_total_compartidos >= 20 then 1
        when v_total_compartidos >= 5 then 1
        else 0
      end
    + case
        when v_total_minutos >= 300 then 2
        when v_total_minutos >= 180 then 1
        when v_total_minutos >= 60 then 1
        else 0
      end;

  if v_dias_consecutivos > 0 or v_total_pilotajes > 0 or v_total_repeticiones > 0 then
    v_nivel := greatest(least(v_nivel, 10), 3);
  else
    v_nivel := greatest(least(v_nivel, 10), 1);
  end if;

  insert into public.usuario_progreso (user_id, dias_consecutivos, total_pilotajes, nivel_energetico, ultimo_pilotaje, created_at, updated_at)
  values (p_user_id, v_dias_consecutivos, v_total_pilotajes, v_nivel, v_now, v_now, v_now)
  on conflict (user_id) do update set
    dias_consecutivos = excluded.dias_consecutivos,
    total_pilotajes = excluded.total_pilotajes,
    nivel_energetico = excluded.nivel_energetico,
    ultimo_pilotaje = excluded.ultimo_pilotaje,
    updated_at = excluded.updated_at;

  -- 4) Recompensa de cristales: una sola vez por código+día (igual que
  --    yaSeOtorgaronRecompensas()/recompensarPorRepeticion() en el cliente).
  --    El unique constraint agregado arriba hace esto seguro ante llamadas
  --    concurrentes (ej. dos turnos de Alexa casi simultáneos).
  begin
    insert into public.user_rewarded_actions (id, user_id, codigo_id, tipo_accion, cristales_otorgados, fecha, fecha_dia, created_at)
    values (gen_random_uuid(), p_user_id, p_codigo, 'repeticion', v_cristales_por_repeticion, v_now, v_fecha_dia, v_now);
    v_cristales_ganados := v_cristales_por_repeticion;
  exception when unique_violation then
    v_ya_otorgada := true;
    v_cristales_ganados := 0;
  end;

  v_luz_cuantica := least(v_dias_consecutivos * 5.0, 100.0);

  if not v_ya_otorgada then
    insert into public.user_rewards (
      user_id, cristales_energia, anclas_continuidad, luz_cuantica,
      mantras_desbloqueados, codigos_premium_desbloqueados,
      ultima_actualizacion, logros, voice_numbers_enabled, voice_gender, updated_at
    ) values (
      p_user_id, v_cristales_por_repeticion, 0, v_luz_cuantica,
      '{}', '{}', v_now, '{}'::jsonb, false, 'female', v_now
    )
    on conflict (user_id) do update set
      cristales_energia = public.user_rewards.cristales_energia + v_cristales_por_repeticion,
      luz_cuantica = v_luz_cuantica,
      ultima_actualizacion = v_now,
      updated_at = v_now;
  else
    -- Sin cristales nuevos, pero mantenemos luz_cuantica sincronizada con la racha.
    update public.user_rewards set luz_cuantica = v_luz_cuantica, updated_at = v_now where user_id = p_user_id;
  end if;

  return jsonb_build_object(
    'codigo', p_codigo,
    'ya_otorgada', v_ya_otorgada,
    'cristales_ganados', v_cristales_ganados,
    'dias_consecutivos', v_dias_consecutivos,
    'nivel_energetico', v_nivel,
    'luz_cuantica', v_luz_cuantica
  );
end;
$function$;

grant execute on function public.otorgar_recompensa_repeticion(uuid, text, text, text) to authenticated, service_role;

-- ============================================================================
-- 4. Código del día global (para que el edge function de Alexa no dependa
--    de un usuario/auth para resolver "el código de hoy" — mismo dato que
--    ve la app para todos los usuarios).
-- ============================================================================
create or replace function public.obtener_codigo_del_dia()
returns table (codigo text, nombre text)
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_codigo text;
  v_nombre text;
  v_total int;
  v_idx int;
  v_codigo_id int;
begin
  select dc.codigo, dc.nombre into v_codigo, v_nombre
  from public.daily_code_assignments dca
  join public.daily_codes dc on dc.id = dca.codigo_id
  where dca.fecha_asignacion = current_date
    and dca.es_activo = true
  limit 1;

  if v_codigo is not null then
    return query select v_codigo, v_nombre;
    return;
  end if;

  -- Nadie (ni la app) ha pedido el código de hoy todavía: lo asignamos con
  -- la misma rotación por día del año que usa DailyCodeService en el
  -- cliente, para que Alexa y la app siempre coincidan en "el código de hoy".
  select count(*) into v_total from public.daily_codes;
  if v_total = 0 then
    return; -- sin filas: el edge function debe manejar este caso
  end if;

  v_idx := (extract(doy from current_date)::int - 1) % v_total;

  select dc.id, dc.codigo, dc.nombre into v_codigo_id, v_codigo, v_nombre
  from public.daily_codes dc
  order by dc.id
  offset v_idx limit 1;

  insert into public.daily_code_assignments (codigo_id, fecha_asignacion, es_activo)
  values (v_codigo_id, current_date, true)
  on conflict do nothing;

  return query select v_codigo, v_nombre;
end;
$function$;

grant execute on function public.obtener_codigo_del_dia() to authenticated, service_role, anon;
