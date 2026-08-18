-- "¡Buenos días!" llegaba 2-3 veces con desafíos distintos, todas
-- alrededor de la misma hora.
--
-- Causa: startChallenge() en challenge_service.dart solo comprobaba un
-- mapa en memoria (_userChallenges) antes de insertar una fila nueva en
-- user_challenges con status='enProgreso'. Si ese mapa estaba
-- desactualizado -- típicamente justo al encadenar automáticamente el
-- siguiente desafío al completar uno (_iniciarSiguienteDesafioEnCadena)
-- -- se insertaba una segunda fila "enProgreso" sin que nada del lado del
-- servidor lo impidiera. El cron challenge-streak-check recorre TODAS las
-- filas "enProgreso" y manda un recordatorio matutino por cada una, así
-- que dos filas activas = dos avisos (o tres, si había una tercera fila
-- vieja que tampoco se había cerrado).
--
-- El cliente ya se corrigió para volver a preguntarle a Supabase antes de
-- insertar, pero eso es defensa de aplicación, no una garantía. El índice
-- único de abajo es la garantía real: nunca más de una fila "enProgreso"
-- por usuario, sin importar cuántas veces el cliente se equivoque.
--
-- Antes del índice hace falta limpiar los duplicados que ya existen, o la
-- creación del índice falla.

-- Para cada usuario con más de una fila "enProgreso", se conserva la de
-- start_date más reciente (la que de verdad está corriendo ahora mismo) y
-- el resto pasa a 'pausado' -- no se borran: siguen siendo historial real
-- de que el usuario empezó ese desafío, solo dejan de contar como activos
-- para el cron y para _getActiveChallenge().
with duplicados as (
  select
    id,
    row_number() over (
      partition by user_id
      order by start_date desc, id desc
    ) as orden
  from public.user_challenges
  where status = 'enProgreso'
)
update public.user_challenges uc
set status = 'pausado'
from duplicados d
where uc.id = d.id
  and d.orden > 1;

-- Garantía real: a partir de aquí, la base de datos rechaza cualquier
-- segundo insert/update que deje a un usuario con dos filas 'enProgreso'
-- a la vez, venga de donde venga (cliente, cron, admin, lo que sea).
create unique index if not exists user_challenges_un_activo_por_usuario
  on public.user_challenges (user_id)
  where status = 'enProgreso';
