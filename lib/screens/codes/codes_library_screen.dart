import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/codes_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/code_card.dart';
import '../../models/grabovoi_code.dart';

class CodesLibraryScreen extends StatefulWidget {
  const CodesLibraryScreen({super.key});

  @override
  State<CodesLibraryScreen> createState() => _CodesLibraryScreenState();
}

class _CodesLibraryScreenState extends State<CodesLibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;

  final List<Map<String, String>> _categories = [
    {'key': 'salud', 'name': 'Salud', 'icon': '❤️'},
    {'key': 'abundancia', 'name': 'Abundancia', 'icon': '💰'},
    {'key': 'relaciones', 'name': 'Relaciones', 'icon': '🤝'},
    {'key': 'crecimiento_personal', 'name': 'Crecimiento', 'icon': '🌱'},
    {'key': 'proteccion', 'name': 'Protección', 'icon': '🛡️'},
    {'key': 'armonia', 'name': 'Armonía', 'icon': '☮️'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Asegura cargar los códigos si aún no están cargados
      final codesProvider = context.read<CodesProvider>();
      if (codesProvider.isLoading == false && codesProvider.codes.isEmpty) {
        codesProvider.loadCodes();
      }
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.getUserId();
      if (userId != null) {
        context.read<FavoritesProvider>().loadFavorites(userId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca de Códigos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Favoritos'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryFilter(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllCodesTab(),
                _buildFavoritesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar códigos...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<CodesProvider>().setSearchQuery('');
                  },
                )
              : null,
        ),
        onChanged: (value) {
          context.read<CodesProvider>().setSearchQuery(value);
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildCategoryChip('Todos', null),
          const SizedBox(width: 8),
          ..._categories.map((category) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildCategoryChip(
              '${category['icon']} ${category['name']}',
              category['key'],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? categoryKey) {
    final isSelected = _selectedCategory == categoryKey;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? categoryKey : null;
        });
        context.read<CodesProvider>().setCategory(_selectedCategory);
      },
    );
  }

  Widget _buildAllCodesTab() {
    return Consumer<CodesProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.codes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No se encontraron códigos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Intenta con otros filtros de búsqueda',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.codes.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CodeCard(code: provider.codes[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    return Consumer3<CodesProvider, FavoritesProvider, AuthProvider>(
      builder: (context, codesProvider, favProvider, authProvider, _) {
        if (favProvider.isLoading || codesProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final favoriteCodes = codesProvider.codes
            .where((code) => favProvider.isFavorite(code.id))
            .toList();

        if (favoriteCodes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No tienes favoritos aún',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Marca códigos como favoritos para acceder fácilmente',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favoriteCodes.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CodeCard(code: favoriteCodes[index]),
            );
          },
        );
      },
    );
  }
}

