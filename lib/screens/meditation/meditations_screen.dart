import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/meditation_provider.dart';
import '../../models/meditation.dart';

class MeditationsScreen extends StatefulWidget {
  const MeditationsScreen({super.key});

  @override
  State<MeditationsScreen> createState() => _MeditationsScreenState();
}

class _MeditationsScreenState extends State<MeditationsScreen> {
  String? _selectedType;
  int? _maxDuration;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeditationProvider>().loadMeditations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meditaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickAccessSection(),
          Expanded(
            child: Consumer<MeditationProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                var meditations = provider.meditations;
                
                if (_selectedType != null) {
                  meditations = meditations
                      .where((m) => m.type == _selectedType)
                      .toList();
                }
                
                if (_maxDuration != null) {
                  meditations = meditations
                      .where((m) => m.durationMinutes <= _maxDuration!)
                      .toList();
                }

                if (meditations.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron meditaciones'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: meditations.length,
                  itemBuilder: (context, index) {
                    return _buildMeditationCard(meditations[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acceso rápido',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickAccessChip('5 min', () {
                  setState(() {
                    _maxDuration = 5;
                    _selectedType = null;
                  });
                }),
                const SizedBox(width: 8),
                _buildQuickAccessChip('Respiración', () {
                  setState(() {
                    _selectedType = 'respiracion';
                    _maxDuration = null;
                  });
                }),
                const SizedBox(width: 8),
                _buildQuickAccessChip('Guiada', () {
                  setState(() {
                    _selectedType = 'guiada';
                    _maxDuration = null;
                  });
                }),
                const SizedBox(width: 8),
                _buildQuickAccessChip('Pilotaje', () {
                  setState(() {
                    _selectedType = 'pilotaje';
                    _maxDuration = null;
                  });
                }),
                const SizedBox(width: 8),
                _buildQuickAccessChip('Todos', () {
                  setState(() {
                    _selectedType = null;
                    _maxDuration = null;
                  });
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessChip(String label, VoidCallback onTap) {
    final isSelected = (_maxDuration == 5 && label == '5 min') ||
        (_selectedType == 'respiracion' && label == 'Respiración') ||
        (_selectedType == 'guiada' && label == 'Guiada') ||
        (_selectedType == 'pilotaje' && label == 'Pilotaje') ||
        (_selectedType == null && _maxDuration == null && label == 'Todos');

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildMeditationCard(Meditation meditation) {
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
            _getIconForType(meditation.type),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          meditation.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(meditation.description, maxLines: 2),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer, size: 16, 
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                const SizedBox(width: 4),
                Text('${meditation.durationMinutes} min'),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(meditation.difficulty),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    meditation.difficulty,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.play_circle_outline, size: 32),
        onTap: () => context.push('/meditations/${meditation.id}'),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'guiada':
        return Icons.self_improvement;
      case 'respiracion':
        return Icons.air;
      case 'visualizacion':
        return Icons.visibility;
      case 'pilotaje':
        return Icons.explore;
      default:
        return Icons.spa;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'principiante':
        return Colors.green;
      case 'intermedio':
        return Colors.orange;
      case 'avanzado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar meditaciones'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tipo:'),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Guiada'),
                  selected: _selectedType == 'guiada',
                  onSelected: (selected) {
                    setState(() => _selectedType = selected ? 'guiada' : null);
                    Navigator.pop(context);
                  },
                ),
                ChoiceChip(
                  label: const Text('Respiración'),
                  selected: _selectedType == 'respiracion',
                  onSelected: (selected) {
                    setState(() => _selectedType = selected ? 'respiracion' : null);
                    Navigator.pop(context);
                  },
                ),
                ChoiceChip(
                  label: const Text('Pilotaje'),
                  selected: _selectedType == 'pilotaje',
                  onSelected: (selected) {
                    setState(() => _selectedType = selected ? 'pilotaje' : null);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Duración máxima:'),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('5 min'),
                  selected: _maxDuration == 5,
                  onSelected: (selected) {
                    setState(() => _maxDuration = selected ? 5 : null);
                    Navigator.pop(context);
                  },
                ),
                ChoiceChip(
                  label: const Text('15 min'),
                  selected: _maxDuration == 15,
                  onSelected: (selected) {
                    setState(() => _maxDuration = selected ? 15 : null);
                    Navigator.pop(context);
                  },
                ),
                ChoiceChip(
                  label: const Text('30 min'),
                  selected: _maxDuration == 30,
                  onSelected: (selected) {
                    setState(() => _maxDuration = selected ? 30 : null);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedType = null;
                _maxDuration = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Limpiar filtros'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

