-- Se encontraron 9 filas en codigos_grabovoi (categoría "Redes sociales")
-- cuyo nombre/descripción eran en realidad fragmentos de rutas de imagen o
-- una etiqueta markdown cruda capturados por error durante un scrape roto
-- desde Etsy/Slideshare (ej. "/c/ / / /il/4ec / /il X . Epxj.jpg)" o
-- "![Ana Vaz, Profile Picture](https://cdn.slidesharecdn.com/...").
-- Un caso incluso tenía un "codigo" que no era una secuencia Grabovoi real,
-- sino el parámetro de caché (cb=...) de la URL de una foto de perfil.
--
-- La causa: sanitizeNombreEs() en process-deep-search-queue solo exige que
-- el texto tenga alguna letra ("hasLetters"), y fragmentos como "il", "jpg"
-- o "Epxj" ya cuentan como letras, así que pasaban el filtro. Se corrige
-- también esa función, pero esta es la barrera de última línea: rechaza a
-- nivel de base de datos CUALQUIER inserción/actualización con un nombre
-- que luzca como ruta de archivo, URL o markdown de imagen, sin importar
-- por qué camino (scraper, admin, futuro script) intente entrar.
CREATE OR REPLACE FUNCTION public.enforce_codigos_grabovoi_nombre_valido()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF NEW.nombre IS NULL OR btrim(NEW.nombre) = '' THEN
    RAISE EXCEPTION 'codigos_grabovoi.nombre no puede estar vacío';
  END IF;

  -- Patrones de basura conocidos: rutas de imagen/CDN, markdown de imagen,
  -- extensiones de archivo, o un nombre que empieza como ruta.
  IF NEW.nombre ~* '!\[|\]\(|\.jpe?g\)|\.png\)|\.gif\)|\.webp\)|cdn\.|slidesharecdn|etsystatic|^\s*/[a-z0-9_]+/'
  THEN
    RAISE EXCEPTION 'codigos_grabovoi.nombre luce como una ruta de archivo/URL/markdown, no un título válido: %', NEW.nombre;
  END IF;

  IF NEW.descripcion IS NOT NULL AND NEW.descripcion ~* '!\[|\]\(|\.jpe?g\)|\.png\)|\.gif\)|\.webp\)|slidesharecdn|etsystatic'
  THEN
    RAISE EXCEPTION 'codigos_grabovoi.descripcion luce como una ruta de archivo/URL/markdown, no una descripción válida: %', NEW.descripcion;
  END IF;

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trigger_enforce_codigos_grabovoi_nombre_valido ON public.codigos_grabovoi;
CREATE TRIGGER trigger_enforce_codigos_grabovoi_nombre_valido
  BEFORE INSERT OR UPDATE ON public.codigos_grabovoi
  FOR EACH ROW EXECUTE FUNCTION public.enforce_codigos_grabovoi_nombre_valido();
