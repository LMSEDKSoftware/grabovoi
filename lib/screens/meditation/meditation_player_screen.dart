import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/meditation_provider.dart';
import '../../providers/auth_provider.dart';

class MeditationPlayerScreen extends StatefulWidget {
  final String meditationId;

  const MeditationPlayerScreen({
    super.key,
    required this.meditationId,
  });

  @override
  State<MeditationPlayerScreen> createState() => _MeditationPlayerScreenState();
}

class _MeditationPlayerScreenState extends State<MeditationPlayerScreen> {
  final TextEditingController _notesController = TextEditingController();
  int _rating = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeditationProvider>().startMeditation(widget.meditationId);
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _completeMeditation() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.getUserId();
    
    await context.read<MeditationProvider>().stopMeditation(
      userId: userId,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      rating: _rating,
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meditación'),
      ),
      body: Consumer<MeditationProvider>(
        builder: (context, provider, _) {
          final meditation = provider.currentMeditation;
          
          if (meditation == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(meditation.title, meditation.durationMinutes),
                const SizedBox(height: 32),
                _buildVisualization(),
                const SizedBox(height: 32),
                _buildControls(provider),
                const SizedBox(height: 32),
                _buildScript(meditation.scriptText),
                const SizedBox(height: 32),
                _buildCompletionSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String title, int duration) {
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.displaySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '$duration minutos',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualization() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.3),
            Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(
          Icons.self_improvement,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildControls(MeditationProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 48,
          icon: Icon(
            provider.isPlaying ? Icons.pause_circle : Icons.play_circle,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () {
            if (provider.isPlaying) {
              provider.pauseMeditation();
            } else {
              provider.resumeMeditation();
            }
          },
        ),
        const SizedBox(width: 24),
        IconButton(
          iconSize: 48,
          icon: Icon(
            Icons.stop_circle,
            color: Theme.of(context).colorScheme.secondary,
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Detener meditación'),
                content: const Text('¿Quieres detener la meditación?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _completeMeditation();
                    },
                    child: const Text('Detener'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildScript(String? scriptText) {
    if (scriptText == null || scriptText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guía de la meditación',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              scriptText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Al finalizar',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              '¿Cómo te sentiste?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                hintText: 'Comparte tus reflexiones...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _completeMeditation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Completar meditación'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

