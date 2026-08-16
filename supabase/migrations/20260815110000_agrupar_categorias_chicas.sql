-- Agrupacion de categorias chicas (ver conversacion): 14 categorias con
-- pocas secuencias se absorben en categorias ya establecidas, revisando
-- nombre/descripcion real de cada una antes de decidir destino. Tambien
-- se resuelve el outlier "Crecimiento de Plantas" (estaba en "Unidad"
-- sin relacion alguna con las otras 2 secuencias de ahi) creando
-- "Medio Ambiente", y se mueven de "Redes sociales" (categoria mal
-- etiquetada, ver auditoria previa) las 15 secuencias con tema
-- identificable hacia Emociones y Abundancia. Las ~49 restantes de
-- "Redes sociales" (genericas sin nombre real, o sin tema claro) NO se
-- tocan aqui -- esas necesitan investigacion contra fuentes reales de
-- codigos Grabovoi antes de renombrarlas, es un paso aparte.

-- 1) Belleza, Peso, Sanación -> Salud
update public.codigos_grabovoi set categoria = 'Salud'
where codigo in ('1489789', '519618718215', '91879481849', '481_214_89', '89471978', '20920605', '719_318_914')
  and categoria in ('Belleza', 'Peso', 'Sanación');

-- 2) Dinero, Empleo, Vivienda -> Abundancia
update public.codigos_grabovoi set categoria = 'Abundancia'
where codigo in ('3657745', '41481888', '5207418', '589317318614', '9798733714615',
                  '518_617219_71', '519714318', '741897', '319612719849', '89471894')
  and categoria in ('Dinero', 'Empleo', 'Vivienda');

-- 3) Espiritual, Maestría -> Espiritualidad
update public.codigos_grabovoi set categoria = 'Espiritualidad'
where codigo in ('35986', '718_819_713', '819_819_714', '819_819_718')
  and categoria in ('Espiritual', 'Maestría');

-- 4) Deportes -> Éxito
update public.codigos_grabovoi set categoria = 'Éxito'
where codigo = '714_21893' and categoria = 'Deportes';

-- 5) Soluciones, Voluntad -> Crecimiento
update public.codigos_grabovoi set categoria = 'Crecimiento'
where codigo in ('69900', '8137142133914', '938179', '714358914')
  and categoria in ('Soluciones', 'Voluntad');

-- 6) Social -> Relaciones
update public.codigos_grabovoi set categoria = 'Relaciones'
where codigo in ('213233530', '498517498317') and categoria = 'Social';

-- 7) Energía se reparte segun el tema real de cada secuencia (no
--    compartian tema entre si)
update public.codigos_grabovoi set categoria = 'Emociones'
where codigo = '7198498' and categoria = 'Energía';

update public.codigos_grabovoi set categoria = 'Espiritualidad'
where codigo = '89471907841' and categoria = 'Energía';

-- 8) General -> Otros
update public.codigos_grabovoi set categoria = 'Otros'
where codigo = '817219738' and categoria = 'General';

-- 9) Unidad: "Mundial"/"Paz mundial" -> Armonía; "Crecimiento de
--    Plantas" era el outlier, resuelto abajo en el punto 10.
update public.codigos_grabovoi set categoria = 'Armonía'
where codigo in ('8196814', '97132185191') and categoria = 'Unidad';

-- 10) Categoria nueva "Medio Ambiente": el outlier "Crecimiento de
--     Plantas" (Unidad) + "Sanación del planeta" (estaba en
--     "Avanzados", sin relacion con las demas secuencias de ahi --
--     unica en toda la base ademas del outlier con tema realmente
--     ecologico/planetario, se reviso descripcion completa de todas
--     las que mencionan tierra/animales/naturaleza/clima antes de
--     elegir estas dos, el resto eran falsos positivos: "Climaterio"
--     no es clima, "Arraigo y conexion a tierra" es grounding
--     espiritual, "Difusion del conocimiento en la Tierra" es
--     "mundialmente" no el planeta).
update public.codigos_grabovoi set categoria = 'Medio Ambiente'
where codigo in ('816273519', '319_714819')
  and categoria in ('Unidad', 'Avanzados');

-- 11) De "Redes sociales" (mal etiquetada, ver auditoria previa): las
--     15 secuencias con tema identificable se mueven a su categoria
--     real. Las ~49 restantes (genericas "Secuencia" sin nombre real, o
--     sueltas sin tema comun) quedan sin tocar -- requieren
--     investigacion contra fuentes reales antes de renombrarlas.
update public.codigos_grabovoi set categoria = 'Emociones'
where categoria = 'Redes sociales' and codigo in (
  '548_317_718_491_48', '519_489_319_12', '498_317_491_46', '891_019_4918808',
  '4894971', '548_49_18917', '489_061_719_88_0618', '519371_818911',
  '614_318171_8914218', '2184_17488901', '121918'
);

update public.codigos_grabovoi set categoria = 'Abundancia'
where categoria = 'Redes sociales' and codigo in (
  '520520', '414818', '4610567', '520741889'
);
