import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/supabase_models.dart';

class CustomDomainService {
  // URLs de dominio personalizado (más compatibles con Android)
  static const List<String> customDomains = [
    'https://whtiazgcxdnemrrgjjqf.supabase.co/functions/v1', // URL directa que funciona
  ];
  
  static const String fallbackUrl = 'https://whtiazgcxdnemrrgjjqf.supabase.co/functions/v1';
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
      print('🔍 [CUSTOM DOMAIN] Verificando conectividad...');
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('✅ [CUSTOM DOMAIN] Conectividad OK');
        return true;
      }
    } catch (e) {
      print('❌ [CUSTOM DOMAIN] Error: $e');
    }
    print('❌ [CUSTOM DOMAIN] Sin conectividad');
    return false;
  }

  // ===== CÓDIGOS CON DOMINIO PERSONALIZADO =====
  
  static Future<List<CodigoGrabovoi>> getCodigos({
    String? categoria,
    String? search,
  }) async {
    print('🔍 [CUSTOM DOMAIN] ===========================================');
    print('🔍 [CUSTOM DOMAIN] INICIANDO CUSTOM DOMAIN SERVICE');
    print('🔍 [CUSTOM DOMAIN] ===========================================');
    print('🔍 [CUSTOM DOMAIN] Parámetros: categoria=$categoria, search=$search');
    print('🔍 [CUSTOM DOMAIN] Timestamp: ${DateTime.now()}');
    print('🔍 [CUSTOM DOMAIN] Dominios disponibles: ${customDomains.length}');
    print('🔍 [CUSTOM DOMAIN] Dominios: $customDomains');
    print('🔍 [CUSTOM DOMAIN] ===========================================');
    
    // Verificar conectividad primero
    final connected = await _checkConnectivity();
    if (!connected) {
      throw Exception('Sin conexión a internet o DNS inaccesible.');
    }

    // Probar cada dominio personalizado en orden
    for (int i = 0; i < customDomains.length; i++) {
      final customDomain = customDomains[i];
      print('🌐 [CUSTOM DOMAIN $i] ===========================================');
      print('🌐 [CUSTOM DOMAIN $i] PROBANDO DOMINIO: $customDomain');
      print('🌐 [CUSTOM DOMAIN $i] ===========================================');
      print('🌐 [CUSTOM DOMAIN $i] Timestamp: ${DateTime.now()}');
      print('🌐 [CUSTOM DOMAIN $i] Índice: $i de ${customDomains.length}');
      
      try {
        final baseUrl = '$customDomain/get-codigos';
        print('🌐 [CUSTOM DOMAIN $i] URL base: $baseUrl');
        
        final queryParams = <String, String>{};
        if (categoria != null && categoria != 'Todos') {
          queryParams['categoria'] = categoria;
          print('🌐 [CUSTOM DOMAIN $i] Agregando categoría: $categoria');
        }
        if (search != null && search.isNotEmpty) {
          queryParams['search'] = search;
          print('🌐 [CUSTOM DOMAIN $i] Agregando búsqueda: $search');
        }
        
        final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
        print('📡 [CUSTOM DOMAIN $i] URI construida: $uri');
        print('📡 [CUSTOM DOMAIN $i] Query parameters: $queryParams');
        print('📡 [CUSTOM DOMAIN $i] Headers: $_headers');
        
        print('📡 [CUSTOM DOMAIN $i] Iniciando petición HTTP...');
        print('📡 [CUSTOM DOMAIN $i] Timeout: 20 segundos');
        
        final response = await http
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 20));

        print('📊 [CUSTOM DOMAIN $i] ===========================================');
        print('📊 [CUSTOM DOMAIN $i] RESPUESTA HTTP RECIBIDA');
        print('📊 [CUSTOM DOMAIN $i] ===========================================');
        print('📊 [CUSTOM DOMAIN $i] Status Code: ${response.statusCode}');
        print('📊 [CUSTOM DOMAIN $i] Reason Phrase: ${response.reasonPhrase}');
        print('📊 [CUSTOM DOMAIN $i] Body Length: ${response.body.length}');
        print('📊 [CUSTOM DOMAIN $i] Headers: ${response.headers}');
        print('📊 [CUSTOM DOMAIN $i] Body Preview: ${response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('🔍 [CUSTOM DOMAIN $i] JSON decodificado: ${data.runtimeType}');
          print('🔍 [CUSTOM DOMAIN $i] Keys: ${data.keys.toList()}');
          print('🔍 [CUSTOM DOMAIN $i] Success: ${data['success']}');
          print('🔍 [CUSTOM DOMAIN $i] Count: ${data['count']}');
          
          if (data['success'] == true) {
            final rawData = data['data'] as List;
            print('🔍 [CUSTOM DOMAIN $i] Total elementos: ${rawData.length}');
            
            final codigos = rawData
                .map((json) {
                  try {
                    final codigo = CodigoGrabovoi.fromJson(json);
                    return codigo;
                  } catch (e) {
                    print('❌ [CUSTOM DOMAIN $i] Error parseando elemento: $json');
                    print('❌ [CUSTOM DOMAIN $i] Error: $e');
                    rethrow;
                  }
                })
                .toList();
            
            print('✅ [CUSTOM DOMAIN $i] ${codigos.length} códigos parseados exitosamente');
            print('🎉 [CUSTOM DOMAIN $i] ¡Dominio personalizado funcionando!');
            return codigos;
          } else {
            print('❌ [CUSTOM DOMAIN $i] Error en respuesta: ${data['error']}');
            continue; // Probar siguiente dominio
          }
        } else {
          print('❌ [CUSTOM DOMAIN $i] HTTP Error: ${response.statusCode}');
          continue; // Probar siguiente dominio
        }
      } catch (e) {
        print('❌ [CUSTOM DOMAIN $i] Error: $e');
        continue; // Probar siguiente dominio
      }
    }

    // Si todos los dominios personalizados fallan, probar URL directa como último recurso
    print('🔄 [FALLBACK] Todos los dominios personalizados fallaron, probando URL directa...');
    try {
      final uri = Uri.parse('$fallbackUrl/get-codigos').replace(queryParameters: {
        if (categoria != null && categoria != 'Todos') 'categoria': categoria,
        if (search != null && search.isNotEmpty) 'search': search,
      });

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final rawData = data['data'] as List;
          final codigos = rawData
              .map((json) => CodigoGrabovoi.fromJson(json))
              .toList();
          
          print('✅ [FALLBACK] ${codigos.length} códigos obtenidos via URL directa');
          return codigos;
        }
      }
    } catch (e) {
      print('❌ [FALLBACK] Error en URL directa: $e');
    }

    throw Exception('Todos los dominios personalizados y la URL directa fallaron. Verifica tu conexión.');
  }

  // ===== CATEGORÍAS CON DOMINIO PERSONALIZADO =====
  
  static Future<List<String>> getCategorias() async {
    print('🔍 [CUSTOM DOMAIN] Obteniendo categorías con dominio personalizado...');
    
    final connected = await _checkConnectivity();
    if (!connected) {
      throw Exception('Sin conexión a internet o DNS inaccesible.');
    }

    // Probar cada dominio personalizado para categorías
    for (int i = 0; i < customDomains.length; i++) {
      final customDomain = customDomains[i];
      
      try {
        print('🌐 [CUSTOM DOMAIN $i] Probando categorías: $customDomain/get-categorias');
        
        final uri = Uri.parse('$customDomain/get-categorias');
        final response = await http
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            final categorias = List<String>.from(data['data']);
            print('✅ [CUSTOM DOMAIN $i] ${categorias.length} categorías obtenidas');
            return categorias;
          }
        }
      } catch (e) {
        print('❌ [CUSTOM DOMAIN $i] Error categorías: $e');
        continue;
      }
    }

    throw Exception('No se pudo obtener categorías desde ningún dominio personalizado.');
  }

  // ===== FAVORITOS CON DOMINIO PERSONALIZADO =====
  
  static Future<List<UsuarioFavorito>> getFavoritos(String userId) async {
    final connected = await _checkConnectivity();
    if (!connected) {
      throw Exception('Sin conexión a internet o DNS inaccesible.');
    }

    // Probar cada dominio personalizado para favoritos
    for (int i = 0; i < customDomains.length; i++) {
      final customDomain = customDomains[i];
      
      try {
        final uri = Uri.parse('$customDomain/get-favoritos').replace(
          queryParameters: {'user_id': userId}
        );

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
          }
        }
      } catch (e) {
        continue;
      }
    }

    throw Exception('No se pudo obtener favoritos desde ningún dominio personalizado.');
  }

  static Future<bool> toggleFavorito(String userId, String codigoId) async {
    final connected = await _checkConnectivity();
    if (!connected) {
      throw Exception('Sin conexión a internet o DNS inaccesible.');
    }

    // Probar cada dominio personalizado para toggle favorito
    for (int i = 0; i < customDomains.length; i++) {
      final customDomain = customDomains[i];
      
      try {
        final uri = Uri.parse('$customDomain/toggle-favorito');
        final body = json.encode({
          'user_id': userId,
          'codigo_id': codigoId,
        });

        final response = await http
            .post(uri, headers: _headers, body: body)
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return data['success'] == true;
        }
      } catch (e) {
        continue;
      }
    }

    throw Exception('No se pudo actualizar favorito desde ningún dominio personalizado.');
  }

  // ===== POPULARIDAD CON DOMINIO PERSONALIZADO =====
  
  static Future<bool> incrementarPopularidad(String codigoId) async {
    final connected = await _checkConnectivity();
    if (!connected) {
      throw Exception('Sin conexión a internet o DNS inaccesible.');
    }

    // Probar cada dominio personalizado para popularidad
    for (int i = 0; i < customDomains.length; i++) {
      final customDomain = customDomains[i];
      
      try {
        final uri = Uri.parse('$customDomain/incrementar-popularidad');
        final body = json.encode({'codigo_id': codigoId});

        final response = await http
            .post(uri, headers: _headers, body: body)
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return data['success'] == true;
        }
      } catch (e) {
        continue;
      }
    }

    throw Exception('No se pudo incrementar popularidad desde ningún dominio personalizado.');
  }
}
