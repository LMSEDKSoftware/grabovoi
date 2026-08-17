-- ManiGraB TV (Roku): vinculación por código en pantalla + QR.
--
-- Matiz importante frente a lo que dice docs/ROKU_TV_PLAN.md: Roku
-- deprecó el "rendezvous" como ÚNICO método de alta, no como atajo. Lo
-- que exige es que el canal siempre ofrezca iniciar sesión sin salir del
-- dispositivo. Por eso esto convive con roku-login.js (email+password
-- con el teclado nativo), que sigue siendo la opción principal y visible
-- en la misma pantalla; el QR es solo comodidad, igual que lo hace Gaia.
--
-- Flujo: la TV pide un código -> muestra número + QR -> el usuario lo
-- confirma desde el teléfono en /tv -> la TV, que está haciendo polling,
-- recibe el mismo access_token opaco que emite roku-login.

create table if not exists public.roku_device_codes (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  -- Se compara en cada poll: sin esto, cualquiera que adivine un código
  -- de 6 dígitos podría reclamar el token de una TV ajena.
  device_id text not null default '',
  status text not null default 'pending',
  user_id uuid references auth.users(id) on delete cascade,
  access_token text,
  access_token_expires_at timestamptz,
  created_at timestamptz not null default now(),
  linked_at timestamptz,
  expires_at timestamptz not null,
  constraint roku_device_codes_status_check
    check (status in ('pending', 'linked', 'claimed'))
);

comment on table public.roku_device_codes is
  'Códigos temporales para vincular un Roku a una cuenta ManiGraB desde el teléfono (QR). Efímeros: 15 minutos. Ver docs/ROKU_TV_PLAN.md.';

alter table public.roku_device_codes enable row level security;

-- A propósito sin políticas: solo los endpoints de Vercel (service_role)
-- tocan esta tabla. Un usuario autenticado no tiene por qué leer códigos
-- pendientes de otras televisiones.

create index if not exists idx_roku_device_codes_expires
  on public.roku_device_codes(expires_at);

-- Los códigos caducan solos por expires_at; esto solo evita que la tabla
-- crezca para siempre. Se puede colgar de un cron, o llamarse desde los
-- propios endpoints de vez en cuando.
create or replace function public.roku_purgar_codigos_vencidos()
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.roku_device_codes
  where expires_at < now() - interval '1 hour';
$$;
