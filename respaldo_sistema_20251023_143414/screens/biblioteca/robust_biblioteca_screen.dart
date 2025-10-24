import 'package:flutter/material.dart';
import '../../services/robust_api_service.dart';
import '../../models/supabase_models.dart';

class RobustBibliotecaScreen extends StatefulWidget {
  const RobustBibliotecaScreen({super.key});

  @override
  State<RobustBibliotecaScreen> createState() => _RobustBibliotecaScreenState();
}

class _RobustBibliotecaScreenState extends State<RobustBibliotecaScreen> {
  bool loading = true;
  String? error;
  List<CodigoGrabovoi> all = [];
  List<CodigoGrabovoi> visible = [];
  List<String> categorias = ['Todos'];
  String categoriaSeleccionada = 'Todos';
  String query = '';
  Set<String> favoritosSet = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    
    setState(() {
      loading = true;
      error = null;
    });
    
    try {
      print('[ROBUST UI] Iniciando carga de datos...');
      
      // Cargar códigos
      final items = await RobustApiService.getCodigos();
      print('[ROBUST UI] Códigos obtenidos: ${items.length}');
      
      if (!mounted) return;
      
      // Cargar categorías
      final cats = await RobustApiService.getCategorias();
      print('[ROBUST UI] Categorías obtenidas: ${cats.length}');
      
      if (!mounted) return;
      
      // Cargar favoritos
      final favoritos = await RobustApiService.getFavoritos('user123');
      print('[ROBUST UI] Favoritos obtenidos: ${favoritos.length}');
      
      if (!mounted) return;
      
      setState(() {
        all = items;
        visible = items; // sin filtros al iniciar
        categorias = ['Todos', ...cats];
        favoritosSet = favoritos.map((f) => f.codigoId).toSet();
        loading = false;
      });
      
      print('[ROBUST UI] Estado actualizado - all: ${all.length}, visible: ${visible.length}');
      
    } catch (e) {
      print('[ROBUST UI] ERROR: $e');
      if (!mounted) return;
      
      setState(() {
        error = e.toString();
        loading = false;
        all = [];
        visible = [];
      });
    }
  }

  void _aplicarFiltros() {
    if (!mounted) return;
    
    print('[ROBUST UI] Aplicando filtros...');
    print('[ROBUST UI] Query: "$query", Categoría: "$categoriaSeleccionada"');
    print('[ROBUST UI] Total códigos disponibles: ${all.length}');
    
    var filtrados = all.where((codigo) {
      final matchCategoria = categoriaSeleccionada == 'Todos' || 
                           codigo.categoria == categoriaSeleccionada;
      final matchQuery = query.isEmpty || 
                        codigo.nombre.toLowerCase().contains(query.toLowerCase()) ||
                        codigo.codigo.contains(query) ||
                        codigo.descripcion.toLowerCase().contains(query.toLowerCase());
      
      return matchCategoria && matchQuery;
    }).toList();
    
    print('[ROBUST UI] Códigos filtrados: ${filtrados.length}');
    
    setState(() {
      visible = filtrados;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Biblioteca Sagrada (${visible.length} códigos)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _mostrarLogs,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar códigos...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    query = value;
                    _aplicarFiltros();
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categorias.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(cat),
                          selected: categoriaSeleccionada == cat,
                          onSelected: (selected) {
                            categoriaSeleccionada = cat;
                            _aplicarFiltros();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Contenido
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando códigos...'),
          ],
        ),
      );
    }
    
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error al cargar los códigos:', 
                 style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(error!, 
                         textAlign: TextAlign.center,
                         style: const TextStyle(fontFamily: 'monospace')),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    
    if (visible.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay códigos disponibles.'),
            Text('Intenta cambiar los filtros o recargar.'),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final codigo = visible[index];
        final esFavorito = favoritosSet.contains(codigo.id);
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCodigoColor(codigo.color),
              child: Text(
                codigo.codigo.split('_').first,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(
              codigo.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${codigo.categoria} · ${codigo.codigo}'),
                if (codigo.descripcion.isNotEmpty)
                  Text(
                    codigo.descripcion,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    esFavorito ? Icons.favorite : Icons.favorite_border,
                    color: esFavorito ? Colors.red : null,
                  ),
                  onPressed: () => _toggleFavorito(codigo),
                ),
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () => _verDetalle(codigo),
                ),
              ],
            ),
            onTap: () => _verDetalle(codigo),
          ),
        );
      },
    );
  }

  Color _getCodigoColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFFFFD700); // Dorado por defecto
    }
  }

  Future<void> _toggleFavorito(CodigoGrabovoi codigo) async {
    try {
      await RobustApiService.toggleFavorito('user123', codigo.id);
      
      setState(() {
        if (favoritosSet.contains(codigo.id)) {
          favoritosSet.remove(codigo.id);
        } else {
          favoritosSet.add(codigo.id);
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(favoritosSet.contains(codigo.id) 
              ? 'Agregado a favoritos' 
              : 'Removido de favoritos'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _verDetalle(CodigoGrabovoi codigo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(codigo.nombre)),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  codigo.codigo,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: _getCodigoColor(codigo.color),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Categoría: ${codigo.categoria}'),
                const SizedBox(height: 16),
                Text(
                  codigo.descripcion,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _incrementarPopularidad(codigo),
                  child: const Text('Usar este código'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _incrementarPopularidad(CodigoGrabovoi codigo) async {
    try {
      await RobustApiService.incrementarPopularidad(codigo.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Popularidad incrementada')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔍 Logs de Debug'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📊 Estado Actual:', style: Theme.of(context).textTheme.titleMedium),
              Text('• Loading: $loading'),
              Text('• Error: ${error ?? "Ninguno"}'),
              Text('• Total códigos: ${all.length}'),
              Text('• Códigos visibles: ${visible.length}'),
              Text('• Categorías: ${categorias.length}'),
              Text('• Favoritos: ${favoritosSet.length}'),
              const SizedBox(height: 16),
              Text('🔍 Filtros:', style: Theme.of(context).textTheme.titleMedium),
              Text('• Query: "$query"'),
              Text('• Categoría: "$categoriaSeleccionada"'),
              const SizedBox(height: 16),
              Text('📱 Para ver logs completos:', style: Theme.of(context).textTheme.titleMedium),
              const Text('1. Conecta el dispositivo a la PC'),
              const Text('2. Ejecuta: flutter logs'),
              const Text('3. Busca líneas con [ROBUST'),
              const SizedBox(height: 16),
              Text('🐛 Último error:', style: Theme.of(context).textTheme.titleMedium),
              Text(error ?? 'Ninguno', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _load();
            },
            child: const Text('Recargar'),
          ),
        ],
      ),
    );
  }
}
