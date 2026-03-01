import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/supabase_models.dart';

class RobustApiService {
  static const String _host = 'whtiazgcxdnemrrgjjqf.supabase.co';
  static const String _path = '/functions/v1/get-codigos';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer ${Env.supabaseAnonKey}',
    'Cache-Control': 'no-cache',
  };

  static Future<List<CodigoGrabovoi>> getCodigos({
    String? categoria,
    String? search,
  }) async {
    final uri = Uri.https(_host, _path, {
      if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
      if (search != null && search.isNotEmpty) 'search': search,
    });

    debugPrint('[ROBUST API] GET $uri');
    
    final res = await http.get(uri, headers: _headers);
    final body = utf8.decode(res.bodyBytes);

    // LOGS ÚTILES EN RELEASE
    debugPrint('[ROBUST API] Status: ${res.statusCode}');
    debugPrint('[ROBUST API] Body length: ${body.length}');
    debugPrint('[ROBUST API] Body preview: ${body.length > 200 ? '${body.substring(0, 200)}...' : body}');

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase} → $body');
    }

    final decoded = jsonDecode(body);

    // Soportar 2 formas: List directa o { data: List }
    List dataList;
    if (decoded is List) {
      debugPrint('[ROBUST API] Formato: List directa');
      dataList = decoded;
    } else if (decoded is Map && decoded['data'] is List) {
      debugPrint('[ROBUST API] Formato: {data: List}');
      dataList = decoded['data'];
    } else {
      debugPrint('[ROBUST API] ERROR: Formato JSON inesperado');
      debugPrint('[ROBUST API] Tipo: ${decoded.runtimeType}');
      debugPrint('[ROBUST API] Keys: ${decoded is Map ? decoded.keys.toList() : 'N/A'}');
      throw Exception('Formato JSON inesperado. Se esperaba List o {data: List}');
    }

    debugPrint('[ROBUST API] DataList length: ${dataList.length}');

    final items = dataList
        .whereType<Map<String, dynamic>>()
        .map((e) {
          try {
            return CodigoGrabovoi.fromJson(e);
          } catch (parseError) {
            debugPrint('[ROBUST API] ERROR parseando elemento: $e');
            debugPrint('[ROBUST API] Parse error: $parseError');
            rethrow;
          }
        })
        .toList();

    debugPrint('[ROBUST API] PARSED ITEMS: ${items.length}');
    if (items.isNotEmpty) {
      debugPrint('[ROBUST API] Primer item: ${items.first.nombre} - ${items.first.codigo}');
    }
    
    return items;
  }

  /// Obtener categorías
  static Future<List<String>> getCategorias() async {
    try {
      final uri = Uri.https(_host, '/functions/v1/get-categorias');
      final res = await http.get(uri, headers: _headers);
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          return List<String>.from(data['data']);
        }
      }
      throw Exception('Error obteniendo categorías: ${res.statusCode}');
    } catch (e) {
      debugPrint('[ROBUST API] Error categorías: $e');
      rethrow;
    }
  }

  /// Obtener favoritos
  static Future<List<UsuarioFavorito>> getFavoritos(String userId) async {
    try {
      final uri = Uri.https(_host, '/functions/v1/get-favoritos', {'userId': userId});
      final res = await http.get(uri, headers: _headers);
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((json) => UsuarioFavorito.fromJson(json))
              .toList();
        }
      }
      throw Exception('Error obteniendo favoritos: ${res.statusCode}');
    } catch (e) {
      debugPrint('[ROBUST API] Error favoritos: $e');
      rethrow;
    }
  }

  /// Toggle favorito
  static Future<void> toggleFavorito(String userId, String codigoId) async {
    try {
      final uri = Uri.https(_host, '/functions/v1/toggle-favorito');
      final body = json.encode({
        'userId': userId,
        'codigoId': codigoId,
      });
      
      final res = await http.post(uri, headers: _headers, body: body);
      
      if (res.statusCode != 200) {
        throw Exception('Error toggle favorito: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('[ROBUST API] Error toggle favorito: $e');
      rethrow;
    }
  }

  /// Incrementar popularidad
  static Future<void> incrementarPopularidad(String codigoId) async {
    try {
      final uri = Uri.https(_host, '/functions/v1/incrementar-popularidad');
      final body = json.encode({'codigoId': codigoId});
      
      final res = await http.post(uri, headers: _headers, body: body);
      
      if (res.statusCode != 200) {
        throw Exception('Error incrementar popularidad: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('[ROBUST API] Error incrementar popularidad: $e');
      rethrow;
    }
  }
}
