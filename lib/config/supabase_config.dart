import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

class SupabaseConfig {
  // Puedes alternar a local si tienes Supabase local
  static const bool useLocal = false;
  static const String localUrl = 'http://localhost:54321';
  static const String localAnonKey = 'your-local-anon-key';

  /// En web no usamos fallback a localhost para evitar cientos de peticiones fallidas.
  /// Hay que lanzar con ./scripts/launch_chrome.sh (inyecta --dart-define desde .env).
  static String get url {
    if (useLocal) return localUrl;
    if (Env.supabaseUrl.isNotEmpty) return Env.supabaseUrl;
    if (kIsWeb) return ''; // Evitar conectar a localhost:54321 sin config
    return localUrl;
  }
  static String get anonKey {
    if (useLocal) return localAnonKey;
    if (Env.supabaseAnonKey.isNotEmpty) return Env.supabaseAnonKey;
    if (kIsWeb) return '';
    return localAnonKey;
  }
  // NOTA: nunca exponer el service_role key en el cliente (bypassa RLS por
  // completo). Toda operación que antes usaba un "serviceClient" aquí ahora
  // pasa por Edge Functions (p.ej. supabase/functions/admin-users) o por
  // políticas RLS correctamente acotadas. Ver database/migration_client_write_policies.sql
  // y database/migration_admin_rls_sugerencias_codigos.sql.

  // Cliente de Supabase
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    if (kIsWeb && (url.isEmpty || anonKey.isEmpty)) {
      throw FlutterError(
        'Supabase no configurado para web. '
        'Lanza la app con: ./scripts/launch_chrome.sh\n'
        'Ese script carga el .env y pasa SUPABASE_URL y SUPABASE_ANON_KEY por --dart-define.'
      );
    }
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );
  }
}
