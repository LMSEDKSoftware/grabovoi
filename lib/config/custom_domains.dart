class CustomDomains {
  // Usar directamente la URL de Supabase que sabemos que funciona
  static const List<String> primaryDomains = [
    'https://whtiazgcxdnemrrgjjqf.supabase.co/functions/v1',
  ];
  
  static const List<String> fallbackDomains = [
    'https://whtiazgcxdnemrrgjjqf.supabase.co/functions/v1',
  ];
  
  static const List<String> emergencyDomains = [
    'https://whtiazgcxdnemrrgjjqf.supabase.co/functions/v1',
  ];
  
  // Configuración de DNS alternativos
  static const List<String> dnsServers = [
    '8.8.8.8',      // Google DNS
    '8.8.4.4',      // Google DNS secundario
    '1.1.1.1',      // Cloudflare DNS
    '1.0.0.1',      // Cloudflare DNS secundario
    '208.67.222.222', // OpenDNS
    '208.67.220.220', // OpenDNS secundario
  ];
  
  // Configuración de timeouts
  static const Duration connectionTimeout = Duration(seconds: 20);
  static const Duration readTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Configuración de headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'User-Agent': 'ManifestacionApp/1.0',
    'Accept': 'application/json',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive',
  };
  
  // Configuración de headers con autenticación
  static Map<String, String> getAuthHeaders(String apiKey) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $apiKey',
  };
}
