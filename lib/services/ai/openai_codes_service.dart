import 'package:flutter/foundation.dart';

class OpenAICodesService {
  final String apiKey;

  OpenAICodesService({required this.apiKey});

  /// Busca sugerencias de códigos sagrados relacionadas a una intención dada
  /// Retorna una lista de objetos con código, descripción, categoría y color
  Future<List<Map<String, dynamic>>> sugerirCodigosPorIntencion(String consulta) async {
    try {
      // Para web, usar un proxy o servicio intermedio para evitar CORS
      // Por ahora, devolver códigos sugeridos basados en palabras clave
      return _generarCodigosSugeridos(consulta);
    } catch (e) {
      debugPrint('Error consultando OpenAI: $e');
      return _generarCodigosSugeridos(consulta);
    }
  }

  /// Genera códigos sugeridos basados en palabras clave (fallback)
  /// IMPORTANTE: Solo usa códigos Grabovoi auténticos y certificados
  List<Map<String, dynamic>> _generarCodigosSugeridos(String consulta) {
    final consultaLower = consulta.toLowerCase();
    final sugerencias = <Map<String, dynamic>>[];

    // CÓDIGOS NUMÉRICOS AUTÉNTICOS Y CERTIFICADOS
    // Fuente: Libros oficiales y enseñanzas de secuencias numéricas
    final codigosAutenticos = {
      'salud': {
        'categoria': 'Salud y Sanación',
        'color': '#00FF7F',
        'codigos': [
          {'codigo': '1884321', 'descripcion': 'Norma Absoluta - Salud perfecta'},
          {'codigo': '88888588888', 'descripcion': 'Cura para todos'},
          {'codigo': '817992191', 'descripcion': 'Autoregeneración'},
          {'codigo': '741', 'descripcion': 'Solución inmediata'},
          {'codigo': '71931', 'descripcion': 'Protección y sanación'},
        ]
      },
      'abundancia': {
        'categoria': 'Abundancia y Prosperidad',
        'color': '#FFD700',
        'codigos': [
          {'codigo': '318798', 'descripcion': 'Activar la abundancia'},
          {'codigo': '71427321893', 'descripcion': 'Prosperidad infinita'},
          {'codigo': '71891871981', 'descripcion': 'Flujo constante de riqueza'},
          {'codigo': '4812412', 'descripcion': 'Eliminar bloqueos financieros'},
          {'codigo': '814418719', 'descripcion': 'Multiplicar ingresos'},
        ]
      },
      'amor': {
        'categoria': 'Amor y Relaciones',
        'color': '#FF3B3B',
        'codigos': [
          {'codigo': '5197148', 'descripcion': 'Todo es posible - Amor universal'},
          {'codigo': '814418719', 'descripcion': 'Apertura al amor'},
          {'codigo': '9187948181', 'descripcion': 'Sanación del corazón'},
          {'codigo': '518491617', 'descripcion': 'Relaciones exitosas'},
          {'codigo': '7199719', 'descripcion': 'Perdón y reconciliación'},
        ]
      },
      'proteccion': {
        'categoria': 'Protección Energética',
        'color': '#1E90FF',
        'codigos': [
          {'codigo': '71931', 'descripcion': 'Protección general'},
          {'codigo': '9187948181', 'descripcion': 'Campo de protección vibracional'},
          {'codigo': '719849817', 'descripcion': 'Escudo contra energías negativas'},
          {'codigo': '88899141819', 'descripcion': 'Protección familiar'},
          {'codigo': '91719871981', 'descripcion': 'Neutralizar ataques energéticos'},
        ]
      },
      'espiritual': {
        'categoria': 'Conciencia Espiritual',
        'color': '#8A2BE2',
        'codigos': [
          {'codigo': '71381921', 'descripcion': 'Entrar en el punto de poder creador'},
          {'codigo': '19712893', 'descripcion': 'Anclaje energético'},
          {'codigo': '319817318', 'descripcion': 'Conexión universal con el Creador'},
          {'codigo': '9187948181', 'descripcion': 'Elevación de frecuencia del alma'},
          {'codigo': '71984981981', 'descripcion': 'Despertar espiritual'},
        ]
      },
      'liberacion': {
        'categoria': 'Liberación Emocional',
        'color': '#C0C0C0',
        'codigos': [
          {'codigo': '591061718489', 'descripcion': 'Liberar creencias limitantes'},
          {'codigo': '49851431918', 'descripcion': 'Liberar traumas'},
          {'codigo': '12516176', 'descripcion': 'Eliminar bloqueos'},
          {'codigo': '9788891719', 'descripcion': 'Resolución total de conflictos'},
          {'codigo': '193751891', 'descripcion': 'Luz del conocimiento'},
        ]
      },
      'limpieza': {
        'categoria': 'Limpieza y Reconexión',
        'color': '#FFFFFF',
        'codigos': [
          {'codigo': '1231115015', 'descripcion': 'Presencia del Creador'},
          {'codigo': '548491698719', 'descripcion': 'Eliminar resistencias inconscientes'},
          {'codigo': '48971281948', 'descripcion': 'Neutralizar miedos'},
          {'codigo': '71042', 'descripcion': 'Armonizar el presente'},
          {'codigo': '61988184161', 'descripcion': 'Limpieza de memorias emocionales'},
        ]
      },
    };

    // Buscar coincidencias con códigos auténticos
    for (final entry in codigosAutenticos.entries) {
      if (consultaLower.contains(entry.key)) {
        final categoriaData = entry.value as Map<String, dynamic>;
        final categoria = categoriaData['categoria'] as String;
        final color = categoriaData['color'] as String;
        final codigos = categoriaData['codigos'] as List<Map<String, String>>;
        
        for (final codigo in codigos) {
          sugerencias.add({
            'codigo': codigo['codigo'],
            'descripcion': codigo['descripcion'],
            'categoria': categoria,
            'color': color,
          });
        }
      }
    }

    // Si no hay coincidencias específicas, sugerir códigos universales
    if (sugerencias.isEmpty) {
      final categoriaUniversal = _generarCategoriaDesdeConsulta(consulta);
      final colorUniversal = _generarColorParaCategoria(categoriaUniversal);
      
      // CÓDIGOS UNIVERSALES DE GRABOVOI - AUTÉNTICOS
      sugerencias.addAll([
        {
          'codigo': '1884321',
          'descripcion': 'Norma Absoluta - Todo es posible - Para $consulta',
          'categoria': categoriaUniversal,
          'color': colorUniversal,
        },
        {
          'codigo': '318798',
          'descripcion': 'Prosperidad universal - Para $consulta',
          'categoria': categoriaUniversal,
          'color': colorUniversal,
        },
        {
          'codigo': '71931',
          'descripcion': 'Protección energética - Para $consulta',
          'categoria': categoriaUniversal,
          'color': colorUniversal,
        },
        {
          'codigo': '5197148',
          'descripcion': 'Manifestación perfecta - Para $consulta',
          'categoria': categoriaUniversal,
          'color': colorUniversal,
        },
        {
          'codigo': '741',
          'descripcion': 'Solución inmediata - Para $consulta',
          'categoria': categoriaUniversal,
          'color': colorUniversal,
        },
      ]);
    }

    return sugerencias.take(5).toList();
  }

  /// Genera una categoría basada en la consulta del usuario
  String _generarCategoriaDesdeConsulta(String consulta) {
    final consultaLower = consulta.toLowerCase().trim();
    
    // Mapeo de palabras comunes a categorías
    final mapeoCategorias = {
      'estudio': 'Educación',
      'aprendizaje': 'Educación',
      'escuela': 'Educación',
      'universidad': 'Educación',
      'examen': 'Educación',
      'deporte': 'Bienestar Físico',
      'ejercicio': 'Bienestar Físico',
      'fitness': 'Bienestar Físico',
      'viaje': 'Aventuras',
      'vacaciones': 'Aventuras',
      'familia': 'Relaciones Familiares',
      'hijos': 'Relaciones Familiares',
      'creatividad': 'Arte y Creatividad',
      'arte': 'Arte y Creatividad',
      'música': 'Arte y Creatividad',
      'negocio': 'Emprendimiento',
      'empresa': 'Emprendimiento',
      'inversión': 'Finanzas',
      'casa': 'Hogar',
      'hogar': 'Hogar',
      'vivienda': 'Hogar',
    };

    // Buscar coincidencias
    for (final entry in mapeoCategorias.entries) {
      if (consultaLower.contains(entry.key)) {
        return entry.value;
      }
    }

    // Si no hay coincidencias, capitalizar la primera letra de cada palabra
    final palabras = consultaLower.split(' ');
    final categoriaCapitalizada = palabras
        .map((palabra) => palabra.isEmpty ? '' : palabra[0].toUpperCase() + palabra.substring(1))
        .join(' ');
    
    return categoriaCapitalizada.isEmpty ? 'Personalizado' : categoriaCapitalizada;
  }

  /// Genera un color único para una categoría
  String _generarColorParaCategoria(String categoria) {
    final colores = [
      '#FF6B6B', // Rojo coral
      '#4ECDC4', // Turquesa
      '#45B7D1', // Azul cielo
      '#96CEB4', // Verde menta
      '#FFEAA7', // Amarillo suave
      '#DDA0DD', // Ciruela
      '#98D8C8', // Verde agua
      '#F7DC6F', // Amarillo dorado
      '#BB8FCE', // Lavanda
      '#85C1E9', // Azul claro
      '#F8C471', // Naranja suave
      '#82E0AA', // Verde claro
      '#F1948A', // Rosa salmón
      '#85C1E9', // Azul pastel
      '#D2B4DE', // Lila
    ];

    // Usar el hash de la categoría para seleccionar un color consistente
    final hash = categoria.hashCode.abs();
    return colores[hash % colores.length];
  }
}


