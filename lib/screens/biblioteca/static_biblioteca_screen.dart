import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/static_codes_service.dart';
import '../../models/supabase_models.dart';
import '../../widgets/glow_background.dart';
import '../codes/repetition_session_screen.dart';

class StaticBibliotecaScreen extends StatefulWidget {
  const StaticBibliotecaScreen({super.key});

  @override
  State<StaticBibliotecaScreen> createState() => _StaticBibliotecaScreenState();
}

class _StaticBibliotecaScreenState extends State<StaticBibliotecaScreen> {
  bool loading = true;
  String? error;
  List<CodigoGrabovoi> all = [];
  List<CodigoGrabovoi> visible = [];
  List<String> categorias = ['Todos'];
  String categoriaSeleccionada = 'Todos';
  String query = '';

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
      print('[STATIC UI] 🚀 Iniciando carga desde CDN...');
      
      // Cargar códigos
      final items = await StaticCodesService.getCodigos();
      print('[STATIC UI] ✅ Códigos obtenidos: ${items.length}');
      
      if (!mounted) return;
      
      // Cargar categorías
      final cats = await StaticCodesService.getCategorias();
      print('[STATIC UI] ✅ Categorías obtenidas: ${cats.length}');
      
      if (!mounted) return;
      
      setState(() {
        all = items;
        visible = items;
        categorias = ['Todos', ...cats];
        loading = false;
      });
      
      print('[STATIC UI] ✅ Estado actualizado - all: ${all.length}, visible: ${visible.length}');
      
    } catch (e) {
      print('[STATIC UI] ❌ ERROR: $e');
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
    
    print('[STATIC UI] 🔍 Aplicando filtros...');
    print('[STATIC UI] Query: "$query", Categoría: "$categoriaSeleccionada"');
    print('[STATIC UI] Total códigos disponibles: ${all.length}');
    
    var filtrados = all.where((codigo) {
      final matchCategoria = categoriaSeleccionada == 'Todos' || 
                           codigo.categoria == categoriaSeleccionada;
      final matchQuery = query.isEmpty || 
                        codigo.nombre.toLowerCase().contains(query.toLowerCase()) ||
                        codigo.codigo.contains(query) ||
                        codigo.descripcion.toLowerCase().contains(query.toLowerCase());
      
      return matchCategoria && matchQuery;
    }).toList();
    
    print('[STATIC UI] ✅ Códigos filtrados: ${filtrados.length}');
    
    setState(() {
      visible = filtrados;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biblioteca Sagrada',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFD700),
                        shadows: [
                          Shadow(
                            color: const Color(0xFFFFD700).withOpacity(0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Códigos numéricos de manifestación',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (value) {
                        query = value;
                        _aplicarFiltros();
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar código, intención o categoría...',
                        hintStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                          borderSide: BorderSide(color: Color(0xFFFFD700)),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categorias.map((cat) {
                          final selected = categoriaSeleccionada == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(cat),
                              selected: selected,
                              onSelected: (_) {
                                setState(() => categoriaSeleccionada = cat);
                                _aplicarFiltros();
                              },
                              selectedColor: const Color(0xFFFFD700),
                              backgroundColor: Colors.white.withOpacity(0.08),
                              labelStyle: TextStyle(
                                color: selected ? const Color(0xFF0B132B) : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
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
            Text('Cargando códigos desde CDN...'),
            SizedBox(height: 8),
            Text('Esto puede tomar unos segundos', style: TextStyle(color: Colors.grey)),
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
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final codigo = visible[index];
        return _buildCodigoCard(codigo);
      },
    );
  }

  Widget _buildCodigoCard(CodigoGrabovoi codigo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getCategoryColor(codigo.categoria).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showCodigoDetail(codigo),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(codigo.categoria).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        codigo.categoria,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _getCategoryColor(codigo.categoria),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        codigo.nombre,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _toggleFavorito(codigo),
                      icon: const Icon(
                        Icons.favorite_border,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  codigo.codigo,
                  style: GoogleFonts.spaceMono(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  codigo.descripcion,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'salud':
        return const Color(0xFF4CAF50);
      case 'abundancia':
        return const Color(0xFFFFD700);
      case 'protección':
      case 'proteccion':
        return const Color(0xFF2196F3);
      case 'amor':
        return const Color(0xFFE91E63);
      case 'armonía':
      case 'armonia':
        return const Color(0xFF9C27B0);
      case 'sanación':
      case 'sanacion':
        return const Color(0xFF00BCD4);
      default:
        return const Color(0xFFFFD700);
    }
  }

  Future<void> _toggleFavorito(CodigoGrabovoi codigo) async {
    try {
      await StaticCodesService.toggleFavorito('user123', codigo.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Funcionalidad de favoritos en desarrollo')),
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

  void _showCodigoDetail(CodigoGrabovoi codigo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1C2541),
              Color(0xFF0B132B),
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              codigo.nombre,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFD700),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              codigo.codigo,
              style: GoogleFonts.spaceMono(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFD700),
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              codigo.descripcion,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RepetitionSessionScreen(
                            codigo: codigo.codigo,
                            nombre: codigo.nombre,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: const Color(0xFF0B132B),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      'Iniciar sesión de repetición',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _usarCodigo(CodigoGrabovoi codigo) async {
    try {
      await StaticCodesService.incrementarPopularidad(codigo.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código utilizado - Popularidad incrementada')),
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

  void _mostrarInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📡 Información del Sistema'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🔄 Sistema de Carga:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Carga desde CDN (GitHub/Netlify)'),
            Text('• Fallback a códigos locales'),
            Text('• Sin problemas de SSL/autenticación'),
            SizedBox(height: 16),
            Text('⚡ Ventajas:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Funciona SIEMPRE'),
            Text('• Se actualiza automáticamente'),
            Text('• Sin problemas de conectividad'),
            Text('• Carga súper rápida'),
            SizedBox(height: 16),
            Text('📊 Estado Actual:', style: TextStyle(fontWeight: FontWeight.bold)),
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
}
