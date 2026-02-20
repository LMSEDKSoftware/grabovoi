import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/supabase_models.dart';

class ProxyApiService {
  // URLs de proxy alternativas para bypassear problemas SSL
  static const List<String> proxyUrls = [
    'https://api.manifestacion.app/codigos', // Cloudflare proxy (recomendado)
    'https://manifestacion-proxy.vercel.app/api/codigos', // Vercel proxy
    'https://grabovoi-proxy.netlify.app/api/codigos', // Netlify proxy
  ];

  static const String fallbackUrl = 'https://whtiazgcxdnemrrgjjqf.supabase.co/functions/v1/get-codigos';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${Env.supabaseAnonKey}',
    'User-Agent': 'ManifestacionApp/1.0',
    'Accept': 'application/json',
    'Cache-Control': 'no-cache',
  };

  /// Verifica conectividad antes de hacer peticiones
  static Future<bool> _checkConnectivity() async {
    try {
      debugPrint('🔍 [PROXY CONNECTIVITY] Verificando conectividad...');
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        debugPrint('✅ [PROXY CONNECTIVITY] Conectividad OK');
        return true;
      }
    } catch (e) {
      debugPrint('❌ [PROXY CONNECTIVITY] Error: $e');
    }
    debugPrint('❌ [PROXY CONNECTIVITY] Sin conectividad');
    return false;
  }

  // ===== CÓDIGOS CON PROXY =====
  
  static Future<List<CodigoGrabovoi>> getCodigos({
    String? categoria,
    String? search,
  }) async {
    debugPrint('🔍 [PROXY API] Iniciando getCodigos con proxy...');
    debugPrint('   📍 Parámetros: categoria=$categoria, search=$search');
    
    // Verificar conectividad primero
    final connected = await _checkConnectivity();
    if (!connected) {
      throw Exception('Sin conexión a internet o DNS inaccesible.');
    }

    // Probar cada proxy en orden
    for (int i = 0; i < proxyUrls.length; i++) {
      final proxyUrl = proxyUrls[i];
      debugPrint('🌐 [PROXY $i] Probando proxy: $proxyUrl');
      
      try {
        final uri = Uri.parse(proxyUrl).replace(queryParameters: {
          if (categoria != null && categoria != 'Todos') 'categoria': categoria,
          if (search != null && search.isNotEmpty) 'search': search,
        });

        debugPrint('📡 [PROXY $i] URI construida: $uri');
        
        final response = await http
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 15));

        debugPrint('📊 [PROXY $i] Status: ${response.statusCode}');
        debugPrint('📊 [PROXY $i] Body length: ${response.body.length}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          debugPrint('🔍 [PROXY $i] JSON decodificado: ${data.runtimeType}');
          debugPrint('🔍 [PROXY $i] Keys: ${data.keys.toList()}');
          debugPrint('🔍 [PROXY $i] Success: ${data['success']}');
          debugPrint('🔍 [PROXY $i] Count: ${data['count']}');
          
          if (data['success'] == true) {
            final rawData = data['data'] as List;
            debugPrint('🔍 [PROXY $i] Total elementos: ${rawData.length}');
            
            final codigos = rawData
                .map((json) {
                  try {
                    final codigo = CodigoGrabovoi.fromJson(json);
                    return codigo;
                  } catch (e) {
                    debugPrint('❌ [PROXY $i] Error parseando elemento: $json');
                    debugPrint('❌ [PROXY $i] Error: $e');
                    rethrow;
                  }
                })
                .toList();
            
            debugPrint('✅ [PROXY $i] ${codigos.length} códigos parseados exitosamente');
            debugPrint('🎉 [PROXY $i] ¡Proxy funcionando correctamente!');
            return codigos;
          } else {
            debugPrint('❌ [PROXY $i] Error en respuesta: ${data['error']}');
            continue; // Probar siguiente proxy
          }
        } else {
          debugPrint('❌ [PROXY $i] HTTP Error: ${response.statusCode}');
          continue; // Probar siguiente proxy
        }
      } catch (e) {
        debugPrint('❌ [PROXY $i] Error: $e');
        continue; // Probar siguiente proxy
      }
    }

    // Si todos los proxies fallan, probar URL directa como último recurso
    debugPrint('🔄 [FALLBACK] Todos los proxies fallaron, probando URL directa...');
    try {
      final uri = Uri.parse(fallbackUrl).replace(queryParameters: {
        if (categoria != null && categoria != 'Todos') 'categoria': categoria,
        if (search != null && search.isNotEmpty) 'search': search,
      });

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final rawData = data['data'] as List;
          final codigos = rawData
              .map((json) => CodigoGrabovoi.fromJson(json))
              .toList();
          
          debugPrint('✅ [FALLBACK] ${codigos.length} códigos obtenidos via URL directa');
          return codigos;
        }
      }
    } catch (e) {
      debugPrint('❌ [FALLBACK] Error en URL directa: $e');
    }

    throw Exception('Todos los proxies y la URL directa fallaron. Verifica tu conexión.');
  }

  // ===== CATEGORÍAS CON PROXY =====
  
  static Future<List<String>> getCategorias() async {
    debugPrint('🔍 [PROXY API] Obteniendo categorías con proxy...');
    
    final connected = await _checkConnectivity();
    if (!connected) {
      throw Exception('Sin conexión a internet o DNS inaccesible.');
    }

    // Probar cada proxy para categorías
    for (int i = 0; i < proxyUrls.length; i++) {
      final proxyUrl = proxyUrls[i];
      final categoriasUrl = proxyUrl.replaceAll('/codigos', '/categorias');
      
      try {
        debugPrint('🌐 [PROXY $i] Probando categorías: $categoriasUrl');
        
        final uri = Uri.parse(categoriasUrl);
        final response = await http
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            final categorias = List<String>.from(data['data']);
            debugPrint('✅ [PROXY $i] ${categorias.length} categorías obtenidas');
            return categorias;
          }
        }
      } catch (e) {
        debugPrint('❌ [PROXY $i] Error categorías: $e');
        continue;
      }
    }

    throw Exception('No se pudo obtener categorías desde ningún proxy.');
  }

  // ===== FAVORITOS CON PROXY =====
  
  static Future<List<UsuarioFavorito>> getFavoritos(String userId) async {
    final connected = await _checkConnectivity();
    if (!connected) {
      throw Exception('Sin conexión a internet o DNS inaccesible.');
    }

    // Probar cada proxy para favoritos
    for (int i = 0; i < proxyUrls.length; i++) {
      final proxyUrl = proxyUrls[i];
      final favoritosUrl = proxyUrl.replaceAll('/codigos', '/favoritos');
      
      try {
        final uri = Uri.parse(favoritosUrl).replace(
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

    throw Exception('No se pudo obtener favoritos desde ningún proxy.');
  }

  static Future<bool> toggleFavorito(String userId, String codigoId) async {
    final connected = await _checkConnectivity();
    if (!connected) {
      throw Exception('Sin conexión a internet o DNS inaccesible.');
    }

    // Probar cada proxy para toggle favorito
    for (int i = 0; i < proxyUrls.length; i++) {
      final proxyUrl = proxyUrls[i];
      final toggleUrl = proxyUrl.replaceAll('/codigos', '/toggle-favorito');
      
      try {
        final uri = Uri.parse(toggleUrl);
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

    throw Exception('No se pudo actualizar favorito desde ningún proxy.');
  }

  // ===== POPULARIDAD CON PROXY =====
  
  static Future<bool> incrementarPopularidad(String codigoId) async {
    final connected = await _checkConnectivity();
    if (!connected) {
      throw Exception('Sin conexión a internet o DNS inaccesible.');
    }

    // Probar cada proxy para popularidad
    for (int i = 0; i < proxyUrls.length; i++) {
      final proxyUrl = proxyUrls[i];
      final popularidadUrl = proxyUrl.replaceAll('/codigos', '/incrementar-popularidad');
      
      try {
        final uri = Uri.parse(popularidadUrl);
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

    throw Exception('No se pudo incrementar popularidad desde ningún proxy.');
  }
}
