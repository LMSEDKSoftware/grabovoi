import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Script de debugging completo para el flujo OTP
/// Este script prueba todo el flujo paso a paso con logging detallado

const String SUPABASE_URL = 'https://whtiazgcxdnemrrgjjqf.supabase.co';
const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1MjM2MzgsImV4cCI6MjA3NjA5OTYzOH0.1CFkusMrMKcvSU_-5RyGYPoKDM_yizuQMVGo7W3mXHU';
const String SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDUyMzYzOCwiZXhwIjoyMDc2MDk5NjM4fQ.LIVQ2FpXRpJD7ie4GVkrwU7lLPRm4S5NekNG2Cqme8o';

const String TEST_EMAIL = '2005.ivan@gmail.com'; // Cambiado según tu solicitud
const String TEST_NEW_PASSWORD = 'TestPass123!';

void main() async {
  print('🔍 ============================================');
  print('🔍 SCRIPT DE DEBUGGING COMPLETO - FLUJO OTP');
  print('🔍 ============================================\n');

  try {
    // PASO 1: Solicitar OTP
    print('📧 PASO 1: Solicitando OTP para $TEST_EMAIL');
    print('   ────────────────────────────────────────────');
    final otpCode = await step1RequestOTP();
    
    if (otpCode == null) {
      print('❌ ERROR: No se pudo obtener el código OTP');
      return;
    }
    
    print('✅ Código OTP recibido: $otpCode\n');
    
    // Esperar un momento
    await Future.delayed(const Duration(seconds: 2));
    
    // PASO 2: Verificar OTP y actualizar contraseña
    print('🔐 PASO 2: Verificando OTP y actualizando contraseña');
    print('   ────────────────────────────────────────────');
    final updateSuccess = await step2VerifyOTPAndUpdatePassword(otpCode);
    
    if (!updateSuccess) {
      print('❌ ERROR: No se pudo actualizar la contraseña');
      return;
    }
    
    print('✅ Contraseña actualizada exitosamente\n');
    
    // Esperar un momento para propagación
    print('⏳ Esperando 3 segundos para propagación de cambios...\n');
    await Future.delayed(const Duration(seconds: 3));
    
    // PASO 3: Verificar estado del usuario después de actualizar
    print('🔍 PASO 3: Verificando estado del usuario en Supabase');
    print('   ────────────────────────────────────────────');
    await step3CheckUserStatus();
    
    // PASO 4: Verificar login con nueva contraseña
    print('\n🔑 PASO 4: Verificando login con nueva contraseña');
    print('   ────────────────────────────────────────────');
    final loginSuccess = await step4TestLogin();
    
    if (loginSuccess) {
      print('\n✅✅✅ ÉXITO COMPLETO: Todo el flujo funciona correctamente');
    } else {
      print('\n❌❌❌ FALLO: El login NO funciona después de actualizar la contraseña');
      print('   Esto confirma el problema que estamos intentando resolver');
      print('\n🔍 Revisando logs en Supabase para más detalles...');
      await step3CheckUserStatus();
    }
    
  } catch (e, stackTrace) {
    print('\n❌ ERROR CRÍTICO:');
    print('   $e');
    print('\n📚 Stack trace:');
    print('   $stackTrace');
  }
}

/// PASO 1: Solicitar OTP
Future<String?> step1RequestOTP() async {
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
    print('   📡 Response body: ${response.body}');
    
    if (response.statusCode != 200) {
      print('   ❌ Error en la solicitud OTP');
      return null;
    }
    
    final data = jsonDecode(response.body);
    
    // En desarrollo, el código puede venir en dev_code
    String? otpCode;
    if (data is Map) {
      otpCode = data['dev_code'] as String?;
      
      if (otpCode == null) {
        print('   ⚠️  No se recibió dev_code (estamos en producción o no está configurado)');
        print('   💡 Ingresa el código que recibiste por email:');
        otpCode = stdin.readLineSync();
      }
    }
    
    return otpCode?.trim();
    
  } catch (e) {
    print('   ❌ Error solicitando OTP: $e');
    return null;
  }
}

/// PASO 2: Verificar OTP y actualizar contraseña
Future<bool> step2VerifyOTPAndUpdatePassword(String otpCode) async {
  try {
    final url = Uri.parse('$SUPABASE_URL/functions/v1/verify-otp');
    
    print('   📡 Enviando:');
    print('      Email: $TEST_EMAIL');
    print('      OTP Code: $otpCode');
    print('      Nueva contraseña: ${TEST_NEW_PASSWORD.length} caracteres');
    
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
        'new_password': TEST_NEW_PASSWORD,
      }),
    );
    
    print('   📡 Response status: ${response.statusCode}');
    print('   📡 Response body: ${response.body}');
    
    if (response.statusCode != 200) {
      print('   ❌ Error actualizando contraseña');
      try {
        final errorData = jsonDecode(response.body);
        print('   📋 Error details: $errorData');
      } catch (_) {}
      return false;
    }
    
    final data = jsonDecode(response.body);
    
    if (data is Map && data['ok'] == true) {
      print('   ✅ Respuesta exitosa del servidor');
      return true;
    } else {
      print('   ❌ Respuesta indica error: $data');
      return false;
    }
    
  } catch (e) {
    print('   ❌ Error verificando OTP: $e');
    return false;
  }
}

/// PASO 3: Verificar estado del usuario
Future<void> step3CheckUserStatus() async {
  try {
    final url = Uri.parse('$SUPABASE_URL/auth/v1/admin/users?per_page=1000');
    
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $SUPABASE_SERVICE_ROLE_KEY',
        'apikey': SUPABASE_SERVICE_ROLE_KEY,
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final users = data['users'] as List?;
      
      if (users != null) {
        final user = users.firstWhere(
          (u) => (u['email'] as String?)?.toLowerCase() == TEST_EMAIL.toLowerCase(),
          orElse: () => null,
        );
        
        if (user != null) {
          print('   ✅ Usuario encontrado:');
          print('      ID: ${user['id']}');
          print('      Email: ${user['email']}');
          print('      Email confirmado: ${user['email_confirmed_at'] != null ? "SÍ ✅ (${user['email_confirmed_at']})" : "NO ❌"}');
          print('      Último sign in: ${user['last_sign_in_at'] ?? "Nunca"}');
          print('      Creado: ${user['created_at']}');
          print('      Updated: ${user['updated_at']}');
          
          // Verificar si tiene phone
          if (user['phone'] != null) {
            print('      Phone: ${user['phone']}');
            print('      Phone confirmado: ${user['phone_confirmed_at'] != null ? "SÍ ✅" : "NO ❌"}');
          }
        } else {
          print('   ⚠️  Usuario NO encontrado en auth.users');
        }
      }
    } else {
      print('   ⚠️  No se pudo verificar estado (status: ${response.statusCode})');
      print('   📡 Response: ${response.body}');
    }
  } catch (e) {
    print('   ⚠️  Error verificando estado: $e');
  }
}

/// PASO 4: Probar login con nueva contraseña
Future<bool> step4TestLogin() async {
  try {
    final url = Uri.parse('$SUPABASE_URL/auth/v1/token?grant_type=password');
    
    print('   📡 Intentando login con:');
    print('      Email: $TEST_EMAIL');
    print('      Password: ${TEST_NEW_PASSWORD.length} caracteres');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $SUPABASE_ANON_KEY',
        'apikey': SUPABASE_ANON_KEY,
      },
      body: jsonEncode({
        'email': TEST_EMAIL,
        'password': TEST_NEW_PASSWORD,
      }),
    );
    
    print('   📡 Response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('   ✅ Login exitoso!');
      print('   📋 Access token recibido: ${(data['access_token'] as String?)?.substring(0, 20)}...');
      
      // Verificar si el usuario está confirmado
      if (data['user'] != null) {
        final user = data['user'] as Map;
        final emailConfirmed = user['email_confirmed_at'];
        print('   📋 Email confirmado: ${emailConfirmed != null ? "SÍ ✅" : "NO ❌"}');
      }
      
      return true;
    } else {
      print('   ❌ Login falló');
      print('   📡 Response body: ${response.body}');
      
      try {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error_description'] ?? errorData['error'] ?? 'Error desconocido';
        print('   📋 Error: $errorMsg');
      } catch (_) {}
      
      return false;
    }
    
  } catch (e) {
    print('   ❌ Error probando login: $e');
    return false;
  }
}

/// BONUS: Verificar estado del usuario directamente en Supabase
Future<void> checkUserStatus() async {
  print('\n🔍 BONUS: Verificando estado del usuario en Supabase');
  print('   ────────────────────────────────────────────');
  
  try {
    // Esto requiere hacer una llamada directa a la API de Supabase Admin
    // Por seguridad, solo lo hacemos si tenemos SERVICE_ROLE_KEY
    final url = Uri.parse('$SUPABASE_URL/auth/v1/admin/users?per_page=1000');
    
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $SUPABASE_SERVICE_ROLE_KEY',
        'apikey': SUPABASE_SERVICE_ROLE_KEY,
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final users = data['users'] as List?;
      
      if (users != null) {
        final user = users.firstWhere(
          (u) => (u['email'] as String?)?.toLowerCase() == TEST_EMAIL.toLowerCase(),
          orElse: () => null,
        );
        
        if (user != null) {
          print('   ✅ Usuario encontrado:');
          print('      ID: ${user['id']}');
          print('      Email: ${user['email']}');
          print('      Email confirmado: ${user['email_confirmed_at'] != null ? "SÍ ✅" : "NO ❌"}');
          print('      Último cambio de contraseña: ${user['last_sign_in_at']}');
        } else {
          print('   ⚠️  Usuario no encontrado');
        }
      }
    } else {
      print('   ⚠️  No se pudo verificar estado (requiere permisos admin)');
    }
  } catch (e) {
    print('   ⚠️  Error verificando estado: $e');
  }
}

