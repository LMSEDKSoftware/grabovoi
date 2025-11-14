import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import '../models/user_model.dart' as app_models;
import 'subscription_service.dart';
import 'biometric_auth_service.dart';

class AuthServiceSimple {
  static final AuthServiceSimple _instance = AuthServiceSimple._internal();
  factory AuthServiceSimple() => _instance;
  AuthServiceSimple._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  app_models.User? _currentUser;
  bool _isInitialized = false;

  // Getters
  app_models.User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _isInitialized;

  // Inicializar el servicio
  Future<void> initialize() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        await _loadUserFromSession(session);
      }
      _isInitialized = true;
    } catch (e) {
      print('Error inicializando AuthService: $e');
      _isInitialized = true;
    }
  }

  // Cargar usuario desde sesión
  Future<void> _loadUserFromSession(Session session) async {
    try {
      // Intentar cargar desde la tabla users
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', session.user.id)
          .single();
      
      _currentUser = app_models.User.fromJson(userData);
      await _saveUserToLocal(_currentUser!);
      print('✅ Usuario cargado desde tabla users');
    } catch (e) {
      print('⚠️ Usuario no encontrado en tabla users, creando...');
      // Si no existe, crear el usuario
      await _createUserFromSession(session);
    }
  }

  // Crear usuario desde sesión
  Future<void> _createUserFromSession(Session session) async {
    try {
      final newUser = app_models.User(
        id: session.user.id,
        email: session.user.email ?? '',
        name: session.user.userMetadata?['name'] ?? session.user.email?.split('@')[0] ?? 'Usuario',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isEmailVerified: session.user.emailConfirmedAt != null,
      );

      // Intentar insertar en la tabla users
      await _supabase.from('users').insert(newUser.toJson());
      _currentUser = newUser;
      await _saveUserToLocal(_currentUser!);
      print('✅ Usuario creado en tabla users');
    } catch (e) {
      print('❌ Error creando usuario en tabla users: $e');
      // Si falla, usar solo datos de sesión
      _currentUser = app_models.User(
        id: session.user.id,
        email: session.user.email ?? '',
        name: session.user.userMetadata?['name'] ?? session.user.email?.split('@')[0] ?? 'Usuario',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isEmailVerified: session.user.emailConfirmedAt != null,
      );
      await _saveUserToLocal(_currentUser!);
      print('⚠️ Usuario creado solo localmente');
    }
  }

  // Guardar usuario localmente
  Future<void> _saveUserToLocal(app_models.User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', json.encode(user.toJson()));
  }

  // Cargar usuario local
  Future<app_models.User?> _loadUserFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      if (userJson != null) {
        return app_models.User.fromJson(json.decode(userJson));
      }
    } catch (e) {
      print('Error cargando usuario local: $e');
    }
    return null;
  }

  // Registro con email y contraseña
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user != null) {
        print('✅ Usuario registrado en auth.users');
        
        // Esperar un momento para que el trigger se ejecute
        await Future.delayed(const Duration(seconds: 2));
        
        // Intentar cargar el usuario desde la tabla users
        try {
          final userData = await _supabase
              .from('users')
              .select()
              .eq('id', response.user!.id)
              .single();
          
          _currentUser = app_models.User.fromJson(userData);
          print('✅ Usuario cargado desde tabla users');
        } catch (e) {
          print('⚠️ Usuario no encontrado en tabla users, creando manualmente...');
          // Crear usuario manualmente
          final newUser = app_models.User(
            id: response.user!.id,
            email: email,
            name: name,
            createdAt: DateTime.now(),
            isEmailVerified: false,
          );

          try {
            await _supabase.from('users').insert(newUser.toJson());
            _currentUser = newUser;
            print('✅ Usuario creado manualmente en tabla users');
          } catch (insertError) {
            print('❌ Error creando usuario manualmente: $insertError');
            _currentUser = newUser;
            print('⚠️ Usuario creado solo localmente');
          }
        }
        
        await _saveUserToLocal(_currentUser!);
        
        // IMPORTANTE: Verificar estado de suscripción después de registro
        // Esto asegura que usuarios nuevos obtengan su período de prueba de 7 días
        // NO hacer que el registro falle si esto falla
        try {
          await SubscriptionService().checkSubscriptionStatus();
          print('✅ Estado de suscripción verificado después de registro');
        } catch (e) {
          print('⚠️ Error verificando suscripción después de registro: $e');
          // NO relanzar el error - el registro fue exitoso
        }
      }

      return response;
    } catch (e) {
      print('Error en registro: $e');
      rethrow;
    }
  }

  // Login con email y contraseña
  Future<AuthResponse> signIn({
    required String email,
    required String password,
    bool saveForBiometric = false,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadUserFromSession(response.session!);
        
        // Guardar credenciales de forma segura si se solicita
        if (saveForBiometric) {
          await saveBiometricCredentials(email: email, password: password);
        }
      }

      // IMPORTANTE: Verificar estado de suscripción después de login
      // Esto asegura que usuarios nuevos obtengan su período de prueba de 7 días
      try {
        await SubscriptionService().checkSubscriptionStatus();
        print('✅ Estado de suscripción verificado después de login');
      } catch (e) {
        print('⚠️ Error verificando suscripción después de login: $e');
      }

      return response;
    } catch (e) {
      print('Error en login: $e');
      rethrow;
    }
  }

  // Guardar credenciales de forma segura para autenticación biométrica
  Future<void> saveBiometricCredentials({
    required String email,
    required String password,
  }) async {
    try {
      await _secureStorage.write(key: 'biometric_email', value: email);
      await _secureStorage.write(key: 'biometric_password', value: password);
      await _secureStorage.write(key: 'biometric_enabled', value: 'true');
      print('✅ Credenciales guardadas de forma segura para biométrica');
    } catch (e) {
      print('❌ Error guardando credenciales biométricas: $e');
    }
  }

  // Obtener credenciales guardadas de forma segura
  Future<Map<String, String>?> getBiometricCredentials() async {
    try {
      final email = await _secureStorage.read(key: 'biometric_email');
      final password = await _secureStorage.read(key: 'biometric_password');
      final enabled = await _secureStorage.read(key: 'biometric_enabled');
      
      if (email != null && password != null && enabled == 'true') {
        return {'email': email, 'password': password};
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo credenciales biométricas: $e');
      return null;
    }
  }

  // Verificar si hay credenciales biométricas guardadas
  Future<bool> hasBiometricCredentials() async {
    try {
      final enabled = await _secureStorage.read(key: 'biometric_enabled');
      return enabled == 'true';
    } catch (e) {
      print('❌ Error verificando credenciales biométricas: $e');
      return false;
    }
  }

  // Eliminar credenciales biométricas
  Future<void> removeBiometricCredentials() async {
    try {
      await _secureStorage.delete(key: 'biometric_email');
      await _secureStorage.delete(key: 'biometric_password');
      await _secureStorage.delete(key: 'biometric_enabled');
      print('✅ Credenciales biométricas eliminadas');
    } catch (e) {
      print('❌ Error eliminando credenciales biométricas: $e');
    }
  }

  // Login con autenticación biométrica
  Future<AuthResponse> signInWithBiometric() async {
    try {
      // Primero autenticar con biométrica
      final biometricService = BiometricAuthService();
      final biometricType = await biometricService.getBiometricTypeName();
      
      final authenticated = await biometricService.authenticate(
        reason: 'Autentícate con $biometricType para acceder a tu cuenta',
      );

      if (!authenticated) {
        throw Exception('Autenticación biométrica cancelada o fallida');
      }

      // Obtener credenciales guardadas
      final credentials = await getBiometricCredentials();
      if (credentials == null) {
        throw Exception('No hay credenciales guardadas para autenticación biométrica');
      }

      // Hacer login con las credenciales
      return await signIn(
        email: credentials['email']!,
        password: credentials['password']!,
        saveForBiometric: false, // Ya están guardadas
      );
    } catch (e) {
      print('Error en login biométrico: $e');
      rethrow;
    }
  }

  // Login con Google
  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
    } catch (e) {
      print('Error en login con Google: $e');
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> signOut({bool removeBiometric = false}) async {
    try {
      await _supabase.auth.signOut();
      _currentUser = null;
      
      // Limpiar datos locales
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
      
      // Opcionalmente eliminar credenciales biométricas
      if (removeBiometric) {
        await removeBiometricCredentials();
      }
    } catch (e) {
      print('Error cerrando sesión: $e');
    }
  }

  // Verificar si el usuario está autenticado
  Future<bool> checkAuthStatus() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        await _loadUserFromSession(session);
        return true;
      } else {
        // Intentar cargar desde local
        _currentUser = await _loadUserFromLocal();
        return _currentUser != null;
      }
    } catch (e) {
      print('Error verificando autenticación: $e');
      return false;
    }
  }

  // Recuperar contraseña usando OTP (Edge Function)
  Future<void> resetPassword({required String email}) async {
    try {
      print('📧 Solicitando OTP a send-otp para: $email');
      final res = await _supabase.functions.invoke('send-otp', body: {
        'email': email,
      });
      dynamic data = res.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }
      if (data == null || (data is Map && data['ok'] != true)) {
        throw Exception('No se pudo generar el OTP');
      }
      // En desarrollo puede venir dev_otp
      if (data is Map && data['dev_otp'] != null) {
        print('🔧 OTP (dev): ${data['dev_otp']}');
      }
      print('✅ OTP solicitado correctamente');
    } catch (e) {
      print('❌ Error solicitando OTP: $e');
      rethrow;
    }
  }

  // Verificar OTP (Edge Function) y actualizar contraseña desde el servidor
  Future<void> verifyOTPAndResetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      print('🔐 Verificando OTP (verify-otp) para: $email');
      final res = await _supabase.functions.invoke('verify-otp', body: {
        'email': email,
        'otp_code': token,
        'new_password': newPassword,
      });
      dynamic data = res.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }
      if (data == null || (data is Map && data['ok'] != true)) {
        final err = (data is Map ? (data['error'] ?? 'Verificación OTP fallida') : 'Verificación OTP fallida');
        throw Exception(err);
      }
      print('✅ Contraseña actualizada exitosamente (server)');
      await _supabase.auth.signOut();
    } catch (e) {
      print('❌ Error verificando OTP o actualizando contraseña (server): $e');
      rethrow;
    }
  }

  // Actualizar perfil (nombre, avatar, zona horaria) en auth.users (metadata) y tabla users
  Future<void> updateProfile({
    String? name,
    String? avatarUrl,
    String? timezone,
  }) async {
    if (_supabase.auth.currentUser == null) {
      throw Exception('No autenticado');
    }
    final userId = _supabase.auth.currentUser!.id;
    try {
      // Actualizar metadata en auth
      final Map<String, dynamic> metadata = {
        if (name != null) 'name': name,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (timezone != null) 'timezone': timezone,
      };
      if (metadata.isNotEmpty) {
        await _supabase.auth.updateUser(UserAttributes(data: metadata));
      }

      // Actualizar tabla users si existe
      final updateMap = <String, dynamic>{};
      if (name != null) updateMap['name'] = name;
      if (avatarUrl != null) updateMap['avatar'] = avatarUrl;
      if (updateMap.isNotEmpty) {
        await _supabase.from('users').update(updateMap).eq('id', userId);
      }

      // Refrescar cache local
      _currentUser = _currentUser?.copyWith(
        name: name ?? _currentUser!.name,
        avatar: avatarUrl ?? _currentUser!.avatar,
      );
      if (_currentUser != null) await _saveUserToLocal(_currentUser!);
    } catch (e) {
      print('❌ Error actualizando perfil: $e');
      rethrow;
    }
  }
}
