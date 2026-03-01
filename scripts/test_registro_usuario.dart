import 'dart:convert';
import 'dart:io';

/// Script para probar el registro de usuario
/// Uso: dart run scripts/test_registro_usuario.dart
Future<void> main(List<String> args) async {
  // Generar email único con timestamp
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final email = args.isNotEmpty ? args[0] : 'test$timestamp@httpsu.com';
  final name = args.length > 1 ? args[1] : 'Usuario de Prueba';
  final password = args.length > 2 ? args[2] : 'Test123456!';
  
  print('🧪 Probando registro de usuario');
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
  
  print('📋 Datos de registro:');
  print('   Email: $email');
  print('   Nombre: $name');
  print('   Password: ${password.substring(0, 3)}***');
  print('');
  
  final client = HttpClient();
  try {
    // Paso 1: Registrar usuario en Supabase Auth
    print('📝 Paso 1: Registrando usuario en Supabase Auth...');
    final signUpUrl = Uri.parse('$supabaseUrl/auth/v1/signup');
    
    final signUpRequest = await client.postUrl(signUpUrl);
    signUpRequest.headers.set('apikey', supabaseAnonKey);
    signUpRequest.headers.set('Content-Type', 'application/json');
    signUpRequest.write(jsonEncode({
      'email': email,
      'password': password,
      'data': {'name': name}
    }));
    
    final signUpResponse = await signUpRequest.close();
    final signUpBody = await signUpResponse.transform(utf8.decoder).join();
    
    print('📊 Respuesta SignUp HTTP: ${signUpResponse.statusCode}');
    
    dynamic signUpData;
    try {
      signUpData = jsonDecode(signUpBody);
      print('📦 Respuesta SignUp:');
      print(jsonEncode(signUpData));
    } catch (e) {
      print('📦 Respuesta SignUp (texto):');
      print(signUpBody);
      signUpData = {'raw': signUpBody};
    }
    
    print('');
    
    if (signUpResponse.statusCode != 200) {
      print('❌ Error en registro de usuario');
      if (signUpData is Map && signUpData['error'] != null) {
        print('   Error: ${signUpData['error']}');
      }
      exit(1);
    }
    
    String? userId;
    if (signUpData is Map && signUpData['user'] != null) {
      userId = signUpData['user']['id'];
      print('✅ Usuario registrado correctamente');
      print('   User ID: $userId');
    } else {
      print('⚠️  No se pudo obtener el User ID de la respuesta');
    }
    
    print('');
    
    // Paso 2: Invocar función send-email
    if (userId != null) {
      print('📧 Paso 2: Invocando función send-email...');
      
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
      
      print('📊 Respuesta send-email HTTP: ${functionResponse.statusCode}');
      
      dynamic functionData;
      try {
        functionData = jsonDecode(functionBody);
        print('📦 Respuesta send-email:');
        print(jsonEncode(functionData));
      } catch (e) {
        print('📦 Respuesta send-email (texto):');
        print(functionBody);
        functionData = {'raw': functionBody};
      }
      
      print('');
      
      if (functionResponse.statusCode == 200) {
        if (functionData is Map && functionData['ok'] == true) {
          print('✅ Email de bienvenida enviado correctamente');
        } else {
          print('⚠️  Respuesta inesperada de send-email');
        }
      } else {
        print('❌ Error enviando email de bienvenida');
        if (functionData is Map && functionData['error'] != null) {
          print('   Error: ${functionData['error']}');
        }
      }
    }
    
    print('');
    print('📋 Para verificar:');
    print('   1. Revisa tu bandeja de entrada: $email');
    print('   2. Revisa los logs en Supabase:');
    print('      https://supabase.com/dashboard/project/whtiazgcxdnemrrgjjqf/functions/send-email/logs');
    print('   3. Revisa SendGrid Activity:');
    print('      https://app.sendgrid.com/activity');
    
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

