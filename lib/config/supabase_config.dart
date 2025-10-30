import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

class SupabaseConfig {
  // Puedes alternar a local si tienes Supabase local
  static const bool useLocal = false;
  static const String localUrl = 'http://localhost:54321';
  static const String localAnonKey = 'your-local-anon-key';

  static String get url => useLocal ? localUrl : (Env.supabaseUrl.isNotEmpty ? Env.supabaseUrl : localUrl);
  static String get anonKey => useLocal ? localAnonKey : (Env.supabaseAnonKey.isNotEmpty ? Env.supabaseAnonKey : localAnonKey);
  static String get serviceRoleKey => Env.supabaseServiceRoleKey;

  // Clientes de Supabase
  static SupabaseClient get client => Supabase.instance.client;
  static SupabaseClient get serviceClient => SupabaseClient(
        url,
        serviceRoleKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
}
