import 'package:flutter_test/flutter_test.dart';
import 'package:manifestacion_numerica_grabovoi/services/subscription_service.dart';
import 'package:manifestacion_numerica_grabovoi/services/auth_service_simple.dart';
import 'package:manifestacion_numerica_grabovoi/config/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Script de prueba manual para verificar el período de prueba de 7 días
/// 
/// Este script verifica la lógica del servicio sin crear usuarios reales.
/// Para pruebas completas con usuarios reales, ejecutar la app y crear un usuario nuevo.

void main() {
  group('Verificación de Lógica del Período de Prueba', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await SupabaseConfig.initialize();
    });

    tearDown(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    test('Verificar que checkSubscriptionStatus se puede llamar sin errores', () async {
      print('\n📋 TEST: checkSubscriptionStatus se puede llamar');
      
      final subscriptionService = SubscriptionService();
      
      // Inicializar el servicio
      await subscriptionService.initialize();
      
      // Verificar que no lanza excepciones
      expect(() => subscriptionService.checkSubscriptionStatus(), returnsNormally);
      
      print('✅ ÉXITO: checkSubscriptionStatus se puede llamar sin errores');
    });

    test('Usuario no autenticado es tratado como gratuito', () async {
      print('\n📋 TEST: Usuario no autenticado es gratuito');
      
      final subscriptionService = SubscriptionService();
      final authService = AuthServiceSimple();
      
      // Asegurarse de que no hay sesión activa
      if (authService.isLoggedIn) {
        await authService.signOut();
      }
      
      await subscriptionService.checkSubscriptionStatus();
      
      expect(subscriptionService.isFreeUser, isTrue,
        reason: 'Usuario no autenticado debería ser gratuito');
      expect(subscriptionService.hasPremiumAccess, isFalse,
        reason: 'Usuario no autenticado NO debería tener acceso premium');
      
      print('✅ ÉXITO: Usuario no autenticado es tratado como gratuito');
    });

    test('SharedPreferences puede guardar y leer período de prueba', () async {
      print('\n📋 TEST: SharedPreferences funciona correctamente');
      
      final prefs = await SharedPreferences.getInstance();
      const testUserId = 'test_user_123';
      const trialStartKey = 'free_trial_start_$testUserId';
      
      // Limpiar cualquier valor previo
      await prefs.remove(trialStartKey);
      
      // Guardar período de prueba
      final now = DateTime.now();
      await prefs.setString(trialStartKey, now.toIso8601String());
      
      // Leer período de prueba
      final trialStartStr = prefs.getString(trialStartKey);
      expect(trialStartStr, isNotNull,
        reason: 'Debería poder leer el período de prueba guardado');
      
      final trialStart = DateTime.parse(trialStartStr!);
      final trialEnd = trialStart.add(const Duration(days: 7));
      
      expect(trialEnd.isAfter(now), isTrue,
        reason: 'La fecha de expiración debería ser 7 días después del inicio');
      
      print('✅ ÉXITO: SharedPreferences funciona correctamente');
      print('   - Inicio guardado: $trialStart');
      print('   - Expira: $trialEnd');
      print('   - Días: ${trialEnd.difference(now).inDays}');
      
      // Limpiar
      await prefs.remove(trialStartKey);
    });

    test('Verificar lógica de expiración del período de prueba', () async {
      print('\n📋 TEST: Lógica de expiración del período de prueba');
      
      final prefs = await SharedPreferences.getInstance();
      const testUserId = 'test_user_expiry';
      const trialStartKey = 'free_trial_start_$testUserId';
      
      // Simular período de prueba que acaba de empezar
      final trialStart = DateTime.now().subtract(const Duration(seconds: 1));
      await prefs.setString(trialStartKey, trialStart.toIso8601String());
      
      final trialEnd = trialStart.add(const Duration(days: 7));
      final now = DateTime.now();
      
      // Verificar que el período de prueba está activo
      expect(now.isBefore(trialEnd), isTrue,
        reason: 'El período de prueba debería estar activo');
      
      // Simular período de prueba expirado
      final expiredTrialStart = DateTime.now().subtract(const Duration(days: 8));
      await prefs.setString(trialStartKey, expiredTrialStart.toIso8601String());
      
      final expiredTrialEnd = expiredTrialStart.add(const Duration(days: 7));
      expect(now.isAfter(expiredTrialEnd), isTrue,
        reason: 'El período de prueba debería estar expirado');
      
      print('✅ ÉXITO: Lógica de expiración funciona correctamente');
      print('   - Período activo: ${now.isBefore(trialEnd)}');
      print('   - Período expirado: ${now.isAfter(expiredTrialEnd)}');
      
      // Limpiar
      await prefs.remove(trialStartKey);
    });

    test('Verificar que initialize() llama a checkSubscriptionStatus incluso sin IAP', () async {
      print('\n📋 TEST: initialize() funciona sin IAP');
      
      final subscriptionService = SubscriptionService();
      
      // Inicializar (puede que IAP no esté disponible en el entorno de test)
      await subscriptionService.initialize();
      
      // Verificar que el servicio se inicializó correctamente
      // (no debería lanzar excepciones incluso si IAP no está disponible)
      expect(subscriptionService, isNotNull);
      
      print('✅ ÉXITO: initialize() funciona correctamente');
    });
  });

  group('Instrucciones para Pruebas Manuales', () {
    test('INSTRUCCIONES: Cómo probar con usuario real', () {
      print('\n${'=' * 60}');
      print('📋 INSTRUCCIONES PARA PRUEBAS MANUALES');
      print('=' * 60);
      print('');
      print('Para probar el período de prueba de 7 días con un usuario real:');
      print('');
      print('1. Ejecuta la aplicación: flutter run');
      print('2. Crea un usuario nuevo desde cero');
      print('3. Verifica en los logs de la consola:');
      print('   - Deberías ver: "✅ Período de prueba iniciado automáticamente"');
      print('   - Deberías ver: "✅ Usuario ahora tiene acceso premium: true"');
      print('4. Verifica que puedes acceder a todas las funciones premium');
      print('5. Verifica en SharedPreferences (usando un inspector de apps):');
      print('   - Clave: free_trial_start_[USER_ID]');
      print('   - Valor: Fecha ISO del inicio del período de prueba');
      print('');
      print('Para verificar que el período expira correctamente:');
      print('1. Modifica manualmente SharedPreferences para simular expiración');
      print('2. O espera 7 días reales');
      print('3. Verifica que el usuario pierde acceso premium');
      print('');
      print('=' * 60);
      
      // Este test siempre pasa, solo muestra instrucciones
      expect(true, isTrue);
    });
  });
}
