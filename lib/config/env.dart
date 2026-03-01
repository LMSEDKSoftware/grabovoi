import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String _read(String key, String fromDefine) {
    // En web, por seguridad no cargamos .env como asset; usar --dart-define
    final fromFile = dotenv.isInitialized ? dotenv.maybeGet(key) : null;
    return (fromFile ?? fromDefine).trim();
  }

  static String get openAiKey => _read('OPENAI_API_KEY', const String.fromEnvironment('OPENAI_API_KEY', defaultValue: ''));
  static String get supabaseUrl => _read('SUPABASE_URL', const String.fromEnvironment('SUPABASE_URL', defaultValue: ''));
  static String get supabaseAnonKey => _read('SUPABASE_ANON_KEY', const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''));
  static String get supabaseServiceRoleKey => _read('SB_SERVICE_ROLE_KEY', const String.fromEnvironment('SB_SERVICE_ROLE_KEY', defaultValue: ''));
}


