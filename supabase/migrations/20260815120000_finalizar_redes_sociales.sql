-- Cierre de "Redes sociales" (categoria mal etiquetada, ver auditoria previa
-- y los 3 agentes de investigacion en grupos A/B/C). De las 49 secuencias
-- que quedaban sin tema identificable, se investigo cada codigo contra
-- fuentes reales (ver Artifact "Investigacion de Codigos"), sin inventar
-- ningun significado: solo se acepta si hay 2+ fuentes independientes
-- (alta confianza) o 1 fuente sin contradiccion (confianza moderada).
--
-- Resultado: 24 sin ninguna fuente confiable (se eliminan, respaldo local
-- en scratchpad/backup_eliminados_redes_sociales.json antes de este DELETE)
-- + 25 con fuente (8 alta + 17 moderada, se renombran y recategorizan).
-- 24 + 25 = 49 = total actual de "Redes sociales" -> la categoria
-- desaparece por completo al aplicar esta migracion.

-- 1) DELETE: sin fuente confiable.
delete from public.codigos_grabovoi
where categoria = 'Redes sociales' and codigo in (
  '432182', '800_1500', '1786514400', '28914075', '187_948_181', '2024_28',
  '2026_14', '212_888_197', '218_49451760', '1481214', '1482182', '467_894',
  '49451760', '494517601', '520_741_889', '5294361', '748_132_148',
  '812_917_513', '814_213_517', '814_513_217', '817_213_514', '9148919',
  '9181419', '963_8114'
);

-- 2) UPDATE: 8 de alta confianza (2+ fuentes independientes).
update public.codigos_grabovoi set nombre = 'Amor', categoria = 'Amor', color = '#FF69B4'
  where categoria = 'Redes sociales' and codigo = '888_412_1289018';
update public.codigos_grabovoi set nombre = 'Amor Romántico', categoria = 'Amor', color = '#FF69B4'
  where categoria = 'Redes sociales' and codigo = '401543512';
update public.codigos_grabovoi set nombre = 'Activación de la Glándula Pineal', categoria = 'Salud', color = '#32CD32'
  where categoria = 'Redes sociales' and codigo = '519_317_819_217';
update public.codigos_grabovoi set nombre = 'Buena Salud', categoria = 'Salud', color = '#32CD32'
  where categoria = 'Redes sociales' and codigo = '80845700';
update public.codigos_grabovoi set nombre = 'Conocimiento del Dinero', categoria = 'Abundancia', color = '#FFD700'
  where categoria = 'Redes sociales' and codigo = '964_986_583';
update public.codigos_grabovoi set nombre = 'Futuro Ideal', categoria = 'Crecimiento', color = '#8338EC'
  where categoria = 'Redes sociales' and codigo = '813_791';
update public.codigos_grabovoi set nombre = 'Fama', categoria = 'Éxito', color = '#FFD700'
  where categoria = 'Redes sociales' and codigo = '8277237';
update public.codigos_grabovoi set nombre = 'Obtener Trabajo Rápidamente', categoria = 'Abundancia', color = '#FFD700'
  where categoria = 'Redes sociales' and codigo = '218_494517601';

-- 3) UPDATE: 17 de confianza moderada (1 fuente sin contradiccion).
update public.codigos_grabovoi set nombre = 'Dinero Inesperado', categoria = 'Abundancia', color = '#FFD700'
  where categoria = 'Redes sociales' and codigo = '520_741';
update public.codigos_grabovoi set nombre = 'Aliviar el Mareo', categoria = 'Salud', color = '#32CD32'
  where categoria = 'Redes sociales' and codigo = '11969751369';
update public.codigos_grabovoi set nombre = 'Atraer Pareja', categoria = 'Amor', color = '#FF69B4'
  where categoria = 'Redes sociales' and codigo = '197_023';
update public.codigos_grabovoi set nombre = 'Cóccix', categoria = 'Salud', color = '#32CD32'
  where categoria = 'Redes sociales' and codigo = '218_312_248_228';
update public.codigos_grabovoi set nombre = 'Crecimiento Rápido de Negocio', categoria = 'Abundancia', color = '#FFD700'
  where categoria = 'Redes sociales' and codigo = '319_512_814';
update public.codigos_grabovoi set nombre = 'Bendiciones Financieras Inesperadas', categoria = 'Abundancia', color = '#FFD700'
  where categoria = 'Redes sociales' and codigo = '419_814_217';
update public.codigos_grabovoi set nombre = 'Trabajo Soñado', categoria = 'Abundancia', color = '#FFD700'
  where categoria = 'Redes sociales' and codigo = '493151_864_1491';
update public.codigos_grabovoi set nombre = 'Lograr Metas Financieras Rápidamente', categoria = 'Abundancia', color = '#FFD700'
  where categoria = 'Redes sociales' and codigo = '518_814_213';
update public.codigos_grabovoi set nombre = 'Normalización de las Relaciones', categoria = 'Emociones', color = '#8338EC'
  where categoria = 'Redes sociales' and codigo = '591_718_9181419';
update public.codigos_grabovoi set nombre = 'Epidermis', categoria = 'Salud', color = '#32CD32'
  where categoria = 'Redes sociales' and codigo = '598_718_889_888';
update public.codigos_grabovoi set nombre = 'Flujo de Dinero Real', categoria = 'Abundancia', color = '#FFD700'
  where categoria = 'Redes sociales' and codigo = '619_714_21841';
update public.codigos_grabovoi set nombre = 'Eliminación de Deudas', categoria = 'Abundancia', color = '#FFD700'
  where categoria = 'Redes sociales' and codigo = '718_916_413';
update public.codigos_grabovoi set nombre = 'Eliminación de Deudas', categoria = 'Abundancia', color = '#FFD700'
  where categoria = 'Redes sociales' and codigo = '891_420_19';
update public.codigos_grabovoi set nombre = 'Salud de Mascotas', categoria = 'Salud', color = '#32CD32'
  where categoria = 'Redes sociales' and codigo = '918_792_189_169';
update public.codigos_grabovoi set nombre = 'Eficiencia de Proyectos', categoria = 'Crecimiento', color = '#8338EC'
  where categoria = 'Redes sociales' and codigo = '981_252_719';
update public.codigos_grabovoi set nombre = 'Salud Ocular', categoria = 'Salud', color = '#32CD32'
  where categoria = 'Redes sociales' and codigo = '189_1014';
update public.codigos_grabovoi set nombre = 'Contacto Espiritual con G. Grabovoi', categoria = 'Espiritualidad', color = '#FFD700'
  where categoria = 'Redes sociales' and codigo = '3582295';
