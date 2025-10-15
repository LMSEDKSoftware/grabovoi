import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
// import 'package:share_plus/share_plus.dart'; // Comentado temporalmente
import '../../providers/codes_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/tracker_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/grabovoi_code.dart';
import '../../config/theme.dart';

class CodeDetailScreen extends StatefulWidget {
  final String codeId;

  const CodeDetailScreen({
    super.key,
    required this.codeId,
  });

  @override
  State<CodeDetailScreen> createState() => _CodeDetailScreenState();
}

class _CodeDetailScreenState extends State<CodeDetailScreen> {
  GrabovoiCode? _code;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCode();
  }

  Future<void> _loadCode() async {
    final code = await context.read<CodesProvider>().getCodeById(widget.codeId);
    if (mounted) {
      setState(() {
        _code = code;
        _isLoading = false;
      });
      
      if (code != null) {
        context.read<CodesProvider>().incrementPopularity(code.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_code == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Código no encontrado'),
        ),
      );
    }

    final categoryColor = AppTheme.categoryColors[_code!.category] ??
        Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        actions: [
          Consumer2<FavoritesProvider, AuthProvider>(
            builder: (context, favProvider, authProvider, _) {
              final isFavorite = favProvider.isFavorite(_code!.id);
              final userId = authProvider.getUserId();

              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                ),
                onPressed: userId != null
                    ? () => favProvider.toggleFavorite(userId, _code!.id)
                    : null,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: 'Código Grabovoi: ${_code!.title}\n${_code!.code}\n\n${_code!.description}',
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Código copiado al portapapeles')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(categoryColor),
            _buildCodeSection(categoryColor),
            _buildDescriptionSection(),
            _buildTagsSection(),
            _buildActionsSection(),
            _buildDisclaimerSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color categoryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            categoryColor.withOpacity(0.2),
            categoryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getCategoryName(_code!.category),
              style: TextStyle(
                color: categoryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _code!.title,
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildCodeSection(Color categoryColor) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: categoryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            _code!.code,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: categoryColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _code!.code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Código copiado')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copiar código'),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Descripción',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            _code!.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    if (_code!.tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _code!.tags.map((tag) => Chip(
          label: Text(tag),
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        )).toList(),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final trackerProvider = context.read<TrackerProvider>();
                trackerProvider.startSession(_code!.code);
                context.push('/tracker');
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar sesión de repetición'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.push('/meditations');
              },
              icon: const Icon(Icons.self_improvement),
              label: const Text('Ver meditaciones relacionadas'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerSection() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.secondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Los códigos Grabovoi son una práctica espiritual sin respaldo científico. Esta herramienta no sustituye el consejo médico profesional.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(String category) {
    final names = {
      'salud': 'Salud',
      'abundancia': 'Abundancia',
      'relaciones': 'Relaciones',
      'crecimiento_personal': 'Crecimiento Personal',
      'proteccion': 'Protección',
      'armonia': 'Armonía',
    };
    return names[category] ?? category;
  }
}

