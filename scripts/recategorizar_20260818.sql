-- Recategorización del 18 de agosto de 2026. YA EJECUTADA en producción.
-- Respaldo previo: public.backup_categorias_20260818.
--
-- "Crecimiento" se había convertido en un cajón de sastre: de sus 40
-- secuencias, 25 no eran de crecimiento personal sino adicciones,
-- condiciones clínicas, estados emocionales o idiomas. Como Crecimiento
-- y Mental son de las categorías que más recomienda el motor de
-- sincrónicas, esa mezcla se amplificaba: al terminar una secuencia de
-- aprendizaje de idiomas, el sistema ofrecía "Psicosis alcohólica".
--
-- Criterio, explícito por si hay que discutirlo:
--   adicciones y cuadros clínicos -> Salud
--   estados emocionales            -> Emociones
--   idiomas                        -> Idiomas
--   enfoque, memoria, voluntad     -> Mental
--   vínculos con otras personas    -> Relaciones
--   se quedan en Crecimiento: aprendizaje, creatividad y capacidades

create table if not exists public.backup_categorias_20260818 as
  select id, codigo, nombre, categoria from public.codigos_grabovoi;

-- Adicciones
update public.codigos_grabovoi set categoria = 'Salud' where codigo in (
  '528419_319718_23',      -- Abstinencia de alcohol y drogas
  '148543292',             -- Abuso de alcohol
  '148543292317_914',      -- Alcoholismo crónico
  '148543292_528',         -- Alcoholismo sintomático
  '1414551',               -- Dejar de fumar
  '5333353',               -- Dependencia química
  '49819_491_89',          -- Embriaguez ocasional
  '518_712618_44',         -- Narcomanía
  '148543292_5194_5194'    -- Prevención de adicción (alcohol/drogas)
);

-- Cuadros clínicos
update public.codigos_grabovoi set categoria = 'Salud' where codigo in (
  '481854383',             -- Demencia / psicosis senil
  '11423519',              -- Psicosis alcohólica
  '548764319_017',         -- Enfermedades psicológicas (general)
  '514218557',             -- Bipolaridad
  '514284538',             -- Insomnio
  '8142543'                -- Compulsión
);

-- Estados emocionales
update public.codigos_grabovoi set categoria = 'Emociones' where codigo in (
  '51949131948',           -- Ansiedad
  '519514_318991',         -- Depresión
  '891_619_4918808',       -- Fobia / ansiedad
  '528471_228911'          -- Agresión
);

-- Idiomas: la categoría existía con UNA sola secuencia ("Aprender
-- inglés") mientras sus dos hermanas estaban en Crecimiento.
update public.codigos_grabovoi set categoria = 'Idiomas' where codigo in (
  '96624756378',           -- Aprender idiomas rápidamente
  '5843718986419'          -- Aprendizaje de idiomas extranjeros
);

-- Enfoque, memoria y voluntad: es lo que ya significaba Mental en este
-- catálogo (claridad, decisiones, gestión), no "salud mental".
update public.codigos_grabovoi set categoria = 'Mental' where codigo in (
  '4588623',               -- Enfoque y atención plena
  '548_748_978',           -- Enfoque y determinación
  '714358914',             -- Fuerza de voluntad
  '3542888',               -- Fuerza de Voluntad
  '814_591_719',           -- Mejorar memoria
  '417584217',             -- Memoria y enfoque
  '69900'                  -- Solución rápida de problemas
);

-- Vínculos con otras personas
update public.codigos_grabovoi set categoria = 'Relaciones' where codigo in (
  '888_412_12848',         -- Desarrollo de relaciones
  '8137142133914'          -- Solución para problemas sociales
);

update public.codigos_grabovoi set categoria = 'Protección' where codigo = '938179';       -- Ayuda rápida de emergencia
update public.codigos_grabovoi set categoria = 'Manifestación' where codigo = '813_791';   -- Futuro Ideal

-- Las 18 descripciones de relleno ("Secuencia importada desde fuentes
-- externas") se vacían en vez de inventarles texto: el nombre ya dice
-- qué es cada una, y el relleno le decía al usuario que no sabemos de
-- dónde salió.
update public.codigos_grabovoi
   set descripcion = ''
 where descripcion like 'Secuencia importada%';
