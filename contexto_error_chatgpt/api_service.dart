import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/supabase_models.dart';

class ApiService {
  static const String baseUrl = 'https://whtiazgcxdnemrrgjjqf.supabase.co/functions/v1';
  static const String apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1MjM2MzgsImV4cCI6MjA3NjA5OTYzOH0.1CFkusMrMKcvSU_-5RyGYPoKDM_yizuQMVGo7W3mXHU';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
    'User-Agent': 'ManifestacionApp/1.0',
    'Accept': 'application/json',
    'Cache-Control': 'no-cache',
  };

  /// Verifica conectividad antes de hacer peticiones
  static Future<bool> _checkConnectivity() async {
    try {
      print('🔍 [CONNECTIVITY] Verificando conectividad...');
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('✅ [CONNECTIVITY] Conectividad OK');
        return true;
      }
    } catch (e) {
      print('❌ [CONNECTIVITY] Error: $e');
    }
    print('❌ [CONNECTIVITY] Sin conectividad');
    return false;
  }

  // ===== CÓDIGOS =====
  
  static Future<List<CodigoGrabovoi>> getCodigos({
    String? categoria,
    String? search,
  }) async {
    print('🔍 [API] Iniciando getCodigos...');
    print('   📍 Parámetros: categoria=$categoria, search=$search');
    
    // Verificar conectividad primero
    final connected = await _checkConnectivity();
    if (!connected) {
      throw Exception('Sin conexión a internet o DNS inaccesible.');
    }

    final Uri uri = Uri.parse('$baseUrl/get-codigos').replace(queryParameters: {
      if (categoria != null && categoria != 'Todos') 'categoria': categoria,
      if (search != null && search.isNotEmpty) 'search': search,
    });

    print('🌐 [API] URI construida: $uri');

    int retryCount = 0;
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);

    while (retryCount < maxRetries) {
      try {
        print('📡 [API] Intento ${retryCount + 1}/$maxRetries...');
        
        final response = await http
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 20));

        print('📊 [API] Status: ${response.statusCode}');
        print('📊 [API] Body length: ${response.body.length}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('🔍 [API] JSON decodificado: ${data.runtimeType}');
          print('🔍 [API] Keys: ${data.keys.toList()}');
          print('🔍 [API] Success: ${data['success']}');
          print('🔍 [API] Count: ${data['count']}');
          
          if (data['success'] == true) {
            final rawData = data['data'] as List;
            print('🔍 [API] Total elementos: ${rawData.length}');
            
            if (rawData.isNotEmpty) {
              print('🔍 [API] Primer elemento: ${rawData.first}');
            }
            
            final codigos = rawData
                .map((json) {
                  try {
                    final codigo = CodigoGrabovoi.fromJson(json);
                    return codigo;
                  } catch (e) {
                    print('❌ [API] Error parseando elemento: $json');
                    print('❌ [API] Error: $e');
                    rethrow;
                  }
                })
                .toList();
            
            print('✅ [API] ${codigos.length} códigos parseados exitosamente');
            return codigos;
          } else {
            print('❌ [API] Error en respuesta: ${data['error']}');
            throw Exception('API Error: ${data['error']}');
          }
        } else {
          print('❌ [API] HTTP Error: ${response.statusCode}');
          print('❌ [API] Response: ${response.body}');
          throw HttpException(
              'Error HTTP ${response.statusCode}: ${response.reasonPhrase}');
        }
      } on SocketException catch (e) {
        // Falla de DNS o conexión
        print('❌ [API ERROR] SocketException → ${e.message}');
        print('❌ [API ERROR] OS Error: ${e.osError?.message}');
        print('❌ [API ERROR] Error Code: ${e.osError?.errorCode}');
        
        if (e.osError?.errorCode == 7) {
          throw Exception(
              'Error DNS: no se pudo resolver el dominio de Supabase.\n'
              'Verifica que el dispositivo tenga acceso a internet o DNS funcional (8.8.8.8).');
        }
        
        retryCount++;
        if (retryCount < maxRetries) {
          print('🔄 [API] Reintentando en ${retryDelay.inSeconds}s...');
          await Future.delayed(retryDelay);
        }
      } on TimeoutException catch (e) {
        print('⏳ [API WARNING] Timeout alcanzado → $e');
        retryCount++;
        if (retryCount < maxRetries) {
          print('🔄 [API] Reintentando en ${retryDelay.inSeconds}s...');
          await Future.delayed(retryDelay);
        }
      } catch (e) {
        print('⚠️ [API UNKNOWN ERROR] → $e');
        rethrow;
      }
    }

    throw Exception('No se pudo conectar a Supabase después de $maxRetries intentos.');
  }

  // ===== CATEGORÍAS =====
  
  static Future<List<String>> getCategorias() async {
    print('🔍 [API] Obteniendo categorías...');
    
    final connected = await _checkConnectivity();
    if (!connected) {
      throw Exception('Sin conexión a internet o DNS inaccesible.');
    }

    final Uri uri = Uri.parse('$baseUrl/get-categorias');
    print('🌐 [API] URI categorías: $uri');

    int retryCount = 0;
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);

    while (retryCount < maxRetries) {
      try {
        print('📡 [API] Intento categorías ${retryCount + 1}/$maxRetries...');
        
        final response = await http
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            final categorias = List<String>.from(data['data']);
            print('✅ [API] ${categorias.length} categorías obtenidas');
            return categorias;
          } else {
            throw Exception('API Error: ${data['error']}');
          }
        } else {
          throw HttpException('Error HTTP ${response.statusCode}: ${response.reasonPhrase}');
        }
      } on SocketException catch (e) {
        print('❌ [API ERROR] SocketException categorías → ${e.message}');
        if (e.osError?.errorCode == 7) {
          throw Exception('Error DNS: no se pudo resolver el dominio de Supabase.');
        }
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(retryDelay);
        }
      } on TimeoutException {
        print('⏳ [API WARNING] Timeout categorías, reintentando...');
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(retryDelay);
        }
      } catch (e) {
        print('⚠️ [API UNKNOWN ERROR] categorías → $e');
        rethrow;
      }
    }

    throw Exception('No se pudo obtener categorías después de $maxRetries intentos.');
  }

  // ===== FAVORITOS =====
  
  static Future<List<UsuarioFavorito>> getFavoritos(String userId) async {
    final connected = await _checkConnectivity();
    if (!connected) {
      throw Exception('Sin conexión a internet o DNS inaccesible.');
    }

    final Uri uri = Uri.parse('$baseUrl/get-favoritos').replace(
      queryParameters: {'user_id': userId}
    );

    int retryCount = 0;
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);

    while (retryCount < maxRetries) {
      try {
        final response = await http
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            final favoritos = (data['data'] as List)
                .map((json) => UsuarioFavorito.fromJson(json))
                .toList();
            return favoritos;
          } else {
            throw Exception('API Error: ${data['error']}');
          }
        } else {
          throw HttpException('Error HTTP ${response.statusCode}: ${response.reasonPhrase}');
        }
      } on SocketException catch (e) {
        if (e.osError?.errorCode == 7) {
          throw Exception('Error DNS: no se pudo resolver el dominio de Supabase.');
        }
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(retryDelay);
        }
      } on TimeoutException {
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(retryDelay);
        }
      } catch (e) {
        rethrow;
      }
    }

    throw Exception('No se pudo obtener favoritos después de $maxRetries intentos.');
  }

  static Future<bool> toggleFavorito(String userId, String codigoId) async {
    final connected = await _checkConnectivity();
    if (!connected) {
      throw Exception('Sin conexión a internet o DNS inaccesible.');
    }

    final Uri uri = Uri.parse('$baseUrl/toggle-favorito');
    final body = json.encode({
      'user_id': userId,
      'codigo_id': codigoId,
    });

    int retryCount = 0;
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);

    while (retryCount < maxRetries) {
      try {
        final response = await http
            .post(uri, headers: _headers, body: body)
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return data['success'] == true;
        } else {
          throw HttpException('Error HTTP ${response.statusCode}: ${response.reasonPhrase}');
        }
      } on SocketException catch (e) {
        if (e.osError?.errorCode == 7) {
          throw Exception('Error DNS: no se pudo resolver el dominio de Supabase.');
        }
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(retryDelay);
        }
      } on TimeoutException {
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(retryDelay);
        }
      } catch (e) {
        rethrow;
      }
    }

    throw Exception('No se pudo actualizar favorito después de $maxRetries intentos.');
  }

  // ===== POPULARIDAD =====
  
  static Future<bool> incrementarPopularidad(String codigoId) async {
    final connected = await _checkConnectivity();
    if (!connected) {
      throw Exception('Sin conexión a internet o DNS inaccesible.');
    }

    final Uri uri = Uri.parse('$baseUrl/incrementar-popularidad');
    final body = json.encode({'codigo_id': codigoId});

    int retryCount = 0;
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);

    while (retryCount < maxRetries) {
      try {
        final response = await http
            .post(uri, headers: _headers, body: body)
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return data['success'] == true;
        } else {
          throw HttpException('Error HTTP ${response.statusCode}: ${response.reasonPhrase}');
        }
      } on SocketException catch (e) {
        if (e.osError?.errorCode == 7) {
          throw Exception('Error DNS: no se pudo resolver el dominio de Supabase.');
        }
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(retryDelay);
        }
      } on TimeoutException {
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(retryDelay);
        }
      } catch (e) {
        rethrow;
      }
    }

    throw Exception('No se pudo incrementar popularidad después de $maxRetries intentos.');
  }
}