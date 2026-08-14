-- Portada (imagen) y video-loop de fondo por secuencia. Generados por
-- scripts/generar_assets_secuencias.py, publicados en el bucket publico
-- `roku` (roku/portadas/<codigo>.jpg, roku/videos_loop/<codigo>.mp4).
-- Reutilizable por app y Roku: son columnas de codigos_grabovoi, no algo
-- especifico de una plataforma.
alter table public.codigos_grabovoi
  add column if not exists imagen_url text,
  add column if not exists video_loop_url text;

notify pgrst, 'reload schema';
