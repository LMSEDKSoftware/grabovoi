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

      final rows = (response as List).cast<Map<String, dynamic>>();
      if (rows.isNotEmpty) {
        // Construir mapa desde la lista de resultados
        final links = <String, String>{};
        for (final item in rows) {
          final key = item['key']?.toString();
          if (key == null || key.isEmpty) continue;
          final value = item['value']?.toString() ?? '';
          links[key] = value;
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
      // Si la tabla no existe o hay error, marcar como intentado y usar valores por defecto
      // No imprimimos error rojo alarmante porque es comportamiento esperado si no se ha configurado la tabla.
      String? code;
      String? message;
      if (e is PostgrestException) {
        code = e.code;
        message = e.message;
        // ignore: avoid_print
        print('ℹ️ Info: Error Supabase app_config: ${e.message} (Code: ${e.code}, Details: ${e.details})');
      } else {
        // ignore: avoid_print
        print('ℹ️ Info: Error general app_config: $e');
      }

      // Solo "deshabilitar" definitivamente el intento en esta sesión si el problema
      // parece estructural (tabla/columna inexistente). Para errores transitorios o
      // de RLS mal configurado, permitir reintentos sin reiniciar la app.
      final pareceInexistente =
          code == '42P01' || (message?.toLowerCase().contains('does not exist') ?? false);
      if (pareceInexistente) {
        _hasTriedDB = true;
        // ignore: avoid_print
        print('ℹ️ Info: Usando links legales por defecto (app_config inexistente).');
      }
    }

    // Retornar valores por defecto. Solo cachear si ya determinamos que no existe.
    if (_hasTriedDB) {
      _cachedLinks = _defaultLinks;
    }
    return _defaultLinks;
  }

  /// Links por defecto (se pueden configurar desde la DB después)
  static const Map<String, String> defaultLinks = {
    'privacy_policy': 'https://manigrab.app/politica-privacidad.html',
    'terms': 'https://manigrab.app/terminos-condiciones.html',
    'cookies': 'https://manigrab.app/politica-cookies.html',
    'data_usage': 'https://example.com/data-usage',
    'credits': 'https://example.com/credits',
  };
  
  static const Map<String, String> _defaultLinks = defaultLinks;
}
