import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/supabase_models.dart';

class SimpleApiService {
  static const String baseUrl = 'https://whtiazgcxdnemrrgjjqf.supabase.co/functions/v1';
  static const String apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1MjM2MzgsImV4cCI6MjA3NjA5OTYzOH0.1CFkusMrMKcvSU_-5RyGYPoKDM_yizuQMVGo7W3mXHU';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
    'User-Agent': 'ManifestacionApp/1.0',
    'Accept': 'application/json',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive',
  };

  /// Verifica conectividad básica
  static Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('✅ [CONNECTIVITY] Conectado a internet');
        return true;
      }
    } catch (e) {
      print('❌ [CONNECTIVITY] Error: $e');
    }
    return false;
  }

  /// Obtener códigos de forma simple y directa
  static Future<List<CodigoGrabovoi>> getCodigos({
    String? categoria,
    String? search,
  }) async {
    print('🔍 [SIMPLE API] ===========================================');
    print('🔍 [SIMPLE API] INICIANDO CONEXIÓN SIMPLE');
    print('🔍 [SIMPLE API] ===========================================');
    print('🔍 [SIMPLE API] Parámetros: categoria=$categoria, search=$search');
    print('🔍 [SIMPLE API] Timestamp: ${DateTime.now()}');
    print('🔍 [SIMPLE API] Platform: ${Platform.operatingSystem}');
    print('🔍 [SIMPLE API] ===========================================');
    
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

    print('📡 [SIMPLE API] URL: $uri');
    print('📡 [SIMPLE API] Headers: $_headers');

    try {
      print('📡 [SIMPLE API] Iniciando petición HTTP...');
      
      // Crear cliente HTTP que bypasee SSL para Android
      final httpClient = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) {
          print('🔓 [SSL BYPASS] Aceptando certificado para $host:$port');
          return true; // Aceptar cualquier certificado
        };
      
      final client = IOClient(httpClient);
      
      final response = await client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      print('📊 [SIMPLE API] Status: ${response.statusCode}');
      print('📊 [SIMPLE API] Body length: ${response.body.length}');

      if (response.statusCode == 200) {
        print('🔍 [SIMPLE API] Decodificando JSON...');
        final data = json.decode(response.body);
        print('🔍 [SIMPLE API] JSON decodificado: ${data.runtimeType}');
        print('🔍 [SIMPLE API] Keys: ${data.keys.toList()}');
        print('🔍 [SIMPLE API] Success: ${data['success']}');
        
        if (data['success'] == true) {
          final rawData = data['data'] as List;
          print('🔍 [SIMPLE API] Data length: ${rawData.length}');
          
          print('🔍 [SIMPLE API] Parseando códigos...');
          final codigos = rawData
              .map((json) {
                try {
                  return CodigoGrabovoi.fromJson(json);
                } catch (e) {
                  print('❌ [SIMPLE API] Error parseando: $e');
                  print('❌ [SIMPLE API] JSON: $json');
                  rethrow;
                }
              })
              .toList();
          
          print('✅ [SIMPLE API] ÉXITO: ${codigos.length} códigos obtenidos');
          print('✅ [SIMPLE API] Primer código: ${codigos.isNotEmpty ? codigos.first.nombre : 'N/A'}');
          print('✅ [SIMPLE API] Último código: ${codigos.isNotEmpty ? codigos.last.nombre : 'N/A'}');
          print('✅ [SIMPLE API] Categorías: ${codigos.map((c) => c.categoria).toSet().toList()}');
          print('✅ [SIMPLE API] Primeros 3 códigos: ${codigos.take(3).map((c) => '${c.codigo} - ${c.nombre}').toList()}');
          return codigos;
        } else {
          print('❌ [SIMPLE API] API Error: ${data['error']}');
          throw Exception('API Error: ${data['error']}');
        }
      } else {
        print('❌ [SIMPLE API] HTTP Error: ${response.statusCode}');
        print('❌ [SIMPLE API] Response: ${response.body}');
        throw Exception('HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } on SocketException catch (e) {
      print('❌ [SIMPLE API] SocketException: ${e.message}');
      print('❌ [SIMPLE API] OS Error: ${e.osError?.message}');
      print('❌ [SIMPLE API] Error Code: ${e.osError?.errorCode}');
      
      if (e.osError?.errorCode == 7) {
        throw Exception('Error DNS: no se pudo resolver el dominio de Supabase.');
      }
      rethrow;
    } on TimeoutException {
      print('❌ [SIMPLE API] TimeoutException: Conexión muy lenta');
      throw Exception('Timeout: La conexión está muy lenta.');
    } catch (e) {
      print('❌ [SIMPLE API] Error desconocido: $e');
      print('❌ [SIMPLE API] Tipo: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Obtener categorías
  static Future<List<String>> getCategorias() async {
    print('🔍 [SIMPLE API] Obteniendo categorías...');
    try {
      final uri = Uri.parse('$baseUrl/get-categorias');
      
      // Cliente HTTP con SSL bypass
      final httpClient = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      final client = IOClient(httpClient);
      
      final response = await client.get(uri, headers: _headers).timeout(const Duration(seconds: 20));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final categorias = List<String>.from(data['data']);
          print('✅ [SIMPLE API] Categorías obtenidas: ${categorias.length}');
          return categorias;
        }
      }
      throw Exception('Error obteniendo categorías: ${response.statusCode}');
    } catch (e) {
      print('❌ [SIMPLE API] Error categorías: $e');
      rethrow;
    }
  }

  /// Obtener favoritos
  static Future<List<UsuarioFavorito>> getFavoritos(String userId) async {
    print('🔍 [SIMPLE API] Obteniendo favoritos para $userId...');
    try {
      final uri = Uri.parse('$baseUrl/get-favoritos?userId=$userId');
      
      // Cliente HTTP con SSL bypass
      final httpClient = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      final client = IOClient(httpClient);
      
      final response = await client.get(uri, headers: _headers).timeout(const Duration(seconds: 20));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final favoritos = (data['data'] as List)
              .map((json) => UsuarioFavorito.fromJson(json))
              .toList();
          print('✅ [SIMPLE API] Favoritos obtenidos: ${favoritos.length}');
          return favoritos;
        }
      }
      throw Exception('Error obteniendo favoritos: ${response.statusCode}');
    } catch (e) {
      print('❌ [SIMPLE API] Error favoritos: $e');
      rethrow;
    }
  }

  /// Toggle favorito
  static Future<void> toggleFavorito(String userId, String codigoId) async {
    print('🔍 [SIMPLE API] Toggle favorito: $codigoId para $userId');
    try {
      final uri = Uri.parse('$baseUrl/toggle-favorito');
      final body = json.encode({
        'userId': userId,
        'codigoId': codigoId,
      });
      
      // Cliente HTTP con SSL bypass
      final httpClient = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      final client = IOClient(httpClient);
      
      final response = await client.post(uri, headers: _headers, body: body).timeout(const Duration(seconds: 20));
      
      if (response.statusCode == 200) {
        print('✅ [SIMPLE API] Favorito toggled exitosamente');
      } else {
        throw Exception('Error toggle favorito: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [SIMPLE API] Error toggle favorito: $e');
      rethrow;
    }
  }

  /// Incrementar popularidad
  static Future<void> incrementarPopularidad(String codigoId) async {
    print('🔍 [SIMPLE API] Incrementando popularidad: $codigoId');
    try {
      final uri = Uri.parse('$baseUrl/incrementar-popularidad');
      final body = json.encode({'codigoId': codigoId});
      
      // Cliente HTTP con SSL bypass
      final httpClient = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      final client = IOClient(httpClient);
      
      final response = await client.post(uri, headers: _headers, body: body).timeout(const Duration(seconds: 20));
      
      if (response.statusCode == 200) {
        print('✅ [SIMPLE API] Popularidad incrementada exitosamente');
      } else {
        throw Exception('Error incrementar popularidad: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [SIMPLE API] Error incrementar popularidad: $e');
      rethrow;
    }
  }
}
