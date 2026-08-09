-- Cleanup: remove obvious date-like false positives imported by crawler
-- Only removes rows recently created, in categoria "Redes sociales" and nombre "Secuencia importada".

delete from public.codigos_grabovoi
where categoria = 'Redes sociales'
  and nombre = 'Secuencia importada'
  and created_at >= (now() - interval '2 days')
  and codigo ~ '^(19|20)\\d{2}(_\\d{2}){1,3}$';

