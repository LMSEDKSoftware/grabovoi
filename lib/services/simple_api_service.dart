import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/supabase_models.dart';
import 'secure_http.dart';

class SimpleApiService {
  static const String baseUrl = 'https://whtiazgcxdnemrrgjjqf.supabase.co/functions/v1';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${Env.supabaseAnonKey}',
    'User-Agent': 'ManifestacionApp/1.0',
    'Accept': 'application/json',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive',
  };

  /// Verifica conectividad básica
  static Future<bool> _checkConnectivity() async {
    if (kIsWeb) return true; // En web delegamos la conectividad al navegador
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        debugPrint('✅ [CONNECTIVITY] Conectado a internet');
        return true;
      }
    } catch (e) {
      debugPrint('❌ [CONNECTIVITY] Error: $e');
    }
    return false;
  }

  /// Obtener códigos de forma simple y directa
  static Future<List<CodigoGrabovoi>> getCodigos({
    String? categoria,
    String? search,
  }) async {
    debugPrint('🔍 [SIMPLE API] ===========================================');
    debugPrint('🔍 [SIMPLE API] INICIANDO CONEXIÓN SIMPLE');
    debugPrint('🔍 [SIMPLE API] ===========================================');
    debugPrint('🔍 [SIMPLE API] Parámetros: categoria=$categoria, search=$search');
    debugPrint('🔍 [SIMPLE API] Timestamp: ${DateTime.now()}');
    debugPrint('🔍 [SIMPLE API] Platform: ${kIsWeb ? "Web" : Platform.operatingSystem}');
    debugPrint('🔍 [SIMPLE API] ===========================================');
    
    // Verificar conectividad básica
    final connected = await _checkConnectivity();
    if (!connected) {
      throw Exception('Sin conexión a internet o DNS inaccesible.');
    }

    // Construir URL
    final Uri uri = Uri.parse('$baseUrl/get-codigos').replace(queryParameters: {
      if (categoria != null && categoria != 'Todos') 'categoria': categoria,
      if (search != null && search.isNotEmpty) 'search': search,
    });

    debugPrint('📡 [SIMPLE API] URL: $uri');
    debugPrint('📡 [SIMPLE API] Headers: $_headers');

    try {
      debugPrint('📡 [SIMPLE API] Iniciando petición HTTP...');

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      debugPrint('📊 [SIMPLE API] Status: ${response.statusCode}');
      debugPrint('📊 [SIMPLE API] Body length: ${response.body.length}');

      if (response.statusCode == 200) {
        debugPrint('🔍 [SIMPLE API] Decodificando JSON...');
        final data = json.decode(response.body);
        debugPrint('🔍 [SIMPLE API] JSON decodificado: ${data.runtimeType}');
        debugPrint('🔍 [SIMPLE API] Keys: ${data.keys.toList()}');
        debugPrint('🔍 [SIMPLE API] Success: ${data['success']}');
        
        if (data['success'] == true) {
          final rawData = data['data'] as List;
          debugPrint('🔍 [SIMPLE API] Data length: ${rawData.length}');
          
          debugPrint('🔍 [SIMPLE API] Parseando códigos...');
          final codigos = rawData
              .map((json) {
                try {
                  return CodigoGrabovoi.fromJson(json);
                } catch (e) {
                  debugPrint('❌ [SIMPLE API] Error parseando: $e');
                  debugPrint('❌ [SIMPLE API] JSON: $json');
                  rethrow;
                }
              })
              .toList();
          
          debugPrint('✅ [SIMPLE API] ÉXITO: ${codigos.length} códigos obtenidos');
          debugPrint('✅ [SIMPLE API] Primer código: ${codigos.isNotEmpty ? codigos.first.nombre : 'N/A'}');
          debugPrint('✅ [SIMPLE API] Último código: ${codigos.isNotEmpty ? codigos.last.nombre : 'N/A'}');
          debugPrint('✅ [SIMPLE API] Categorías: ${codigos.map((c) => c.categoria).toSet().toList()}');
          debugPrint('✅ [SIMPLE API] Primeros 3 códigos: ${codigos.take(3).map((c) => '${c.codigo} - ${c.nombre}').toList()}');
          return codigos;
        } else {
          debugPrint('❌ [SIMPLE API] API Error: ${data['error']}');
          throw Exception('API Error: ${data['error']}');
        }
      } else {
        debugPrint('❌ [SIMPLE API] HTTP Error: ${response.statusCode}');
        debugPrint('❌ [SIMPLE API] Response: ${response.body}');
        throw Exception('HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } on SocketException catch (e) {
      debugPrint('❌ [SIMPLE API] SocketException: ${e.message}');
      debugPrint('❌ [SIMPLE API] OS Error: ${e.osError?.message}');
      debugPrint('❌ [SIMPLE API] Error Code: ${e.osError?.errorCode}');
      
      if (e.osError?.errorCode == 7) {
        throw Exception('Error DNS: no se pudo resolver el dominio de Supabase.');
      }
      rethrow;
    } on TimeoutException {
      debugPrint('❌ [SIMPLE API] TimeoutException: Conexión muy lenta');
      throw Exception('Timeout: La conexión está muy lenta.');
    } catch (e) {
      debugPrint('❌ [SIMPLE API] Error desconocido: $e');
      debugPrint('❌ [SIMPLE API] Tipo: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Obtener categorías
  static Future<List<String>> getCategorias() async {
    debugPrint('🔍 [SIMPLE API] Obteniendo categorías...');
    final client = SecureHttp.createSecureClient();
    try {
      final uri = Uri.parse('$baseUrl/get-categorias');
      final response = await client.get(uri, headers: _headers).timeout(const Duration(seconds: 20));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final categorias = List<String>.from(data['data']);
          debugPrint('✅ [SIMPLE API] Categorías obtenidas: ${categorias.length}');
          return categorias;
        }
      }
      throw Exception('Error obteniendo categorías: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [SIMPLE API] Error categorías: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Obtener favoritos
  static Future<List<UsuarioFavorito>> getFavoritos(String userId) async {
    debugPrint('🔍 [SIMPLE API] Obteniendo favoritos para $userId...');
    final client = SecureHttp.createSecureClient();
    try {
      final uri = Uri.parse('$baseUrl/get-favoritos?userId=$userId');
      final response = await client.get(uri, headers: _headers).timeout(const Duration(seconds: 20));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final favoritos = (data['data'] as List)
              .map((json) => UsuarioFavorito.fromJson(json))
              .toList();
          debugPrint('✅ [SIMPLE API] Favoritos obtenidos: ${favoritos.length}');
          return favoritos;
        }
      }
      throw Exception('Error obteniendo favoritos: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [SIMPLE API] Error favoritos: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Toggle favorito
  static Future<void> toggleFavorito(String userId, String codigoId) async {
    debugPrint('🔍 [SIMPLE API] Toggle favorito: $codigoId para $userId');
    final client = SecureHttp.createSecureClient();
    try {
      final uri = Uri.parse('$baseUrl/toggle-favorito');
      final body = json.encode({
        'userId': userId,
        'codigoId': codigoId,
      });
      final response = await client.post(uri, headers: _headers, body: body).timeout(const Duration(seconds: 20));
      
      if (response.statusCode == 200) {
        debugPrint('✅ [SIMPLE API] Favorito toggled exitosamente');
      } else {
        throw Exception('Error toggle favorito: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [SIMPLE API] Error toggle favorito: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Incrementar popularidad
  static Future<void> incrementarPopularidad(String codigoId) async {
    debugPrint('🔍 [SIMPLE API] Incrementando popularidad: $codigoId');
    final client = SecureHttp.createSecureClient();
    try {
      final uri = Uri.parse('$baseUrl/incrementar-popularidad');
      final body = json.encode({'codigoId': codigoId});
      final response = await client.post(uri, headers: _headers, body: body).timeout(const Duration(seconds: 20));
      
      if (response.statusCode == 200) {
        debugPrint('✅ [SIMPLE API] Popularidad incrementada exitosamente');
      } else {
        throw Exception('Error incrementar popularidad: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [SIMPLE API] Error incrementar popularidad: $e');
      rethrow;
    } finally {
      client.close();
    }
  }
}
