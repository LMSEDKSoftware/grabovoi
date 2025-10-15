import '../../models/user_progress.dart';

/// Servicio para calcular y visualizar el progreso energético
class ProgressService {
  /// Calcula el nivel vibracional del usuario (1-7)
  int calcularNivelVibracional(int dias, int sesiones) {
    int score = dias * 2 + sesiones;
    
    if (score >= 50) return 7; // Maestro
    if (score >= 35) return 6; // Avanzado
    if (score >= 20) return 5; // Intermedio Alto
    if (score >= 12) return 4; // Intermedio
    if (score >= 6) return 3;  // Iniciado
    if (score >= 2) return 2;  // Despertar
    return 1; // Semilla
  }

  /// Genera un reporte completo del progreso
  Map<String, dynamic> generarReporte(UserProgress progreso) {
    final nivel = calcularNivelVibracional(
      progreso.diasConsecutivos,
      progreso.totalSesiones,
    );
    
    return {
      'nivel': nivel,
      'nombreNivel': _nombrePorNivel(nivel),
      'mensaje': _mensajePorNivel(nivel),
      'colorAura': _colorPorNivel(nivel),
      'energiaPromedio': _calcularEnergiaPromedio(progreso),
      'tendencia': _calcularTendencia(progreso),
      'proximoNivel': _proximoNivel(nivel),
      'sesionesParaSubir': _sesionesParaSubir(nivel, progreso.totalSesiones),
      'diasParaMaestria': _diasParaMaestria(progreso.diasConsecutivos),
    };
  }

  /// Calcula la energía promedio del usuario (0-100)
  double _calcularEnergiaPromedio(UserProgress progreso) {
    if (progreso.totalSesiones == 0) return 50.0;
    
    double base = 50.0;
    double porSesiones = (progreso.totalSesiones * 2).clamp(0, 30).toDouble();
    double porDias = (progreso.diasConsecutivos * 3).clamp(0, 20).toDouble();
    
    return (base + porSesiones + porDias).clamp(0, 100);
  }

  /// Determina la tendencia (creciente, estable, decreciente)
  String _calcularTendencia(UserProgress progreso) {
    if (progreso.diasConsecutivos >= 7) {
      return 'creciente'; // Usuario muy activo
    } else if (progreso.diasConsecutivos >= 3) {
      return 'estable'; // Usuario consistente
    } else if (progreso.totalSesiones > 0) {
      return 'irregular'; // Usuario ocasional
    }
    return 'inicio'; // Usuario nuevo
  }

  /// Calcula cuántas sesiones faltan para el siguiente nivel
  int _sesionesParaSubir(int nivelActual, int sesionesActuales) {
    if (nivelActual >= 7) return 0; // Ya es maestro
    
    final Map<int, int> umbrales = {
      1: 2,   // De 1 a 2
      2: 6,   // De 2 a 3
      3: 12,  // De 3 a 4
      4: 20,  // De 4 a 5
      5: 35,  // De 5 a 6
      6: 50,  // De 6 a 7
    };
    
    final umbralSiguiente = umbrales[nivelActual] ?? 50;
    final faltantes = umbralSiguiente - sesionesActuales;
    return faltantes > 0 ? faltantes : 0;
  }

  /// Calcula días para llegar a maestría (21 días consecutivos)
  int _diasParaMaestria(int diasActuales) {
    if (diasActuales >= 21) return 0;
    return 21 - diasActuales;
  }

  /// Obtiene el nombre del nivel
  String _nombrePorNivel(int nivel) {
    switch (nivel) {
      case 7: return 'Maestro de Luz';
      case 6: return 'Vibración Dorada';
      case 5: return 'Piloto Consciente';
      case 4: return 'Viajero Energético';
      case 3: return 'Despertar Luminoso';
      case 2: return 'Semilla en Crecimiento';
      default: return 'Inicio del Camino';
    }
  }

  /// Mensaje motivacional por nivel
  String _mensajePorNivel(int nivel) {
    switch (nivel) {
      case 7:
        return 'Tu campo energético está en expansión total. Eres un faro de luz para otros 🌟';
      case 6:
        return 'Vibras en frecuencia dorada. La manifestación fluye naturalmente a través de ti ✨';
      case 5:
        return 'Tu energía se ha estabilizado en frecuencias elevadas. Continúa expandiendo 🌕';
      case 4:
        return 'Has desbloqueado el poder del pilotaje consciente. Tu realidad responde 💫';
      case 3:
        return 'El despertar ha comenzado. Cada práctica te eleva más alto 🔮';
      case 2:
        return 'Tu semilla energética está germinando. La constancia es tu poder 🌱';
      default:
        return 'Das tus primeros pasos en el camino. El universo te acompaña 🌙';
    }
  }

  /// Color del aura según nivel
  String _colorPorNivel(int nivel) {
    switch (nivel) {
      case 7: return '#FFD700'; // Dorado brillante
      case 6: return '#F4C430'; // Dorado suave
      case 5: return '#DDA15E'; // Bronce dorado
      case 4: return '#BC6C25'; // Cobre
      case 3: return '#8B7355'; // Tierra dorada
      case 2: return '#A0A0A0'; // Plata
      default: return '#808080'; // Gris neutro
    }
  }

  /// Nombre del siguiente nivel
  String _proximoNivel(int nivelActual) {
    if (nivelActual >= 7) return 'Maestro de Luz'; // Ya está en el máximo
    return _nombrePorNivel(nivelActual + 1);
  }

  /// Genera estadísticas semanales
  Map<String, dynamic> generarEstadisticasSemanales(UserProgress progreso) {
    final energia = _calcularEnergiaPromedio(progreso);
    
    return {
      'energiaPromedio': energia,
      'sesionesEstaSemana': _estimarSesionesSemanales(progreso),
      'categoriaPreferida': _obtenerCategoriaMasUsada(progreso.frecuenciaPorCategoria),
      'constanteEstaSemana': progreso.diasConsecutivos >= 7,
      'tendencia': _calcularTendencia(progreso),
    };
  }

  /// Genera recomendaciones para mejorar
  List<String> generarRecomendacionesMejora(UserProgress progreso) {
    final recomendaciones = <String>[];
    
    if (progreso.diasConsecutivos == 0) {
      recomendaciones.add('Establece una práctica diaria para crear el hábito');
    }
    
    if (progreso.diasConsecutivos < 7) {
      recomendaciones.add('Intenta llegar a 7 días consecutivos para desbloquear el primer nivel');
    }
    
    if (progreso.totalSesiones < 10) {
      recomendaciones.add('Completa más sesiones para profundizar tu conexión');
    }
    
    if (progreso.categoriasUsadas.length < 3) {
      recomendaciones.add('Explora diferentes categorías de códigos para equilibrio');
    }
    
    if (progreso.diasConsecutivos >= 7 && progreso.nivelVibracional < 4) {
      recomendaciones.add('Prueba un desafío de 14 días para subir de nivel');
    }
    
    if (recomendaciones.isEmpty) {
      recomendaciones.add('¡Excelente trabajo! Continúa con tu práctica diaria');
    }
    
    return recomendaciones;
  }

  // Métodos auxiliares privados

  String _obtenerCategoriaMasUsada(Map<String, int> frecuencia) {
    if (frecuencia.isEmpty) return 'Armonía';
    
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

  int _estimarSesionesSemanales(UserProgress progreso) {
    // Si tiene menos de 7 días, todas las sesiones son de esta semana
    if (progreso.diasConsecutivos <= 7) {
      return progreso.totalSesiones;
    }
    
    // Estimación: promedio de 1 sesión por día de racha
    return progreso.diasConsecutivos.clamp(0, 7);
  }
}


