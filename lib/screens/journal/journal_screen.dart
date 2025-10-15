import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/journal_provider.dart';
import '../../providers/auth_provider.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.getUserId();
    if (userId != null) {
      await context.read<JournalProvider>().loadEntries(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Diario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () => _showInsights(),
          ),
        ],
      ),
      body: Consumer2<JournalProvider, AuthProvider>(
        builder: (context, journalProvider, authProvider, _) {
          if (journalProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = journalProvider.entries;

          if (entries.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _loadEntries,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
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
                        Icons.book,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      DateFormat.yMMMMd('es').format(entry.date),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (entry.intention != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            entry.intention!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (entry.gratitudes.isNotEmpty)
                              Chip(
                                label: Text('${entry.gratitudes.length} gratitudes'),
                                visualDensity: VisualDensity.compact,
                              ),
                            if (entry.moodRatings.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Chip(
                                label: const Text('Con estado de ánimo'),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => context.push('/journal/${entry.id}'),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/journal/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva entrada'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Tu diario está vacío',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Comienza a registrar tus intenciones y gratitudes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.push('/journal/new'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Crear primera entrada'),
          ),
        ],
      ),
    );
  }

  void _showInsights() {
    final provider = context.read<JournalProvider>();
    final averageMoods = provider.getAverageMoodRatings(days: 7);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insights de los últimos 7 días',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                if (averageMoods.isEmpty)
                  const Text('No hay suficientes datos aún')
                else
                  ...averageMoods.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getMoodLabel(entry.key),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: entry.value / 5,
                            minHeight: 8,
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          ),
                          const SizedBox(height: 4),
                          Text('${(entry.value).toStringAsFixed(1)} / 5.0'),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getMoodLabel(String key) {
    final labels = {
      'animo': 'Ánimo',
      'energia': 'Energía',
      'sueno': 'Sueño',
      'estres': 'Estrés',
    };
    return labels[key] ?? key;
  }
}

