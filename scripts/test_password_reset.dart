#!/usr/bin/env dart
// Script para probar el flujo completo de cambio de contraseña

import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  if (args.length < 3) {
    print('Uso: dart run scripts/test_password_reset.dart <email> <otp> <nueva_contraseña>');
    exit(1);
  }

  final email = args[0];
  final otp = args[1];
  final newPassword = args[2];

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
    print('❌ Error: Faltan SUPABASE_URL o SUPABASE_ANON_KEY en .env');
    exit(1);
  }

  print('');
  print('🔐 Probando cambio de contraseña...');
  print('   Email: $email');
  print('   OTP: ${otp.substring(0, 3)}...');
  print('   Nueva contraseña: ${newPassword.length} caracteres');
  print('');

  // Llamar a verify-otp
  try {
    final functionUrl = '$supabaseUrl/functions/v1/verify-otp';
    print('📡 Invocando verify-otp...');
    print('   URL: $functionUrl');

    final request = await HttpClient().postUrl(Uri.parse(functionUrl));
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
    request.headers.set('apikey', supabaseAnonKey);

    final body = jsonEncode({
      'email': email,
      'otp_code': otp,
      'new_password': newPassword,
    });

    request.write(body);
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    print('');
    print('📊 Respuesta:');
    print('   Status: ${response.statusCode}');
    print('   Body: $responseBody');

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      if (data['ok'] == true) {
        print('');
        print('✅ Contraseña actualizada exitosamente');
        print('');
        print('💡 Ahora intenta hacer login con:');
        print('   Email: $email');
        print('   Contraseña: $newPassword');
      } else {
        print('');
        print('❌ Error: ${data['error'] ?? 'Error desconocido'}');
      }
    } else {
      print('');
      print('❌ Error HTTP ${response.statusCode}');
      try {
        final error = jsonDecode(responseBody);
        print('   Error: ${error['error'] ?? responseBody}');
      } catch (_) {
        print('   Error: $responseBody');
      }
    }
  } catch (e) {
    print('');
    print('❌ Error: $e');
  }
}


