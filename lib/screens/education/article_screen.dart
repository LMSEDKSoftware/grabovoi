import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ArticleScreen extends StatelessWidget {
  final String articleId;

  const ArticleScreen({super.key, required this.articleId});

  @override
  Widget build(BuildContext context) {
    final article = _getArticle(articleId);

    return Scaffold(
      appBar: AppBar(
        title: Text(article['title'] as String),
      ),
      body: Markdown(
        data: article['content'] as String,
        padding: const EdgeInsets.all(24),
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: Theme.of(context).textTheme.bodyLarge,
          h1: Theme.of(context).textTheme.displaySmall,
          h2: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }

  Map<String, String> _getArticle(String id) {
    final articles = {
      '1': {
        'title': '¿Qué son los códigos Grabovoi?',
        'content': '''
# ¿Qué son los códigos Grabovoi?

Los códigos Grabovoi son secuencias numéricas desarrolladas por Grigori Grabovoi, un matemático ruso que propuso que ciertos números contienen frecuencias vibracionales específicas.

## Origen

Grigori Grabovoi desarrolló este sistema en la década de 1990, basándose en conceptos de numerología, radiestesia y sus propias teorías sobre la realidad.

## Funcionamiento propuesto

Según Grabovoi:
- Cada número tiene una vibración única
- Las secuencias numéricas pueden influir en la realidad
- La concentración en estos números activa procesos de armonización

## Perspectiva científica

**Es importante destacar que:**
- No existe evidencia científica que respalde estos conceptos
- Se considera una práctica pseudocientífica
- No debe usarse como sustituto de tratamiento médico

## Uso responsable

Si decides explorar esta práctica:
- Úsala como complemento, nunca como reemplazo de atención médica
- Mantén expectativas realistas
- Combínala con prácticas de bienestar comprobadas
- Consulta profesionales para problemas de salud

La práctica puede tener valor como herramienta de enfoque y meditación, independientemente de las afirmaciones sobre sus efectos específicos.
''',
      },
      '2': {
        'title': 'Práctica consciente y responsable',
        'content': '''
# Práctica consciente y responsable

Esta guía te ayudará a usar los códigos Grabovoi de forma equilibrada y consciente.

## Principios fundamentales

### 1. Complemento, no reemplazo
Los códigos Grabovoi no sustituyen:
- Atención médica profesional
- Medicamentos prescritos
- Terapia psicológica
- Asesoramiento financiero

### 2. Expectativas realistas
- No esperes resultados mágicos o instantáneos
- La práctica requiere constancia y paciencia
- Los cambios reales requieren acción concreta

### 3. Enfoque holístico
Combina esta práctica con:
- Hábitos saludables
- Ejercicio regular
- Alimentación equilibrada
- Descanso adecuado
- Gestión del estrés

## Cómo practicar

1. **Elige tu momento**: Encuentra un tiempo tranquilo
2. **Crea ambiente**: Espacio calmado y sin interrupciones
3. **Enfoca tu intención**: Claridad en lo que buscas
4. **Repite conscientemente**: Con atención y presencia
5. **Registra tu experiencia**: Lleva un diario

## Señales de alarma

Deja de usar esta práctica si:
- Te aíslas socialmente
- Descuidas responsabilidades
- Ignoras problemas reales
- Gastas más de lo razonable
- Rechazas ayuda profesional necesaria

Recuerda: el verdadero bienestar viene de un equilibrio entre cuerpo, mente y acción consciente.
''',
      },
      // Agregar más artículos según sea necesario
    };

    return articles[id] ?? {
      'title': 'Artículo no encontrado',
      'content': '# Artículo no disponible\n\nEste artículo aún no está disponible.',
    };
  }
}

