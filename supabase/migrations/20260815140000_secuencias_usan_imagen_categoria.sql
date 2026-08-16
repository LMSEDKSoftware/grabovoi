-- Las portadas individuales por secuencia (una por codigo) se veian muy
-- repetitivas en la grilla de Roku (mismo fondo + logo/texto horneado
-- repetido en cada tarjeta, ver conversacion) y ademas la mayoria de
-- filas nunca tuvo una generada (solo una prueba, fallback a rectangulo
-- de color solido). Se reemplaza: todas las secuencias de una misma
-- categoria pasan a compartir la imagen de su categoria (generada sin
-- logo, ver scripts/generar_imagenes_categorias.py) -- SequenceCard.brs
-- ya dibuja titulo y codigo como texto encima, asi que no hace falta una
-- imagen distinta por secuencia.

update public.codigos_grabovoi c
set imagen_url = ci.imagen_url
from public.categoria_imagenes ci
where c.categoria = ci.categoria
  and (c.imagen_url is distinct from ci.imagen_url);
