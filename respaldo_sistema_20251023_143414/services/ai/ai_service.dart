import '../../models/user_progress.dart';
import 'recommendation_service.dart';
import 'progress_service.dart';
import 'habit_tracker.dart';

/// Servicio principal de IA que centraliza todas las funcionalidades inteligentes
class AIService {
  final RecommendationService _recommendationService;
  final ProgressService _progressService;
  final HabitTracker _habitTracker;

  AIService({
    RecommendationService? recommendationService,
    ProgressService? progressService,
    HabitTracker? habitTracker,
  })  : _recommendationService = recommendationService ?? RecommendationService(),
        _progressService = progressService ?? ProgressService(),
        _habitTracker = habitTracker ?? HabitTracker();

  // ============================================
  // MÉTODOS PÚBLICOS PRINCIPALES
  // ============================================

  /// Obtiene recomendaciones personalizadas para el dashboard
  Future<Map<String, dynamic>> obtenerDashboard() async {
    final progreso = await _habitTracker.obtenerProgreso();
    final sugerencias = _recommendationService.obtenerSugerenciasDiarias(progreso);
    final reporte = _progressService.generarReporte(progreso);
    
    return {
      'progreso': progreso,
      'sugerencias': sugerencias,
      'reporte': reporte,
      'energia': reporte['energiaPromedio'],
      'nivel': reporte['nivel'],
      'mensaje': reporte['mensaje'],
      'colorAura': reporte['colorAura'],
    };
  }

  /// Recomienda un código basado en categoría y progreso
  Future<String> obtenerCodigoRecomendado({String? categoria}) async {
    final progreso = await _habitTracker.obtenerProgreso();
    return _recommendationService.recomendarCodigo(categoria, progreso: progreso);
  }

  /// Sugiere un desafío personalizado
  Future<String> obtenerDesafioPersonalizado() async {
    final progreso = await _habitTracker.obtenerProgreso();
    return _recommendationService.sugerirDesafio(progreso);
  }

  /// Genera resumen energético completo
  Future<Map<String, dynamic>> obtenerResumenEnergetico() async {
    final progreso = await _habitTracker.obtenerProgreso();
    return _progressService.generarReporte(progreso);
  }

  /// Registra una sesión de práctica
  Future<void> registrarSesion({String? categoria}) async {
    await _habitTracker.registrarSesion();
  }

  /// Obtiene el progreso actual del usuario
  Future<UserProgress> obtenerProgreso() async {
    return await _habitTracker.obtenerProgreso();
  }

  /// Obtiene códigos complementarios
  List<String> obtenerCodigosComplementarios(String codigoPrincipal) {
    return _recommendationService.sugerirCodigosComplementarios(codigoPrincipal);
  }

  /// Obtiene recomendaciones de mejora
  Future<List<String>> obtenerRecomendacionesMejora() async {
    final progreso = await _habitTracker.obtenerProgreso();
    return _progressService.generarRecomendacionesMejora(progreso);
  }

  /// Obtiene estadísticas semanales
  Future<Map<String, dynamic>> obtenerEstadisticasSemanales() async {
    final progreso = await _habitTracker.obtenerProgreso();
    return _progressService.generarEstadisticasSemanales(progreso);
  }

  /// Sugiere meditación apropiada
  Future<String> obtenerMeditacionRecomendada() async {
    final progreso = await _habitTracker.obtenerProgreso();
    return _recommendationService.sugerirMeditacion(progreso);
  }

  /// Resetea todo el progreso (solo usar en casos específicos)
  Future<void> resetearProgreso() async {
    await _habitTracker.resetearProgreso();
  }

  // ============================================
  // MÉTODOS DE ANÁLISIS AVANZADO
  // ============================================

  /// Analiza patrones de uso y genera insights
  Future<Map<String, dynamic>> analizarPatrones() async {
    final progreso = await _habitTracker.obtenerProgreso();
    final reporte = _progressService.generarReporte(progreso);
    final sugerencias = _recommendationService.obtenerSugerenciasDiarias(progreso);
    
    return {
      'nivelVibracional': reporte['nivel'],
      'nombreNivel': reporte['nombreNivel'],
      'energiaPromedio': reporte['energiaPromedio'],
      'tendencia': reporte['tendencia'],
      'diasConsecutivos': progreso.diasConsecutivos,
      'totalSesiones': progreso.totalSesiones,
      'codigoRecomendado': sugerencias['codigoDelDia'],
      'desafioSugerido': sugerencias['desafioSugerido'],
      'meditacionRecomendada': sugerencias['meditacionRecomendada'],
      'fraseMotiadora': sugerencias['fraseMotiadora'],
      'proximoNivel': reporte['proximoNivel'],
      'sesionesParaSubir': reporte['sesionesParaSubir'],
      'colorAura': reporte['colorAura'],
    };
  }

  /// Predice el próximo paso recomendado
  Future<String> predecirProximoPaso() async {
    final progreso = await _habitTracker.obtenerProgreso();
    
    if (progreso.diasConsecutivos == 0) {
      return 'Realiza tu primer pilotaje consciente hoy';
    } else if (progreso.diasConsecutivos < 3) {
      return 'Completa 3 días consecutivos para establecer el hábito';
    } else if (progreso.diasConsecutivos < 7) {
      return 'Llega a 7 días para desbloquear el primer nivel vibracional';
    } else if (progreso.diasConsecutivos < 14) {
      return 'Continúa hasta 14 días para alcanzar vibración intermedia';
    } else if (progreso.diasConsecutivos < 21) {
      return 'Completa 21 días para una transformación profunda';
    } else {
      return 'Comparte tu luz con la comunidad y ayuda a otros';
    }
  }

  /// Calcula el porcentaje de progreso hacia el siguiente nivel
  Future<double> obtenerPorcentajeProgresoNivel() async {
    final progreso = await _habitTracker.obtenerProgreso();
    final reporte = _progressService.generarReporte(progreso);
    final sesionesParaSubir = reporte['sesionesParaSubir'] as int;
    
    if (sesionesParaSubir == 0) return 100.0;
    
    final nivelActual = reporte['nivel'] as int;
    final umbralActual = _obtenerUmbralNivel(nivelActual);
    final umbralSiguiente = _obtenerUmbralNivel(nivelActual + 1);
    final progresoDentroNivel = progreso.totalSesiones - umbralActual;
    final rangoNivel = umbralSiguiente - umbralActual;
    
    return ((progresoDentroNivel / rangoNivel) * 100).clamp(0, 100);
  }

  int _obtenerUmbralNivel(int nivel) {
    const Map<int, int> umbrales = {
      1: 0,
      2: 2,
      3: 6,
      4: 12,
      5: 20,
      6: 35,
      7: 50,
    };
    return umbrales[nivel] ?? 0;
  }

  /// Obtiene sugerencia de práctica óptima para hoy
  Future<Map<String, dynamic>> obtenerPracticaOptima() async {
    final progreso = await _habitTracker.obtenerProgreso();
    final categoria = _obtenerCategoriaSugerida(progreso);
    
    return {
      'categoriaSugerida': categoria,
      'codigoSugerido': _recommendationService.recomendarCodigo(categoria, progreso: progreso),
      'duracionSugerida': _obtenerDuracionSugerida(progreso.nivelVibracional),
      'horarioOptimo': 'Mañana (9:00 AM)', // Por ahora fijo, puede ser dinámico
      'intensidad': _obtenerIntensidadSugerida(progreso.nivelVibracional),
    };
  }

  String _obtenerCategoriaSugerida(UserProgress progreso) {
    // Si no ha usado ninguna, sugerir abundancia (motivador)
    if (progreso.frecuenciaPorCategoria.isEmpty) {
      return 'Abundancia';
    }
    
    // Rotar entre las categorías para balance
    final categorias = ['Salud', 'Abundancia', 'Armonía', 'Protección', 'Amor'];
    final categoriasUsadas = progreso.frecuenciaPorCategoria.keys.toList();
    
    for (var cat in categorias) {
      if (!categoriasUsadas.contains(cat)) {
        return cat; // Sugerir una no usada para balance
      }
    }
    
    // Si ya usó todas, rotar basado en día
    return categorias[DateTime.now().weekday % categorias.length];
  }

  int _obtenerDuracionSugerida(int nivel) {
    // Minutos de práctica sugeridos según nivel
    if (nivel >= 6) return 20;
    if (nivel >= 4) return 15;
    if (nivel >= 2) return 10;
    return 5;
  }

  String _obtenerIntensidadSugerida(int nivel) {
    if (nivel >= 6) return 'Avanzada';
    if (nivel >= 4) return 'Intermedia';
    return 'Inicial';
  }
}


