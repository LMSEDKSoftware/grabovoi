import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class LegalLinksService {
  static final SupabaseClient _client = SupabaseConfig.client;

  /// Obtener links legales desde la base de datos
  /// Si no existen en la DB, retorna valores por defecto
  static Future<Map<String, String>> getLegalLinks() async {
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
          return {
            'privacy_policy': links['legal_privacy_policy_url'] ?? _defaultLinks['privacy_policy']!,
            'terms': links['legal_terms_url'] ?? _defaultLinks['terms']!,
            'cookies': links['legal_cookies_url'] ?? _defaultLinks['cookies']!,
            'data_usage': links['legal_data_usage_url'] ?? _defaultLinks['data_usage']!,
            'credits': links['legal_credits_url'] ?? _defaultLinks['credits']!,
          };
        }
      }
    } catch (e) {
      // Si la tabla no existe o hay error, usar valores por defecto
      print('⚠️ Error obteniendo links legales desde DB: $e');
      print('📝 Usando valores por defecto. Para configurar desde DB, crea la tabla app_config con columnas: key (text), value (text)');
    }

    // Retornar valores por defecto si no hay configuración en la DB
    return _defaultLinks;
  }

  /// Links por defecto (se pueden configurar desde la DB después)
  static const Map<String, String> _defaultLinks = {
    'privacy_policy': 'https://example.com/privacy-policy',
    'terms': 'https://example.com/terms',
    'cookies': 'https://example.com/cookies',
    'data_usage': 'https://example.com/data-usage',
    'credits': 'https://example.com/credits',
  };
}

