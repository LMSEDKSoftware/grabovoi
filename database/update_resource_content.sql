-- Script para actualizar el contenido del primer recurso con formato HTML correcto
-- Ejecutar este script en el SQL Editor de Supabase

UPDATE public.resources
SET content = '<p>Los números de Grabovoi son secuencias numéricas específicas diseñadas por el científico ruso Grigori Grabovoi para ayudar en la manifestación y sanación. Cada número tiene un propósito único y puede ser utilizado a través de la visualización, repetición o meditación.</p>

<p><b>¿Cómo funcionan?</b></p>

<p>Los números de Grabovoi actúan como códigos de programación para la realidad. Cuando los visualizas o repites, estás enviando una señal específica al campo cuántico que puede influir en la manifestación de tus deseos.</p>

<p><b>Métodos de uso:</b></p>

<ol>
<li><b>Visualización</b>: Visualiza el número en tu mente durante 5-10 minutos al día</li>
<li><b>Repetición</b>: Repite el número mentalmente o en voz alta</li>
<li><b>Meditación</b>: Incorpora el número en tu práctica meditativa</li>
<li><b>Escritura</b>: Escribe el número varias veces en un papel</li>
</ol>

<p><b>Ejemplo práctico:</b></p>

<p>El número 5197148 es conocido como el código de armonización. Puedes usarlo cuando sientas desequilibrio emocional o necesites restaurar la armonía en tu vida.</p>

<p><b>Consejos importantes:</b></p>

<ul>
<li>Sé consistente: usa el número diariamente durante al menos 21 días</li>
<li>Mantén una intención clara mientras trabajas con el número</li>
<li>Confía en el proceso y permite que la manifestación ocurra naturalmente</li>
<li>Combina el uso de números con otras prácticas espirituales para mejores resultados</li>
</ul>',
    updated_at = NOW()
WHERE title = 'Introducción a los Números de Grabovoi';

-- Verificar que se actualizó correctamente
SELECT title, LEFT(content, 100) as content_preview, updated_at 
FROM public.resources 
WHERE title = 'Introducción a los Números de Grabovoi';

