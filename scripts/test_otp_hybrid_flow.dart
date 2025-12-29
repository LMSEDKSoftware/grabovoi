import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Script de testing completo para el flujo OTP híbrido
/// Prueba: solicitar OTP -> verificar OTP -> obtener recovery_link -> simular cambio de contraseña

const String SUPABASE_URL = 'https://whtiazgcxdnemrrgjjqf.supabase.co';
const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1MjM2MzgsImV4cCI6MjA3NjA5OTYzOH0.1CFkusMrMKcvSU_-5RyGYPoKDM_yizuQMVGo7W3mXHU';
const String SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDUyMzYzOCwiZXhwIjoyMDc2MDk5NjM4fQ.LIVQ2FpXRpJD7ie4GVkrwU7lLPRm4S5NekNG2Cqme8o';

const String TEST_EMAIL = '2005.ivan@gmail.com';
const String TEST_NEW_PASSWORD = 'NewTestPass123!';

void main() async {
  print('🧪 ============================================');
  print('🧪 SCRIPT DE PRUEBAS - FLUJO OTP HÍBRIDO');
  print('🧪 ============================================\n');

  try {
    // PASO 1: Solicitar OTP
    print('📧 PASO 1: Solicitando OTP para $TEST_EMAIL');
    print('   ────────────────────────────────────────────');
    final otpResult = await step1RequestOTP();
    
    if (!otpResult['success']) {
      print('❌ ERROR: No se pudo obtener el código OTP');
      print('   Error: ${otpResult['error']}');
      return;
    }
    
    final otpCode = otpResult['otp_code'];
    print('✅ Código OTP recibido: $otpCode\n');
    
    // Esperar un momento
    await Future.delayed(Duration(seconds: 2));
    
    // PASO 2: Verificar OTP y obtener recovery_link
    print('🔐 PASO 2: Verificando OTP y obteniendo recovery_link');
    print('   ────────────────────────────────────────────');
    final verifyResult = await step2VerifyOTPAndGetRecoveryLink(otpCode);
    
    if (!verifyResult['success']) {
      print('❌ ERROR: No se pudo verificar OTP');
      print('   Error: ${verifyResult['error']}');
      return;
    }
    
    final recoveryLink = verifyResult['recovery_link'];
    print('✅ Recovery link obtenido:');
    print('   ${recoveryLink.substring(0, 80)}...\n');
    
    // PASO 3: Analizar recovery_link
    print('🔍 PASO 3: Analizando recovery_link');
    print('   ────────────────────────────────────────────');
    final linkAnalysis = analyzeRecoveryLink(recoveryLink);
    print('   Tipo: ${linkAnalysis['type']}');
    print('   Tiene token: ${linkAnalysis['has_token']}');
    print('   Redirect URL: ${linkAnalysis['redirect_url']}');
    print('   Link completo: ${linkAnalysis['full_url']?.substring(0, 100)}...\n');
    
    // PASO 4: Simular acceso al recovery_link (extraer tokens si vienen en URL)
    print('🔑 PASO 4: Simulando acceso al recovery_link');
    print('   ────────────────────────────────────────────');
    print('   ⚠️  NOTA: Para probar completamente, necesitas:');
    print('   1. Abrir el recovery_link en un navegador');
    print('   2. Verificar que redirige a /recovery con tokens');
    print('   3. Probar cambiar la contraseña desde la app\n');
    
    // PASO 5: Verificar que el OTP fue marcado como usado
    print('✅ PASO 5: Verificando que el OTP fue marcado como usado');
    print('   ────────────────────────────────────────────');
    await step5CheckOTPStatus(TEST_EMAIL);
    
    // PASO 6: Resumen
    print('\n📊 RESUMEN DE PRUEBAS');
    print('   ────────────────────────────────────────────');
    print('   ✅ OTP solicitado: ÉXITO');
    print('   ✅ OTP verificado: ÉXITO');
    print('   ✅ Recovery link obtenido: ÉXITO');
    print('   ✅ Flujo backend: FUNCIONANDO');
    print('\n   ⚠️  PRUEBAS PENDIENTES (requieren interacción manual):');
    print('   - Abrir recovery_link en navegador');
    print('   - Verificar redirección a /recovery');
    print('   - Establecer nueva contraseña');
    print('   - Verificar login con nueva contraseña\n');
    
    print('✅✅✅ PRUEBAS AUTOMÁTICAS COMPLETADAS EXITOSAMENTE');
    print('\n💡 Para probar el flujo completo:');
    print('   1. Copia el recovery_link mostrado arriba');
    print('   2. Ábrelo en un navegador');
    print('   3. Verifica que redirige a tu app en /recovery');
    print('   4. Establece una nueva contraseña');
    print('   5. Intenta hacer login con la nueva contraseña\n');
    
  } catch (e, stackTrace) {
    print('\n❌ ERROR CRÍTICO:');
    print('   $e');
    print('\n📚 Stack trace:');
    print('   $stackTrace');
  }
}

/// PASO 1: Solicitar OTP
Future<Map<String, dynamic>> step1RequestOTP() async {
  try {
    final url = Uri.parse('$SUPABASE_URL/functions/v1/send-otp');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $SUPABASE_ANON_KEY',
        'apikey': SUPABASE_ANON_KEY,
      },
      body: jsonEncode({
        'email': TEST_EMAIL,
      }),
    );
    
    print('   📡 Response status: ${response.statusCode}');
    
    if (response.statusCode != 200) {
      return {
        'success': false,
        'error': 'Status ${response.statusCode}: ${response.body}',
      };
    }
    
    final data = jsonDecode(response.body);
    
    String? otpCode;
    if (data is Map) {
      otpCode = data['dev_code'] as String?;
      
      if (otpCode == null) {
        print('   ⚠️  No se recibió dev_code (estamos en producción)');
        print('   💡 Ingresa el código que recibiste por email:');
        otpCode = stdin.readLineSync();
      }
    }
    
    if (otpCode == null || otpCode.isEmpty) {
      return {
        'success': false,
        'error': 'No se obtuvo código OTP',
      };
    }
    
    return {
      'success': true,
      'otp_code': otpCode.trim(),
    };
    
  } catch (e) {
    return {
      'success': false,
      'error': 'Error solicitando OTP: $e',
    };
  }
}

/// PASO 2: Verificar OTP y obtener recovery_link
Future<Map<String, dynamic>> step2VerifyOTPAndGetRecoveryLink(String otpCode) async {
  try {
    final url = Uri.parse('$SUPABASE_URL/functions/v1/verify-otp');
    
    print('   📡 Enviando:');
    print('      Email: $TEST_EMAIL');
    print('      OTP Code: $otpCode');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $SUPABASE_ANON_KEY',
        'apikey': SUPABASE_ANON_KEY,
      },
      body: jsonEncode({
        'email': TEST_EMAIL,
        'otp_code': otpCode,
      }),
    );
    
    print('   📡 Response status: ${response.statusCode}');
    print('   📡 Response body: ${response.body.substring(0, 200)}...');
    
    if (response.statusCode != 200) {
      try {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Error desconocido',
        };
      } catch (_) {
        return {
          'success': false,
          'error': 'Status ${response.statusCode}: ${response.body}',
        };
      }
    }
    
    final data = jsonDecode(response.body);
    
    if (data is Map && data['ok'] == true) {
      final recoveryLink = data['recovery_link'] as String?;
      
      if (recoveryLink == null || recoveryLink.isEmpty) {
        return {
          'success': false,
          'error': 'Recovery link no recibido en la respuesta',
        };
      }
      
      return {
        'success': true,
        'recovery_link': recoveryLink,
      };
    } else {
      return {
        'success': false,
        'error': 'Respuesta indica error: $data',
      };
    }
    
  } catch (e) {
    return {
      'success': false,
      'error': 'Error verificando OTP: $e',
    };
  }
}

/// PASO 3: Analizar recovery_link
Map<String, dynamic> analyzeRecoveryLink(String recoveryLink) {
  try {
    final uri = Uri.parse(recoveryLink);
    
    final hasToken = uri.queryParameters.containsKey('token');
    final redirectUrl = uri.queryParameters['redirect_to'];
    
    String type = 'unknown';
    if (recoveryLink.contains('/auth/v1/verify')) {
      type = 'supabase_verify';
    } else if (recoveryLink.contains('/recovery')) {
      type = 'direct_recovery';
    }
    
    return {
      'type': type,
      'has_token': hasToken,
      'redirect_url': redirectUrl,
      'full_url': recoveryLink,
    };
  } catch (e) {
    return {
      'type': 'error',
      'error': e.toString(),
    };
  }
}

/// PASO 5: Verificar estado del OTP en la base de datos
Future<void> step5CheckOTPStatus(String email) async {
  try {
    // Nota: Esto requeriría acceso a la base de datos directamente
    // Por ahora solo mostramos un mensaje informativo
    print('   ℹ️  Para verificar el estado del OTP en la BD:');
    print('      Ejecuta en Supabase SQL Editor:');
    print('      SELECT * FROM password_reset_otps WHERE email = \'$email\' ORDER BY created_at DESC LIMIT 1;');
    print('      Verifica que "used" = true');
  } catch (e) {
    print('   ⚠️  No se pudo verificar estado: $e');
  }
}

