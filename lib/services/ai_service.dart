/// Servicio de IA simple basado en reglas
/// Sin NLP ni procesamiento de lenguaje natural
class AIService {
  /// Recomienda un código basado en las categorías usadas recientemente
  static String recomendarCodigo(List<String> categoriasUsadas) {
    if (categoriasUsadas.isEmpty) return '5197148'; // Código universal
    
    final ultimaCategoria = categoriasUsadas.last.toLowerCase();
    
    switch (ultimaCategoria) {
      case 'abundancia':
        return '318798'; // Prosperidad
      case 'salud':
        return '1884321'; // Norma Absoluta
      case 'protección':
      case 'proteccion':
        return '71931'; // Campo energético
      case 'amor':
        return '888412'; // Amor Universal
      case 'sanación':
      case 'sanacion':
        return '5432189'; // Regeneración Celular
      default:
        return '5197148'; // Todo es posible
    }
  }

  /// Sugiere códigos complementarios basados en la categoría actual
  static List<String> sugerirCodigosComplementarios(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'abundancia':
        return ['520741', '71427321893']; // Éxito y Dinero inesperado
      case 'salud':
        return ['5432189', '8142543']; // Regeneración y Sistema inmune
      case 'protección':
      case 'proteccion':
        return ['9187756981818', '71427321893']; // Protección general y hogar
      default:
        return ['1888948', '741']; // Armonía universal y Sanación
    }
  }

  /// Calcula el nivel energético basado en la frecuencia de uso
  static int calcularNivelEnergetico(int diasConsecutivos, int totalPilotajes) {
    int nivel = 1;
    
    // Por días consecutivos (ajustado para ser más accesible)
    if (diasConsecutivos >= 21) {
      nivel += 4;
    } else if (diasConsecutivos >= 14) nivel += 3;
    else if (diasConsecutivos >= 7) nivel += 2;
    else if (diasConsecutivos >= 3) nivel += 1;
    
    // Por total de pilotajes (ajustado para ser más accesible)
    if (totalPilotajes >= 100) {
      nivel += 3;
    } else if (totalPilotajes >= 50) nivel += 2;
    else if (totalPilotajes >= 20) nivel += 1;
    else if (totalPilotajes >= 5) nivel += 1;
    
    // Nivel mínimo de 3 para usuarios activos
    if (diasConsecutivos > 0 || totalPilotajes > 0) {
      nivel = nivel.clamp(3, 10);
    }
    
    return nivel.clamp(1, 10);
  }

  /// Recomienda un desafío basado en el historial del usuario
  static String recomendarDesafio(
    List<String> categoriasUsadas,
    int diasConsecutivos,
  ) {
    if (diasConsecutivos == 0) {
      return 'Desafío de Abundancia'; // Empezar con algo motivador
    }
    
    if (diasConsecutivos >= 7 && diasConsecutivos < 14) {
      return 'Camino de Sanación'; // Usuario constante, subir nivel
    }
    
    if (diasConsecutivos >= 14) {
      return 'Transformación Total'; // Usuario avanzado
    }
    
    // Basado en categoría más usada
    final Map<String, int> frecuenciaCategoria = {};
    for (var cat in categoriasUsadas) {
      frecuenciaCategoria[cat] = (frecuenciaCategoria[cat] ?? 0) + 1;
    }
    
    if (frecuenciaCategoria['Abundancia'] != null &&
        frecuenciaCategoria['Abundancia']! > 3) {
      return 'Desafío de Abundancia';
    }
    
    return 'Camino de Sanación'; // Default
  }

  /// Genera una frase motivacional basada en el progreso
  static String generarFraseMotivacional(int nivel, int diasConsecutivos) {
    if (diasConsecutivos >= 21) {
      return '✨ Tu energía vibra en frecuencias elevadas. ¡Eres imparable!';
    } else if (diasConsecutivos >= 14) {
      return '🌟 Tu constancia está manifestando resultados poderosos.';
    } else if (diasConsecutivos >= 7) {
      return '💫 Una semana de conexión consciente. ¡Continúa el camino!';
    } else if (diasConsecutivos >= 3) {
      return '🔮 La energía fluye contigo. Cada día es más poderoso.';
    } else {
      return '🌙 El viaje de mil millas comienza con un solo paso.';
    }
  }

  /// Analiza patrones de uso y sugiere próximos pasos
  static Map<String, dynamic> analizarPatrones({
    required List<String> categoriasUsadas,
    required int diasConsecutivos,
    required int totalPilotajes,
  }) {
    final nivel = calcularNivelEnergetico(diasConsecutivos, totalPilotajes);
    final codigoRecomendado = recomendarCodigo(categoriasUsadas);
    final desafioSugerido = recomendarDesafio(categoriasUsadas, diasConsecutivos);
    final frase = generarFraseMotivacional(nivel, diasConsecutivos);
    
    return {
      'nivel': nivel,
      'codigoRecomendado': codigoRecomendado,
      'desafioSugerido': desafioSugerido,
      'fraseMotivacional': frase,
      'proximoPaso': _determinarProximoPaso(diasConsecutivos, totalPilotajes),
    };
  }

  static String _determinarProximoPaso(int diasConsecutivos, int totalPilotajes) {
    if (diasConsecutivos == 0) {
      return 'Realiza tu primer pilotaje consciente hoy';
    } else if (diasConsecutivos < 7) {
      return 'Completa 7 días consecutivos para desbloquear el primer nivel';
    } else if (diasConsecutivos < 21) {
      return 'Continúa hasta 21 días para una transformación profunda';
    } else {
      return 'Comparte tu luz con la comunidad';
    }
  }
}

