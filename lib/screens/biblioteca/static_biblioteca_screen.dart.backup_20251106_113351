import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/biblioteca_supabase_service.dart';
import '../../services/supabase_service.dart';
import '../../models/supabase_models.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/favorite_label_modal.dart';
import '../../widgets/custom_button.dart';
import '../../repositories/codigos_repository.dart';
import '../../config/env.dart';
import '../../config/supabase_config.dart';
import '../../models/busqueda_profunda_model.dart';
import '../../services/busquedas_profundas_service.dart';
import '../../services/sugerencias_codigos_service.dart';
import '../../models/sugerencia_codigo_model.dart';
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
  
  // Variables para búsqueda profunda con IA
  TextEditingController _searchController = TextEditingController();
  String _queryBusqueda = '';
  bool _mostrarResultados = false;
  String? _codigoNoEncontrado;
  bool _showOptionsModal = false;
  bool _buscandoConIA = false;
  String? _codigoBuscando;
  bool _mostrarConfirmacionGuardado = false;
  String? _codigoGuardadoNombre;
  int? _busquedaActualId;
  DateTime? _inicioBusqueda;
  List<CodigoGrabovoi> _codigosEncontrados = [];
  bool _mostrarSeleccionCodigos = false;
  int _tokensUsadosOpenAI = 0;
  double _costoEstimadoOpenAI = 0.0;

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
    _searchController.dispose();
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

  // Método para actualizar códigos desde el repositorio (pull to refresh)
  Future<void> _refreshCodigos() async {
    try {
      // Actualizar códigos desde Supabase
      await CodigosRepository().refreshCodigos();
      
      // Recargar los datos en la pantalla
      await _load();
      
      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Códigos actualizados correctamente'),
            backgroundColor: Color(0xFFFFD700),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al actualizar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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

  // Método helper para obtener el ID del usuario actual
  String? _getCurrentUserId() {
    try {
      return SupabaseConfig.client.auth.currentUser?.id;
    } catch (e) {
      print('⚠️ No se pudo obtener el ID del usuario actual: $e');
      return null;
    }
  }

  // Filtrar códigos mientras el usuario escribe
  void _filtrarCodigos(String query) async {
    setState(() {
      _queryBusqueda = query;
    });
    
    if (query.isEmpty) {
      setState(() {
        _mostrarResultados = false;
      });
      _aplicarFiltros();
      return;
    }
    
    final queryLower = query.toLowerCase().trim();
    
    // 1. Buscar coincidencias exactas en lista local
    final coincidenciasExactas = _codigos.where((codigo) {
      return codigo.codigo.toLowerCase() == queryLower;
    }).toList();
    
    // 2. Buscar coincidencias parciales en lista local
    var coincidenciasLocales = _codigos.where((codigo) {
      return codigo.codigo.toLowerCase().contains(queryLower) ||
             codigo.nombre.toLowerCase().contains(queryLower) ||
             codigo.categoria.toLowerCase().contains(queryLower) ||
             codigo.descripcion.toLowerCase().contains(queryLower);
    }).toList();
    
    // 3. Si no hay resultados locales, buscar en títulos relacionados (búsqueda asíncrona)
    List<CodigoGrabovoi> codigosPorTitulo = [];
    if (coincidenciasExactas.isEmpty && coincidenciasLocales.isEmpty) {
      try {
        codigosPorTitulo = await SupabaseService.buscarCodigosPorTitulo(queryLower);
        if (codigosPorTitulo.isNotEmpty) {
          print('🔍 [FILTRAR] Códigos encontrados por títulos relacionados: ${codigosPorTitulo.length}');
        }
      } catch (e) {
        print('⚠️ Error buscando en títulos relacionados durante filtrado: $e');
      }
    }
    
    // 4. Combinar resultados (eliminar duplicados)
    final todosLosResultados = <String, CodigoGrabovoi>{};
    
    // Agregar coincidencias exactas primero
    for (var codigo in coincidenciasExactas) {
      todosLosResultados[codigo.codigo] = codigo;
    }
    
    // Agregar coincidencias locales
    for (var codigo in coincidenciasLocales) {
      if (!todosLosResultados.containsKey(codigo.codigo)) {
        todosLosResultados[codigo.codigo] = codigo;
      }
    }
    
    // Agregar códigos encontrados por títulos relacionados
    for (var codigo in codigosPorTitulo) {
      if (!todosLosResultados.containsKey(codigo.codigo)) {
        todosLosResultados[codigo.codigo] = codigo;
      }
    }
    
    final resultadoFinal = todosLosResultados.values.toList();
    
    // Aplicar filtros de categoría si hay resultados
    var resultadoFiltrado = resultadoFinal;
    if (resultadoFiltrado.isNotEmpty && categoriaSeleccionada != 'Todos') {
      resultadoFiltrado = resultadoFiltrado.where((codigo) {
        return codigo.categoria == categoriaSeleccionada;
      }).toList();
    }
    
    if (mounted) {
      setState(() {
        visible = resultadoFiltrado;
        _mostrarResultados = true;
      });
    }
  }

  // Confirmar búsqueda (cuando el usuario presiona Enter o busca explícitamente)
  void _confirmarBusqueda() async {
    if (_queryBusqueda.isEmpty) {
      _aplicarFiltros();
      return;
    }
    
    print('🔍 Confirmando búsqueda para: $_queryBusqueda');
    
    // 1. PRIMERO: Buscar coincidencias exactas en lista local
    final coincidenciasExactas = _codigos.where((codigo) {
      return codigo.codigo.toLowerCase() == _queryBusqueda.toLowerCase();
    }).toList();
    
    // 2. SEGUNDO: Buscar coincidencias similares/parciales en lista local
    var coincidenciasSimilares = _codigos.where((codigo) {
      final query = _queryBusqueda.toLowerCase();
      return codigo.codigo.toLowerCase().contains(query) ||
             codigo.nombre.toLowerCase().contains(query) ||
             codigo.categoria.toLowerCase().contains(query) ||
             codigo.descripcion.toLowerCase().contains(query) ||
             // Búsqueda por temas comunes
             (query.contains('salud') && codigo.categoria.toLowerCase().contains('salud')) ||
             (query.contains('amor') && codigo.categoria.toLowerCase().contains('amor')) ||
             (query.contains('dinero') && (codigo.categoria.toLowerCase().contains('abundancia') || codigo.categoria.toLowerCase().contains('manifestacion'))) ||
             (query.contains('trabajo') && (codigo.categoria.toLowerCase().contains('abundancia') || codigo.categoria.toLowerCase().contains('manifestacion'))) ||
             (query.contains('sanacion') && codigo.categoria.toLowerCase().contains('salud')) ||
             (query.contains('prosperidad') && codigo.categoria.toLowerCase().contains('abundancia'));
    }).toList();
    
    // 3. TERCERO: SIEMPRE buscar en títulos relacionados (tanto si hay resultados locales como si no)
    List<CodigoGrabovoi> codigosPorTitulo = [];
    try {
      codigosPorTitulo = await SupabaseService.buscarCodigosPorTitulo(_queryBusqueda);
      if (codigosPorTitulo.isNotEmpty) {
        print('🔍 Códigos encontrados por títulos relacionados: ${codigosPorTitulo.length}');
      }
    } catch (e) {
      print('⚠️ Error buscando en títulos relacionados: $e');
    }
    
    // 4. Combinar todos los resultados (eliminar duplicados por código)
    final todosLosResultados = <String, CodigoGrabovoi>{};
    
    // Agregar coincidencias exactas primero (tienen prioridad)
    for (var codigo in coincidenciasExactas) {
      todosLosResultados[codigo.codigo] = codigo;
    }
    
    // Agregar coincidencias similares locales
    for (var codigo in coincidenciasSimilares) {
      if (!todosLosResultados.containsKey(codigo.codigo)) {
        todosLosResultados[codigo.codigo] = codigo;
      }
    }
    
    // Agregar códigos encontrados por títulos relacionados
    for (var codigo in codigosPorTitulo) {
      if (!todosLosResultados.containsKey(codigo.codigo)) {
        todosLosResultados[codigo.codigo] = codigo;
      }
    }
    
    final resultadoFinal = todosLosResultados.values.toList();
    
    if (resultadoFinal.isNotEmpty) {
      print('✅ Resultados encontrados: ${resultadoFinal.length} códigos (${coincidenciasExactas.length} exactos, ${coincidenciasSimilares.length} locales, ${codigosPorTitulo.length} por títulos relacionados)');
      setState(() {
        visible = resultadoFinal;
        _mostrarResultados = true;
      });
      return;
    }
    
    // 5. Si no hay resultados, mostrar modal de búsqueda profunda
    print('❌ No se encontraron coincidencias para: $_queryBusqueda');
    setState(() {
      _codigoNoEncontrado = _queryBusqueda;
      _showOptionsModal = true;
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

  // ========== MÉTODOS DE BÚSQUEDA PROFUNDA CON IA ==========

  Future<String?> _guardarCodigoEnBaseDatos(CodigoGrabovoi codigo) async {
    try {
      print('💾 Verificando si el código ya existe: ${codigo.codigo}');
      
      final existe = await SupabaseService.codigoExiste(codigo.codigo);
      
      if (existe) {
        print('⚠️ El código ${codigo.codigo} ya existe en la base de datos');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ℹ️ El código ${codigo.codigo} ya existe en la base de datos',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
          ),
        );
        return null;
      }
      
      print('💾 Guardando código nuevo en base de datos: ${codigo.codigo}');
      final codigoCreado = await SupabaseService.crearCodigo(codigo);
      
      print('✅ Código guardado exitosamente en la base de datos con ID: ${codigoCreado.id}');
      
      // Mostrar modal de confirmación elegante
      if (mounted) {
        setState(() {
          _mostrarConfirmacionGuardado = true;
          _codigoGuardadoNombre = codigo.nombre;
        });
      }
      
      // Recargar la lista de códigos
      await _load();
      
      return codigoCreado.id;
    } catch (e) {
      print('❌ Error al guardar en la base de datos: $e');
      
      // Determinar el tipo de error y mostrar mensaje apropiado
      String mensajeError = 'No se pudo guardar el código.';
      if (e.toString().contains('401') || e.toString().contains('No API key')) {
        mensajeError = 'Error de autenticación: Verifica la configuración de la aplicación.';
      } else if (e.toString().contains('duplicate') || e.toString().contains('unique')) {
        mensajeError = 'El código ya existe en la base de datos.';
      } else if (e.toString().contains('permission') || e.toString().contains('RLS')) {
        mensajeError = 'No tienes permisos para guardar códigos. Contacta al administrador.';
      } else {
        mensajeError = 'Error al guardar: ${e.toString().length > 100 ? e.toString().substring(0, 100) + "..." : e.toString()}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Error al guardar código',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mensajeError,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
      return null;
    }
  }

  // Verificar conexión a internet
  Future<bool> _verificarConexionInternet() async {
    // En web, asumir que hay conexión (estamos en un navegador)
    // La verificación real se hará cuando intentemos usar la API
    if (kIsWeb) {
      return true;
    }
    
    // Para mobile, intentar verificar con un endpoint más confiable
    try {
      // Intentar conectar a Supabase (nuestro propio servicio)
      final response = await http.head(
        Uri.parse('https://whtiazgcxdnemrrgjjqf.supabase.co'),
      ).timeout(const Duration(seconds: 3));
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (e) {
      print('⚠️ Verificación de conexión: $e');
      // En caso de error, asumir que hay conexión y dejar que la llamada real falle si no hay
      // Esto evita falsos negativos
      return true;
    }
  }

  Future<void> _busquedaProfunda(String codigo) async {
    // Verificar conexión a internet antes de iniciar
    final tieneInternet = await _verificarConexionInternet();
    
    if (!tieneInternet) {
      print('⚠️ No hay conexión a internet, no se puede usar IA');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sin conexión a internet',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'La búsqueda con IA requiere conexión. Verifica tu conexión e intenta nuevamente.',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    
    try {
      print('🚀 Iniciando búsqueda profunda para código: $codigo');
      
      _inicioBusqueda = DateTime.now();
      
      final busqueda = BusquedaProfunda(
        codigoBuscado: codigo,
        usuarioId: _getCurrentUserId(),
        promptSystem: 'Eres un asistente experto en códigos de Grigori Grabovoi. Tu tarea es ayudar a encontrar códigos reales y verificados relacionados con la búsqueda del usuario.\n\nIMPORTANTE: Solo puedes sugerir códigos que realmente existan en las fuentes oficiales de Grabovoi. NO inventes códigos nuevos.\n\nPara búsquedas relacionadas con HUMANOS, PERSONAS, RELACIONES o INTERACCIONES HUMANAS, sugiere códigos reales específicos como:\n- 519_7148_21 — Armonía familiar\n- 619_734_218 — Armonización de relaciones\n- 814_418_719 — Comprensión y perdón\n- 714_319 — Amor y relaciones\n- 888_412_12848 — Desarrollo de relaciones\n- 520_741_8 — Relaciones armoniosas\n\nIMPORTANTE:\n1. Usa guiones bajos (_) en lugar de espacios en los códigos.\n2. Si el usuario busca algo específico, sugiere AL MENOS 3-5 códigos relacionados REALES del tema más cercano.\n3. Los códigos deben estar DIRECTAMENTE relacionados con la búsqueda del usuario.\n4. Responde SOLO en formato JSON con la siguiente estructura:\n{\n  "codigos": [\n    {\n      "codigo": "519_7148_21",\n      "nombre": "Armonía familiar",\n      "descripcion": "Descripción detallada y específica del código que explique su propósito y beneficios",\n      "categoria": "Armonía"\n    }\n  ]\n}\n5. La descripción debe ser una frase completa y descriptiva que explique qué hace el código, no solo el tema de búsqueda.',
        promptUser: 'Necesito códigos Grabovoi relacionados con: $codigo. Sugiere al menos 3-5 códigos REALES directamente relacionados con este tema. Para cada código, proporciona: código, nombre, una descripción detallada que explique su propósito específico, y categoría.',
        fechaBusqueda: _inicioBusqueda!,
        modeloIa: 'gpt-3.5-turbo',
      );
      
      try {
        _busquedaActualId = await BusquedasProfundasService.guardarBusquedaProfunda(busqueda);
        print('📝 Búsqueda registrada con ID: $_busquedaActualId');
      } catch (e) {
        print('⚠️ Error al registrar búsqueda inicial: $e');
        _busquedaActualId = null;
      }
      
      // Mostrar overlay elegante de búsqueda
      setState(() {
        _buscandoConIA = true;
        _codigoBuscando = codigo;
      });

      final resultado = await _buscarConOpenAI(codigo);
      
      // Ocultar overlay cuando termine
      if (mounted) {
        setState(() {
          _buscandoConIA = false;
          _codigoBuscando = null;
        });
      }
      
      final duracion = _inicioBusqueda != null 
          ? DateTime.now().difference(_inicioBusqueda!).inMilliseconds 
          : 0;
      
      if (resultado != null || _codigosEncontrados.isNotEmpty) {
        if (_busquedaActualId != null) {
          try {
            final busquedaActualizada = busqueda.copyWith(
              codigoEncontrado: true,
              codigoGuardado: true,
              duracionMs: duracion,
              tokensUsados: _tokensUsadosOpenAI,
              costoEstimado: _costoEstimadoOpenAI,
            );
            await BusquedasProfundasService.actualizarBusquedaProfunda(_busquedaActualId!, busquedaActualizada);
          } catch (e) {
            print('⚠️ Error al actualizar búsqueda: $e');
          }
        }
      } else {
        if (_busquedaActualId != null) {
          try {
            final busquedaActualizada = busqueda.copyWith(
              codigoEncontrado: false,
              codigoGuardado: false,
              duracionMs: duracion,
            );
            await BusquedasProfundasService.actualizarBusquedaProfunda(_busquedaActualId!, busquedaActualizada);
          } catch (e) {
            print('⚠️ Error al actualizar búsqueda: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Error en búsqueda profunda: $e');
      // Ocultar overlay si hay error
      if (mounted) {
        setState(() {
          _buscandoConIA = false;
          _codigoBuscando = null;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Error en la búsqueda profunda: ${e.toString()}',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<CodigoGrabovoi?> _buscarConOpenAI(String codigo) async {
    // Verificar conexión antes de llamar a OpenAI
    final tieneInternet = await _verificarConexionInternet();
    
    if (!tieneInternet) {
      print('❌ Sin conexión a internet, no se puede usar OpenAI');
      // Ocultar overlay si no hay conexión
      if (mounted) {
        setState(() {
          _buscandoConIA = false;
          _codigoBuscando = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sin conexión a internet',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No se puede conectar con la IA. Verifica tu conexión.',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
    
    try {
      print('🔍 Buscando código $codigo con OpenAI...');
      
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Env.openAiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'Eres un asistente experto en códigos de Grigori Grabovoi. Tu tarea es ayudar a encontrar códigos reales y verificados relacionados con la búsqueda del usuario.\n\nIMPORTANTE: Solo puedes sugerir códigos que realmente existan en las fuentes oficiales de Grabovoi. NO inventes códigos nuevos.\n\nPara búsquedas relacionadas con HUMANOS, PERSONAS, RELACIONES o INTERACCIONES HUMANAS, sugiere códigos reales específicos como:\n- 519_7148_21 — Armonía familiar\n- 619_734_218 — Armonización de relaciones\n- 814_418_719 — Comprensión y perdón\n- 714_319 — Amor y relaciones\n- 888_412_12848 — Desarrollo de relaciones\n- 520_741_8 — Relaciones armoniosas\n\nIMPORTANTE:\n1. Usa guiones bajos (_) en lugar de espacios en los códigos.\n2. Si el usuario busca algo específico, sugiere AL MENOS 3-5 códigos relacionados REALES del tema más cercano.\n3. Los códigos deben estar DIRECTAMENTE relacionados con la búsqueda del usuario.\n4. Responde SOLO en formato JSON con la siguiente estructura:\n{\n  "codigos": [\n    {\n      "codigo": "519_7148_21",\n      "nombre": "Armonía familiar",\n      "descripcion": "Descripción detallada y específica del código que explique su propósito y beneficios",\n      "categoria": "Armonía"\n    }\n  ]\n}\n5. La descripción debe ser una frase completa y descriptiva que explique qué hace el código, no solo el tema de búsqueda.'
            },
            {
              'role': 'user',
              'content': 'Necesito códigos Grabovoi relacionados con: $codigo. Sugiere al menos 3-5 códigos REALES directamente relacionados con este tema. Para cada código, proporciona: código, nombre, una descripción detallada que explique su propósito específico, y categoría.'
            }
          ],
          'max_tokens': 1000,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        if (data['usage'] != null) {
          final usage = data['usage'];
          _tokensUsadosOpenAI = (usage['total_tokens'] ?? 0) as int;
          final promptTokens = usage['prompt_tokens'] ?? 0;
          final completionTokens = usage['completion_tokens'] ?? 0;
          _costoEstimadoOpenAI = ((promptTokens / 1000) * 0.0015) + ((completionTokens / 1000) * 0.002);
        }
        
        if (content != 'null' && content.isNotEmpty && content.toLowerCase() != 'null') {
          try {
            String cleanedContent = content.trim();
            
            if (cleanedContent.contains('1.') && cleanedContent.contains('—')) {
              print('📋 Detectado formato de lista numerada');
              final codigosEncontrados = await _parsearListaNumerada(cleanedContent);
              
              if (codigosEncontrados.isNotEmpty) {
                print('✅ Códigos extraídos de lista: ${codigosEncontrados.length}');
                setState(() {
                  _codigosEncontrados = codigosEncontrados;
                  _mostrarSeleccionCodigos = true;
                  _showOptionsModal = false;
                });
                return null;
              } else {
                print('❌ No se pudieron extraer códigos de la lista');
                _mostrarMensajeNoEncontrado();
              }
              return null;
            }
            
            // Intentar parsear como JSON (formato anterior)
            if (!cleanedContent.endsWith('}') && !cleanedContent.endsWith(']')) {
              int lastCompleteObject = cleanedContent.lastIndexOf('}');
              if (lastCompleteObject > 0) {
                int arrayStart = cleanedContent.indexOf('"codigos": [');
                if (arrayStart > 0) {
                  String validPart = cleanedContent.substring(0, lastCompleteObject + 1);
                  if (validPart.contains('"codigos": [') && !validPart.contains(']')) {
                    validPart = validPart + ']}';
                  }
                  cleanedContent = validPart;
                }
              }
            }
            
            final responseData = jsonDecode(cleanedContent);
            
            if (responseData['codigos'] != null && responseData['codigos'] is List) {
              final codigosList = responseData['codigos'] as List;
              final codigosEncontrados = <CodigoGrabovoi>[];
              
              for (var codigoData in codigosList) {
                if (codigoData['codigo'] != null && codigoData['codigo'].toString().isNotEmpty) {
                  var codigoNumero = codigoData['codigo'].toString().replaceAll(' ', '_').replaceAll('-', '_');
                  
                  // Siempre agregamos el código sugerido, aunque no esté en BD
                  // Esto permite mostrar opciones relacionadas al usuario
                  final codigoExiste = await _validarCodigoEnBaseDatos(codigoNumero);
                  final nombre = codigoData['nombre']?.toString() ?? 'Código relacionado';
                  // Usar la descripción real de la IA, o generar una basada en el nombre
                  String descripcionReal = codigoData['descripcion']?.toString() ?? '';
                  if (descripcionReal.isEmpty || descripcionReal.contains('Código sugerido por IA')) {
                    // Si no hay descripción o es genérica, generar una basada en el nombre
                    descripcionReal = _generarDescripcionDesdeNombre(nombre);
                  }
                  final categoriaRaw = codigoData['categoria']?.toString() ?? '';
                  // Validar y corregir categoría: si es "codigo" o vacía, usar _determinarCategoria
                  final categoria = (categoriaRaw.isEmpty || categoriaRaw.toLowerCase() == 'codigo') 
                      ? _determinarCategoria(nombre) 
                      : categoriaRaw;
                  
                  if (codigoExiste) {
                    // Si existe en BD, priorizar la descripción de la IA si es mejor
                    final codigoExistente = await SupabaseService.getCodigoExistente(codigoNumero);
                    if (codigoExistente != null) {
                      // Usar descripción de IA si existe y es más específica, sino usar la de BD
                      final descripcionFinal = descripcionReal.isNotEmpty && descripcionReal.length > 20
                          ? descripcionReal
                          : codigoExistente.descripcion;
                      
                      codigosEncontrados.add(CodigoGrabovoi(
                        id: codigoExistente.id,
                        codigo: codigoNumero,
                        nombre: nombre.isNotEmpty ? nombre : codigoExistente.nombre,
                        descripcion: descripcionFinal, // Usar descripción real
                        categoria: categoria,
                        color: codigoExistente.color,
                      ));
                    }
                  } else {
                    // Si no existe, lo mostramos como sugerencia relacionada con descripción real
                    print('⚠️ Código $codigoNumero sugerido por IA (no en BD), mostrando como opción relacionada');
                    codigosEncontrados.add(CodigoGrabovoi(
                      id: DateTime.now().millisecondsSinceEpoch.toString() + '_${codigosEncontrados.length}',
                      codigo: codigoNumero,
                      nombre: nombre,
                      descripcion: descripcionReal, // Usar descripción real de la IA
                      categoria: categoria,
                      color: '#FFD700',
                    ));
                  }
                }
              }
              
              if (codigosEncontrados.isNotEmpty) {
                setState(() {
                  _codigosEncontrados = codigosEncontrados;
                  _mostrarSeleccionCodigos = true;
                  _showOptionsModal = false;
                });
                return null;
              } else {
                _mostrarMensajeNoEncontrado();
              }
            }
          } catch (e) {
            print('❌ Error parseando respuesta de OpenAI: $e');
            await _extraerCodigosDelTexto(content);
            return null;
          }
        }
      } else {
        print('❌ Error en respuesta de OpenAI: ${response.statusCode}');
      }
      
      return null;
    } catch (e) {
      print('❌ Error en búsqueda con OpenAI: $e');
      
      // Mostrar mensaje amigable al usuario si hay error de conexión
      if (mounted) {
        final esErrorConexion = e.toString().contains('SocketException') || 
                               e.toString().contains('TimeoutException') ||
                               e.toString().contains('Failed host lookup') ||
                               e.toString().contains('Network is unreachable');
        
        if (esErrorConexion) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Error de conexión',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No se pudo conectar con la IA. Verifica tu conexión a internet.',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      
      return null;
    }
  }

  Future<bool> _validarCodigoEnBaseDatos(String codigo) async {
    try {
      final codigoExiste = _codigos.any((c) => c.codigo == codigo);
      if (codigoExiste) {
        print('✅ Código $codigo encontrado en la base de datos local');
        return true;
      }
      
      final response = await SupabaseConfig.client
          .from('codigos_grabovoi')
          .select('codigo')
          .eq('codigo', codigo)
          .limit(1);
      
      final existe = response.isNotEmpty;
      print('${existe ? "✅" : "❌"} Código $codigo ${existe ? "existe" : "NO existe"} en Supabase');
      return existe;
    } catch (e) {
      print('❌ Error validando código $codigo: $e');
      return false;
    }
  }

  Future<void> _seleccionarCodigo(CodigoGrabovoi codigo) async {
    print('🎯 Código seleccionado: ${codigo.codigo} - ${codigo.nombre}');
    
    // PASO 1: Verificar si el código existe en Supabase (no solo en lista local)
    final existeEnSupabase = await SupabaseService.codigoExiste(codigo.codigo);
    
    if (!existeEnSupabase) {
      // CASO 1: El código NO existe en Supabase → INSERTAR directamente sin aprobación
      print('💾 Código NO existe en Supabase, insertando directamente: ${codigo.codigo}');
      try {
        final codigoId = await _guardarCodigoEnBaseDatos(codigo);
        if (codigoId != null) {
          print('✅ Código nuevo guardado con ID: $codigoId');
          // El modal de confirmación ya se muestra en _guardarCodigoEnBaseDatos
        }
      } catch (e) {
        print('⚠️ Error al guardar código nuevo: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar código: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // CASO 2: El código EXISTE en Supabase → Verificar si tiene diferente descripción
      print('🔍 Código existe en Supabase, verificando si tiene diferente descripción...');
      
      final codigoExistente = await SupabaseService.getCodigoExistente(codigo.codigo);
      if (codigoExistente != null) {
        final nombreExistente = codigoExistente.nombre.toLowerCase().trim();
        final descripcionExistente = codigoExistente.descripcion.toLowerCase().trim();
        final nombreNuevo = codigo.nombre.toLowerCase().trim();
        final descripcionNueva = codigo.descripcion.toLowerCase().trim();
        
        // Comparar tanto nombre como descripción
        final tieneDiferenteDescripcion = nombreExistente != nombreNuevo || descripcionExistente != descripcionNueva;
        
        if (tieneDiferenteDescripcion) {
          // CASO 2A: Código existe pero con diferente descripción → Crear sugerencia para aprobación
          print('⚠️ Código existe con diferente descripción. Creando sugerencia para aprobación');
          print('   Existente: "$nombreExistente"');
          print('   Nuevo: "$nombreNuevo"');
          
          try {
            await _crearSugerencia(codigoExistente, codigo.nombre, codigo.descripcion);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✨ Sugerencia creada para aprobación: ${codigo.nombre}'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 3),
              ),
            );
          } catch (e) {
            print('⚠️ Error al crear sugerencia: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ Error al crear sugerencia: $e'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          // CASO 2B: Código existe con la misma descripción → Solo confirmar
          print('✅ Código existe con la misma descripción');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Código seleccionado: ${codigo.nombre}'),
              backgroundColor: const Color(0xFF4CAF50),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
    
    setState(() {
      _mostrarSeleccionCodigos = false;
      _codigosEncontrados = [];
      _searchController.clear();
      _mostrarResultados = false;
      _queryBusqueda = '';
      query = '';
    });
    
    // Recargar códigos para mostrar el nuevo código en la lista
    await _load();
  }

  Future<void> _crearSugerencia(CodigoGrabovoi codigoExistente, String temaSugerido, String descripcionSugerida) async {
    try {
      print('💾 Creando sugerencia para código: ${codigoExistente.codigo}');
      
      final existeSimilar = await SugerenciasCodigosService.existeSugerenciaSimilar(
        _busquedaActualId ?? 0,
        codigoExistente.codigo,
        temaSugerido,
        _getCurrentUserId(),
      );
      
      if (existeSimilar) {
        print('ℹ️ Ya existe una sugerencia similar para este código');
        return;
      }
      
      final sugerencia = SugerenciaCodigo(
        busquedaId: _busquedaActualId ?? 0,
        codigoExistente: codigoExistente.codigo,
        temaEnDb: codigoExistente.nombre,
        temaSugerido: temaSugerido,
        descripcionSugerida: descripcionSugerida,
        usuarioId: _getCurrentUserId(),
        fuente: 'IA',
        estado: 'pendiente',
        fechaSugerencia: DateTime.now(),
      );
      
      final sugerenciaId = await SugerenciasCodigosService.crearSugerencia(sugerencia);
      print('✅ Sugerencia creada con ID: $sugerenciaId');
    } catch (e) {
      print('❌ Error creando sugerencia: $e');
    }
  }

  Future<List<CodigoGrabovoi>> _parsearListaNumerada(String content) async {
    try {
      final codigosEncontrados = <CodigoGrabovoi>[];
      final lineas = content.split('\n');
      
      for (String linea in lineas) {
        linea = linea.trim();
        if (linea.isEmpty || !linea.contains('.')) continue;
        
        final match = RegExp(r'^\d+\.\s+(.+)$').firstMatch(linea);
        if (match == null) continue;
        
        final contenido = match.group(1)!.trim();
        Match? codeMatch = RegExp(r'^([0-9_\s]+?)\s+-\s+(.+)$').firstMatch(contenido);
        if (codeMatch == null) {
          codeMatch = RegExp(r'^([0-9_\s]+?)\s+—\s+(.+)$').firstMatch(contenido);
        }
        if (codeMatch == null) {
          codeMatch = RegExp(r'^([0-9_\s]+?)\s*[-—]\s*(.+)$').firstMatch(contenido);
        }
        
        if (codeMatch != null) {
          var codigoStr = codeMatch.group(1)!.trim();
          final nombre = codeMatch.group(2)!.trim();
          
          codigoStr = codigoStr.replaceAll(' ', '_').replaceAll('__', '_');
          
          // Siempre agregamos el código sugerido para mostrar opciones relacionadas
          final codigoExiste = await _validarCodigoEnBaseDatos(codigoStr);
          final categoria = _determinarCategoria(nombre);
          
          // Generar descripción real basada en el nombre
          final descripcionReal = _generarDescripcionDesdeNombre(nombre);
          
          if (codigoExiste) {
            final codigoExistente = await SupabaseService.getCodigoExistente(codigoStr);
            if (codigoExistente != null) {
              // Usar descripción generada si es más específica que la de BD
              final descripcionFinal = descripcionReal.length > 20 && !codigoExistente.descripcion.contains('Código sugerido')
                  ? descripcionReal
                  : codigoExistente.descripcion;
              
              codigosEncontrados.add(CodigoGrabovoi(
                id: codigoExistente.id,
                codigo: codigoStr,
                nombre: nombre.isNotEmpty ? nombre : codigoExistente.nombre,
                descripcion: descripcionFinal, // Usar descripción real
                categoria: categoria.isNotEmpty ? categoria : codigoExistente.categoria,
                color: codigoExistente.color,
              ));
            }
          } else {
            // Si el código no existe, aún lo mostramos como sugerencia relacionada con descripción real
            print('⚠️ Código $codigoStr sugerido por IA (no en BD), mostrando como opción relacionada');
            codigosEncontrados.add(CodigoGrabovoi(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_${codigosEncontrados.length}',
              codigo: codigoStr,
              nombre: nombre,
              descripcion: descripcionReal, // Usar descripción real generada
              categoria: categoria.isNotEmpty ? categoria : 'Abundancia',
              color: '#FFD700',
            ));
          }
        }
      }
      
      return codigosEncontrados;
    } catch (e) {
      print('❌ Error parseando lista numerada: $e');
      return [];
    }
  }

  Future<void> _extraerCodigosDelTexto(String content) async {
    print('🔍 Intentando extraer códigos del texto...');
    
    try {
      final codigosEncontrados = <CodigoGrabovoi>[];
      final lineas = content.split('\n');
      
      for (String linea in lineas) {
        linea = linea.trim();
        if (linea.isEmpty) continue;
        
        final match = RegExp(r'^\d+\.\s+(.+)$').firstMatch(linea);
        if (match == null) continue;
        
        final contenido = match.group(1)!.trim();
        Match? codeMatch = RegExp(r'^([0-9_\s]+?)\s+-\s+(.+)$').firstMatch(contenido);
        if (codeMatch == null) {
          codeMatch = RegExp(r'^([0-9_\s]+?)\s+—\s+(.+)$').firstMatch(contenido);
        }
        if (codeMatch == null) {
          codeMatch = RegExp(r'^([0-9_\s]+?)\s*[-—]\s*(.+)$').firstMatch(contenido);
        }
        
        if (codeMatch != null) {
          var codigoStr = codeMatch.group(1)!.trim();
          final nombre = codeMatch.group(2)!.trim();
          
          codigoStr = codigoStr.replaceAll(' ', '_').replaceAll('__', '_');
          
          // Siempre agregamos el código sugerido para mostrar opciones relacionadas
          final codigoExiste = await _validarCodigoEnBaseDatos(codigoStr);
          final categoria = _determinarCategoria(nombre);
          
          // Generar descripción real basada en el nombre
          final descripcionReal = _generarDescripcionDesdeNombre(nombre);
          
          if (codigoExiste) {
            final codigoExistente = await SupabaseService.getCodigoExistente(codigoStr);
            if (codigoExistente != null) {
              // Usar descripción generada si es más específica que la de BD
              final descripcionFinal = descripcionReal.length > 20 && !codigoExistente.descripcion.contains('Código sugerido')
                  ? descripcionReal
                  : codigoExistente.descripcion;
              
              codigosEncontrados.add(CodigoGrabovoi(
                id: codigoExistente.id,
                codigo: codigoStr,
                nombre: nombre.isNotEmpty ? nombre : codigoExistente.nombre,
                descripcion: descripcionFinal, // Usar descripción real
                categoria: categoria.isNotEmpty ? categoria : codigoExistente.categoria,
                color: codigoExistente.color,
              ));
            }
          } else {
            // Si el código no existe, aún lo mostramos como sugerencia relacionada con descripción real
            print('⚠️ Código $codigoStr sugerido por IA (no en BD), mostrando como opción relacionada');
            codigosEncontrados.add(CodigoGrabovoi(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_${codigosEncontrados.length}',
              codigo: codigoStr,
              nombre: nombre,
              descripcion: descripcionReal, // Usar descripción real generada
              categoria: categoria.isNotEmpty ? categoria : 'Abundancia',
              color: '#FFD700',
            ));
          }
        }
      }
      
      if (codigosEncontrados.isNotEmpty) {
        print('✅ Mostrando ${codigosEncontrados.length} códigos relacionados encontrados por IA');
        setState(() {
          _codigosEncontrados = codigosEncontrados;
          _mostrarSeleccionCodigos = true;
          _showOptionsModal = false;
        });
      } else {
        print('⚠️ No se pudieron extraer códigos del texto de OpenAI');
        _mostrarMensajeNoEncontrado();
      }
    } catch (e) {
      print('❌ Error extrayendo códigos del texto: $e');
      _mostrarMensajeNoEncontrado();
    }
  }

  // Genera una descripción basada en el nombre del código
  String _generarDescripcionDesdeNombre(String nombre) {
    if (nombre.isEmpty) {
      return 'Código de manifestación numérica para transformación positiva.';
    }
    
    // Generar descripciones basadas en el nombre
    final nombreLower = nombre.toLowerCase();
    
    // Mapeo de palabras clave a descripciones
    if (nombreLower.contains('armonía') || nombreLower.contains('armonia')) {
      return 'Restaura el equilibrio y la armonía en las relaciones y situaciones.';
    } else if (nombreLower.contains('amor') || nombreLower.contains('relacion')) {
      return 'Fortalece las conexiones afectivas y mejora las relaciones interpersonales.';
    } else if (nombreLower.contains('abundancia') || nombreLower.contains('prosperidad')) {
      return 'Abre caminos hacia la abundancia y prosperidad en todos los aspectos de la vida.';
    } else if (nombreLower.contains('salud') || nombreLower.contains('cura') || nombreLower.contains('sanación')) {
      return 'Acelera los procesos de sanación y restauración del bienestar físico y emocional.';
    } else if (nombreLower.contains('protección') || nombreLower.contains('seguridad')) {
      return 'Proporciona protección y seguridad en situaciones desafiantes.';
    } else if (nombreLower.contains('hermandad') || nombreLower.contains('familia')) {
      return 'Fomenta la unidad, comprensión y armonía en las relaciones familiares y grupales.';
    } else if (nombreLower.contains('trabajo') || nombreLower.contains('profesional')) {
      return 'Abre caminos de reconocimiento y crecimiento profesional.';
    } else if (nombreLower.contains('dinero') || nombreLower.contains('finanza')) {
      return 'Atrae estabilidad financiera y oportunidades de prosperidad económica.';
    } else {
      // Descripción genérica pero útil basada en el nombre
      return 'Código de manifestación para ${nombre.toLowerCase()}. Activa procesos de transformación positiva relacionados con este propósito.';
    }
  }

  String _determinarCategoria(String nombre) {
    if (nombre.isEmpty || nombre.toLowerCase() == 'codigo') {
      return 'Abundancia'; // Categoría por defecto válida
    }
    
    final nombreLower = nombre.toLowerCase();
    
    // Mapeo extenso de palabras clave a categorías existentes
    final mapeoCategorias = {
      // Salud y Sanación
      'salud': 'Salud',
      'sanacion': 'Salud',
      'sanar': 'Salud',
      'cura': 'Salud',
      'curación': 'Salud',
      'enfermedad': 'Salud',
      'dolor': 'Salud',
      'medicina': 'Salud',
      'vitalidad': 'Salud',
      'bienestar': 'Salud',
      
      // Abundancia y Prosperidad
      'abundancia': 'Abundancia',
      'prosperidad': 'Abundancia',
      'dinero': 'Abundancia',
      'riqueza': 'Abundancia',
      'finanzas': 'Abundancia',
      'trabajo': 'Abundancia',
      'empleo': 'Abundancia',
      'negocio': 'Abundancia',
      'exito': 'Abundancia',
      'éxito': 'Abundancia',
      
      // Amor y Relaciones
      'amor': 'Amor',
      'relacion': 'Amor',
      'pareja': 'Amor',
      'matrimonio': 'Amor',
      'romance': 'Amor',
      'familia': 'Amor',
      'humano': 'Amor',
      'humanos': 'Amor',
      'persona': 'Amor',
      'personas': 'Amor',
      
      // Armonía y Paz
      'armonia': 'Armonía',
      'armonía': 'Armonía',
      'paz': 'Paz',
      'tranquilidad': 'Paz',
      'equilibrio': 'Armonía',
      'balance': 'Armonía',
      
      // Protección
      'proteccion': 'Protección',
      'protección': 'Protección',
      'seguridad': 'Protección',
      'defensa': 'Protección',
      
      // Espiritualidad
      'espiritualidad': 'Espiritualidad',
      'espiritual': 'Espiritualidad',
      'divino': 'Espiritualidad',
      'sagrado': 'Espiritualidad',
      'desarrollo': 'Espiritualidad',
      'crecimiento': 'Espiritualidad',
      
      // Relaciones generales
      'relaciones': 'Relaciones',
      'social': 'Relaciones',
      'comunicacion': 'Relaciones',
      'comunicación': 'Relaciones',
    };
    
    // Buscar coincidencias exactas primero
    for (var entrada in mapeoCategorias.entries) {
      if (nombreLower.contains(entrada.key)) {
        print('✅ Categoría encontrada por palabra clave "${entrada.key}": ${entrada.value}');
        return entrada.value;
      }
    }
    
    // Si no hay coincidencias, extraer palabra clave principal y buscar categoría similar
    final palabras = nombre.split(' ').where((p) => p.length > 3).toList();
    for (var palabra in palabras) {
      final palabraLower = palabra.toLowerCase();
      for (var entrada in mapeoCategorias.entries) {
        if (palabraLower.contains(entrada.key) || entrada.key.contains(palabraLower)) {
          print('✅ Categoría encontrada por palabra "${palabra}": ${entrada.value}');
          return entrada.value;
        }
      }
    }
    
    // Si aún no hay coincidencias, crear una categoría relacionada (capitalizada)
    final palabrasSignificativas = palabras.isNotEmpty ? palabras : [nombre];
    final primeraPalabra = palabrasSignificativas.first;
    if (primeraPalabra.length > 3 && primeraPalabra.toLowerCase() != 'codigo') {
      final categoriaNueva = primeraPalabra[0].toUpperCase() + primeraPalabra.substring(1).toLowerCase();
      print('🆕 Nueva categoría creada: $categoriaNueva');
      return categoriaNueva;
    }
    
    // Fallback a categoría por defecto válida
    print('⚠️ No se pudo determinar categoría, usando "Abundancia" por defecto');
    return 'Abundancia';
  }

  void _mostrarMensajeNoEncontrado() {
    setState(() {
      _showOptionsModal = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'No se encontraron códigos válidos para tu búsqueda. '
          'Dado que no existe uno "oficial" para tu consulta específica, '
          'puedes utilizar códigos de relaciones generales como:\n'
          '• 619 734 218 — Armonización de relaciones\n'
          '• 814 418 719 — Comprensión y perdón\n'
          '• 714 319 — Amor y relaciones',
          style: TextStyle(fontSize: 14),
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Entendido',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Color _getCategoryColor(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'salud':
        return const Color(0xFF4CAF50);
      case 'amor':
        return const Color(0xFFFF6B6B);
      case 'abundancia':
        return const Color(0xFFFFD700);
      case 'reprogramación':
      case 'reprogramacion':
        return const Color(0xFF9C27B0);
      case 'conciencia':
        return const Color(0xFF2196F3);
      case 'limpieza':
        return const Color(0xFF00BCD4);
      case 'armonía':
      case 'armonia':
        return const Color(0xFF00BCD4);
      default:
        return const Color(0xFFFFD700);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      body: Stack(
        children: [
          GlowBackground(
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
                      controller: _searchController,
                      onChanged: (value) {
                        query = value;
                        _queryBusqueda = value;
                        _filtrarCodigos(value);
                      },
                      onSubmitted: (value) {
                        _confirmarBusqueda();
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar código, intención o categoría...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search, color: Colors.white54),
                        suffixIcon: query.isNotEmpty
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (visible.isEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.search, color: Color(0xFFFFD700)),
                                      onPressed: _confirmarBusqueda,
                                      tooltip: 'Buscar código completo',
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.white54),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        query = '';
                                        _queryBusqueda = '';
                                        _mostrarResultados = false;
                                        _aplicarFiltros();
                                      });
                                    },
                                    tooltip: 'Limpiar búsqueda',
                                  ),
                                ],
                              )
                            : null,
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
          // Modales de búsqueda profunda
          if (_showOptionsModal) _buildOptionsModal(),
          if (_mostrarSeleccionCodigos) _buildSeleccionCodigosModal(),
          if (_buscandoConIA) _buildBuscandoConIAModal(),
          if (_mostrarConfirmacionGuardado) _buildConfirmacionGuardadoModal(),
        ],
      ),
    );
  }

  Widget _buildOptionsModal() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2541),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Código no encontrado',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No se encontró "$_codigoNoEncontrado" en la biblioteca',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '¿Qué deseas hacer?',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Búsqueda Profunda con IA',
                    icon: Icons.psychology,
                    onPressed: () {
                      setState(() {
                        _showOptionsModal = false;
                      });
                      _busquedaProfunda(_codigoNoEncontrado ?? _queryBusqueda);
                    },
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showOptionsModal = false;
                      _searchController.clear();
                      _queryBusqueda = '';
                      query = '';
                    });
                  },
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBuscandoConIAModal() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2541),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de IA con animación
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Buscando con Inteligencia Artificial',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Analizando códigos relacionados con "${_codigoBuscando ?? 'tu búsqueda'}"',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Esto puede tomar unos segundos...',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white54,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmacionGuardadoModal() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2541),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de éxito
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF4CAF50),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Código Guardado',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _codigoGuardadoNombre ?? 'Código guardado exitosamente',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'El código ha sido agregado permanentemente a la biblioteca',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _mostrarConfirmacionGuardado = false;
                        _codigoGuardadoNombre = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Entendido',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeleccionCodigosModal() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2541),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Códigos encontrados',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFFD700),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecciona el código que mejor se adapte a tu necesidad:',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Lista de códigos
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _codigosEncontrados.length,
                    itemBuilder: (context, index) {
                      final codigo = _codigosEncontrados[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _seleccionarCodigo(codigo),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C3E50).withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getCategoryColor(codigo.categoria).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _getCategoryColor(codigo.categoria).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: _getCategoryColor(codigo.categoria),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          codigo.codigo,
                                          style: GoogleFonts.inter(
                                            color: _getCategoryColor(codigo.categoria),
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          codigo.nombre,
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Descripción real del código
                                  Text(
                                    codigo.descripcion,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.category,
                                        color: _getCategoryColor(codigo.categoria),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        codigo.categoria,
                                        style: GoogleFonts.inter(
                                          color: _getCategoryColor(codigo.categoria),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      // Información de búsqueda como texto pequeño
                                      Text(
                                        'Sugerido por IA',
                                        style: GoogleFonts.inter(
                                          color: Colors.white54,
                                          fontSize: 10,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Botón cancelar
                TextButton(
                  onPressed: () {
                    setState(() {
                      _mostrarSeleccionCodigos = false;
                      _codigosEncontrados = [];
                    });
                  },
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
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
      // Si hay una búsqueda activa, mostrar el mismo mensaje que en Pilotaje Cuántico
      if (_queryBusqueda.isNotEmpty) {
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'No se encontraron resultados para "$_queryBusqueda". Presiona Enter o el botón de búsqueda para confirmar.',
                    style: GoogleFonts.inter(
                      color: Colors.orange,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      
      // Si no hay búsqueda activa, mostrar mensaje genérico
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

    return RefreshIndicator(
      onRefresh: _refreshCodigos,
      color: const Color(0xFFFFD700),
      backgroundColor: const Color(0xFF1C2541),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: visible.length,
        itemBuilder: (context, index) {
          final codigo = visible[index];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _buildCodigoCard(codigo),
            ),
          );
        },
      ),
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
          
          // Código con icono de copiar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  codigo.codigo,
                  style: GoogleFonts.spaceMono(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                    letterSpacing: 2,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.copy,
                  color: Color(0xFFFFD700),
                  size: 20,
                ),
                tooltip: 'Copiar código',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: codigo.codigo));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Código ${codigo.codigo} copiado al portapapeles'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: const Color(0xFFFFD700).withOpacity(0.9),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
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
          
          // Títulos relacionados
          FutureBuilder<List<Map<String, dynamic>>>(
            future: SupabaseService.getTitulosRelacionados(codigo.codigo),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              
              final titulosRelacionados = snapshot.data ?? [];
              
              if (titulosRelacionados.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFFFFD700),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'También relacionado con:',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFD700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...titulosRelacionados.map((tituloRel) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• ${tituloRel['titulo']?.toString() ?? ''}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                if (tituloRel['descripcion'] != null && 
                                    (tituloRel['descripcion'] as String).isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Text(
                                      tituloRel['descripcion']?.toString() ?? '',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: Colors.white.withOpacity(0.7),
                                        height: 1.2,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              );
            },
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