import 'dart:io';
import 'dart:convert';

/// Script para probar la función auth-reset-password
/// Uso: dart scripts/test_auth_reset_password.dart <email>
void main(List<String> args) async {
  if (args.isEmpty) {
    print('❌ Uso: dart scripts/test_auth_reset_password.dart <email>');
    exit(1);
  }

  final email = args[0];
  print('📧 Probando auth-reset-password para: $email');
  print('');

  // Cargar variables de entorno desde .env
  Map<String, String> envVars = {};
  try {
    final envFile = File('.env');
    if (await envFile.exists()) {
      final lines = await envFile.readAsLines();
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final parts = trimmed.split('=');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts.sublist(1).join('=').trim();
          final cleanValue = value.replaceAll(RegExp(r'''^["']|["']$'''), '');
          envVars[key] = cleanValue;
        }
      }
      print('✅ Variables de entorno cargadas desde .env');
    } else {
      print('⚠️  No se encontró archivo .env');
    }
  } catch (e) {
    print('⚠️  Error cargando .env: $e');
  }

  final supabaseUrl = envVars['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = envVars['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    print('❌ Faltan SUPABASE_URL o SUPABASE_ANON_KEY en .env');
    exit(1);
  }

  print('🔧 Configuración:');
  print('   SUPABASE_URL: ${supabaseUrl.substring(0, 30)}...');
  print('   SUPABASE_ANON_KEY: ${supabaseAnonKey.substring(0, 20)}...');
  print('');

  // Construir URL de la Edge Function
  final functionUrl = '$supabaseUrl/functions/v1/auth-reset-password';
  print('📡 Invocando: $functionUrl');
  print('');

  try {
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse(functionUrl));
    
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
    request.headers.set('apikey', supabaseAnonKey);
    
    final body = jsonEncode({'email': email});
    request.write(body);
    
    print('📤 Request:');
    print('   Method: POST');
    print('   Headers:');
    print('     Content-Type: application/json');
    print('     Authorization: Bearer ${supabaseAnonKey.substring(0, 20)}...');
    print('     apikey: ${supabaseAnonKey.substring(0, 20)}...');
    print('   Body: $body');
    print('');

    final response = await request.close();
    final statusCode = response.statusCode;
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('📥 Response:');
    print('   Status: $statusCode');
    print('   Body: $responseBody');
    print('');

    if (statusCode == 200) {
      try {
        final data = jsonDecode(responseBody);
        if (data is Map && data['ok'] == true) {
          print('✅ Éxito: Email de recuperación enviado');
        } else {
          print('⚠️  Respuesta inesperada: $data');
        }
      } catch (e) {
        print('⚠️  Error parseando respuesta: $e');
      }
    } else {
      print('❌ Error HTTP $statusCode');
      try {
        final errorData = jsonDecode(responseBody);
        print('   Error: $errorData');
      } catch (e) {
        print('   Respuesta: $responseBody');
      }
    }
  } catch (e, stackTrace) {
    print('❌ Error en la solicitud:');
    print('   $e');
    print('');
    print('📚 Stack trace:');
    print('   $stackTrace');
    exit(1);
  }
}


