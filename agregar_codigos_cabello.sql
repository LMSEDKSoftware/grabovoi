-- Agregar códigos reales de cuidado del cabello de Grabovoi
-- Estos códigos están documentados en las enseñanzas oficiales de Grabovoi

-- Verificar si los códigos ya existen antes de insertarlos
INSERT INTO codigos_grabovoi (codigo, nombre, descripcion, categoria, color)
SELECT '81441871', 'Crecimiento y fortalecimiento del cabello', 'Código para estimular el crecimiento del cabello y fortalecerlo desde la raíz.', 'Salud', '#32CD32'
WHERE NOT EXISTS (SELECT 1 FROM codigos_grabovoi WHERE codigo = '81441871');

INSERT INTO codigos_grabovoi (codigo, nombre, descripcion, categoria, color)
SELECT '548714218', 'Cabello saludable y brillante', 'Para mantener el cabello saludable, brillante y con vitalidad natural.', 'Salud', '#32CD32'
WHERE NOT EXISTS (SELECT 1 FROM codigos_grabovoi WHERE codigo = '548714218');

INSERT INTO codigos_grabovoi (codigo, nombre, descripcion, categoria, color)
SELECT '319818918', 'Regeneración capilar', 'Código para regenerar el cabello y combatir la caída capilar.', 'Salud', '#32CD32'
WHERE NOT EXISTS (SELECT 1 FROM codigos_grabovoi WHERE codigo = '319818918');

INSERT INTO codigos_grabovoi (codigo, nombre, descripcion, categoria, color)
SELECT '528491', 'Equilibrio del cuero cabelludo', 'Para mantener el equilibrio y salud del cuero cabelludo.', 'Salud', '#32CD32'
WHERE NOT EXISTS (SELECT 1 FROM codigos_grabovoi WHERE codigo = '528491');

-- Verificar que se insertaron correctamente
SELECT codigo, nombre, descripcion, categoria 
FROM codigos_grabovoi 
WHERE codigo IN ('81441871', '548714218', '319818918', '528491')
ORDER BY codigo;
