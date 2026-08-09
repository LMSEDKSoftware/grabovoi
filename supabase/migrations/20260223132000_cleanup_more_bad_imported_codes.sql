-- Cleanup v2: remove additional year-like false positives imported by crawler
-- Limits to recently created rows to avoid touching curated catalog.

delete from public.codigos_grabovoi
where categoria = 'Redes sociales'
  and nombre = 'Secuencia importada'
  and created_at >= (now() - interval '2 days')
  and (
    -- YYYY_MM / YYYY_MM_DD / YYYY_MM_DD_HH
    codigo ~ '^(19|20)\\d{2}(_\\d{2}){1,3}$'
    or
    -- YYYY_YYYY ranges
    codigo ~ '^(19|20)\\d{2}_(19|20)\\d{2}$'
    or
    -- Any code starting with a year-like prefix (common noise in blogs)
    codigo ~ '^(19|20)\\d{2}_\\d{1,4}(_\\d{1,4}){0,2}$'
  );

