import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/supabase_models.dart';
import 'secure_http.dart';
import 'custom_domain_service.dart';
import 'dns_service.dart';

class ApiService {
  static const String baseUrl = 'https://whtiazgcxdnemrrgjjqf.supabase.co/functions/v1';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${Env.supabaseAnonKey}',
    'User-Agent': 'ManifestacionApp/1.0',
    'Accept': 'application/json',
    'Cache-Control': 'no-cache',
  };

  /// Verifica conectividad antes de hacer peticiones
  static Future<bool> _checkConnectivity() async {
    if (kIsWeb) return true; // En web delegamos la conectividad al navegador
    try {
      debugPrint('🔍 [CONNECTIVITY] Verificando conectividad...');
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        debugPrint('✅ [CONNECTIVITY] Conectividad OK');
        return true;
      }
    } catch (e) {
      debugPrint('❌ [CONNECTIVITY] Error: $e');
    }
    debugPrint('❌ [CONNECTIVITY] Sin conectividad');
    return false;
  }

  // ===== CÓDIGOS =====
  
  static Future<List<CodigoGrabovoi>> getCodigos({
    String? categoria,
    String? search,
  }) async {
    debugPrint('🔍 [API] ===========================================');
    debugPrint('🔍 [API] INICIANDO DIAGNÓSTICO COMPLETO');
    debugPrint('🔍 [API] ===========================================');
    debugPrint('🔍 [API] Parámetros: categoria=$categoria, search=$search');
    debugPrint('🔍 [API] Timestamp: ${DateTime.now()}');
    debugPrint('🔍 [API] Platform: ${kIsWeb ? "Web" : Platform.operatingSystem}');
    debugPrint('🔍 [API] ===========================================');
    
    // ESTRATEGIA 1: Intentar con dominio personalizado (más compatible)
    try {
      debugPrint('🌐 [ESTRATEGIA 1] ===========================================');
      debugPrint('🌐 [ESTRATEGIA 1] PROBANDO DOMINIO PERSONALIZADO');
      debugPrint('🌐 [ESTRATEGIA 1] ===========================================');
      debugPrint('🌐 [ESTRATEGIA 1] Timestamp: ${DateTime.now()}');
      debugPrint('🌐 [ESTRATEGIA 1] Llamando CustomDomainService.getCodigos()...');
      
      final result = await CustomDomainService.getCodigos(
        categoria: categoria,
        search: search,
      );
      
      debugPrint('✅ [ESTRATEGIA 1] ÉXITO - Dominio personalizado funcionó');
      debugPrint('✅ [ESTRATEGIA 1] Códigos obtenidos: ${result.length}');
      debugPrint('✅ [ESTRATEGIA 1] Primer código: ${result.isNotEmpty ? result.first.nombre : 'N/A'}');
      return result;
    } catch (e) {
      debugPrint('❌ [ESTRATEGIA 1] ===========================================');
      debugPrint('❌ [ESTRATEGIA 1] DOMINIO PERSONALIZADO FALLÓ');
      debugPrint('❌ [ESTRATEGIA 1] ===========================================');
      debugPrint('❌ [ESTRATEGIA 1] Error: $e');
      debugPrint('❌ [ESTRATEGIA 1] Tipo de error: ${e.runtimeType}');
      debugPrint('❌ [ESTRATEGIA 1] Stack trace: ${StackTrace.current}');
    }
    
    // ESTRATEGIA 2: Configurar DNS y reintentar
    try {
      debugPrint('🔧 [ESTRATEGIA 2] ===========================================');
      debugPrint('🔧 [ESTRATEGIA 2] CONFIGURANDO DNS Y REINTENTANDO');
      debugPrint('🔧 [ESTRATEGIA 2] ===========================================');
      debugPrint('🔧 [ESTRATEGIA 2] Timestamp: ${DateTime.now()}');
      debugPrint('🔧 [ESTRATEGIA 2] Llamando DnsService.autoConfigureDns()...');
      
      final dnsResult = await DnsService.autoConfigureDns();
      debugPrint('🔧 [ESTRATEGIA 2] DNS configurado: $dnsResult');
      
      debugPrint('🔧 [ESTRATEGIA 2] Reintentando con dominio personalizado...');
      final result = await CustomDomainService.getCodigos(
        categoria: categoria,
        search: search,
      );
      
      debugPrint('✅ [ESTRATEGIA 2] ÉXITO - DNS + dominio personalizado funcionó');
      debugPrint('✅ [ESTRATEGIA 2] Códigos obtenidos: ${result.length}');
      return result;
    } catch (e) {
      debugPrint('❌ [ESTRATEGIA 2] ===========================================');
      debugPrint('❌ [ESTRATEGIA 2] DNS + DOMINIO PERSONALIZADO FALLÓ');
      debugPrint('❌ [ESTRATEGIA 2] ===========================================');
      debugPrint('❌ [ESTRATEGIA 2] Error: $e');
      debugPrint('❌ [ESTRATEGIA 2] Tipo de error: ${e.runtimeType}');
    }
    
    // ESTRATEGIA 3: Verificar conectividad y usar método original
    final connected = await _checkConnectivity();
    if (!connected) {
      throw Exception('Sin conexión a internet o DNS inaccesible.');
    }

    final Uri uri = Uri.parse('$baseUrl/get-codigos').replace(queryParameters: {
      if (categoria != null && categoria != 'Todos') 'categoria': categoria,
      if (search != null && search.isNotEmpty) 'search': search,
    });

    debugPrint('🌐 [API] URI construida: $uri');

    int retryCount = 0;
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);

    while (retryCount < maxRetries) {
      final client = SecureHttp.createSecureClient();
      try {
        debugPrint('📡 [API] Intento ${retryCount + 1}/$maxRetries...');
        
        // Siempre usar cliente seguro (sin SSL bypass en producción)
        final response = await client
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 20));

        debugPrint('📊 [API] Status: ${response.statusCode}');
        debugPrint('📊 [API] Body length: ${response.body.length}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          debugPrint('🔍 [API] JSON decodificado: ${data.runtimeType}');
          debugPrint('🔍 [API] Keys: ${data.keys.toList()}');
          debugPrint('🔍 [API] Success: ${data['success']}');
          debugPrint('🔍 [API] Count: ${data['count']}');
          
          if (data['success'] == true) {
            final rawData = data['data'] as List;
            debugPrint('🔍 [API] Total elementos: ${rawData.length}');
            
            if (rawData.isNotEmpty) {
              debugPrint('🔍 [API] Primer elemento: ${rawData.first}');
            }
            
            final codigos = rawData
                .map((json) {
                  try {
                    final codigo = CodigoGrabovoi.fromJson(json);
                    return codigo;
                  } catch (e) {
                    debugPrint('❌ [API] Error parseando elemento: $json');
                    debugPrint('❌ [API] Error: $e');
                    rethrow;
                  }
                })
                .toList();
            
            debugPrint('✅ [API] ${codigos.length} códigos parseados exitosamente');
            return codigos;
          } else {
            debugPrint('❌ [API] Error en respuesta: ${data['error']}');
            throw Exception('API Error: ${data['error']}');
          }
        } else {
          debugPrint('❌ [API] HTTP Error: ${response.statusCode}');
          debugPrint('❌ [API] Response: ${response.body}');
          throw HttpException(
              'Error HTTP ${response.statusCode}: ${response.reasonPhrase}');
        }
      } on SocketException catch (e) {
        // Falla de DNS o conexión
        debugPrint('❌ [API ERROR] SocketException → ${e.message}');
        debugPrint('❌ [API ERROR] OS Error: ${e.osError?.message}');
        debugPrint('❌ [API ERROR] Error Code: ${e.osError?.errorCode}');
        
        if (e.osError?.errorCode == 7) {
          throw Exception(
              'Error DNS: no se pudo resolver el dominio de Supabase.\n'
              'Verifica que el dispositivo tenga acceso a internet o DNS funcional (8.8.8.8).');
        }
        
        retryCount++;
        if (retryCount < maxRetries) {
          debugPrint('🔄 [API] Reintentando en ${retryDelay.inSeconds}s...');
          await Future.delayed(retryDelay);
        }
      } on TimeoutException catch (e) {
        debugPrint('⏳ [API WARNING] Timeout alcanzado → $e');
        retryCount++;
        if (retryCount < maxRetries) {
          debugPrint('🔄 [API] Reintentando en ${retryDelay.inSeconds}s...');
          await Future.delayed(retryDelay);
        }
      } catch (e) {
        debugPrint('⚠️ [API UNKNOWN ERROR] → $e');
        rethrow;
      } finally {
        client.close();
      }
    }

    throw Exception('No se pudo conectar a Supabase después de $maxRetries intentos.');
  }

  // ===== CATEGORÍAS =====
  
  static Future<List<String>> getCategorias() async {
    debugPrint('🔍 [API] Obteniendo categorías...');
    
    final connected = await _checkConnectivity();
    if (!connected) {
      throw Exception('Sin conexión a internet o DNS inaccesible.');
    }

    final Uri uri = Uri.parse('$baseUrl/get-categorias');
    debugPrint('🌐 [API] URI categorías: $uri');

    int retryCount = 0;
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);

    while (retryCount < maxRetries) {
      try {
        debugPrint('📡 [API] Intento categorías ${retryCount + 1}/$maxRetries...');
        
        final response = await http
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            final categorias = List<String>.from(data['data']);
            debugPrint('✅ [API] ${categorias.length} categorías obtenidas');
            return categorias;
          } else {
            throw Exception('API Error: ${data['error']}');
          }
        } else {
          throw HttpException('Error HTTP ${response.statusCode}: ${response.reasonPhrase}');
        }
      } on SocketException catch (e) {
        debugPrint('❌ [API ERROR] SocketException categorías → ${e.message}');
        if (e.osError?.errorCode == 7) {
          throw Exception('Error DNS: no se pudo resolver el dominio de Supabase.');
        }
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(retryDelay);
        }
      } on TimeoutException {
        debugPrint('⏳ [API WARNING] Timeout categorías, reintentando...');
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(retryDelay);
        }
      } catch (e) {
        debugPrint('⚠️ [API UNKNOWN ERROR] categorías → $e');
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