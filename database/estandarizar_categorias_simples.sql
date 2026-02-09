-- Estandariza categorías de codigos_grabovoi en grupos simples
-- Ejecutar en Supabase SQL Editor después de cargar los códigos.
-- Grupos: Salud, Crecimiento personal, Energía y vitalidad, Otros

-- 1. Salud (todo lo físico/orgánico)
UPDATE public.codigos_grabovoi
SET categoria = 'Salud', updated_at = now()
WHERE categoria IN (
  'Salud crítica',
  'Tumores',
  'Digestivo',
  'Endocrino',
  'Cardiovascular',
  'Respiratorio',
  'Nervioso',
  'Renal/urinario',
  'Reproductor',
  'Infecciosas',
  'Piel',
  'Músculo-esquelético',
  'Ojos/Oídos',
  'Dolor/Inflamación',
  'Inmunidad'
);

-- 2. Crecimiento personal (emocional/mental)
UPDATE public.codigos_grabovoi
SET categoria = 'Crecimiento personal', updated_at = now()
WHERE categoria = 'Emocional/Mental';

-- 3. Energía y vitalidad
UPDATE public.codigos_grabovoi
SET categoria = 'Energía y vitalidad', updated_at = now()
WHERE categoria = 'Energía/Vitalidad';

-- 4. Otros (se mantiene)
-- WHERE categoria = 'Otros' → no se cambia

-- Ver resultado
SELECT categoria, COUNT(*) AS total
FROM public.codigos_grabovoi
GROUP BY categoria
ORDER BY categoria;
