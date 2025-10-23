import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Configuración de Supabase para producción
  static const String url = 'https://whtiazgcxdnemrrgjjqf.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1MjM2MzgsImV4cCI6MjA3NjA5OTYzOH0.1CFkusMrMKcvSU_-5RyGYPoKDM_yizuQMVGo7W3mXHU';
  static const String serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDUyMzYzOCwiZXhwIjoyMDc2MDk5NjM4fQ.LIVQ2FpXRpJD7ie4GVkrwU7lLPRm4S5NekNG2Cqme8o';
  
  // Configuración para desarrollo local (si usas Supabase local)
  static const String localUrl = 'http://localhost:54321';
  static const String localAnonKey = 'your-local-anon-key';
  
  // Determinar si usar configuración local o de producción
  static const bool useLocal = false; // Cambiar a true para desarrollo local
  
  // Clientes de Supabase
  static SupabaseClient get client => Supabase.instance.client;
  static SupabaseClient get serviceClient => SupabaseClient(
    url,
    serviceRoleKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Método de inicialización
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: useLocal ? localUrl : url,
      anonKey: useLocal ? localAnonKey : anonKey,
    );
  }
}
