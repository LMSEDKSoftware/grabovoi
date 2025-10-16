import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class SecureHttp {
  /// Cliente HTTP que bypassea la verificación SSL para diagnóstico
  /// ⚠️ SOLO PARA DIAGNÓSTICO - NO USAR EN PRODUCCIÓN
  static http.Client createUnsafeClient() {
    final ioClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        print('🔓 [SSL BYPASS] Certificado SSL bypasseado para: $host:$port');
        print('🔓 [SSL BYPASS] Certificado: ${cert.subject}');
        print('🔓 [SSL BYPASS] Emisor: ${cert.issuer}');
        return true; // Aceptar cualquier certificado
      };
    return IOClient(ioClient);
  }

  /// Cliente HTTP seguro con configuración TLS moderna
  static http.Client createSecureClient() {
    final ioClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..idleTimeout = const Duration(seconds: 30);
    
    return IOClient(ioClient);
  }
}
