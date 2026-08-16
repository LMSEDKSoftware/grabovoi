-- Aplica la propuesta del audit "Colores por Categoria" (ver conversacion,
-- Artifact "Colores por Categoria"): cada categoria pasa a tener un color
-- unico -- necesario porque las portadas de Roku se generan una por color
-- (si dos categorias comparten hex, comparten portada). Las 8 categorias
-- ya correctas (Salud, Abundancia, Amor, Manifestacion, Proteccion,
-- Limpieza, Liberacion, Conciencia) no se tocan.

update public.codigos_grabovoi set color = '#DA70D6' where categoria = 'Transformación';
update public.codigos_grabovoi set color = '#FF7F50' where categoria = 'Emociones';
update public.codigos_grabovoi set color = '#2E8B57' where categoria = 'Crecimiento';
update public.codigos_grabovoi set color = '#708090' where categoria = 'Avanzados';
update public.codigos_grabovoi set color = '#5F9EA0' where categoria = 'Medio Ambiente';
update public.codigos_grabovoi set color = '#00FFFF' where categoria = 'Expansión';
update public.codigos_grabovoi set color = '#CD7F32' where categoria = 'Éxito';
update public.codigos_grabovoi set color = '#E6E6FA' where categoria = 'Espiritualidad';
update public.codigos_grabovoi set color = '#7FFFD4' where categoria = 'Armonía';
update public.codigos_grabovoi set color = '#A9A9A9' where categoria = 'Otros';
update public.codigos_grabovoi set color = '#B0E0E6' where categoria = 'Idiomas';
update public.codigos_grabovoi set color = '#4B0082' where categoria = 'Mental';
update public.codigos_grabovoi set color = '#FA8072' where categoria = 'Relaciones';
