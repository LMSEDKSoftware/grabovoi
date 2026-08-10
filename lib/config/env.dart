import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String _read(String key, String fromDefine) {
    // En web, por seguridad no cargamos .env como asset; usar --dart-define
    final fromFile = dotenv.isInitialized ? dotenv.maybeGet(key) : null;
    return (fromFile ?? fromDefine).trim();
  }

  // OPENAI_API_KEY NUNCA debe leerse aquí: no la necesita el cliente (la
  // búsqueda con IA va por la edge function deep-search-codes, que usa su
  // propia copia server-side de la clave vía Deno.env).
  static String get supabaseUrl => _read('SUPABASE_URL', const String.fromEnvironment('SUPABASE_URL', defaultValue: ''));
  static String get supabaseAnonKey => _read('SUPABASE_ANON_KEY', const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''));
  // SB_SERVICE_ROLE_KEY NUNCA debe leerse aquí: este código corre en el
  // dispositivo/navegador del usuario. Esa key vive solo en Edge Functions
  // (Deno.env) y en scripts server-side (server/, scripts/).
}


