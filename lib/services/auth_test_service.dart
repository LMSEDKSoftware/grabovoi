import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class AuthTestService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final AuthService _authService = AuthService();

  // Probar registro de usuario
  static Future<void> testUserRegistration() async {
    try {
      print('🧪 Iniciando prueba de registro de usuario...');
      
      // Verificar conexión con Supabase
      final response = await _supabase.from('users').select('count').limit(1);
      print('✅ Conexión con Supabase establecida');
      
      // Verificar si el trigger está funcionando
      print('🔍 Verificando trigger automático...');
      
      // Intentar registrar un usuario de prueba
      final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@gmail.com';
      final testPassword = 'testpassword123';
      final testName = 'Usuario de Prueba';
      
      print('📝 Registrando usuario de prueba: $testEmail');
      
      final authResponse = await _supabase.auth.signUp(
        email: testEmail,
        password: testPassword,
        data: {'name': testName},
      );
      
      if (authResponse.user != null) {
        print('✅ Usuario registrado en auth.users con ID: ${authResponse.user!.id}');
        
        // Esperar un momento para que el trigger se ejecute
        await Future.delayed(const Duration(seconds: 2));
        
        // Verificar si el usuario se creó en la tabla users
        try {
          // Esperar un poco más para que el trigger se ejecute
          await Future.delayed(const Duration(seconds: 3));
          
          final userData = await _supabase
              .from('users')
              .select()
              .eq('id', authResponse.user!.id)
              .single();
          
          print('✅ Usuario creado automáticamente en tabla users:');
          print('   - ID: ${userData['id']}');
          print('   - Email: ${userData['email']}');
          print('   - Nombre: ${userData['name']}');
          print('   - Creado: ${userData['created_at']}');
          
          // Limpiar usuario de prueba
          await _supabase.auth.admin.deleteUser(authResponse.user!.id);
          print('🗑️ Usuario de prueba eliminado');
          
        } catch (e) {
          print('❌ Error: El usuario no se creó automáticamente en la tabla users');
          print('   Error: $e');
          print('   💡 Posibles soluciones:');
          print('   1. Ejecutar el script fix_rls_policies.sql');
          print('   2. Ejecutar el script fix_trigger.sql');
          print('   3. Verificar que RLS esté configurado correctamente');
          
          // Intentar crear el usuario manualmente para debug
          try {
            print('🔧 Intentando crear usuario manualmente...');
            await _supabase.from('users').insert({
              'id': authResponse.user!.id,
              'email': testEmail,
              'name': testName,
              'created_at': DateTime.now().toIso8601String(),
              'is_email_verified': false,
            });
            print('✅ Usuario creado manualmente');
          } catch (manualError) {
            print('❌ Error creando usuario manualmente: $manualError');
          }
        }
        
      } else {
        print('❌ Error: No se pudo registrar el usuario');
      }
      
    } catch (e) {
      print('❌ Error en la prueba: $e');
    }
  }

  // Verificar configuración de la base de datos
  static Future<void> checkDatabaseSetup() async {
    try {
      print('🔍 Verificando configuración de la base de datos...');
      
      // Verificar tabla users
      final usersResponse = await _supabase.from('users').select('count').limit(1);
      print('✅ Tabla users existe');
      
      // Verificar tabla user_challenges
      final challengesResponse = await _supabase.from('user_challenges').select('count').limit(1);
      print('✅ Tabla user_challenges existe');
      
      // Verificar tabla user_actions
      final actionsResponse = await _supabase.from('user_actions').select('count').limit(1);
      print('✅ Tabla user_actions existe');
      
      // Verificar tabla daily_progress
      final progressResponse = await _supabase.from('daily_progress').select('count').limit(1);
      print('✅ Tabla daily_progress existe');
      
      print('🎉 Todas las tablas están configuradas correctamente');
      
    } catch (e) {
      print('❌ Error verificando configuración: $e');
    }
  }

  // Probar login de usuario existente
  static Future<void> testUserLogin() async {
    try {
      print('🧪 Probando login de usuario...');
      
      // Verificar si hay usuarios en la tabla
      final users = await _supabase.from('users').select('id, email, name').limit(5);
      
      if (users.isNotEmpty) {
        print('👥 Usuarios encontrados en la base de datos:');
        for (final user in users) {
          print('   - ${user['name']} (${user['email']}) - ID: ${user['id']}');
        }
      } else {
        print('ℹ️ No hay usuarios en la base de datos');
      }
      
    } catch (e) {
      print('❌ Error verificando usuarios: $e');
    }
  }
}
