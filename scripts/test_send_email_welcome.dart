import 'dart:convert';
import 'dart:io';

/// Script para probar el envío de email de bienvenida
/// Uso: dart run scripts/test_send_email_welcome.dart [email] [userId]
Future<void> main(List<String> args) async {
  final email = args.isNotEmpty ? args[0] : 'pagam18659@httpsu.com';
  final userId = args.length > 1 ? args[1] : '6170400e-a0e5-4414-912b-a4cdb084c295';
  final name = 'Usuario de Prueba';
  
  print('🧪 Probando envío de email de bienvenida');
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
          var value = parts.sublist(1).join('=').trim();
          // Remover comillas si existen
          if (value.startsWith('"') && value.endsWith('"')) {
            value = value.substring(1, value.length - 1);
          } else if (value.startsWith("'") && value.endsWith("'")) {
            value = value.substring(1, value.length - 1);
          }
          envVars[key] = value;
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
  
  print('📋 Datos del email:');
  print('   Email: $email');
  print('   User ID: $userId');
  print('   Nombre: $name');
  print('');
  
  final client = HttpClient();
  try {
    print('📧 Invocando función send-email...');
    
    final actionUrl = supabaseUrl.contains('localhost') || supabaseUrl.contains('127.0.0.1')
        ? 'http://localhost/auth/callback'
        : 'https://manigrab.app/auth/callback';
    
    final functionUrl = Uri.parse('$supabaseUrl/functions/v1/send-email');
    
    final functionRequest = await client.postUrl(functionUrl);
    functionRequest.headers.set('Authorization', 'Bearer $supabaseAnonKey');
    functionRequest.headers.set('Content-Type', 'application/json');
    functionRequest.write(jsonEncode({
      'to': email,
      'template': 'welcome_or_confirm',
      'userId': userId,
      'name': name,
      'actionUrl': actionUrl,
    }));
    
    final functionResponse = await functionRequest.close();
    final functionBody = await functionResponse.transform(utf8.decoder).join();
    
    print('📊 Respuesta HTTP: ${functionResponse.statusCode}');
    print('📦 Headers:');
    functionResponse.headers.forEach((key, values) {
      print('   $key: ${values.join(', ')}');
    });
    print('');
    print('📦 Cuerpo de respuesta:');
    
    dynamic functionData;
    try {
      functionData = jsonDecode(functionBody);
      print(jsonEncode(functionData));
    } catch (e) {
      print(functionBody);
      functionData = {'raw': functionBody};
    }
    
    print('');
    
    if (functionResponse.statusCode == 200) {
      if (functionData is Map && functionData['ok'] == true) {
        print('✅ Email de bienvenida enviado correctamente');
      } else {
        print('⚠️  Respuesta inesperada');
      }
    } else {
      print('❌ Error enviando email de bienvenida');
      if (functionData is Map && functionData['error'] != null) {
        print('   Error: ${functionData['error']}');
      }
    }
    
    print('');
    print('📋 Para verificar:');
    print('   1. Revisa tu bandeja de entrada: $email');
    print('   2. Revisa los logs en Supabase:');
    print('      https://supabase.com/dashboard/project/whtiazgcxdnemrrgjjqf/functions/send-email/logs');
    print('   3. Deberías ver: "📧 Enviando email a través del servidor propio (IP estática)..."');
    print('   4. Revisa SendGrid Activity:');
    print('      https://app.sendgrid.com/activity');
    print('      Debe mostrar IP: 153.92.215.178');
    
  } catch (e, stackTrace) {
    print('❌ Error en la prueba:');
    print('   $e');
    print('');
    print('📚 Stack trace:');
    print(stackTrace);
    exit(1);
  } finally {
    client.close();
  }
}


