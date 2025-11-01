import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/biblioteca_supabase_service.dart';
import '../../services/supabase_service.dart';
import '../../models/supabase_models.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/favorite_label_modal.dart';
import '../codes/repetition_session_screen.dart';

class StaticBibliotecaScreen extends StatefulWidget {
  const StaticBibliotecaScreen({super.key});

  @override
  State<StaticBibliotecaScreen> createState() => _StaticBibliotecaScreenState();
}

class _StaticBibliotecaScreenState extends State<StaticBibliotecaScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFab = false;
  List<CodigoGrabovoi> _codigos = [];
  List<CodigoGrabovoi> visible = [];
  List<String> categorias = ['Todos'];
  String categoriaSeleccionada = 'Todos';
  String query = '';
  bool loading = true;
  String? error;
  
  // Variables para favoritos
  List<String> etiquetasFavoritos = [];
  String? etiquetaSeleccionada;
  bool mostrarFavoritos = false;
  List<CodigoGrabovoi> favoritosFiltrados = [];
  DateTime? _lastLoadTime;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _showFab = _scrollController.offset > 100;
      });
    });
    _load();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar si han pasado más de 5 segundos desde la última carga
    final now = DateTime.now();
    if (_lastLoadTime == null || now.difference(_lastLoadTime!).inSeconds > 5) {
      print('🔄 Recargando biblioteca (han pasado más de 5 segundos)');
      _load();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final items = await BibliotecaSupabaseService.getTodosLosCodigos();
      final cats = items.map((c) => c.categoria).toSet().toList();
      final etiquetas = await BibliotecaSupabaseService.getEtiquetasFavoritos();
      
      setState(() {
        _codigos = items;
        visible = items;
        categorias = ['Todos', ...cats];
        etiquetasFavoritos = etiquetas;
        loading = false;
        _lastLoadTime = DateTime.now();
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void _aplicarFiltros() {
    setState(() {
      if (mostrarFavoritos) {
        // Mostrar favoritos filtrados por etiqueta si hay una seleccionada
        if (etiquetaSeleccionada != null) {
          // Usar el método asíncrono para filtrar por etiqueta
          _filtrarFavoritosPorEtiqueta(etiquetaSeleccionada!);
        } else {
          // Mostrar todos los favoritos (botón "Todas" seleccionado)
          if (favoritosFiltrados.isNotEmpty) {
            visible = favoritosFiltrados;
          } else {
            // Fallback: recargar favoritos si están vacíos
            _recargarFavoritosFallback();
          }
        }
      } else {
        // Mostrar todos los códigos con filtros normales
        visible = _codigos.where((codigo) {
          final matchesQuery = query.isEmpty ||
              codigo.nombre.toLowerCase().contains(query.toLowerCase()) ||
              codigo.codigo.contains(query) ||
              codigo.descripcion.toLowerCase().contains(query.toLowerCase());
          
          final matchesCategory = categoriaSeleccionada == 'Todos' ||
              codigo.categoria == categoriaSeleccionada;
          
          return matchesQuery && matchesCategory;
        }).toList();
      }
    });
  }

  Future<void> _filtrarFavoritosPorEtiqueta(String etiqueta) async {
    try {
      final favoritos = await BibliotecaSupabaseService.getFavoritosPorEtiqueta(etiqueta);
      setState(() {
        visible = favoritos;
      });
    } catch (e) {
      print('Error filtrando favoritos por etiqueta: $e');
    }
  }

  Future<void> _recargarFavoritosFallback() async {
    try {
      print('DEBUG → Fallback: Recargando favoritos desde Supabase');
      final favoritos = await BibliotecaSupabaseService.getFavoritos();
      setState(() {
        favoritosFiltrados = favoritos;
        visible = favoritos;
      });
      print('DEBUG → Fallback: Favoritos recargados: ${favoritos.length}');
    } catch (e) {
      print('Error en fallback al recargar favoritos: $e');
    }
  }

  Future<void> _cargarFavoritosPorEtiqueta(String etiqueta) async {
    try {
      final favoritos = await BibliotecaSupabaseService.getFavoritosPorEtiqueta(etiqueta);
      setState(() {
        favoritosFiltrados = favoritos;
        etiquetaSeleccionada = etiqueta;
        mostrarFavoritos = true;
      });
      _aplicarFiltros();
    } catch (e) {
      print('Error cargando favoritos por etiqueta: $e');
    }
  }

  Future<void> _toggleFavoritos() async {
    if (!mostrarFavoritos) {
      // Cargar favoritos del usuario
      try {
        final favoritos = await BibliotecaSupabaseService.getFavoritos();
        final etiquetas = await BibliotecaSupabaseService.getEtiquetasFavoritos();
        setState(() {
          mostrarFavoritos = true;
          favoritosFiltrados = favoritos;
          etiquetasFavoritos = etiquetas;
          etiquetaSeleccionada = null;
        });
      } catch (e) {
        print('Error cargando favoritos: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando favoritos: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      setState(() {
        mostrarFavoritos = false;
        etiquetaSeleccionada = null;
        favoritosFiltrados = [];
      });
    }
    _aplicarFiltros();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      body: GlowBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título de la sección
                  Text(
                    'Biblioteca Cuántica',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
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
                  const SizedBox(height: 20),
                  
                  // Contador de códigos y botón de favoritos
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Total de códigos: ',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFFFFD700),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${visible.length}',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    color: const Color(0xFFFFD700),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Botón de favoritos
                          GestureDetector(
                            onTap: _toggleFavoritos,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: mostrarFavoritos 
                                    ? const Color(0xFFFFD700).withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFFFD700).withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.favorite,
                                    color: mostrarFavoritos 
                                        ? const Color(0xFFFFD700)
                                        : Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Favoritos',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: mostrarFavoritos 
                                          ? const Color(0xFFFFD700)
                                          : Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Barra de búsqueda (solo cuando NO están habilitados los favoritos)
                  if (!mostrarFavoritos) ...[
                    TextField(
                      onChanged: (value) {
                        query = value;
                        _aplicarFiltros();
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar código, intención o categoría...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search, color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
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
                    
                    // Filtros de categoría
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
                  
                  // Filtro de etiquetas de favoritos (solo cuando se muestran favoritos)
                  if (mostrarFavoritos) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Filtrar por etiqueta:',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Botón "Todas"
                          GestureDetector(
                            onTap: () async {
                              setState(() {
                                etiquetaSeleccionada = null;
                              });

                              try {
                                // Recarga los favoritos directamente desde Supabase
                                final favoritos = await BibliotecaSupabaseService.getFavoritos();
                                
                                print('DEBUG → Favoritos cargados: ${favoritos.length}');
                                print('DEBUG → Etiqueta seleccionada: $etiquetaSeleccionada');

                                setState(() {
                                  favoritosFiltrados = favoritos;
                                  visible = favoritos;
                                });
                              } catch (e) {
                                print('Error al recargar todos los favoritos: $e');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: etiquetaSeleccionada == null 
                                    ? const Color(0xFFFFD700).withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFFFD700).withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Todas',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: etiquetaSeleccionada == null 
                                      ? const Color(0xFFFFD700)
                                      : Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          // Botones de etiquetas
                          ...etiquetasFavoritos.map((etiqueta) {
                            final isSelected = etiquetaSeleccionada == etiqueta;
                            return GestureDetector(
                              onTap: () => _cargarFavoritosPorEtiqueta(etiqueta),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? const Color(0xFFFFD700).withOpacity(0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFFFD700).withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  etiqueta,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isSelected 
                                        ? const Color(0xFFFFD700)
                                        : Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Lista de códigos con scroll independiente
            Expanded(
              child: _buildContent(),
            ),
          ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Categoría
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(codigo.categoria).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getCategoryColor(codigo.categoria).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    codigo.categoria,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(codigo.categoria),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Botón de favorito con etiqueta
              FutureBuilder<bool>(
                future: BibliotecaSupabaseService.esFavorito(codigo.codigo),
                builder: (context, snapshot) {
                  final isFavorite = snapshot.data ?? false;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () async {
                          if (isFavorite) {
                            // Si ya es favorito, removerlo directamente
                            try {
                              await BibliotecaSupabaseService.toggleFavorito(codigo.codigo);
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ ${codigo.nombre} removido de favoritos'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } catch (e) {
                              print('Error removiendo favorito: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          } else {
                            // Si no es favorito, mostrar modal para etiquetar
                            _mostrarModalEtiquetado(codigo);
                          }
                        },
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.white70,
                          size: 20,
                        ),
                      ),
                      // Mostrar etiqueta si es favorito
                      if (isFavorite)
                        FutureBuilder<String?>(
                          future: BibliotecaSupabaseService.getEtiquetaFavorito(codigo.codigo),
                          builder: (context, etiquetaSnapshot) {
                            final etiqueta = etiquetaSnapshot.data;
                            if (etiqueta != null && etiqueta.isNotEmpty) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFFFD700).withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  etiqueta,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFFD700),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Título
          Text(
            codigo.nombre,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          
          // Código
          Text(
            codigo.codigo,
            style: GoogleFonts.spaceMono(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFD700),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          
          // Descripción
          Text(
            codigo.descripcion,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          
          // Botón de acción
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _mostrarModalRepeticion(codigo);
              },
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Iniciar sesión de repetición'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF0B132B),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'salud':
        return Colors.green;
      case 'abundancia':
        return Colors.amber;
      case 'amor':
        return Colors.pink;
      case 'protección':
        return Colors.red;
      case 'conciencia':
        return Colors.purple;
      case 'limpieza':
        return Colors.blue;
      case 'avanzados':
        return Colors.orange;
      case 'energía':
        return Colors.cyan;
      case 'regeneración':
        return Colors.teal;
      case 'maestría':
        return Colors.indigo;
      case 'expansión':
        return Colors.lime;
      case 'liberación':
        return Colors.deepOrange;
      default:
        return const Color(0xFFFFD700);
    }
  }

  void _mostrarModalRepeticion(CodigoGrabovoi codigo) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2541),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título
                  Text(
                    'Instrucciones de Repetición',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFD700),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Mensaje principal - Texto más compacto
                  Text(
                    'La activación de los códigos ocurre por resonancia, no por acumulación de repeticiones.\n\n'
                    'Una sola repetición con total enfoque puede ser más efectiva que cientos realizadas de forma automática.\n\n'
                    'Visualiza la secuencia dentro de una esfera de luz y repítela mentalmente hasta sentir que la energía se acomoda en armonía.\n\n'
                    'Lo esencial no es cuántas veces repitas, sino la calidad de tu atención e intención.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  // Botón de continuar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Cerrar modal
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
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: Text(
                        'Comenzar Repetición',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Botón de cancelar
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _mostrarModalEtiquetado(CodigoGrabovoi codigo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FavoriteLabelModal(
        codigo: codigo.codigo,
        nombre: codigo.nombre,
        onSave: (etiqueta) async {
          try {
            await BibliotecaSupabaseService.agregarFavoritoConEtiqueta(codigo.codigo, etiqueta);
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❤️ ${codigo.nombre} agregado a favoritos con etiqueta: $etiqueta'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } catch (e) {
            print('Error agregando favorito con etiqueta: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      ),
    );
  }

}