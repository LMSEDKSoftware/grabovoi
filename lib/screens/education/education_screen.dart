import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Educación'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDisclaimerCard(context),
          const SizedBox(height: 16),
          Text(
            'Artículos y recursos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _buildArticleCard(
            context,
            id: '1',
            title: '¿Qué son los códigos Grabovoi?',
            description: 'Introducción a las secuencias numéricas y su origen',
            category: 'Fundamentos',
          ),
          _buildArticleCard(
            context,
            id: '2',
            title: 'Práctica consciente y responsable',
            description: 'Cómo usar esta herramienta de forma equilibrada',
            category: 'Práctica',
          ),
          _buildArticleCard(
            context,
            id: '3',
            title: 'Numerología y manifestación',
            description: 'Explorando el significado de los números',
            category: 'Numerología',
          ),
          _buildArticleCard(
            context,
            id: '4',
            title: 'Meditación y visualización',
            description: 'Técnicas para potenciar tu práctica',
            category: 'Técnicas',
          ),
          _buildArticleCard(
            context,
            id: '5',
            title: 'Bienestar holístico',
            description: 'Integrando cuerpo, mente y espíritu',
            category: 'Bienestar',
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Información importante',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Los códigos Grabovoi son una práctica espiritual sin respaldo científico. '
              'Esta aplicación es una herramienta de bienestar complementaria y no sustituye '
              'el consejo, diagnóstico o tratamiento médico profesional. '
              'Si tienes problemas de salud, consulta siempre con un profesional calificado.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(
    BuildContext context, {
    required String id,
    required String title,
    required String description,
    required String category,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.article,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(description),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => context.push('/education/$id'),
      ),
    );
  }
}

