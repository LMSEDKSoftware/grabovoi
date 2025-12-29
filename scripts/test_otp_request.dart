import 'dart:convert';
import 'dart:io';

/// Script para probar la solicitud de OTP
/// Uso: dart run scripts/test_otp_request.dart <email>
Future<void> main(List<String> args) async {
  final email = args.isNotEmpty ? args[0] : '2005.ivan@gmail.com';
  
  print('🧪 Probando solicitud de OTP para: $email');
  print('');
  
  // Cargar variables de entorno desde .env manualmente
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
          // Remover comillas si existen
          var cleanValue = value;
          if (cleanValue.startsWith('"') && cleanValue.endsWith('"')) {
            cleanValue = cleanValue.substring(1, cleanValue.length - 1);
          } else if (cleanValue.startsWith("'") && cleanValue.endsWith("'")) {
            cleanValue = cleanValue.substring(1, cleanValue.length - 1);
          }
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
  
  final supabaseUrl = envVars['SUPABASE_URL'] ?? 
                      Platform.environment['SUPABASE_URL'] ?? 
                      'http://127.0.0.1:54321';
  final supabaseAnonKey = envVars['SUPABASE_ANON_KEY'] ?? 
                          Platform.environment['SUPABASE_ANON_KEY'] ?? '';
  
  if (supabaseAnonKey.isEmpty) {
    print('❌ Error: SUPABASE_ANON_KEY no encontrada');
    exit(1);
  }
  
  print('🔍 Configuración:');
  print('   SUPABASE_URL: ${supabaseUrl.substring(0, supabaseUrl.length > 40 ? 40 : supabaseUrl.length)}...');
  print('   SUPABASE_ANON_KEY: ${supabaseAnonKey.substring(0, 30)}...');
  print('');
  
  print('📧 Invocando función send-otp...');
  print('');
  
  final client = HttpClient();
  try {
    final url = Uri.parse('$supabaseUrl/functions/v1/send-otp');
    
    final request = await client.postUrl(url);
    request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
    request.headers.set('Content-Type', 'application/json');
    request.write(jsonEncode({'email': email}));
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('📊 Respuesta HTTP: ${response.statusCode}');
    print('📦 Headers:');
    response.headers.forEach((key, values) {
      print('   $key: ${values.join(', ')}');
    });
    print('');
    print('📦 Cuerpo de respuesta:');
    
    dynamic data;
    try {
      data = jsonDecode(responseBody);
      print(jsonEncode(data));
    } catch (e) {
      print(responseBody);
      data = {'raw': responseBody};
    }
    
    print('');
    
    if (response.statusCode == 200) {
      if (data is Map && data['ok'] == true) {
        print('✅ Solicitud exitosa');
        if (data['dev_otp'] != null) {
          print('🔧 OTP generado (dev): ${data['dev_otp']}');
        }
      } else if (data is Map && data['ok'] == false) {
        print('❌ Error en la respuesta:');
        print('   ${data['error'] ?? 'Error desconocido'}');
        if (data['dev_otp'] != null) {
          print('🔧 OTP generado (dev): ${data['dev_otp']}');
          print('   (El OTP se generó pero hubo un error enviando el email)');
        }
      }
    } else {
      print('❌ Error HTTP ${response.statusCode}');
      if (data is Map && data['error'] != null) {
        print('   Error: ${data['error']}');
      }
    }
    
    print('');
    print('📋 Para ver los logs de la función Edge:');
    print('   - Supabase Dashboard > Edge Functions > send-otp > Logs');
    print('   - O ejecuta: supabase functions logs send-otp');
    
  } catch (e, stackTrace) {
    print('❌ Error en la solicitud:');
    print('   $e');
    print('');
    print('📚 Stack trace:');
    print(stackTrace);
    exit(1);
  } finally {
    client.close();
  }
}

