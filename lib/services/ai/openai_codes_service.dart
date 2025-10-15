import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OpenAICodesService {
  final String apiKey;

  OpenAICodesService({required this.apiKey});

  /// Busca sugerencias de códigos sagrados relacionadas a una intención dada
  /// Retorna una lista de objetos con código y descripción
  Future<List<Map<String, String>>> sugerirCodigosPorIntencion(String consulta) async {
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
  List<Map<String, String>> _generarCodigosSugeridos(String consulta) {
    final consultaLower = consulta.toLowerCase();
    final sugerencias = <Map<String, String>>[];

    // Mapeo de palabras clave a códigos sugeridos
    final mapeo = {
      'alergia': [
        {'codigo': '123456789012', 'descripcion': 'Eliminar alergias y sensibilidades alimentarias'},
        {'codigo': '111111111', 'descripcion': 'Escudo energético contra alergias'},
        {'codigo': '333333333', 'descripcion': 'Equilibrar sistema inmunológico'},
      ],
      'salud': [
        {'codigo': '1884321', 'descripcion': 'Norma Absoluta - Salud perfecta'},
        {'codigo': '1234567', 'descripcion': 'Regeneración celular'},
        {'codigo': '9876543', 'descripcion': 'Sistema inmune fortalecido'},
      ],
      'dinero': [
        {'codigo': '318798', 'descripcion': 'Prosperidad y abundancia'},
        {'codigo': '123456789', 'descripcion': 'Riqueza material'},
        {'codigo': '88888588888', 'descripcion': 'Código Universal de abundancia'},
      ],
      'amor': [
        {'codigo': '5197148', 'descripcion': 'Conexión universal del amor'},
        {'codigo': '1234567890', 'descripcion': 'Amor verdadero'},
        {'codigo': '0987654321', 'descripcion': 'Reconciliación'},
      ],
      'proteccion': [
        {'codigo': '71931', 'descripcion': 'Campo energético protector'},
        {'codigo': '111111111', 'descripcion': 'Escudo energético'},
        {'codigo': '222222222', 'descripcion': 'Protección psíquica'},
      ],
      'trabajo': [
        {'codigo': '321654987', 'descripcion': 'Trabajo ideal'},
        {'codigo': '555555555555', 'descripcion': 'Empleos bien pagados'},
        {'codigo': '666666666666', 'descripcion': 'Ascensos laborales'},
      ],
    };

    // Buscar coincidencias
    for (final entry in mapeo.entries) {
      if (consultaLower.contains(entry.key)) {
        sugerencias.addAll(entry.value);
      }
    }

    // Si no hay coincidencias específicas, devolver códigos generales
    if (sugerencias.isEmpty) {
      sugerencias.addAll([
        {'codigo': '1884321', 'descripcion': 'Norma Absoluta - Todo es posible'},
        {'codigo': '318798', 'descripcion': 'Prosperidad universal'},
        {'codigo': '71931', 'descripcion': 'Protección energética'},
        {'codigo': '5197148', 'descripcion': 'Amor y conexión'},
        {'codigo': '741', 'descripcion': 'Limpieza y purificación'},
      ]);
    }

    return sugerencias.take(5).toList();
  }
}


