import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/config/supabase_config.dart';
import 'lib/services/auth_service_simple.dart';
import 'lib/services/subscription_service.dart';

/// Script de prueba para verificar el funcionamiento del período de prueba de 7 días
/// 
/// Ejecutar con: dart test_subscription_trial.dart
/// 
/// Este script prueba:
/// 1. Creación de usuario nuevo
/// 2. Activación automática del período de prueba
/// 3. Verificación de acceso premium
/// 4. Verificación de expiración del período de prueba

void main() async {
  print('🧪 INICIANDO PRUEBAS DEL SISTEMA DE SUSCRIPCIONES\n');
  print('=' * 60);
  
  try {
    // Inicializar Supabase
    print('\n📦 Inicializando Supabase...');
    await SupabaseConfig.initialize();
    print('✅ Supabase inicializado');
    
    // Inicializar servicio de suscripciones
    print('\n📦 Inicializando SubscriptionService...');
    await SubscriptionService().initialize();
    print('✅ SubscriptionService inicializado');
    
    // Test 1: Verificar que un usuario nuevo obtiene período de prueba
    await testNewUserGetsTrial();
    
    // Test 2: Verificar que el período de prueba se guarda correctamente
    await testTrialIsSaved();
    
    // Test 3: Verificar que el usuario tiene acceso premium durante el período de prueba
    await testPremiumAccessDuringTrial();
    
    // Test 4: Verificar que SharedPreferences funciona correctamente
    await testSharedPreferences();
    
    // Test 5: Verificar que el servicio detecta usuarios no autenticados
    await testUnauthenticatedUser();
    
    print('\n' + '=' * 60);
    print('✅ TODAS LAS PRUEBAS COMPLETADAS');
    print('=' * 60);
    
  } catch (e, stackTrace) {
    print('\n❌ ERROR EN LAS PRUEBAS:');
    print('Error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
  
  exit(0);
}

/// Test 1: Verificar que un usuario nuevo obtiene período de prueba automáticamente
Future<void> testNewUserGetsTrial() async {
  print('\n📋 TEST 1: Usuario nuevo obtiene período de prueba');
  print('-' * 60);
  
  final authService = AuthServiceSimple();
  final subscriptionService = SubscriptionService();
  
  // Crear un usuario de prueba único
  final testEmail = 'test_trial_${DateTime.now().millisecondsSinceEpoch}@test.com';
  final testPassword = 'TestPassword123!';
  final testName = 'Usuario Prueba';
  
  try {
    print('📝 Creando usuario de prueba: $testEmail');
    
    // Registrar usuario
    final signUpResponse = await authService.signUp(
      email: testEmail,
      password: testPassword,
      name: testName,
    );
    
    if (signUpResponse.user == null) {
      throw Exception('No se pudo crear el usuario de prueba');
    }
    
    print('✅ Usuario creado: ${signUpResponse.user!.id}');
    
    // Verificar estado de suscripción después del registro
    print('🔍 Verificando estado de suscripción...');
    await subscriptionService.checkSubscriptionStatus();
    
    // Verificar que tiene acceso premium
    final hasPremium = subscriptionService.hasPremiumAccess;
    final isFreeUser = subscriptionService.isFreeUser;
    
    print('📊 Resultados:');
    print('   - Tiene acceso premium: $hasPremium');
    print('   - Es usuario gratuito: $isFreeUser');
    
    if (!hasPremium || isFreeUser) {
      throw Exception('❌ FALLO: El usuario nuevo NO obtuvo acceso premium automáticamente');
    }
    
    print('✅ ÉXITO: Usuario nuevo obtuvo acceso premium automáticamente');
    
    // Limpiar: cerrar sesión
    await authService.signOut();
    print('🧹 Sesión cerrada');
    
  } catch (e) {
    print('❌ ERROR en Test 1: $e');
    // Intentar limpiar
    try {
      await authService.signOut();
    } catch (_) {}
    rethrow;
  }
}

/// Test 2: Verificar que el período de prueba se guarda correctamente en SharedPreferences
Future<void> testTrialIsSaved() async {
  print('\n📋 TEST 2: Período de prueba se guarda en SharedPreferences');
  print('-' * 60);
  
  final authService = AuthServiceSimple();
  final subscriptionService = SubscriptionService();
  
  final testEmail = 'test_trial_save_${DateTime.now().millisecondsSinceEpoch}@test.com';
  final testPassword = 'TestPassword123!';
  
  try {
    print('📝 Creando usuario: $testEmail');
    
    await authService.signUp(
      email: testEmail,
      password: testPassword,
      name: 'Test Save',
    );
    
    final userId = authService.currentUser!.id;
    print('✅ Usuario creado: $userId');
    
    // Verificar estado de suscripción
    await subscriptionService.checkSubscriptionStatus();
    
    // Verificar SharedPreferences directamente
    final prefs = await SharedPreferences.getInstance();
    final trialStartKey = 'free_trial_start_$userId';
    final trialStartStr = prefs.getString(trialStartKey);
    
    print('🔍 Verificando SharedPreferences...');
    print('   - Clave: $trialStartKey');
    print('   - Valor encontrado: ${trialStartStr != null ? "Sí" : "No"}');
    
    if (trialStartStr == null) {
      throw Exception('❌ FALLO: No se guardó el período de prueba en SharedPreferences');
    }
    
    final trialStart = DateTime.parse(trialStartStr);
    final trialEnd = trialStart.add(const Duration(days: 7));
    final now = DateTime.now();
    
    print('   - Fecha de inicio: $trialStart');
    print('   - Fecha de expiración: $trialEnd');
    print('   - Fecha actual: $now');
    print('   - Días restantes: ${trialEnd.difference(now).inDays}');
    
    if (now.isAfter(trialEnd)) {
      throw Exception('❌ FALLO: El período de prueba ya expiró inmediatamente');
    }
    
    print('✅ ÉXITO: Período de prueba guardado correctamente');
    
    await authService.signOut();
    
  } catch (e) {
    print('❌ ERROR en Test 2: $e');
    try {
      await authService.signOut();
    } catch (_) {}
    rethrow;
  }
}

/// Test 3: Verificar que el usuario tiene acceso premium durante el período de prueba
Future<void> testPremiumAccessDuringTrial() async {
  print('\n📋 TEST 3: Acceso premium durante período de prueba');
  print('-' * 60);
  
  final authService = AuthServiceSimple();
  final subscriptionService = SubscriptionService();
  
  final testEmail = 'test_premium_${DateTime.now().millisecondsSinceEpoch}@test.com';
  final testPassword = 'TestPassword123!';
  
  try {
    print('📝 Creando usuario: $testEmail');
    
    await authService.signUp(
      email: testEmail,
      password: testPassword,
      name: 'Test Premium',
    );
    
    print('✅ Usuario creado');
    
    // Verificar estado
    await subscriptionService.checkSubscriptionStatus();
    
    // Verificar múltiples veces que el acceso premium persiste
    for (int i = 1; i <= 3; i++) {
      await subscriptionService.checkSubscriptionStatus();
      
      final hasPremium = subscriptionService.hasPremiumAccess;
      final isFreeUser = subscriptionService.isFreeUser;
      
      print('   Verificación $i:');
      print('      - Premium: $hasPremium');
      print('      - Gratuito: $isFreeUser');
      
      if (!hasPremium || isFreeUser) {
        throw Exception('❌ FALLO: El acceso premium no persiste en verificación $i');
      }
    }
    
    print('✅ ÉXITO: Acceso premium persiste correctamente');
    
    await authService.signOut();
    
  } catch (e) {
    print('❌ ERROR en Test 3: $e');
    try {
      await authService.signOut();
    } catch (_) {}
    rethrow;
  }
}

/// Test 4: Verificar que SharedPreferences funciona correctamente
Future<void> testSharedPreferences() async {
  print('\n📋 TEST 4: Funcionamiento de SharedPreferences');
  print('-' * 60);
  
  final authService = AuthServiceSimple();
  final subscriptionService = SubscriptionService();
  
  final testEmail = 'test_prefs_${DateTime.now().millisecondsSinceEpoch}@test.com';
  final testPassword = 'TestPassword123!';
  
  try {
    print('📝 Creando usuario: $testEmail');
    
    await authService.signUp(
      email: testEmail,
      password: testPassword,
      name: 'Test Prefs',
    );
    
    final userId = authService.currentUser!.id;
    print('✅ Usuario creado: $userId');
    
    // Verificar estado inicial
    await subscriptionService.checkSubscriptionStatus();
    
    final prefs = await SharedPreferences.getInstance();
    final trialStartKey = 'free_trial_start_$userId';
    
    // Leer directamente desde SharedPreferences
    final trialStartStr1 = prefs.getString(trialStartKey);
    print('🔍 Lectura directa de SharedPreferences:');
    print('   - Valor: $trialStartStr1');
    
    if (trialStartStr1 == null) {
      throw Exception('❌ FALLO: No se puede leer desde SharedPreferences');
    }
    
    // Cerrar sesión y volver a iniciar sesión
    print('🔄 Cerrando sesión y volviendo a iniciar...');
    await authService.signOut();
    
    await Future.delayed(const Duration(seconds: 1));
    
    await authService.signIn(
      email: testEmail,
      password: testPassword,
    );
    
    // Verificar que el período de prueba persiste después del login
    await subscriptionService.checkSubscriptionStatus();
    
    final trialStartStr2 = prefs.getString(trialStartKey);
    print('🔍 Después de login:');
    print('   - Valor: $trialStartStr2');
    
    if (trialStartStr2 != trialStartStr1) {
      throw Exception('❌ FALLO: El período de prueba cambió después del login');
    }
    
    final hasPremium = subscriptionService.hasPremiumAccess;
    if (!hasPremium) {
      throw Exception('❌ FALLO: Perdió acceso premium después del login');
    }
    
    print('✅ ÉXITO: SharedPreferences funciona correctamente');
    
    await authService.signOut();
    
  } catch (e) {
    print('❌ ERROR en Test 4: $e');
    try {
      await authService.signOut();
    } catch (_) {}
    rethrow;
  }
}

/// Test 5: Verificar que usuarios no autenticados son tratados como gratuitos
Future<void> testUnauthenticatedUser() async {
  print('\n📋 TEST 5: Usuario no autenticado es tratado como gratuito');
  print('-' * 60);
  
  final subscriptionService = SubscriptionService();
  
  try {
    // Asegurarse de que no hay sesión activa
    final authService = AuthServiceSimple();
    if (authService.isLoggedIn) {
      await authService.signOut();
    }
    
    print('🔍 Verificando estado sin autenticación...');
    await subscriptionService.checkSubscriptionStatus();
    
    final hasPremium = subscriptionService.hasPremiumAccess;
    final isFreeUser = subscriptionService.isFreeUser;
    
    print('📊 Resultados:');
    print('   - Tiene acceso premium: $hasPremium');
    print('   - Es usuario gratuito: $isFreeUser');
    
    if (hasPremium || !isFreeUser) {
      throw Exception('❌ FALLO: Usuario no autenticado tiene acceso premium');
    }
    
    print('✅ ÉXITO: Usuario no autenticado es tratado como gratuito');
    
  } catch (e) {
    print('❌ ERROR en Test 5: $e');
    rethrow;
  }
}

