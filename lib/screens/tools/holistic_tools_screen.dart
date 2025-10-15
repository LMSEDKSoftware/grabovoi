import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HolisticToolsScreen extends StatelessWidget {
  const HolisticToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Herramientas Holísticas'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildToolCard(
            context,
            icon: Icons.air,
            title: 'Ejercicios de Respiración',
            description: 'Técnicas de respiración consciente para calmar la mente',
            color: const Color(0xFF88C4A8),
            onTap: () => context.push('/tools/breathing'),
          ),
          const SizedBox(height: 12),
          _buildToolCard(
            context,
            icon: Icons.spa,
            title: 'Yoga Suave',
            description: 'Posturas y estiramientos para conectar cuerpo y mente',
            color: const Color(0xFFC488A8),
            onTap: () {
              // TODO: Implementar pantalla de yoga
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Próximamente')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildToolCard(
            context,
            icon: Icons.format_quote,
            title: 'Afirmaciones Diarias',
            description: 'Mensajes positivos para fortalecer tu intención',
            color: const Color(0xFFA888C4),
            onTap: () => _showAffirmationsDialog(context),
          ),
          const SizedBox(height: 12),
          _buildToolCard(
            context,
            icon: Icons.music_note,
            title: 'Sonidos Relajantes',
            description: 'Ambientes sonoros para meditación y relajación',
            color: const Color(0xFFC4A888),
            onTap: () => _showSoundsDialog(context),
          ),
          const SizedBox(height: 12),
          _buildToolCard(
            context,
            icon: Icons.emoji_emotions,
            title: 'Gratitud Diaria',
            description: 'Registra aquello por lo que estás agradecido',
            color: const Color(0xFF88A8C4),
            onTap: () {
              context.push('/journal');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAffirmationsDialog(BuildContext context) {
    final affirmations = [
      'Soy merecedor de todo lo bueno que llega a mi vida',
      'Mis pensamientos crean mi realidad',
      'Atraigo abundancia en todas sus formas',
      'Estoy en perfecto equilibrio y armonía',
      'Mi energía fluye libremente',
      'Confío en el proceso de la vida',
      'Cada día es una nueva oportunidad',
      'Soy amor, soy luz, soy gratitud',
    ];

    final random = DateTime.now().millisecondsSinceEpoch % affirmations.length;
    final affirmation = affirmations[random];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Afirmación del día'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              affirmation,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showSoundsDialog(BuildContext context) {
    final sounds = [
      {'name': 'Lluvia', 'icon': Icons.water_drop},
      {'name': 'Océano', 'icon': Icons.waves},
      {'name': 'Bosque', 'icon': Icons.forest},
      {'name': 'Viento', 'icon': Icons.air},
      {'name': 'Fuego', 'icon': Icons.local_fire_department},
      {'name': 'Campanas', 'icon': Icons.notifications},
      {'name': 'Cuencos Tibetanos', 'icon': Icons.spa},
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sonidos Relajantes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: sounds.length,
                itemBuilder: (context, index) {
                  final sound = sounds[index];
                  return ListTile(
                    leading: Icon(sound['icon'] as IconData),
                    title: Text(sound['name'] as String),
                    trailing: const Icon(Icons.play_arrow),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reproduciendo ${sound['name']}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

