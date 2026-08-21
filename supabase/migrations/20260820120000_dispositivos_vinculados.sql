-- "Dispositivos vinculados" en Perfil (Alexa, Roku): roku_account_links y
-- alexa_account_links tienen RLS activo sin ninguna politica, asi que hoy
-- nadie puede leerlas desde el cliente -- ni siquiera el propio dueno de
-- la fila. Es a proposito: esas tablas guardan access_token/refresh_token
-- en texto, y esta funcion nunca los devuelve, solo si hay un vinculo
-- vigente (token sin expirar) y desde cuando.
--
-- security definer + auth.uid() interno (no recibe user_id como
-- parametro): asi no hay forma de pedir el estado de otro usuario aunque
-- se llame la funcion directo por PostgREST.
create or replace function public.dispositivos_vinculados()
returns table (
  alexa_vinculado boolean,
  alexa_desde timestamptz,
  roku_vinculado boolean,
  roku_desde timestamptz
)
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'no autenticado';
  end if;

  return query
  select
    (a.user_id is not null and a.access_token_expires_at > now()) as alexa_vinculado,
    a.created_at as alexa_desde,
    (r.user_id is not null and r.access_token_expires_at > now()) as roku_vinculado,
    r.created_at as roku_desde
  from (select 1) uno
  left join public.alexa_account_links a on a.user_id = v_user_id
  left join public.roku_account_links r on r.user_id = v_user_id;
end;
$function$;

revoke all on function public.dispositivos_vinculados() from public;
grant execute on function public.dispositivos_vinculados() to authenticated;

comment on function public.dispositivos_vinculados() is
  'Estado de vinculacion con Alexa/Roku para el usuario autenticado. Nunca devuelve tokens, solo booleano + fecha.';
