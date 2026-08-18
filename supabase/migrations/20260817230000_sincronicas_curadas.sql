-- Sugerencias sincrónicas, versión híbrida: curaduría manual donde
-- importa + descubrimiento automático para el resto del catálogo.
--
-- Tres cosas en un solo archivo porque son inseparables: sin el mapeo
-- corregido la función no tiene de dónde elegir, y sin la tabla de
-- parejas la función no compila.

-- ---------------------------------------------------------------
-- 1. Parejas curadas
-- ---------------------------------------------------------------
-- 45 secuencias de intención transversal (dinero, trabajo, amor, miedo,
-- ansiedad, autoestima, enfoque, protección...) con 2 sugerencias
-- elegidas a mano cada una. Estas mandan sobre el algoritmo por
-- categoría: donde hay criterio humano, se usa.
--
-- A propósito NO se curaron secuencias médicas concretas: el catálogo
-- tiene cientos de entradas muy específicas de Salud y para una
-- sugerencia general funcionan mejor las intenciones amplias.

create table if not exists public.codigos_sincronicos (
  id uuid primary key default gen_random_uuid(),
  codigo_origen text not null references public.codigos_grabovoi(codigo) on delete cascade,
  codigo_sugerido text not null references public.codigos_grabovoi(codigo) on delete cascade,
  -- 0 se muestra antes que 1; no es prioridad absoluta, solo el orden
  -- en que se ofrecen las dos.
  orden int not null default 0,
  created_at timestamptz not null default now(),
  unique (codigo_origen, codigo_sugerido),
  constraint codigos_sincronicos_no_autoreferencia check (codigo_origen <> codigo_sugerido)
);

comment on table public.codigos_sincronicos is
  'Parejas de secuencias elegidas a mano. Tienen prioridad sobre categorias_sincronicas. Ver la funcion roku_sincronicas.';

alter table public.codigos_sincronicos enable row level security;

-- Lectura publica: es catalogo, igual que codigos_grabovoi. La escritura
-- queda solo para service_role (sin politica de insert/update/delete).
drop policy if exists "codigos_sincronicos_lectura" on public.codigos_sincronicos;
create policy "codigos_sincronicos_lectura" on public.codigos_sincronicos
  for select using (true);

create index if not exists idx_codigos_sincronicos_origen
  on public.codigos_sincronicos(codigo_origen);

-- ---------------------------------------------------------------
-- 2. Mapeo de categorías, reescrito
-- ---------------------------------------------------------------
-- La tabla traía nombres de una versión anterior del catálogo
-- ("Armonización", "Maestría", "Energía", "Empleo", "Manifestacion" sin
-- tilde), asi que 6 de 15 reglas principales no casaban con nada y 12 de
-- las 21 categorías reales no tenían ninguna regla. Se reemplaza entera
-- por un mapeo que cubre las 21, validado nombre por nombre contra
-- codigos_grabovoi antes de escribirlo.
--
-- Ojo: esta tabla la lee tambien la app movil
-- (lib/repositories/codigos_repository.dart), asi que esto arregla las
-- sugerencias en los dos lados.

create table if not exists public.backup_categorias_sincronicas_20260817 as
  select * from public.categorias_sincronicas;

delete from public.categorias_sincronicas;

insert into public.categorias_sincronicas (categoria_principal, categoria_recomendada, peso) values
  ('Salud', 'Limpieza', 5),
  ('Salud', 'Emociones', 4),
  ('Salud', 'Liberación', 3),
  ('Salud', 'Protección', 2),
  ('Salud', 'Armonía', 1),
  ('Abundancia', 'Éxito', 5),
  ('Abundancia', 'Manifestación', 4),
  ('Abundancia', 'Crecimiento', 3),
  ('Abundancia', 'Mental', 2),
  ('Abundancia', 'Conciencia', 1),
  ('Amor', 'Relaciones', 5),
  ('Amor', 'Emociones', 4),
  ('Amor', 'Liberación', 3),
  ('Amor', 'Armonía', 2),
  ('Amor', 'Conciencia', 1),
  ('Protección', 'Limpieza', 5),
  ('Protección', 'Armonía', 4),
  ('Protección', 'Conciencia', 3),
  ('Protección', 'Liberación', 2),
  ('Protección', 'Espiritualidad', 1),
  ('Conciencia', 'Espiritualidad', 5),
  ('Conciencia', 'Expansión', 4),
  ('Conciencia', 'Mental', 3),
  ('Conciencia', 'Liberación', 2),
  ('Conciencia', 'Avanzados', 1),
  ('Crecimiento', 'Mental', 5),
  ('Crecimiento', 'Éxito', 4),
  ('Crecimiento', 'Emociones', 3),
  ('Crecimiento', 'Conciencia', 2),
  ('Crecimiento', 'Liberación', 1),
  ('Emociones', 'Liberación', 5),
  ('Emociones', 'Amor', 4),
  ('Emociones', 'Armonía', 3),
  ('Emociones', 'Mental', 2),
  ('Emociones', 'Conciencia', 1),
  ('Avanzados', 'Conciencia', 5),
  ('Avanzados', 'Expansión', 4),
  ('Avanzados', 'Espiritualidad', 3),
  ('Avanzados', 'Manifestación', 2),
  ('Avanzados', 'Transformación', 1),
  ('Liberación', 'Emociones', 5),
  ('Liberación', 'Limpieza', 4),
  ('Liberación', 'Transformación', 3),
  ('Liberación', 'Conciencia', 2),
  ('Liberación', 'Armonía', 1),
  ('Limpieza', 'Liberación', 5),
  ('Limpieza', 'Protección', 4),
  ('Limpieza', 'Armonía', 3),
  ('Limpieza', 'Conciencia', 2),
  ('Limpieza', 'Espiritualidad', 1),
  ('Expansión', 'Conciencia', 5),
  ('Expansión', 'Espiritualidad', 4),
  ('Expansión', 'Manifestación', 3),
  ('Expansión', 'Crecimiento', 2),
  ('Expansión', 'Avanzados', 1),
  ('Éxito', 'Crecimiento', 5),
  ('Éxito', 'Abundancia', 4),
  ('Éxito', 'Mental', 3),
  ('Éxito', 'Manifestación', 2),
  ('Éxito', 'Conciencia', 1),
  ('Relaciones', 'Amor', 5),
  ('Relaciones', 'Emociones', 4),
  ('Relaciones', 'Armonía', 3),
  ('Relaciones', 'Liberación', 2),
  ('Relaciones', 'Crecimiento', 1),
  ('Espiritualidad', 'Conciencia', 5),
  ('Espiritualidad', 'Expansión', 4),
  ('Espiritualidad', 'Armonía', 3),
  ('Espiritualidad', 'Protección', 2),
  ('Espiritualidad', 'Manifestación', 1),
  ('Mental', 'Crecimiento', 5),
  ('Mental', 'Emociones', 4),
  ('Mental', 'Conciencia', 3),
  ('Mental', 'Éxito', 2),
  ('Mental', 'Liberación', 1),
  ('Transformación', 'Liberación', 5),
  ('Transformación', 'Crecimiento', 4),
  ('Transformación', 'Conciencia', 3),
  ('Transformación', 'Expansión', 2),
  ('Transformación', 'Manifestación', 1),
  ('Armonía', 'Emociones', 5),
  ('Armonía', 'Relaciones', 4),
  ('Armonía', 'Limpieza', 3),
  ('Armonía', 'Conciencia', 2),
  ('Armonía', 'Espiritualidad', 1),
  ('Manifestación', 'Éxito', 5),
  ('Manifestación', 'Crecimiento', 4),
  ('Manifestación', 'Conciencia', 3),
  ('Manifestación', 'Abundancia', 2),
  ('Manifestación', 'Expansión', 1),
  ('Otros', 'Crecimiento', 5),
  ('Otros', 'Protección', 4),
  ('Otros', 'Liberación', 3),
  ('Medio Ambiente', 'Armonía', 5),
  ('Medio Ambiente', 'Protección', 4),
  ('Medio Ambiente', 'Conciencia', 3),
  ('Medio Ambiente', 'Espiritualidad', 2),
  ('Idiomas', 'Crecimiento', 5),
  ('Idiomas', 'Mental', 4),
  ('Idiomas', 'Éxito', 3);

insert into public.codigos_sincronicos (codigo_origen, codigo_sugerido, orden) values
  ('318', '519_481', 0),
  ('318', '714_814_718_91', 1),
  ('520', '520741889', 0),
  ('520', '519_481', 1),
  ('520741889', '520', 0),
  ('520741889', '9798733714615', 1),
  ('519_481', '719_481_219_81', 0),
  ('519_481', '719_481_315', 1),
  ('3657745', '4812412', 0),
  ('3657745', '318', 1),
  ('4812412', '418_719_814_19', 0),
  ('4812412', '318', 1),
  ('719_491_214', '714_219_819', 0),
  ('719_491_214', '913_714_819', 1),
  ('714_219_718', '4931518641491', 0),
  ('714_219_718', '741897', 1),
  ('4931518641491', '519714318', 0),
  ('4931518641491', '812_719_481', 1),
  ('318514517', '814_719_481', 0),
  ('318514517', '714_819_481', 1),
  ('591', '814_719_481', 0),
  ('591', '318514517', 1),
  ('813_719_814_19', '918_719_814', 0),
  ('813_719_814_19', '319_512_814', 1),
  ('518_719_813', '519_714_812', 0),
  ('518_719_813', '719_481_315', 1),
  ('9798733714615', '59148861109871', 0),
  ('9798733714615', '318', 1),
  ('719_481_315', '914_719_714', 0),
  ('719_481_315', '548_748_978', 1),
  ('811', '719_481_315', 0),
  ('811', '813_791', 1),
  ('914_719_714', '714358914', 0),
  ('914_719_714', '548_748_978', 1),
  ('401543512', '519606', 0),
  ('401543512', '718_714_819_91', 1),
  ('519606', '814_418_719', 0),
  ('519606', '715_819', 1),
  ('197_023', '715_819', 0),
  ('197_023', '814_418_719', 1),
  ('715_819', '713_819_814_91', 0),
  ('715_819', '718_714_819_91', 1),
  ('819_814_719_81', '49181951749814', 0),
  ('819_814_719_81', '517489719841', 1),
  ('918_794_818_21', '819_714_819_81', 0),
  ('918_794_818_21', '814_419_719', 1),
  ('7199719', '3856794', 0),
  ('7199719', '814_419_719', 1),
  ('3856794', '706', 0),
  ('3856794', '814_419_719', 1),
  ('3197148', '498517498317', 0),
  ('3197148', '7147148', 1),
  ('49181951749814', '819_814_719_81', 0),
  ('49181951749814', '517489719841', 1),
  ('517489719841', '49181951749814', 0),
  ('517489719841', '714358914', 1),
  ('51941671481', '713_819_814', 0),
  ('51941671481', '121918', 1),
  ('719_741_214', '489_712_819_48', 0),
  ('719_741_214', '121918', 1),
  ('213_819', '148_721_481', 0),
  ('213_819', '814_819_718_81', 1),
  ('61881971', '148_721_481', 0),
  ('61881971', '819_819_713_81', 1),
  ('444_666_888_999', '121918', 0),
  ('444_666_888_999', '41781971981', 1),
  ('706', '718_913_819_81', 0),
  ('706', '814_819_714_91', 1),
  ('819_718_913_81', '591061718_489', 0),
  ('819_718_913_81', '991_819_214', 1),
  ('591061718_489', '548491698719', 0),
  ('591061718_489', '819_718_913_81', 1),
  ('814_819_714_91', '61_988_184_161', 0),
  ('814_819_714_91', '14111963', 1),
  ('814_819_718_81', '41781971981', 0),
  ('814_819_718_81', '148_721_481', 1),
  ('212888197', '4588623', 0),
  ('212888197', '61971421841', 1),
  ('4588623', '548_748_978', 0),
  ('4588623', '417584217', 1),
  ('714358914', '914_719_714', 0),
  ('714358914', '548_748_978', 1),
  ('813_791', '14854232190', 0),
  ('813_791', '719_481_71', 1),
  ('719_481_71', '59148861109871', 0),
  ('719_481_71', '519_714_812', 1),
  ('59148861109871', '823494781572954', 0),
  ('59148861109871', '719_481_315', 1),
  ('881881881', '8881111', 0),
  ('881881881', '714_813_814_91', 1);


-- ---------------------------------------------------------------
-- 3. La función, ahora en tres niveles
-- ---------------------------------------------------------------
-- Orden: pareja curada -> categoría recomendada por peso -> misma
-- categoría. El nivel 3 existe porque una secuencia siempre debe poder
-- ofrecer algo, aunque su categoría se quede sin reglas en el futuro.

drop function if exists public.roku_sincronicas(text, uuid, int);

create or replace function public.roku_sincronicas(
  p_categoria text,
  p_excluir uuid default null,
  p_limite int default 2,
  p_codigo text default null
)
returns table (id uuid, codigo text, nombre text, categoria text)
-- volatile, no stable: usa random() y debe dar algo distinto en cada
-- llamada. Con stable el planner podría cachear el resultado dentro de
-- una misma consulta y volveríamos al problema original, que era
-- justamente que las sugerencias nunca cambiaban.
language sql
volatile
as $$
  with curadas as (
    select c.id, c.codigo, c.nombre, c.categoria,
           0 as prioridad, s.orden as rn, 0 as peso
      from public.codigos_sincronicos s
      join public.codigos_grabovoi c on c.codigo = s.codigo_sugerido
     where p_codigo is not null
       and s.codigo_origen = p_codigo
       and (p_excluir is null or c.id <> p_excluir)
  ),
  recomendadas as (
    select s.categoria_recomendada, s.peso
      from public.categorias_sincronicas s
     where s.categoria_principal = p_categoria
       and s.categoria_recomendada <> p_categoria
       -- Defensa contra el error que motivó todo esto: si alguien vuelve
       -- a meter una categoría que no existe, la regla se ignora en vez
       -- de traducirse en cero sugerencias.
       and exists (
         select 1 from public.codigos_grabovoi c
          where c.categoria = s.categoria_recomendada
       )
  ),
  por_categoria as (
    select c.id, c.codigo, c.nombre, c.categoria,
           1 as prioridad,
           row_number() over (partition by c.categoria order by random())::int as rn,
           r.peso
      from public.codigos_grabovoi c
      join recomendadas r on r.categoria_recomendada = c.categoria
     where c.nombre is not null
       and (p_excluir is null or c.id <> p_excluir)
  ),
  respaldo as (
    select c.id, c.codigo, c.nombre, c.categoria,
           2 as prioridad,
           row_number() over (order by random())::int as rn,
           0 as peso
      from public.codigos_grabovoi c
     where c.categoria = p_categoria
       and c.nombre is not null
       and (p_excluir is null or c.id <> p_excluir)
  ),
  todas as (
    select * from curadas
    union all select * from por_categoria
    union all select * from respaldo
  ),
  -- Una secuencia puede aparecer en dos niveles a la vez; se queda con
  -- el mejor y así nunca sale repetida en las dos tarjetas.
  unicas as (
    select distinct on (t.id) t.id, t.codigo, t.nombre, t.categoria, t.prioridad, t.rn, t.peso
      from todas t
     order by t.id, t.prioridad, t.rn
  )
  select u.id, u.codigo, u.nombre, u.categoria
    from unicas u
   -- rn antes que peso: agota una de cada categoría recomendada (la de
   -- más peso primero) antes de repetir categoría, para que las dos
   -- sugerencias salgan de categorías distintas siempre que se pueda.
   order by u.prioridad, u.rn, u.peso desc, random()
   limit p_limite;
$$;

comment on function public.roku_sincronicas is
  'Sugerencias al terminar una secuencia, en tres niveles: pareja curada (codigos_sincronicos), categoria afin por peso (categorias_sincronicas), y misma categoria como respaldo. Nunca sugiere la recien escuchada. Ver roku-complete.js.';
