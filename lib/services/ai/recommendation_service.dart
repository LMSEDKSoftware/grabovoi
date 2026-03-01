import '../../models/user_progress.dart';

/// Servicio de recomendaciones personalizadas basado en reglas
class RecommendationService {
  // Base de datos de códigos por categoría
  static const Map<String, List<String>> codigosPorCategoria = {
    'salud': ['1884321', '88888588888', '5432189', '8142543'],
    'abundancia': ['318798', '5197148', '520741', '71427321893'],
    'proteccion': ['71931', '741', '9187756981818'],
    'protección': ['71931', '741', '9187756981818'],
    'armonia': ['5197148', '9788819719', '1888948', '14854232190'],
    'armonía': ['5197148', '9788819719', '1888948', '14854232190'],
    'amor': ['888412', '419488', '5148241'],
    'sanacion': ['5432189', '741', '1489999'],
    'sanación': ['5432189', '741', '1489999'],
  };

  // Códigos universales para cuando no hay categoría específica
  static const List<String> codigosUniversales = [
    '5197148', // Todo es posible
    '1888948', // Armonía universal
    '741',     // Sanación holística
  ];

  /// Recomienda un código basado en la categoría y el historial
  String recomendarCodigo(String? categoria, {UserProgress? progreso}) {
    // Si no hay categoría, usar categoría más frecuente del usuario
    if (categoria == null || categoria.isEmpty) {
      if (progreso != null && progreso.frecuenciaPorCategoria.isNotEmpty) {
        categoria = _obtenerCategoriaMasUsada(progreso.frecuenciaPorCategoria);
      } else {
        return _codigoUniversalRotativo();
      }
    }
    
    final lista = codigosPorCategoria[categoria.toLowerCase()];
    if (lista == null || lista.isEmpty) {
      return _codigoUniversalRotativo();
    }
    
    // Rotar códigos basado en el día + sesiones del usuario
    final seed = progreso?.totalSesiones ?? DateTime.now().day;
    return lista[seed % lista.length];
  }

  /// Sugiere códigos complementarios a uno dado
  List<String> sugerirCodigosComplementarios(String codigoPrincipal, {int limite = 3}) {
    // Encontrar categoría del código
    String? categoria;
    for (var entry in codigosPorCategoria.entries) {
      if (entry.value.contains(codigoPrincipal)) {
        categoria = entry.key;
        break;
      }
    }
    
    if (categoria == null) return [];
    
    final lista = codigosPorCategoria[categoria] ?? [];
    final complementarios = lista.where((c) => c != codigoPrincipal).toList();
    
    return complementarios.take(limite).toList();
  }

  /// Recomienda un desafío basado en el progreso del usuario
  String sugerirDesafio(UserProgress progreso) {
    final dias = progreso.diasConsecutivos;
    final sesiones = progreso.totalSesiones;
    
    // Usuario nuevo o irregular
    if (dias == 0 || sesiones < 3) {
      return 'Desafío de Abundancia'; // 7 días - motivador
    }
    
    // Usuario con racha corta
    if (dias >= 3 && dias < 7) {
      return 'Desafío de Abundancia'; // Consolidar hábito
    }
    
    // Usuario consistente
    if (dias >= 7 && dias < 14) {
      return 'Camino de Sanación'; // 14 días - siguiente nivel
    }
    
    // Usuario avanzado
    if (dias >= 14 || sesiones >= 30) {
      return 'Transformación Total'; // 21 días - máximo desafío
    }
    
    // Por categoría más usada
    if (progreso.frecuenciaPorCategoria.isNotEmpty) {
      final categoriaMasUsada = _obtenerCategoriaMasUsada(progreso.frecuenciaPorCategoria);
      
      if (categoriaMasUsada.toLowerCase().contains('abundancia')) {
        return 'Desafío de Abundancia';
      } else if (categoriaMasUsada.toLowerCase().contains('salud') || 
                 categoriaMasUsada.toLowerCase().contains('sanacion')) {
        return 'Camino de Sanación';
      }
    }
    
    return 'Desafío de Abundancia'; // Default
  }

  /// Recomienda una meditación basada en el nivel y categoría
  String sugerirMeditacion(UserProgress progreso) {
    final nivel = progreso.nivelVibracional;
    
    if (nivel >= 6) {
      return 'Meditación Avanzada de Manifestación Cuántica';
    } else if (nivel >= 4) {
      return 'Meditación Intermedia de Pilotaje Consciente';
    } else {
      return 'Meditación Básica de Respiración 4-7-8';
    }
  }

  /// Obtiene sugerencias personalizadas para el dashboard
  Map<String, dynamic> obtenerSugerenciasDiarias(UserProgress progreso) {
    final categoria = progreso.frecuenciaPorCategoria.isNotEmpty
        ? _obtenerCategoriaMasUsada(progreso.frecuenciaPorCategoria)
        : 'armonia';
    
    return {
      'codigoDelDia': recomendarCodigo(categoria, progreso: progreso),
      'desafioSugerido': sugerirDesafio(progreso),
      'meditacionRecomendada': sugerirMeditacion(progreso),
      'codigosComplementarios': _obtenerCodigosVarios(progreso),
      'fraseMotiadora': _generarFrasePorNivel(progreso.nivelVibracional),
    };
  }

  /// Analiza el mejor momento del día para practicar (basado en historial)
  String analizarMejorHorario(List<DateTime> fechasRegistradas) {
    if (fechasRegistradas.isEmpty) {
      return 'Mañana (9:00 AM)'; // Recomendación default
    }
    
    final Map<int, int> frecuenciaPorHora = {};
    for (var fecha in fechasRegistradas) {
      final hora = fecha.hour;
      frecuenciaPorHora[hora] = (frecuenciaPorHora[hora] ?? 0) + 1;
    }
    
    // Encontrar hora más frecuente
    int horaMasFrecuente = 9; // Default
    int maxFrecuencia = 0;
    
    frecuenciaPorHora.forEach((hora, frecuencia) {
      if (frecuencia > maxFrecuencia) {
        maxFrecuencia = frecuencia;
        horaMasFrecuente = hora;
      }
    });
    
    return _formatHora(horaMasFrecuente);
  }

  // Métodos auxiliares privados

  String _codigoUniversalRotativo() {
    final index = DateTime.now().day % codigosUniversales.length;
    return codigosUniversales[index];
  }

  String _obtenerCategoriaMasUsada(Map<String, int> frecuencia) {
    if (frecuencia.isEmpty) return 'armonia';
    
    String categoriaMasUsada = frecuencia.keys.first;
    int maxFrecuencia = frecuencia.values.first;
    
    frecuencia.forEach((categoria, freq) {
      if (freq > maxFrecuencia) {
        maxFrecuencia = freq;
        categoriaMasUsada = categoria;
      }
    });
    
    return categoriaMasUsada;
  }

  List<String> _obtenerCodigosVarios(UserProgress progreso) {
    final List<String> codigos = [];
    
    // Un código de cada categoría top
    final categorias = progreso.frecuenciaPorCategoria.keys.take(3).toList();
    for (var cat in categorias) {
      final lista = codigosPorCategoria[cat.toLowerCase()];
      if (lista != null && lista.isNotEmpty) {
        codigos.add(lista.first);
      }
    }
    
    // Completar con universales si faltan
    while (codigos.length < 3) {
      codigos.add(codigosUniversales[codigos.length % codigosUniversales.length]);
    }
    
    return codigos;
  }

  String _generarFrasePorNivel(int nivel) {
    switch (nivel) {
      case 7:
        return '✨ Maestro de la Manifestación - Tu luz ilumina el camino';
      case 6:
        return '🌟 Vibrando en Alta Frecuencia - La abundancia te rodea';
      case 5:
        return '💫 En Expansión Constante - Tu energía se eleva cada día';
      case 4:
        return '🔮 Piloto Consciente - Diriges tu realidad con intención';
      case 3:
        return '🌙 Despertar Energético - Tu viaje ha comenzado';
      case 2:
        return '⭐ Primeros Pasos - Cada día es una nueva oportunidad';
      default:
        return '🌱 Semilla de Luz - El universo conspira a tu favor';
    }
  }

  String _formatHora(int hora) {
    if (hora >= 5 && hora < 12) return 'Mañana ($hora:00)';
    if (hora >= 12 && hora < 18) return 'Tarde ($hora:00)';
    if (hora >= 18 && hora < 22) return 'Noche ($hora:00)';
    return 'Madrugada ($hora:00)';
  }
}


