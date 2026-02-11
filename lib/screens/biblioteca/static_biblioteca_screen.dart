import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:screenshot/screenshot.dart';
import '../../services/biblioteca_supabase_service.dart';
import '../../services/supabase_service.dart';
import '../../models/supabase_models.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/favorite_label_modal.dart';
import '../../widgets/custom_button.dart';
import '../../repositories/codigos_repository.dart';
import '../../config/env.dart';
import '../../config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/busqueda_profunda_model.dart';
import '../../services/busquedas_profundas_service.dart';
import '../../services/sugerencias_codigos_service.dart';
import '../../models/sugerencia_codigo_model.dart';
import '../codes/repetition_session_screen.dart';
import '../../services/subscription_service.dart';
import '../../widgets/subscription_required_modal.dart';
import '../../services/user_progress_service.dart';
import '../../services/user_custom_codes_service.dart';
import '../../services/user_favorites_service.dart';
import '../../utils/codigo_busqueda_util.dart';
import '../../utils/share_helper.dart';
import '../../services/challenge_progress_tracker.dart';

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
  bool _tieneFavoritos = false; // Flag para saber si hay favoritos disponibles
  
  // Caché de favoritos para optimizar consultas
  Map<String, bool> _favoritosCache = {}; // codigo -> isFavorite
  Map<String, String?> _etiquetasCache = {}; // codigo -> etiqueta
  Set<String> _customCodesCache = {}; // códigos personalizados
  DateTime? _favoritosCacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  // Caché de títulos relacionados para evitar consultas repetitivas durante scroll
  Map<String, List<Map<String, dynamic>>> _titulosRelacionadosCache = {}; // codigo -> titulos relacionados
  bool _titulosRelacionadosCargados = false;
  
  // Variables para ordenamiento inteligente basado en evaluación
  List<String> _userGoals = []; // Objetivos del usuario desde la evaluación
  final UserProgressService _progressService = UserProgressService();
  
  // Variables para búsqueda profunda con IA
  TextEditingController _searchController = TextEditingController();
  String _queryBusqueda = '';
  bool _mostrarResultados = false;
  String? _codigoNoEncontrado;
  bool _showOptionsModal = false;
  /// Cuando hay búsqueda por código con resultados parciales pero sin coincidencia exacta,
  /// mostrar opción "Buscar código exacto" / búsqueda profunda / pilotaje manual.
  bool _mostrarOpcionBusquedaExacta = false;
  /// Si no hay resultados pero el usuario tiene en Favoritos (pilotaje manual) una secuencia que coincide.
  bool _tieneSecuenciaEnFavoritosPilotajeManual = false;
  String? _nombreSecuenciaEnFavoritosPilotajeManual;
  CodigoGrabovoi? _codigoFavoritoPilotajeManualCoincidente;
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
  // Flujo B Fase 2: fallback relacionados cuando no hay fuente externa
  bool _mostrarFallbackFase2 = false;
  List<Map<String, dynamic>> _fallbackFase2Items = []; // [{ 'codigo': CodigoGrabovoi, 'why_recommended': String }]
  String? _safetyNoteFase2;
  String _queryFallbackFase2 = '';
  bool _buscandoRelacionadosFase2 = false;
  String? _codigoBuscandoFase2;
  
  // Compartir código desde la biblioteca
  final ScreenshotController _shareController = ScreenshotController();
  CodigoGrabovoi? _codigoParaCompartir;
  
  // Variables para pilotaje manual
  bool _showManualPilotage = false;
  TextEditingController _manualCodeController = TextEditingController();
  TextEditingController _manualTitleController = TextEditingController();
  TextEditingController _manualDescriptionController = TextEditingController();
  String _manualCategory = 'Abundancia y Prosperidad';
  
  /// Usa util compartido (flujo B): código = dígitos/espacios/_; no "-".
  bool _esBusquedaPorCodigo(String query) => esBusquedaPorCodigo(query);

  /// Si la secuencia ya está guardada en pilotajes manuales del usuario, devuelve ese código; si no, null.
  Future<CodigoGrabovoi?> _secuenciaYaEnPilotajeManual(String secuencia) async {
    final q = secuencia.trim();
    if (q.isEmpty) return null;
    final queryDigitos = codigoSoloDigitos(normalizarCodigo(q));
    if (queryDigitos.length < 3) return null;
    try {
      final customCodes = await UserCustomCodesService().getUserCustomCodes();
      for (final c in customCodes) {
        if (codigoSoloDigitos(normalizarCodigo(c.codigo)) == queryDigitos) return c;
      }
    } catch (_) {}
    return null;
  }

  /// Redirige a la vista que muestra el card de la secuencia guardada en Favoritos (sin abrir el formulario).
  void _redirigirAVistaSecuenciaGuardadaEnFavoritos(CodigoGrabovoi c, String queryBusqueda) {
    setState(() {
      _showManualPilotage = false;
      _showOptionsModal = false;
      _queryBusqueda = queryBusqueda;
      _mostrarResultados = true;
      visible = [];
      _tieneSecuenciaEnFavoritosPilotajeManual = true;
      _nombreSecuenciaEnFavoritosPilotajeManual = c.nombre;
      _codigoFavoritoPilotajeManualCoincidente = c;
    });
    _searchController.text = queryBusqueda;
  }

  /// Abre el modal de pilotaje manual precargando el campo adecuado.
  /// Si la secuencia ya existe en pilotajes manuales del usuario, redirige a ver esa secuencia guardada.
  Future<void> _abrirPilotajeManualDesdeBusqueda(String consultaOriginal) async {
    final consulta = consultaOriginal.trim();
    if (consulta.isEmpty) return;
    
    final esCodigo = _esBusquedaPorCodigo(consulta);
    
    if (esCodigo) {
      final normalizado = consulta.replaceAll(' ', '_');
      final yaGuardado = await _secuenciaYaEnPilotajeManual(normalizado);
      if (mounted && yaGuardado != null) {
        _redirigirAVistaSecuenciaGuardadaEnFavoritos(yaGuardado, normalizado);
        return;
      }
    }
    
    if (!mounted) return;
    setState(() {
      _showManualPilotage = true;
      if (esCodigo) {
        final normalizado = consulta.replaceAll(' ', '_');
        _manualCodeController.text = normalizado;
        if (_manualTitleController.text.isNotEmpty) _manualTitleController.clear();
      } else {
        _manualTitleController.text = consulta;
        _manualCodeController.clear();
      }
    });
  }

  /// Cuando la búsqueda empieza con número, solo permite dígitos, "_" y espacio.
  /// No permite letras, "-" ni otros símbolos. Si es texto, no modifica.
  String _filtrarEntradaBusqueda(String value) {
    return filtrarEntradaCodigo(value);
  }
  
  // Variables para el deslizamiento y reporte de códigos
  final Map<String, double> _swipeOffsets = {}; // Almacena el offset de deslizamiento por código
  final Map<String, String?> _reportReasons = {}; // Almacena la razón del reporte por código

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _showFab = _scrollController.offset > 100;
      });
    });
    
    // Verificar si el usuario es gratuito después de los 7 días
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subscriptionService = SubscriptionService();
      if (subscriptionService.isFreeUser && mounted) {
        SubscriptionRequiredModal.show(
          context,
          message: 'La Biblioteca Cuántica está disponible solo para usuarios Premium. Suscríbete para acceder a todas las secuencias.',
          onDismiss: () {
            // Redirigir a Inicio después de cerrar el modal
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        );
      }
    });
    
    _load();
  }
  
  // Eliminado didChangeDependencies para evitar recargas innecesarias
  // Los datos se cargan una sola vez en initState y se actualizan solo con pull-to-refresh

  @override
  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _manualCodeController.dispose();
    _manualTitleController.dispose();
    _manualDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      // Cargar preferencias del usuario ANTES de cargar el resto de los datos
      await _loadUserPreferences();

      final items = await BibliotecaSupabaseService.getTodosLosCodigos();
      final cats = items.map((c) => c.categoria).toSet().toList();
      final etiquetas = await BibliotecaSupabaseService.getEtiquetasFavoritos();
      final favoritos = await BibliotecaSupabaseService.getFavoritos();
      
      // Cargar y cachear favoritos
      await _cargarFavoritosCache();
      
      // Precargar títulos relacionados para todos los códigos visibles (solo una vez)
      if (!_titulosRelacionadosCargados) {
        await _precargarTitulosRelacionados(items);
      }

      // Ordenar las categorías basadas en los objetivos del usuario
      final sortedCategories = _applyCategorySorting(cats, _userGoals);

      // Ordenar los códigos visibles iniciales alfabéticamente por nombre
      items.sort((a, b) => a.nombre.compareTo(b.nombre));
      
      setState(() {
        _codigos = items;
        visible = items; // La lista visible inicial contiene todos los códigos ordenados
        categorias = ['Todos', ...sortedCategories];
        etiquetasFavoritos = etiquetas;
        _tieneFavoritos = favoritos.isNotEmpty;
        loading = false;
        _lastLoadTime = DateTime.now();
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
        _tieneFavoritos = false;
      });
    }
  }

  /// Cargar los objetivos del usuario desde la evaluación.
  Future<void> _loadUserPreferences() async {
    try {
      final assessment = await _progressService.getUserAssessment();
      if (assessment != null && assessment['goals'] != null) {
        final goals = assessment['goals'];
        if (goals is List) {
          _userGoals = List<String>.from(goals.map((e) => e.toString()));
          print('✅ Objetivos del usuario cargados para ordenamiento: $_userGoals');
        }
      }
    } catch (e) {
      print('⚠️ Error cargando las preferencias del usuario (evaluación): $e');
      _userGoals = [];
    }
  }

  /// Ordena la lista de categorías para que las que coinciden con los objetivos del usuario aparezcan primero.
  List<String> _applyCategorySorting(List<String> allCategories, List<String> userGoals) {
    if (userGoals.isEmpty) {
      allCategories.sort((a, b) => a.compareTo(b));
      return allCategories;
    }

    final preferredCategories = <String>[];
    final remainingCategories = <String>[];

    // Mapeo flexible de objetivos a posibles categorías
    final Map<String, List<String>> goalToCategoryMap = {
      'amor y relaciones': ['amor', 'relaciones', 'pareja', 'familia'],
      'salud y bienestar': ['salud', 'sanación', 'bienestar', 'curación', 'medicina'],
      'desarrollo personal y espiritual': ['desarrollo', 'crecimiento', 'espiritualidad', 'conciencia'],
      'carrera y finanzas': ['abundancia', 'prosperidad', 'dinero', 'finanzas', 'trabajo', 'negocio', 'éxito'],
      'protección y armonía': ['protección', 'seguridad', 'armonía', 'paz', 'equilibrio', 'limpieza'],
    };

    // Crear una lista plana de todas las palabras clave de categorías preferidas
    final Set<String> preferredKeywords = {};
    for (final goal in userGoals) {
      final keywords = goalToCategoryMap[goal.toLowerCase()];
      if (keywords != null) {
        preferredKeywords.addAll(keywords);
      }
    }

    for (final category in allCategories) {
      bool isPreferred = preferredKeywords.any((keyword) => category.toLowerCase().contains(keyword));
      if (isPreferred) {
        preferredCategories.add(category);
      } else {
        remainingCategories.add(category);
      }
    }

    // Ordenar alfabéticamente cada sub-lista
    preferredCategories.sort((a, b) => a.compareTo(b));
    remainingCategories.sort((a, b) => a.compareTo(b));

    print('🔀 Categorías ordenadas: ${[...preferredCategories, ...remainingCategories]}');
    return [...preferredCategories, ...remainingCategories];
  }

  // Método para actualizar códigos desde el repositorio (pull to refresh)
  Future<void> _refreshCodigos() async {
    try {
      // Actualizar códigos desde Supabase
      await CodigosRepository().refreshCodigos();
      
      // Recargar los datos en la pantalla (esto ya incluye la carga de preferencias)
      await _load();
      
      // Reaplicar búsqueda/filtros actuales para no perder la vista filtrada (ej. "empleo" → 4 secuencias)
      if (mounted && _queryBusqueda.trim().isNotEmpty) {
        _filtrarCodigos(_queryBusqueda);
      } else if (mounted) {
        _aplicarFiltros();
      }
      
      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Secuencias actualizadas correctamente'),
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
            // Si no hay favoritos, volver a la vista normal
            mostrarFavoritos = false;
            _tieneFavoritos = false;
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
        _mostrarOpcionBusquedaExacta = false;
        _tieneSecuenciaEnFavoritosPilotajeManual = false;
        _nombreSecuenciaEnFavoritosPilotajeManual = null;
        _codigoFavoritoPilotajeManualCoincidente = null;
      });
      _aplicarFiltros();
      return;
    }
    
    final queryLower = query.toLowerCase().trim();
    final exactCode = exactCodeFromQuery(query);
    final isNumeric = isNumericQuery(query);
    
    // Búsqueda por código: exactas + parciales; comparar por dígitos para que 5207418 y 520_741_8 coincidan.
    List<CodigoGrabovoi> coincidenciasExactas;
    List<CodigoGrabovoi> coincidenciasLocales;
    if (isNumeric && exactCode != null) {
      final queryDigitos = codigoSoloDigitos(exactCode);
      coincidenciasExactas = _codigos.where((c) =>
          codigoSoloDigitos(normalizarCodigo(c.codigo)) == queryDigitos).toList();
      // Parciales: códigos cuya secuencia (solo dígitos) contiene lo escrito (ej. 520741 incluye 5207418)
      coincidenciasLocales = _codigos.where((c) =>
          codigoSoloDigitos(normalizarCodigo(c.codigo)).contains(queryDigitos)).toList();
    } else {
      coincidenciasExactas = _codigos.where((c) => c.codigo.toLowerCase() == queryLower).toList();
      coincidenciasLocales = _codigos.where((codigo) {
        return codigo.codigo.toLowerCase().contains(queryLower) ||
               codigo.nombre.toLowerCase().contains(queryLower) ||
               codigo.categoria.toLowerCase().contains(queryLower) ||
               codigo.descripcion.toLowerCase().contains(queryLower);
      }).toList();
    }
    
    // Si numérico y no hay en lista local, intentar BD por variantes (codigo con _ o espacios)
    List<CodigoGrabovoi> codigosPorTitulo = [];
    if (coincidenciasExactas.isEmpty && coincidenciasLocales.isEmpty) {
      if (isNumeric && exactCode != null) {
        final varianteEspacios = exactCodeWithSpaces(exactCode);
        final c1 = await SupabaseService.getCodigoExistente(exactCode);
        final c2 = await SupabaseService.getCodigoExistente(varianteEspacios);
        if (c1 != null) codigosPorTitulo = [c1];
        if (c2 != null && codigosPorTitulo.isEmpty) codigosPorTitulo = [c2];
      } else {
        try {
          codigosPorTitulo = await SupabaseService.buscarCodigosPorTitulo(queryLower);
          if (codigosPorTitulo.isNotEmpty) {
            print('🔍 [FILTRAR] Códigos encontrados por títulos relacionados: ${codigosPorTitulo.length}');
          }
        } catch (e) {
          print('⚠️ Error buscando en títulos relacionados durante filtrado: $e');
        }
      }
    }
    
    final todosLosResultados = <String, CodigoGrabovoi>{};
    for (var codigo in coincidenciasExactas) {
      todosLosResultados[codigo.codigo] = codigo;
    }
    for (var codigo in coincidenciasLocales) {
      if (!todosLosResultados.containsKey(codigo.codigo)) todosLosResultados[codigo.codigo] = codigo;
    }
    for (var codigo in codigosPorTitulo) {
      if (!todosLosResultados.containsKey(codigo.codigo)) todosLosResultados[codigo.codigo] = codigo;
    }
    
    final resultadoFinal = todosLosResultados.values.toList();
    
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
        // Opción "Buscar código exacto" cuando hay parciales pero no hay coincidencia exacta
        _mostrarOpcionBusquedaExacta = isNumeric &&
            exactCode != null &&
            coincidenciasExactas.isEmpty &&
            resultadoFiltrado.isNotEmpty;
        if (resultadoFiltrado.isNotEmpty) {
          _tieneSecuenciaEnFavoritosPilotajeManual = false;
          _nombreSecuenciaEnFavoritosPilotajeManual = null;
          _codigoFavoritoPilotajeManualCoincidente = null;
        }
      });
      if (resultadoFiltrado.isEmpty && query.trim().isNotEmpty) {
        _verificarCoincidenciaEnFavoritosPilotajeManual();
      }
    }
  }

  /// Comprueba si el usuario tiene en Favoritos (pilotaje manual) una secuencia que coincide con la búsqueda.
  Future<void> _verificarCoincidenciaEnFavoritosPilotajeManual() async {
    final q = _queryBusqueda.trim();
    if (q.isEmpty) return;
    final queryDigitos = codigoSoloDigitos(normalizarCodigo(q));
    if (queryDigitos.length < 3) return;
    try {
      final customCodes = await UserCustomCodesService().getUserCustomCodes();
      for (final c in customCodes) {
        if (codigoSoloDigitos(normalizarCodigo(c.codigo)) == queryDigitos) {
          if (mounted) {
            setState(() {
              _tieneSecuenciaEnFavoritosPilotajeManual = true;
              _nombreSecuenciaEnFavoritosPilotajeManual = c.nombre;
              _codigoFavoritoPilotajeManualCoincidente = c;
            });
          }
          return;
        }
      }
      if (mounted) {
        setState(() {
          _tieneSecuenciaEnFavoritosPilotajeManual = false;
          _nombreSecuenciaEnFavoritosPilotajeManual = null;
          _codigoFavoritoPilotajeManualCoincidente = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _tieneSecuenciaEnFavoritosPilotajeManual = false;
          _nombreSecuenciaEnFavoritosPilotajeManual = null;
          _codigoFavoritoPilotajeManualCoincidente = null;
        });
      }
    }
  }

  // Confirmar búsqueda (cuando el usuario presiona Enter o busca explícitamente)
  void _confirmarBusqueda() async {
    if (_queryBusqueda.isEmpty) {
      _aplicarFiltros();
      return;
    }
    
    print('🔍 Confirmando búsqueda para: $_queryBusqueda');
    
    final exactCode = exactCodeFromQuery(_queryBusqueda);
    final isNumeric = isNumericQuery(_queryBusqueda);
    
    // Flujo B: numérico = SOLO exacto (normalizado). Texto = exactas + similares + títulos relacionados.
    List<CodigoGrabovoi> coincidenciasExactas;
    List<CodigoGrabovoi> coincidenciasSimilares;
    List<CodigoGrabovoi> codigosPorTitulo = [];
    if (isNumeric && exactCode != null) {
      final queryDigitos = codigoSoloDigitos(exactCode);
      coincidenciasExactas = _codigos.where((c) =>
          codigoSoloDigitos(normalizarCodigo(c.codigo)) == queryDigitos).toList();
      coincidenciasSimilares = [];
      if (coincidenciasExactas.isEmpty) {
        final varianteEspacios = exactCodeWithSpaces(exactCode);
        final c1 = await SupabaseService.getCodigoExistente(exactCode);
        final c2 = await SupabaseService.getCodigoExistente(varianteEspacios);
        if (c1 != null) codigosPorTitulo = [c1];
        if (c2 != null && codigosPorTitulo.isEmpty) codigosPorTitulo = [c2];
      }
    } else {
      coincidenciasExactas = _codigos.where((c) => c.codigo.toLowerCase() == _queryBusqueda.toLowerCase()).toList();
      coincidenciasSimilares = _codigos.where((codigo) {
        final query = _queryBusqueda.toLowerCase();
        return codigo.codigo.toLowerCase().contains(query) ||
               codigo.nombre.toLowerCase().contains(query) ||
               codigo.categoria.toLowerCase().contains(query) ||
               codigo.descripcion.toLowerCase().contains(query) ||
               (query.contains('salud') && codigo.categoria.toLowerCase().contains('salud')) ||
               (query.contains('amor') && codigo.categoria.toLowerCase().contains('amor')) ||
               (query.contains('dinero') && (codigo.categoria.toLowerCase().contains('abundancia') || codigo.categoria.toLowerCase().contains('manifestacion'))) ||
               (query.contains('trabajo') && (codigo.categoria.toLowerCase().contains('abundancia') || codigo.categoria.toLowerCase().contains('manifestacion'))) ||
               (query.contains('sanacion') && codigo.categoria.toLowerCase().contains('salud')) ||
               (query.contains('prosperidad') && codigo.categoria.toLowerCase().contains('abundancia'));
      }).toList();
      try {
        codigosPorTitulo = await SupabaseService.buscarCodigosPorTitulo(_queryBusqueda);
        if (codigosPorTitulo.isNotEmpty) {
          print('🔍 Códigos encontrados por títulos relacionados: ${codigosPorTitulo.length}');
        }
      } catch (e) {
        print('⚠️ Error buscando en títulos relacionados: $e');
      }
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
      final esBusquedaCodigo = _esBusquedaPorCodigo(_queryBusqueda);
      final sinCoincidenciaExacta = coincidenciasExactas.isEmpty;
      setState(() {
        visible = resultadoFinal;
        _mostrarResultados = true;
        _tieneSecuenciaEnFavoritosPilotajeManual = false;
        _nombreSecuenciaEnFavoritosPilotajeManual = null;
        _codigoFavoritoPilotajeManualCoincidente = null;
        // Ocultar el banner solo si hubo coincidencia exacta; si no, mantenerlo al final
        if (coincidenciasExactas.isNotEmpty) _mostrarOpcionBusquedaExacta = false;
        // Si el usuario buscó una secuencia numérica y NO hay coincidencia exacta,
        // ofrecer igualmente la opción de Búsqueda Profunda con la secuencia exacta.
        if (esBusquedaCodigo && sinCoincidenciaExacta) {
          _codigoNoEncontrado = _queryBusqueda;
          _showOptionsModal = true;
        }
      });
      return;
    }
    
    // 5. Si no hay resultados, mostrar modal de búsqueda profunda (el banner "¿No está tu código?" se mantiene)
    print('❌ No se encontraron coincidencias para: $_queryBusqueda');
    setState(() {
      visible = [];
      _codigoNoEncontrado = _queryBusqueda;
      _showOptionsModal = true;
    });
    _verificarCoincidenciaEnFavoritosPilotajeManual();
  }

  // Cargar favoritos en caché para optimizar consultas
  Future<void> _cargarFavoritosCache() async {
    try {
      // Solo recargar si el caché expiró
      if (_favoritosCacheTime != null && 
          DateTime.now().difference(_favoritosCacheTime!) < _cacheDuration) {
        print('✅ Usando caché de favoritos');
        return;
      }
      
      print('🔄 Cargando favoritos en caché...');
      final favoritesWithDetails = await UserFavoritesService().getFavoritesWithDetails();
      
      _favoritosCache.clear();
      _etiquetasCache.clear();
      _customCodesCache.clear();
      
      for (final item in favoritesWithDetails) {
        final codigoId = item['codigo_id'] as String? ?? 
                        (item['codigos_grabovoi'] as Map?)?['codigo'] as String? ?? '';
        final etiqueta = item['etiqueta'] as String?;
        final isCustom = item['is_custom'] == true;
        
        if (codigoId.isNotEmpty) {
          _favoritosCache[codigoId] = true;
          _etiquetasCache[codigoId] = etiqueta;
          if (isCustom) {
            _customCodesCache.add(codigoId);
          }
        }
      }
      
      _favoritosCacheTime = DateTime.now();
      print('✅ Caché de favoritos cargado: ${_favoritosCache.length} códigos');
    } catch (e) {
      print('⚠️ Error cargando caché de favoritos: $e');
    }
  }
  
  // Verificar si un código es favorito (usando caché)
  bool _esFavoritoCached(String codigoId) {
    return _favoritosCache[codigoId] ?? false;
  }
  
  // Obtener etiqueta de un favorito (usando caché)
  String? _getEtiquetaCached(String codigoId) {
    return _etiquetasCache[codigoId];
  }
  
  // Verificar si un código es personalizado
  bool _esCodigoPersonalizado(String codigoId) {
    return _customCodesCache.contains(codigoId);
  }
  
  // Precargar títulos relacionados para todos los códigos (solo una vez)
  Future<void> _precargarTitulosRelacionados(List<CodigoGrabovoi> codigos) async {
    if (_titulosRelacionadosCargados) return;
    
    print('🔄 Precargando títulos relacionados para ${codigos.length} códigos...');
    try {
      // Cargar títulos relacionados en paralelo para los primeros 50 códigos (para no sobrecargar)
      final codigosALimitar = codigos.take(50).toList();
      final futures = codigosALimitar.map((codigo) async {
        try {
          final titulos = await SupabaseService.getTitulosRelacionados(codigo.codigo);
          _titulosRelacionadosCache[codigo.codigo] = titulos;
        } catch (e) {
          print('⚠️ Error precargando títulos para ${codigo.codigo}: $e');
          _titulosRelacionadosCache[codigo.codigo] = [];
        }
      });
      
      await Future.wait(futures);
      _titulosRelacionadosCargados = true;
      print('✅ Títulos relacionados precargados para ${_titulosRelacionadosCache.length} códigos');
    } catch (e) {
      print('⚠️ Error precargando títulos relacionados: $e');
    }
  }
  
  // Obtener títulos relacionados desde cache o cargar si no están en cache
  List<Map<String, dynamic>> _getTitulosRelacionados(String codigo) {
    // Si está en cache, retornar inmediatamente
    if (_titulosRelacionadosCache.containsKey(codigo)) {
      return _titulosRelacionadosCache[codigo]!;
    }
    // Si no está en cache, retornar lista vacía (no hacer consulta durante scroll)
    return [];
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
      
      // Precargar títulos relacionados para los favoritos si no se han cargado
      if (!_titulosRelacionadosCargados && favoritos.isNotEmpty) {
        await _precargarTitulosRelacionados(favoritos);
      }
      
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

  /// Actualizar el estado de favoritos después de agregar/quitar uno
  Future<void> _actualizarEstadoFavoritos() async {
    // Recargar caché de favoritos
    await _cargarFavoritosCache();
    try {
      final favoritos = await BibliotecaSupabaseService.getFavoritos();
      final etiquetas = await BibliotecaSupabaseService.getEtiquetasFavoritos();
      
      setState(() {
        _tieneFavoritos = favoritos.isNotEmpty;
        
        // Si estamos mostrando favoritos, actualizar la lista
        if (mostrarFavoritos) {
          favoritosFiltrados = favoritos;
          etiquetasFavoritos = etiquetas;
          
          // Si se eliminó el último favorito, volver a la vista normal
          if (favoritos.isEmpty) {
            mostrarFavoritos = false;
            etiquetaSeleccionada = null;
            categoriaSeleccionada = 'Todos';
            _aplicarFiltros();
          } else {
            // Aplicar filtros para actualizar la vista
            _aplicarFiltros();
          }
        } else {
          // Si no estamos en vista de favoritos pero se agregó uno, mantener _tieneFavoritos actualizado
          // El botón seguirá visible para poder activar el filtro
        }
      });
    } catch (e) {
      print('Error actualizando estado de favoritos: $e');
    }
  }

  Future<void> _toggleFavoritos() async {
    // Si no estamos mostrando favoritos, cargar y precargar títulos relacionados
    if (!mostrarFavoritos) {
      // Precargar títulos relacionados si no se han cargado
      if (!_titulosRelacionadosCargados && _codigos.isNotEmpty) {
        await _precargarTitulosRelacionados(_codigos);
      }
      // Activar filtro de favoritos
      try {
        // Recargar caché antes de mostrar favoritos
        await _cargarFavoritosCache();
        
        final favoritos = await BibliotecaSupabaseService.getFavoritos();
        final etiquetas = await BibliotecaSupabaseService.getEtiquetasFavoritos();
        
        // Precargar títulos relacionados para los favoritos si no se han cargado
        if (!_titulosRelacionadosCargados && favoritos.isNotEmpty) {
          await _precargarTitulosRelacionados(favoritos);
        }
        
        if (favoritos.isEmpty) {
          // Si no hay favoritos, mostrar mensaje y no cambiar el estado
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No tienes secuencias en favoritos. Agrega algunas desde la biblioteca.',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }
        
        setState(() {
          mostrarFavoritos = true;
          favoritosFiltrados = favoritos;
          etiquetasFavoritos = etiquetas;
          etiquetaSeleccionada = null;
          _tieneFavoritos = true;
          // Resetear filtro de categoría cuando se activa favoritos
          categoriaSeleccionada = 'Todos';
        });
      } catch (e) {
        print('Error cargando favoritos: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando favoritos: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
    } else {
      // Desactivar filtro de favoritos - volver a vista normal
      setState(() {
        mostrarFavoritos = false;
        etiquetaSeleccionada = null;
        favoritosFiltrados = [];
        // Mantener _tieneFavoritos en true si hay favoritos (para que el botón siga visible)
        // Solo se oculta si realmente no hay favoritos
        // Restaurar la vista normal con todos los códigos
        categoriaSeleccionada = 'Todos';
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
              'ℹ️ La secuencia ${codigo.codigo} ya existe en la base de datos',
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
      
      // 1. Refrescar el repositorio para asegurar que el código nuevo esté disponible
      await CodigosRepository().refreshCodigos();
      print('🔄 Repositorio refrescado');
      
      // 2. Mostrar modal de confirmación elegante
      if (mounted) {
        setState(() {
          _mostrarConfirmacionGuardado = true;
          _codigoGuardadoNombre = codigo.nombre;
        });
      }
      
      // 3. Recargar la lista de códigos
      await _load();
      print('🔄 Lista de códigos recargada');
      
      // 4. Si hay una búsqueda activa, aplicar el filtro automáticamente
      // para que el código recién guardado aparezca en los resultados
      if (query.isNotEmpty || _queryBusqueda.isNotEmpty) {
        final queryActiva = query.isNotEmpty ? query : _queryBusqueda;
        print('🔄 Aplicando filtro automático después de guardar código: "$queryActiva"');
        // Pequeño delay para asegurar que los datos estén completamente cargados
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          setState(() {
            // Aplicar el filtro para mostrar el código recién guardado
            _aplicarFiltros();
          });
          print('✅ Filtro aplicado, códigos visibles: ${visible.length}');
        }
      }
      
      return codigoCreado.id;
    } catch (e) {
      print('❌ Error al guardar en la base de datos: $e');
      
      // Determinar el tipo de error y mostrar mensaje apropiado
      String mensajeError = 'No se pudo guardar la secuencia.';
      if (e.toString().contains('401') || e.toString().contains('No API key')) {
        mensajeError = 'Error de autenticación: Verifica la configuración de la aplicación.';
      } else if (e.toString().contains('duplicate') || e.toString().contains('unique')) {
        mensajeError = 'La secuencia ya existe en la base de datos.';
      } else if (e.toString().contains('permission') || e.toString().contains('RLS')) {
        mensajeError = 'No tienes permisos para guardar secuencias. Contacta al administrador.';
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
                      'Error al guardar secuencia',
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
        promptSystem:
            'Eres un asistente experto en códigos de Grigori Grabovoi. Tu tarea es ayudar a encontrar códigos REALES y VERIFICADOS relacionados con la búsqueda del usuario a partir de FUENTES AUTÉNTICAS (libros oficiales, materiales de Grigori Grabovoi o repositorios confiables).\n\nREGLAS CRÍTICAS:\n1. NUNCA inventes ni interpretes nuevos códigos. Si no encuentras un código real en las fuentes, debes indicarlo explícitamente.\n2. Para cada código sugerido debes incluir SIEMPRE un campo "fuente" que indique claramente de dónde sale ese código (por ejemplo: libro, página, curso, material oficial, URL del repositorio autorizado, etc.).\n3. Si NO encuentras ninguna fuente confiable para la intención del usuario, debes responder que no encontraste códigos reales y sugerir que el usuario cree su propia secuencia personalizada.\n\nFORMATO DE RESPUESTA:\n- Responde SOLO en formato JSON con UNA de estas dos opciones:\n\nA) Cuando SÍ hay códigos reales encontrados:\n{\n  "codigos": [\n    {\n      "codigo": "519_7148_21",\n      "nombre": "Armonía familiar",\n      "descripcion": "Descripción detallada y específica del código que explique su propósito y beneficios",\n      "categoria": "Armonía",\n      "fuente": "Nombre del libro o recurso oficial, página X, u otra referencia clara"\n    }\n  ],\n  "sin_fuente": false\n}\n\nB) Cuando NO hay códigos reales para ese tema:\n{\n  "codigos": [],\n  "sin_fuente": true,\n  "mensaje": "No se encontraron códigos reales de Grabovoi para este tema en las fuentes consultadas."\n}\n\nIMPORTANTE:\n- Usa guiones bajos (_) en lugar de espacios en los códigos.\n- No incluyas texto fuera del JSON.\n- La descripción debe explicar claramente el propósito del código según la fuente, NO una interpretación libre.',
        promptUser:
            'El usuario busca códigos Grabovoi relacionados con: "$codigo". Busca SOLO en fuentes reales y verificables. Si existen códigos reales, respóndelos siguiendo exactamente el formato indicado (incluyendo el campo "fuente" por código). Si no encuentras nada fiable, responde con "codigos": [] y "sin_fuente": true, indicando que no hay códigos oficiales para este tema.',
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
      final exactCode = exactCodeFromQuery(codigo);
      final isNumeric = isNumericQuery(codigo);
      const systemFase1 =
          'Eres un asistente experto en códigos de Grigori Grabovoi. Tu tarea es ayudar a encontrar códigos REALES y VERIFICADOS relacionados con la búsqueda del usuario a partir de FUENTES AUTÉNTICAS (libros oficiales, materiales de Grigori Grabovoi o repositorios confiables).\n\nREGLAS CRÍTICAS:\n1. NUNCA inventes ni interpretes nuevos códigos. Si no encuentras un código real en las fuentes, debes indicarlo explícitamente.\n2. Para cada código sugerido debes incluir SIEMPRE un campo "fuente" que indique claramente de dónde sale ese código (por ejemplo: libro, página, curso, material oficial, URL del repositorio autorizado, etc.).\n3. Si NO encuentras ninguna fuente confiable para la intención del usuario, debes responder que no encontraste códigos reales y sugerir que el usuario cree su propia secuencia personalizada.\n4. Si la consulta es numérica, solo es match si la fuente contiene EXACTAMENTE la misma secuencia de dígitos (ignorando espacios; espacios y _ equivalen). Si no, marca sin_fuente:true.\n\nFORMATO DE RESPUESTA:\n- Responde SOLO en formato JSON con UNA de estas dos opciones:\n\nA) Cuando SÍ hay códigos reales encontrados:\n{\n  "codigos": [\n    {\n      "codigo": "519_7148_21",\n      "nombre": "Armonía familiar",\n      "descripcion": "Descripción detallada y específica del código que explique su propósito y beneficios",\n      "categoria": "Armonía",\n      "fuente": "Nombre del libro o recurso oficial, página X, u otra referencia clara"\n    }\n  ],\n  "sin_fuente": false\n}\n\nB) Cuando NO hay códigos reales para ese tema:\n{\n  "codigos": [],\n  "sin_fuente": true,\n  "mensaje": "No se encontraron códigos reales de Grabovoi para este tema en las fuentes consultadas."\n}\n\nIMPORTANTE:\n- Usa guiones bajos (_) en lugar de espacios en los códigos.\n- No incluyas texto fuera del JSON.\n- La descripción debe explicar claramente el propósito del código según la fuente, NO una interpretación libre.';
      final userFase1 = isNumeric && exactCode != null
          ? 'El usuario busca el código Grabovoi exacto: "$codigo". Código normalizado (solo dígitos y _): "$exactCode". Busca SOLO en fuentes reales y verificables. Solo es válido si la fuente cita exactamente esa secuencia. Si no encuentras esa secuencia en una fuente, responde con "codigos": [] y "sin_fuente": true.'
          : 'El usuario busca códigos Grabovoi relacionados con: "$codigo". Busca SOLO en fuentes reales y verificables. Si existen códigos reales, respóndelos siguiendo exactamente el formato indicado (incluyendo el campo "fuente" por código). Si no encuentras nada fiable, responde con "codigos": [] y "sin_fuente": true, indicando que no hay códigos oficiales para este tema.';
      
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Env.openAiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': systemFase1},
            {'role': 'user', 'content': userFase1},
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

            // Flujo B: si no hay fuente externa → Fase 2 fallback (3 relacionados desde BD)
            final sinFuente = responseData['sin_fuente'] == true;
            if (sinFuente) {
              print('ℹ️ OpenAI indica que no hay fuentes (sin_fuente = true). Ejecutando Fase 2 fallback.');
              if (mounted) {
                setState(() {
                  _buscandoConIA = false;
                  _codigoBuscando = null;
                  _buscandoRelacionadosFase2 = true;
                  _codigoBuscandoFase2 = codigo;
                });
              }
              final fallbackResult = await _buscarRelacionadosFase2(codigo);
              if (mounted) {
                setState(() {
                  _buscandoRelacionadosFase2 = false;
                  _codigoBuscandoFase2 = null;
                });
              }
              if (mounted && fallbackResult != null && (fallbackResult['items'] as List).length >= 3) {
                setState(() {
                  _mostrarFallbackFase2 = true;
                  _fallbackFase2Items = List<Map<String, dynamic>>.from(fallbackResult['items'] as List);
                  _queryFallbackFase2 = codigo;
                  _safetyNoteFase2 = fallbackResult['safety_note'] as String?;
                });
                return null;
              }
              // Si Fase 2 no devolvió 3 códigos, abrir pilotaje manual como antes
              if (mounted) await _abrirPilotajeManualDesdeBusqueda(codigo);
              final mensajeRaw = responseData['mensaje']?.toString() ??
                  'No se encontraron secuencias oficiales de Grabovoi para este tema.';
              final mensaje = mensajeRaw
                  .replaceAll('códigos', 'secuencias')
                  .replaceAll('código', 'secuencia');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$mensaje Puedes crear tu propia secuencia personalizada.',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
              return null;
            }

            if (responseData['codigos'] != null && responseData['codigos'] is List) {
              final codigosList = responseData['codigos'] as List;
              final codigosEncontrados = <CodigoGrabovoi>[];

              for (var codigoData in codigosList) {
                if (codigoData['codigo'] != null && codigoData['codigo'].toString().isNotEmpty) {
                  var codigoNumero = codigoData['codigo'].toString().replaceAll(' ', '_').replaceAll('-', '_');

                  // Validar siempre contra la base, no inventar códigos inexistentes
                  final codigoExiste = await _validarCodigoEnBaseDatos(codigoNumero);
                  if (!codigoExiste) {
                    print('❌ Código sugerido sin respaldo en BD: $codigoNumero. Se descarta.');
                    continue;
                  }

                  final nombre = codigoData['nombre']?.toString() ?? 'Secuencia relacionada';
                  String descripcionReal = codigoData['descripcion']?.toString() ?? '';
                  if (descripcionReal.isEmpty || descripcionReal.contains('Secuencia sugerida por IA')) {
                    descripcionReal = _generarDescripcionDesdeNombre(nombre);
                  }
                  final categoriaRaw = codigoData['categoria']?.toString() ?? '';
                  final categoria = (categoriaRaw.isEmpty || categoriaRaw.toLowerCase() == 'codigo')
                      ? _determinarCategoria(nombre)
                      : categoriaRaw;

                  final codigoExistente = await SupabaseService.getCodigoExistente(codigoNumero);
                  if (codigoExistente != null) {
                    final descripcionFinal = descripcionReal.isNotEmpty && descripcionReal.length > 20
                        ? descripcionReal
                        : codigoExistente.descripcion;

                    codigosEncontrados.add(CodigoGrabovoi(
                      id: codigoExistente.id,
                      codigo: codigoNumero,
                      nombre: nombre.isNotEmpty ? nombre : codigoExistente.nombre,
                      descripcion: descripcionFinal,
                      categoria: categoria,
                      color: codigoExistente.color,
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

  /// Flujo B Fase 2: recomienda 3 códigos relacionados desde catálogo local cuando no hay fuente externa.
  /// Retorna { 'items': [ { 'codigo': CodigoGrabovoi, 'why_recommended': String }, ... ], 'safety_note': String? } o null.
  Future<Map<String, dynamic>?> _buscarRelacionadosFase2(String userQueryText) async {
    try {
      final exactCode = exactCodeFromQuery(userQueryText);
      final isNumeric = isNumericQuery(userQueryText);
      List<CodigoGrabovoi> candidates = await SupabaseService.getCandidatosParaFallbackRelacionados(
        userQueryText: userQueryText,
        isNumericQuery: isNumeric,
        exactCode: exactCode,
        maxCandidatos: 60,
      );
      // Búsqueda por código: solo recomendar códigos que CONTENGAN la secuencia (ej. 520_741 → 5207418).
      // Si no hay al menos 3, no mostrar recomendaciones no relacionadas; se guiará a pilotaje manual.
      if (isNumeric && exactCode != null) {
        final queryDigitos = codigoSoloDigitos(exactCode);
        candidates = candidates.where((c) =>
            codigoSoloDigitos(normalizarCodigo(c.codigo)).contains(queryDigitos)).toList();
        if (candidates.length < 3) {
          print('ℹ️ Fase 2: búsqueda por código "$userQueryText": solo ${candidates.length} códigos contienen la secuencia. Se guía a pilotaje manual.');
          return null;
        }
      }
      if (candidates.length < 3) {
        print('⚠️ Fase 2: menos de 3 candidatos (${candidates.length}), no se puede recomendar 3.');
        return null;
      }
      final jsonCandidates = candidates.map((c) => {
        'code': normalizarCodigo(c.codigo),
        'title': c.nombre,
        'section': c.categoria,
        'description': c.descripcion.length > 200 ? '${c.descripcion.substring(0, 200)}...' : c.descripcion,
      }).toList();
      const systemFase2 =
          'Eres un motor de recomendación de secuencias numéricas basado en un catálogo local. No inventes códigos. Solo puedes elegir códigos que estén en CANDIDATES. No prometas curas; usa lenguaje de apoyo (armonización, regulación). Devuelve JSON válido y nada más.';
      final userFase2 = '''
TAREA
El usuario no obtuvo una fuente externa confiable para su búsqueda exacta.
Debes recomendar EXACTAMENTE 3 códigos RELACIONADOS CON LA INTENCIÓN O TEMA de la búsqueda, seleccionados SOLO del catálogo en CANDIDATES.

REGLAS DE RELEVANCIA (OBLIGATORIAS)
- La búsqueda del usuario fue: "$userQueryText". Las recomendaciones DEBEN ser temáticamente o semánticamente relacionadas con esa intención.
- Para búsquedas de DEPORTE / ACTIVIDAD FÍSICA (futbol, deporte, ejercicio, correr, etc.): prioriza SOLO códigos sobre rendimiento físico, vitalidad, recuperación, lesiones, energía, músculos, articulaciones. NUNCA recomiendes códigos de Amor/relaciones, problemas digestivos o cardíacos específicos para una búsqueda de deporte.
- Para otras búsquedas: no recomiendes códigos de temas no relacionados (ej. no Amor para una búsqueda de deporte).
- relation_score debe reflejar la relación real: 70-100 = vínculo claro con el tema; 40-69 = apoyo relacionado (vitalidad, recuperación); 20-39 = solo si no hay 3 claramente relacionados, indica "apoyo general" en why_recommended.
- Si en CANDIDATES no hay 3 códigos claramente relacionados con la búsqueda, elige los 3 más cercanos (ej. vitalidad, recuperación, energía, rendimiento) y pon relation_score bajo (20-40) explicando en why_recommended que son de apoyo general.
- NO inventes secuencias. Solo devuelve códigos presentes en CANDIDATES.
- Cada recomendación: code, title, section, relation_type, relation_score(0-100), why_recommended, usage_note.
- relation_type: synonym_equivalent, symptom_related, cause_related, supportive_regulation, goal_higher_level, recovery_acceleration, prevention_protection
- Devuelve siempre 3. No uses "cura", "sanar definitivamente", "garantiza". safety_note breve.

INPUT
USER_QUERY_TEXT: $userQueryText
IS_NUMERIC_QUERY: $isNumeric
EXACT_CODE: ${exactCode ?? 'null'}

CANDIDATES:
${jsonEncode(jsonCandidates)}

OUTPUT (JSON ESTRICTO)
{
  "mode": "related_fallback",
  "exact_query": { "is_numeric": $isNumeric, "code": ${exactCode != null ? '"$exactCode"' : 'null'}, "text": "$userQueryText" },
  "related": [
    { "code": "string", "title": "string", "section": "string", "relation_type": "string", "relation_score": number, "why_recommended": "string", "usage_note": "string" }
  ],
  "safety_note": "string"
}
''';
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Env.openAiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': systemFase2},
            {'role': 'user', 'content': userFase2},
          ],
          'max_tokens': 800,
          'temperature': 0.5,
        }),
      );
      if (response.statusCode != 200) {
        print('❌ Fase 2 OpenAI error: ${response.statusCode}');
        return null;
      }
      final data = jsonDecode(response.body);
      final content = data['choices']?[0]?['message']?['content']?.toString() ?? '';
      if (content.isEmpty) return null;
      String cleaned = content.trim();
      final start = cleaned.indexOf('{');
      final end = cleaned.lastIndexOf('}') + 1;
      if (start >= 0 && end > start) cleaned = cleaned.substring(start, end);
      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
      final related = parsed['related'] as List? ?? [];
      final safetyNote = parsed['safety_note']?.toString();
      final items = <Map<String, dynamic>>[];
      for (var i = 0; i < related.length && items.length < 3; i++) {
        final r = related[i] as Map<String, dynamic>;
        final codeStr = (r['code'] ?? '').toString().replaceAll(' ', '_').replaceAll('-', '_');
        final normalized = normalizarCodigo(codeStr);
        CodigoGrabovoi? c = await SupabaseService.getCodigoExistente(normalized);
        if (c == null) c = await SupabaseService.getCodigoExistente(exactCodeWithSpaces(normalized));
        if (c != null) {
          items.add({
            'codigo': c,
            'why_recommended': (r['why_recommended'] ?? '').toString(),
          });
        }
      }
      if (items.length < 3) {
        print('⚠️ Fase 2: solo ${items.length} códigos válidos en BD.');
        return null;
      }
      return {'items': items, 'safety_note': safetyNote};
    } catch (e) {
      print('❌ _buscarRelacionadosFase2: $e');
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
          
          // 1. Refrescar el repositorio para asegurar que el código nuevo esté disponible
          await CodigosRepository().refreshCodigos();
          print('🔄 Repositorio refrescado');
          
          // 2. Actualizar lista de códigos para que el contador se actualice
          await _load();
          print('🔄 Lista de códigos recargada');
          
          // 3. Si hay una búsqueda activa, aplicar el filtro automáticamente
          // para que el código recién guardado aparezca en los resultados
          if (query.isNotEmpty || _queryBusqueda.isNotEmpty) {
            final queryActiva = query.isNotEmpty ? query : _queryBusqueda;
            print('🔄 Aplicando filtro automático después de guardar código desde selección: "$queryActiva"');
            // Pequeño delay para asegurar que los datos estén completamente cargados
            await Future.delayed(const Duration(milliseconds: 300));
            if (mounted) {
              setState(() {
                // Aplicar el filtro para mostrar el código recién guardado
                _aplicarFiltros();
              });
              print('✅ Filtro aplicado, códigos visibles: ${visible.length}');
            }
          }
          
          print('✅ Contador de secuencias actualizado: ${_codigos.length} códigos disponibles');
          // El modal de confirmación ya se muestra en _guardarCodigoEnBaseDatos
        }
      } catch (e) {
        print('⚠️ Error al guardar código nuevo: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar secuencia: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return; // Salir si hay error
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
              content: Text('✅ Secuencia seleccionada: ${codigo.nombre}'),
              backgroundColor: const Color(0xFF4CAF50),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
    
    // Actualizar estado y precargar el código seleccionado
    setState(() {
      _mostrarSeleccionCodigos = false;
      _codigosEncontrados = [];
      // Precargar el código en el campo de búsqueda para mostrarlo
      _searchController.text = codigo.codigo;
      _queryBusqueda = codigo.codigo;
      query = codigo.codigo;
      _mostrarResultados = false;
    });
    
    // Recargar códigos para mostrar el nuevo código en la lista
    await _load();
    
    // Filtrar para mostrar solo el código seleccionado (recientemente agregado)
    _filtrarCodigos(codigo.codigo);
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
      return 'Secuencia de manifestación numérica para transformación positiva.';
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
      return 'Secuencia de manifestación para ${nombre.toLowerCase()}. Activa procesos de transformación positiva relacionados con este propósito.';
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

  Future<void> _mostrarMensajeNoEncontrado() async {
    setState(() {
      _showOptionsModal = false;
    });

    // Usar la última búsqueda conocida para prellenar el pilotaje manual
    String ultimaConsulta = '';
    if (_codigoBuscando != null && _codigoBuscando!.trim().isNotEmpty) {
      ultimaConsulta = _codigoBuscando!.trim();
    } else if (_queryBusqueda.trim().isNotEmpty) {
      ultimaConsulta = _queryBusqueda.trim();
    } else if (_searchController.text.trim().isNotEmpty) {
      ultimaConsulta = _searchController.text.trim();
    }

    if (ultimaConsulta.isNotEmpty) {
      await _abrirPilotajeManualDesdeBusqueda(ultimaConsulta);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'No se encontraron secuencias oficiales para tu búsqueda. '
          'Puedes crear tu propia secuencia personalizada basada en tu intención.',
          style: TextStyle(fontSize: 14),
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 6),
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

  Future<void> _compartirCodigo(CodigoGrabovoi codigo) async {
    try {
      if (!mounted) return;
      setState(() {
        _codigoParaCompartir = codigo;
      });

      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 200));

      final Uint8List? pngBytes = await _shareController.capture(pixelRatio: 2.0);

      if (pngBytes == null || pngBytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo generar la imagen. Intenta nuevamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await ShareHelper.shareImage(
        pngBytes: pngBytes,
        fileName: 'grabovoi_${codigo.codigo}',
        text: 'Compartido desde ManiGraB - Manifestaciones Cuánticas Grabovoi',
        context: context,
      );

      try {
        ChallengeProgressTracker().trackPilotageShared(
          codeId: codigo.codigo,
          codeName: codigo.nombre,
        );
      } catch (e) {
        print('⚠️ Error registrando pilotaje compartido: $e');
      }
    } catch (e) {
      print('❌ Error al compartir imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildShareableImage(String codigoCrudo, String titulo, String descripcion) {
    return Container(
      width: 800,
      height: 800,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage('assets/images/ManiGrab-esfera.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 140),
            Expanded(
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.80,
                  child: Text(
                    codigoCrudo,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: GoogleFonts.spaceMono(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 6,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.8),
                          blurRadius: 6,
                          offset: const Offset(2, 2),
                        ),
                        Shadow(
                          color: Colors.white.withOpacity(0.8),
                          blurRadius: 30,
                          offset: Offset.zero,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titulo,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFD700),
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.7),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      descripcion,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        height: 1.35,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.7),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Secuencias numéricas de manifestación',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  
                  // Contador de códigos y botón de favoritos activo en una sola fila
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total de secuencias: ${visible.length}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFFFFD700),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Botón de Favoritos activo (solo cuando se muestran favoritos)
                      if (mostrarFavoritos)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: FilterChip(
                            avatar: Icon(
                              Icons.favorite,
                              size: 18,
                              color: const Color(0xFF0B132B),
                            ),
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Favoritos'),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.close,
                                  size: 16,
                                  color: const Color(0xFF0B132B).withOpacity(0.7),
                                ),
                              ],
                            ),
                            selected: true,
                            onSelected: (_) {
                              _toggleFavoritos();
                            },
                            selectedColor: const Color(0xFFFFD700),
                            backgroundColor: Colors.white.withOpacity(0.08),
                            labelStyle: const TextStyle(
                              color: Color(0xFF0B132B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Barra de búsqueda (solo cuando NO están habilitados los favoritos)
                  if (!mostrarFavoritos) ...[
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 360;
                        return TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            // Si empieza con número: solo dígitos, "_" y espacio (no letras ni "-")
                            final filtrado = _filtrarEntradaBusqueda(value);
                            if (filtrado != value) {
                              final cursorPos = filtrado.length;
                              _searchController.value = TextEditingValue(
                                text: filtrado,
                                selection: TextSelection.collapsed(offset: cursorPos),
                              );
                            }
                            query = filtrado;
                            _queryBusqueda = filtrado;
                            _filtrarCodigos(filtrado);
                          },
                          onSubmitted: (value) {
                            _confirmarBusqueda();
                          },
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            hintText: 'Buscar secuencia, intención o categoría...',
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
                                          tooltip: 'Buscar secuencia completa',
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
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(16)),
                              borderSide: BorderSide(color: Color(0xFFFFD700)),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Filtros de categoría y botón de favoritos (solo cuando NO se muestran favoritos)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Botón de Favoritos (siempre visible cuando hay favoritos)
                          if (_tieneFavoritos)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                avatar: Icon(
                                  Icons.favorite,
                                  size: 18,
                                  color: mostrarFavoritos
                                      ? const Color(0xFF0B132B)
                                      : Colors.white70,
                                ),
                                label: const Text(
                                  'Favoritos',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                selected: mostrarFavoritos,
                                onSelected: (_) {
                                  _toggleFavoritos();
                                },
                                selectedColor: const Color(0xFFFFD700),
                                backgroundColor: Colors.white.withOpacity(0.08),
                                labelStyle: TextStyle(
                                  color: mostrarFavoritos ? const Color(0xFF0B132B) : Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          // Filtros de categoría
                          ...categorias.map((cat) {
                            final selected = categoriaSeleccionada == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(
                                  cat,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
                        ],
                      ),
                    ),
                  ],
                  
                  // Filtros de etiquetas (solo cuando se muestran favoritos)
                  if (mostrarFavoritos) ...[
                    const SizedBox(height: 12),
                    // "Filtrar por etiqueta:" y etiquetas en una sola fila
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Text(
                            'Filtrar por etiqueta:',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 12),
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildContent(),
                  );
                },
              ),
            ),
          ],
            ),
          ),
          // Widget oculto para generar la imagen compartible de cada secuencia
          Positioned(
            left: -1000,
            top: -1000,
            child: IgnorePointer(
              ignoring: true,
              child: SizedBox(
                width: 800,
                height: 800,
                child: Screenshot(
                  controller: _shareController,
                  child: _codigoParaCompartir == null
                      ? const SizedBox.shrink()
                      : _buildShareableImage(
                          _codigoParaCompartir!.codigo,
                          _codigoParaCompartir!.nombre.isNotEmpty
                              ? _codigoParaCompartir!.nombre
                              : 'Campo Energético',
                          _codigoParaCompartir!.descripcion.isNotEmpty
                              ? _codigoParaCompartir!.descripcion
                              : 'Secuencia cuántica para la manifestación y transformación energética.',
                        ),
                ),
              ),
            ),
          ),
          // Modales de búsqueda profunda (flujo B)
          if (_showOptionsModal) _buildOptionsModal(),
          if (_mostrarFallbackFase2) _buildFallbackFase2Modal(),
          if (_buscandoRelacionadosFase2) _buildBuscandoRelacionadosFase2Modal(),
          if (_showManualPilotage) _buildManualPilotageModal(),
          if (_mostrarSeleccionCodigos) _buildSeleccionCodigosModal(),
          if (_buscandoConIA) _buildBuscandoConIAModal(),
          if (_mostrarConfirmacionGuardado) _buildConfirmacionGuardadoModal(),
          
          // Botón flotante para volver al inicio
          if (_showFab)
            Positioned(
              bottom: 20, // En la esquina inferior derecha
              right: 20,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.7), // Semitransparente
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_upward,
                        size: 24,
                        color: Color(0xFF0B132B),
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
                  'Secuencia no encontrada',
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
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
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
                const SizedBox(height: 20),
                // Opción 1: Búsqueda Profunda
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showOptionsModal = false;
                      });
                      _busquedaProfunda(_codigoNoEncontrado ?? _queryBusqueda);
                    },
                    icon: const Icon(Icons.psychology, color: Colors.white),
                    label: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Búsqueda Profunda',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Esto consulta fuentes externas y puede tardar.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
                // Opción 2: Pilotaje Manual
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _iniciarPilotajeManual,
                    icon: const Icon(Icons.edit, color: Color(0xFFFFD700)),
                    label: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pilotaje Manual',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Crea y guarda tu secuencia personalizada con nombre, descripción y categoría',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.centerLeft,
                    ),
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

  /// Flujo B Fase 2: UI de 3 códigos relacionados cuando no hay fuente externa.
  Widget _buildFallbackFase2Modal() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2541),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'No encontramos una secuencia que resuene con tu búsqueda.',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estas 3 secuencias están relacionadas y pueden servir como alternativa.',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  if (_safetyNoteFase2 != null && _safetyNoteFase2!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(_safetyNoteFase2!.replaceAll('códigos', 'secuencias').replaceAll('código', 'secuencia'), style: GoogleFonts.inter(fontSize: 12, color: Colors.orange), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 20),
                  ..._fallbackFase2Items.map((item) {
                    final c = item['codigo'] as CodigoGrabovoi;
                    final why = (item['why_recommended'] ?? '').toString();
                    final codeDisplay = normalizarCodigo(c.codigo);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(codeDisplay, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFFFD700))),
                          const SizedBox(height: 4),
                          Text(c.nombre, style: GoogleFonts.inter(fontSize: 14, color: Colors.white)),
                          Text(c.categoria, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                          if (why.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(why, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _prefiltrarBibliotecaConCodigo(c);
                              },
                              icon: const Icon(Icons.touch_app, size: 18),
                              label: const Text('Usar esta secuencia'),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final q = _queryFallbackFase2;
                      setState(() {
                        _mostrarFallbackFase2 = false;
                        _fallbackFase2Items = [];
                        _queryFallbackFase2 = '';
                        _safetyNoteFase2 = null;
                      });
                      await _abrirPilotajeManualDesdeBusqueda(q);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.edit, color: Color(0xFFFFD700), size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ir a pilotaje manual',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFFFD700),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Crea y guarda tu secuencia personalizada con nombre, descripción y categoría.',
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _mostrarFallbackFase2 = false;
                        _fallbackFase2Items = [];
                        _queryFallbackFase2 = '';
                        _safetyNoteFase2 = null;
                      });
                    },
                    child: const Text('Cerrar', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Mapea categoría de BD (ej. "Amor", "Salud") al valor exacto del dropdown para evitar assertion.
  static const _dropdownCategorias = [
    'Abundancia y Prosperidad',
    'Amor y Relaciones',
    'Conciencia Espiritual',
    'Liberación Emocional',
    'Limpieza y Reconexión',
    'Protección Energética',
    'Salud y Regeneración',
  ];
  String _categoriaParaDropdown(String? cat) {
    if (cat == null || cat.isEmpty) return _dropdownCategorias.first;
    final c = cat.toLowerCase();
    if (c.contains('amor') || c.contains('relacion')) return 'Amor y Relaciones';
    if (c.contains('salud')) return 'Salud y Regeneración';
    if (c.contains('abundancia') || c.contains('prosperidad') || c.contains('manifestacion')) return 'Abundancia y Prosperidad';
    if (c.contains('energia') || c.contains('vitalidad') || c.contains('crecimiento')) return 'Salud y Regeneración';
    if (c.contains('proteccion')) return 'Protección Energética';
    if (c.contains('espiritual') || c.contains('conciencia')) return 'Conciencia Espiritual';
    if (c.contains('emocional') || c.contains('liberacion')) return 'Liberación Emocional';
    if (c.contains('limpieza') || c.contains('reconexion')) return 'Limpieza y Reconexión';
    return 'Abundancia y Prosperidad';
  }

  /// Cierra el modal Fase 2 y muestra la biblioteca con el código seleccionado prefiltrado
  /// (el código ya existe en la DB; no se abre pilotaje manual).
  void _prefiltrarBibliotecaConCodigo(CodigoGrabovoi c) {
    final codigoNorm = normalizarCodigo(c.codigo);
    setState(() {
      _mostrarFallbackFase2 = false;
      _fallbackFase2Items = [];
      _queryFallbackFase2 = '';
      _safetyNoteFase2 = null;
      query = codigoNorm;
      _queryBusqueda = codigoNorm;
    });
    _searchController.text = codigoNorm;
    _aplicarFiltros();
  }

  void _abrirPilotajeManualConCodigo(CodigoGrabovoi c) {
    _manualCodeController.text = normalizarCodigo(c.codigo);
    _manualTitleController.text = c.nombre;
    _manualDescriptionController.text = c.descripcion;
    final cats = categorias.where((x) => x != 'Todos').toList();
    setState(() {
      _showManualPilotage = true;
      _manualCategory = cats.isNotEmpty && cats.contains(c.categoria)
          ? c.categoria
          : _categoriaParaDropdown(c.categoria);
    });
  }

  Future<void> _iniciarPilotajeManual() async {
    final textoBusqueda = _codigoNoEncontrado ?? _queryBusqueda ?? query ?? '';
    final esCodigo = textoBusqueda.isNotEmpty && _esBusquedaPorCodigo(textoBusqueda);
    if (textoBusqueda.isNotEmpty && esCodigo) {
      final normalizado = normalizarCodigo(textoBusqueda);
      final yaGuardado = await _secuenciaYaEnPilotajeManual(normalizado);
      if (mounted && yaGuardado != null) {
        _redirigirAVistaSecuenciaGuardadaEnFavoritos(yaGuardado, normalizado);
        return;
      }
    }
    if (textoBusqueda.isNotEmpty) {
      if (esCodigo) {
        _manualCodeController.text = normalizarCodigo(textoBusqueda);
        _manualTitleController.clear();
      } else {
        _manualTitleController.text = textoBusqueda;
        _manualCodeController.clear();
      }
    }
    if (!mounted) return;
    setState(() {
      _showManualPilotage = true;
      _showOptionsModal = false;
    });
  }

  Widget _buildManualPilotageModal() {
    // Usar categorías que existen en los códigos (sin "Todos"); si no hay, fallback a lista fija
    final categoriasDeCodigos = categorias.where((c) => c != 'Todos').toList();
    final categoriasDisponibles = categoriasDeCodigos.isNotEmpty
        ? categoriasDeCodigos
        : _dropdownCategorias;
    final valueDropdown = categoriasDisponibles.contains(_manualCategory)
        ? _manualCategory
        : categoriasDisponibles.first;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: SingleChildScrollView(
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
                    'Pilotaje Manual',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingresa tu secuencia personalizada',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _manualCodeController,
                    decoration: InputDecoration(
                      labelText: 'Secuencia',
                      hintText: 'Ej: 123_456_789',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFFD700)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _manualTitleController,
                    decoration: InputDecoration(
                      labelText: 'Título',
                      hintText: 'Ej: Mi secuencia personalizada',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFFD700)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _manualDescriptionController,
                    decoration: InputDecoration(
                      labelText: 'Descripción',
                      hintText: 'Ej: Descripción de la secuencia personalizada',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFFD700)),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: valueDropdown,
                    decoration: InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFFD700)),
                      ),
                    ),
                    items: categoriasDisponibles.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _manualCategory = value ?? categoriasDisponibles.first;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _guardarCodigoManual,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            foregroundColor: const Color(0xFF0B132B),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Guardar y Usar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _showManualPilotage = false;
                              _manualCodeController.clear();
                              _manualTitleController.clear();
                              _manualDescriptionController.clear();
                            });
                          },
                          child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _guardarCodigoManual() async {
    if (_manualCodeController.text.isEmpty || _manualTitleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final customCodesService = UserCustomCodesService();
      
      // Guardar secuencia personalizada
      final success = await customCodesService.saveCustomCode(
        codigo: _manualCodeController.text,
        nombre: _manualTitleController.text,
        categoria: _manualCategory,
        descripcion: _manualDescriptionController.text.isNotEmpty 
            ? _manualDescriptionController.text 
            : 'Secuencia personalizada del usuario',
      );

      if (success) {
        // Guardar valores antes de limpiar
        final codigoGuardado = _manualCodeController.text;
        final nombreGuardado = _manualTitleController.text;
        final categoriaGuardada = _manualCategory;
        
        setState(() {
          _showManualPilotage = false;
          _manualCodeController.clear();
          _manualTitleController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Secuencia guardada en favoritos'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );

        // Navegar a repetición de la secuencia recién guardada; el usuario verá
        // un aviso central indicando que está en Favoritos con el nombre que puso
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RepetitionSessionScreen(
              codigo: codigoGuardado,
              nombre: nombreGuardado,
              nombrePilotajeManualEnFavoritos: nombreGuardado,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: La secuencia ya existe o no se pudo guardar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                  'Buscando con Inteligencia Cuántica Vibracional',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  'Analizando secuencias relacionadas con "${_codigoBuscando ?? 'tu búsqueda'}"',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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

  /// Modal de espera cuando no hay secuencia que resuene y se buscan secuencias RELACIONADAS (Fase 2).
  Widget _buildBuscandoRelacionadosFase2Modal() {
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
                  'No encontramos una secuencia que resuene con tu búsqueda.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Text(
                  'Buscando secuencias RELACIONADAS para ti...',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFD700),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '"${_codigoBuscandoFase2 ?? 'tu búsqueda'}"',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  'Un momento, por favor...',
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
                  'Secuencia Guardada',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  _codigoGuardadoNombre ?? 'Secuencia guardada exitosamente',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'La secuencia ha sido agregada permanentemente a la biblioteca',
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
                      
                      // Si hay una búsqueda activa, asegurar que el filtro esté aplicado
                      if (query.isNotEmpty || _queryBusqueda.isNotEmpty) {
                        _aplicarFiltros();
                      }
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final mediaQuery = MediaQuery.of(context);
              final textScale = mediaQuery.textScaleFactor.clamp(1.0, 1.3);
              final maxWidth = (mediaQuery.size.width * 0.9).clamp(320.0, 540.0);
              final maxHeight = (mediaQuery.size.height * 0.8).clamp(380.0, 640.0);

              return MediaQuery(
                data: mediaQuery.copyWith(textScaleFactor: textScale),
                child: Container(
                  width: maxWidth,
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2541),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secuencias encontradas',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFFD700),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selecciona la secuencia que mejor se adapte a tu necesidad:',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _codigosEncontrados.map((codigo) {
                              return ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 260,
                                  maxWidth: 320,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _seleccionarCodigo(codigo),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2C3E50).withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: _getCategoryColor(codigo.categoria).withOpacity(0.4),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: _getCategoryColor(codigo.categoria).withOpacity(0.2),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.water_drop,
                                                  color: _getCategoryColor(codigo.categoria),
                                                  size: 14,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: _getCategoryColor(codigo.categoria).withOpacity(0.2),
                                                        borderRadius: BorderRadius.circular(10),
                                                        border: Border.all(
                                                          color: _getCategoryColor(codigo.categoria).withOpacity(0.6),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        codigo.codigo,
                                                        style: GoogleFonts.spaceMono(
                                                          color: _getCategoryColor(codigo.categoria),
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      codigo.nombre,
                                                      style: GoogleFonts.inter(
                                                        color: Colors.white,
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            codigo.descripcion,
                                            style: GoogleFonts.inter(
                                              color: Colors.white.withOpacity(0.85),
                                              fontSize: 14,
                                              height: 1.4,
                                            ),
                                            maxLines: 4,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.category,
                                                color: _getCategoryColor(codigo.categoria),
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  codigo.categoria,
                                                  style: GoogleFonts.inter(
                                                    color: _getCategoryColor(codigo.categoria),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Sugerido por IA',
                                                style: GoogleFonts.inter(
                                                  color: Colors.white54,
                                                  fontSize: 11,
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
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
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
                      ),
                    ],
                  ),
                ),
              );
            },
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
            Text('Cargando secuencias desde CDN...'),
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
            Text('Error al cargar las secuencias:', 
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
      // Si hay una búsqueda activa y tiene la secuencia en Favoritos (pilotaje manual), mostrar el card
      if (_queryBusqueda.isNotEmpty) {
        if (_tieneSecuenciaEnFavoritosPilotajeManual && _codigoFavoritoPilotajeManualCoincidente != null) {
          final codigoFav = _codigoFavoritoPilotajeManualCoincidente!;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
                  ),
                  child: Text(
                    'Resultado de tus Favoritos — no forma parte de las secuencias generales.',
                    style: GoogleFonts.inter(color: Colors.orange, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: _buildCodigoCard(codigoFav),
                  ),
                ),
              ],
            ),
          );
        }
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
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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
            Text('No hay secuencias disponibles.'),
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
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: visible.length + (_mostrarOpcionBusquedaExacta ? 1 : 0),
        itemBuilder: (context, index) {
          if (_mostrarOpcionBusquedaExacta && index == visible.length) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _buildOpcionBusquedaExacta(),
              ),
            );
          }
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

  /// Banner "¿No está tu código? Buscar código exacto" cuando hay parciales pero no exacto.
  Widget _buildOpcionBusquedaExacta() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            _confirmarBusqueda();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.search, color: const Color(0xFFFFD700), size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '¿No está tu secuencia?',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Buscar secuencia exacta "$_queryBusqueda" o usar búsqueda profunda / pilotaje manual',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Color(0xFFFFD700), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodigoCard(CodigoGrabovoi codigo) {
    final offset = _swipeOffsets[codigo.codigo] ?? 0.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth - 40; // Ancho del card (padding incluido)
    final reportWidth = cardWidth * 0.42; // 42% del ancho para el área de reporte (más visible)
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Área de reporte (detrás del card, a la derecha)
          Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            width: reportWidth,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildReportArea(codigo, reportWidth),
            ),
          ),
          // Card principal (se desliza)
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              // Solo permitir deslizamiento hacia la izquierda
              if (details.delta.dx < 0) {
                setState(() {
                  final newOffset = (offset + details.delta.dx).clamp(-reportWidth, 0.0);
                  _swipeOffsets[codigo.codigo] = newOffset;
                });
              } else if (details.delta.dx > 0 && offset < 0) {
                // Permitir volver a la posición original deslizando hacia la derecha
                setState(() {
                  final newOffset = (offset + details.delta.dx).clamp(-reportWidth, 0.0);
                  _swipeOffsets[codigo.codigo] = newOffset;
                });
              }
            },
            onHorizontalDragEnd: (details) {
              // Si se deslizó más de la mitad, mantener abierto, sino cerrar
              final threshold = -reportWidth / 2;
              setState(() {
                if (offset < threshold) {
                  _swipeOffsets[codigo.codigo] = -reportWidth;
                } else {
                  _swipeOffsets[codigo.codigo] = 0.0;
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(offset, 0, 0),
              child: Container(
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
                        // Botón de favorito con etiqueta (usando caché)
                        Builder(
                          builder: (context) {
                            final isFavorite = _esFavoritoCached(codigo.codigo);
                            final etiqueta = _getEtiquetaCached(codigo.codigo);
                            final isCustom = _esCodigoPersonalizado(codigo.codigo);
                            
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    if (isFavorite) {
                                      // Si es secuencia personalizada, mostrar advertencia
                                      if (isCustom) {
                                        final confirmar = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor: const Color(0xFF1C2541),
                                            title: Text(
                                              '⚠️ Advertencia',
                                              style: GoogleFonts.inter(
                                                color: Colors.orange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            content: Text(
                                              'Esta secuencia fue insertada manualmente. Si la eliminas de favoritos, no podrás volver a verla hasta que la insertes nuevamente de forma manual.\n\n¿Deseas continuar?',
                                              style: GoogleFonts.inter(color: Colors.white),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: Text(
                                                  'Cancelar',
                                                  style: GoogleFonts.inter(color: Colors.white70),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                                child: Text(
                                                  'Eliminar',
                                                  style: GoogleFonts.inter(color: Colors.white),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                        
                                        if (confirmar != true) {
                                          return; // Usuario canceló
                                        }
                                        
                                        // Eliminar secuencia personalizada
                                        try {
                                          final customCodesService = UserCustomCodesService();
                                          await customCodesService.deleteCustomCode(codigo.codigo);
                                          
                                          // Actualizar caché
                                          _favoritosCache.remove(codigo.codigo);
                                          _etiquetasCache.remove(codigo.codigo);
                                          _customCodesCache.remove(codigo.codigo);
                                          
                                          // Actualizar estado
                                          await _actualizarEstadoFavoritos();
                                          
                                          if (mounted) {
                                            setState(() {});
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('❌ ${codigo.nombre} eliminado de favoritos'),
                                                backgroundColor: Colors.red,
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          print('Error eliminando secuencia personalizada: $e');
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Error: ${e.toString()}'),
                                                backgroundColor: Colors.red,
                                                duration: const Duration(seconds: 3),
                                              ),
                                            );
                                          }
                                        }
                                      } else {
                                        // Si ya es favorito (no personalizado), removerlo directamente
                                      try {
                                        await BibliotecaSupabaseService.toggleFavorito(codigo.codigo);
                                          
                                          // Actualizar caché
                                          _favoritosCache.remove(codigo.codigo);
                                          _etiquetasCache.remove(codigo.codigo);
                                          
                                        // Actualizar estado de favoritos después de remover
                                        await _actualizarEstadoFavoritos();
                                          
                                          if (mounted) {
                                            setState(() {});
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('❌ ${codigo.nombre} removido de favoritos'),
                                            backgroundColor: Colors.red,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                          }
                                      } catch (e) {
                                        print('Error removiendo favorito: $e');
                                          if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: ${e.toString()}'),
                                            backgroundColor: Colors.red,
                                            duration: const Duration(seconds: 3),
                                          ),
                                        );
                                          }
                                        }
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
                                if (isFavorite && etiqueta != null && etiqueta.isNotEmpty)
                                  Container(
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
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.share,
                                color: Color(0xFFFFD700),
                                size: 20,
                              ),
                              tooltip: 'Compartir imagen',
                              onPressed: () => _compartirCodigo(codigo),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.copy,
                                color: Color(0xFFFFD700),
                                size: 20,
                              ),
                              tooltip: 'Copiar secuencia',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: codigo.codigo));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Secuencia ${codigo.codigo} copiada al portapapeles'),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: const Color(0xFFFFD700).withOpacity(0.9),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ],
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
                    
                    // Títulos relacionados (usando cache para evitar consultas repetitivas)
                    Builder(
                      builder: (context) {
                        // Usar cache en lugar de FutureBuilder para evitar consultas repetitivas durante scroll
                        final titulosRelacionados = _getTitulosRelacionados(codigo.codigo);
                        
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
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
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
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Iniciar sesión de repetición'),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.diamond, color: Color(0xFF0B132B), size: 14),
                                  const SizedBox(width: 3),
                                  const Text(
                                    '+3',
                                    style: TextStyle(
                                      color: Color(0xFF0B132B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget para el área de reporte que se muestra al deslizar
  Widget _buildReportArea(CodigoGrabovoi codigo, double width) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título
            Text(
              'Reportar',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0B132B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            
            // Número del código
            Text(
              'Secuencia:',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0B132B).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              codigo.codigo,
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0B132B),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            
            // Opciones de botones para el motivo del reporte (se envían directamente al presionar)
            _buildReportReasonButton(
              codigo,
              'Secuencia incorrecta',
              'codigo_incorrecto',
            ),
            const SizedBox(height: 8),
            _buildReportReasonButton(
              codigo,
              'Descripción incorrecta',
              'descripcion_incorrecta',
            ),
            const SizedBox(height: 8),
            _buildReportReasonButton(
              codigo,
              'Categoría incorrecta',
              'categoria_incorrecta',
            ),
          ],
        ),
      ),
    );
  }

  /// Widget para cada opción de botón del reporte
  /// Al presionar, envía el reporte directamente
  Widget _buildReportReasonButton(CodigoGrabovoi codigo, String label, String value) {
    return GestureDetector(
      onTap: () {
        // Enviar el reporte directamente al presionar el botón
        _enviarReporte(codigo, value);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0B132B).withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF0B132B).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF0B132B),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Método para enviar el reporte del código
  Future<void> _enviarReporte(CodigoGrabovoi codigo, String tipoReporte) async {
    try {
      // Obtener información del usuario actual
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        _mostrarNotificacionError('Debes iniciar sesión para reportar una secuencia');
        return;
      }

      final userData = await SupabaseService.getCurrentUser();
      final email = currentUser.email ?? userData?['email'] ?? '';

      // Guardar el reporte en Supabase
      await SupabaseService.guardarReporteCodigo(
        usuarioId: currentUser.id,
        email: email,
        codigoId: codigo.codigo,
        tipoReporte: tipoReporte,
      );

      // Cerrar el área de reporte y limpiar el estado
      setState(() {
        _swipeOffsets[codigo.codigo] = 0.0;
        _reportReasons[codigo.codigo] = null;
      });

      // Mostrar notificación elegante de éxito
      _mostrarNotificacionExito();
    } catch (e) {
      print('❌ Error enviando reporte: $e');
      _mostrarNotificacionError('Error al enviar el reporte. Por favor intenta nuevamente.');
    }
  }

  /// Muestra una notificación elegante de éxito
  void _mostrarNotificacionExito() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Reporte enviado',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Gracias por ayudarnos a mejorar',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981), // Verde elegante
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  /// Muestra una notificación de error
  void _mostrarNotificacionError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444), // Rojo elegante
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  void _mostrarModalRepeticion(CodigoGrabovoi codigo) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return _RepetitionInstructionsModal(codigo: codigo);
      },
    );
  }

  void _mostrarModalEtiquetado(CodigoGrabovoi codigo) async {
    final etiquetasExistentes = await BibliotecaSupabaseService.getEtiquetasFavoritos();
    if (!mounted) return;
    // Capturar ScaffoldMessenger antes de abrir el diálogo para usarlo en el callback async.
    // Tras Navigator.pop() el context del builder puede estar desactivado y .of(context) falla.
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FavoriteLabelModal(
        codigo: codigo.codigo,
        nombre: codigo.nombre,
        etiquetasExistentes: etiquetasExistentes,
        onSave: (etiqueta) async {
          try {
            await BibliotecaSupabaseService.agregarFavoritoConEtiqueta(codigo.codigo, etiqueta);
            if (!mounted) return;
            _favoritosCache[codigo.codigo] = true;
            _etiquetasCache[codigo.codigo] = etiqueta;
            await _actualizarEstadoFavoritos();
            if (!mounted) return;
            setState(() {});
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('❤️ ${codigo.nombre} agregado a favoritos con etiqueta: $etiqueta'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } catch (e) {
            print('Error agregando favorito con etiqueta: $e');
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        },
      ),
    );
  }
}

class _RepetitionInstructionsModal extends StatefulWidget {
  final CodigoGrabovoi codigo;
  
  const _RepetitionInstructionsModal({required this.codigo});

  @override
  State<_RepetitionInstructionsModal> createState() => _RepetitionInstructionsModalState();
}

class _RepetitionInstructionsModalState extends State<_RepetitionInstructionsModal> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollIndicator = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScrollPosition);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollPosition();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScrollPosition() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final canScroll = maxScroll > 0;
      final shouldShow = canScroll && currentScroll < maxScroll - 50;
      if (_showScrollIndicator != shouldShow) {
        setState(() {
          _showScrollIndicator = shouldShow;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
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
                  
                  // Mensaje principal - Mismo tamaño que la descripción de las tarjetas (icono modo concentración inline)
                  Text.rich(
                    TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(
                          text: 'La activación de las secuencias ocurre por resonancia, no por acumulación de repeticiones.\n\n'
                              'Una sola repetición con total enfoque puede ser más efectiva que cientos realizadas de forma automática.\n\n'
                              'Visualiza la secuencia dentro de una esfera de luz y repítela mentalmente hasta sentir que la energía se acomoda en armonía. Con esta app puedes materializar esos números y esa esfera de manera más fácil, usando la visualización interactiva que te ofrece la pantalla. El modo "Concentración" ',
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(Icons.fullscreen, size: 16, color: Colors.white70),
                          ),
                        ),
                        const TextSpan(
                          text: ' permite ver solo la esfera y las secuencias sin distracciones.\n\n'
                              'Lo esencial no es cuántas veces repitas, sino la calidad de tu atención e intención.\n\n'
                              'Para recibir los cristales de energía, debes "pilotar" 2 minutos seguidos con la secuencia seleccionada. Si lo cancelas, los cristales no serán entregados.',
                        ),
                      ],
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
                              codigo: widget.codigo.codigo,
                              nombre: widget.codigo.nombre,
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
                  const SizedBox(height: 12),
                  
                  // Badge con icono de cristal y +3
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.diamond, color: Color(0xFFFFD700), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '+3',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
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
            // Mensaje "Desliza hacia arriba" cuando hay contenido scrolleable
            if (_showScrollIndicator)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF1C2541).withOpacity(0.95),
                          const Color(0xFF1C2541),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.keyboard_arrow_up,
                          color: const Color(0xFFFFD700),
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Desliza hacia arriba',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFFD700),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
