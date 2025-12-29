import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class LegalLinksService {
  static final SupabaseClient _client = SupabaseConfig.client;

  // Caché estático para evitar múltiples consultas cuando falla
  static Map<String, String>? _cachedLinks;
  static bool _hasTriedDB = false;
  
  /// Obtener links legales desde la base de datos
  /// Si no existen en la DB, retorna valores por defecto
  /// Usa caché para evitar múltiples consultas cuando la tabla no existe
  static Future<Map<String, String>> getLegalLinks() async {
    // Si ya tenemos caché, retornar inmediatamente
    if (_cachedLinks != null) {
      return _cachedLinks!;
    }
    
    // Si ya intentamos y falló, usar valores por defecto directamente
    if (_hasTriedDB) {
      return _defaultLinks;
    }
    
    try {
      // Intentar obtener desde la tabla app_config (si existe)
      // La tabla debe tener estructura: key (text), value (text)
      final response = await _client
          .from('app_config')
          .select('key, value')
          .inFilter('key', [
            'legal_privacy_policy_url',
            'legal_terms_url',
            'legal_cookies_url',
            'legal_data_usage_url',
            'legal_credits_url',
          ]);

      if (response != null && response is List && response.isNotEmpty) {
        // Construir mapa desde la lista de resultados
        final links = <String, String>{};
        for (var item in response) {
          if (item is Map && item.containsKey('key') && item.containsKey('value')) {
            final key = item['key'] as String;
            final value = item['value'] as String? ?? '';
            links[key] = value;
          }
        }

        // Si se obtuvieron links, retornarlos mapeados
        if (links.isNotEmpty) {
          _cachedLinks = {
            'privacy_policy': links['legal_privacy_policy_url'] ?? _defaultLinks['privacy_policy']!,
            'terms': links['legal_terms_url'] ?? _defaultLinks['terms']!,
            'cookies': links['legal_cookies_url'] ?? _defaultLinks['cookies']!,
            'data_usage': links['legal_data_usage_url'] ?? _defaultLinks['data_usage']!,
            'credits': links['legal_credits_url'] ?? _defaultLinks['credits']!,
          };
          return _cachedLinks!;
        }
      }
    } catch (e) {
      // Si la tabla no existe o hay error, marcar como intentado y usar valores por defecto
      print('⚠️ Error obteniendo links legales desde DB: $e');
      print('📝 Usando valores por defecto. Para configurar desde DB, crea la tabla app_config con columnas: key (text), value (text)');
      _hasTriedDB = true;
    }

    // Retornar valores por defecto y cachearlos
    _cachedLinks = _defaultLinks;
    return _defaultLinks;
  }

  /// Links por defecto (se pueden configurar desde la DB después)
  static const Map<String, String> defaultLinks = {
    'privacy_policy': 'https://manigrab.app/politica-privacidad.html',
    'terms': 'https://manigrab.app/terminos.html',
    'cookies': 'https://manigrab.app/politica-cookies.html',
    'data_usage': 'https://example.com/data-usage',
    'credits': 'https://example.com/credits',
  };
  
  static const Map<String, String> _defaultLinks = defaultLinks;
}

