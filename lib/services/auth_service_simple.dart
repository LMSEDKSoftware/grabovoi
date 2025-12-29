import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:io' show Platform;
import '../models/user_model.dart' as app_models;
import '../config/supabase_config.dart';
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
      // Si no existe, crear el usuario (esto incluye usuarios de OAuth/Google)
      await _createUserFromSession(session);
    }
  }

  // Crear usuario desde sesión (incluye usuarios de OAuth/Google)
  Future<void> _createUserFromSession(Session session) async {
    try {
      // Obtener nombre de Google OAuth si está disponible
      String userName = session.user.userMetadata?['name'] ?? 
                       session.user.userMetadata?['full_name'] ??
                       session.user.email?.split('@')[0] ?? 
                       'Usuario';
      
      // Obtener avatar de Google si está disponible
      String? avatarUrl = session.user.userMetadata?['avatar_url'] ?? 
                         session.user.userMetadata?['picture'];
      
      final newUser = app_models.User(
        id: session.user.id,
        email: session.user.email ?? '',
        name: userName,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isEmailVerified: session.user.emailConfirmedAt != null,
        avatar: avatarUrl,
      );

      // Intentar insertar en la tabla users
      try {
        final userJson = newUser.toJson();
        userJson['confirmado-correo'] = false; // Inicializar como no confirmado
        await _supabase.from('users').insert(userJson);
        _currentUser = newUser;
        await _saveUserToLocal(_currentUser!);
        print('✅ Usuario creado en tabla users (OAuth/Google) (confirmado-correo = FALSE)');
      } catch (insertError) {
        // Si falla por duplicado, intentar cargar el usuario existente
        if (insertError.toString().contains('duplicate') || insertError.toString().contains('unique')) {
          print('⚠️ Usuario ya existe, cargando...');
          try {
            final userData = await _supabase
                .from('users')
                .select()
                .eq('id', session.user.id)
                .single();
            _currentUser = app_models.User.fromJson(userData);
            await _saveUserToLocal(_currentUser!);
            print('✅ Usuario cargado después de intento de inserción');
          } catch (loadError) {
            // Si también falla la carga, usar datos de sesión
            _currentUser = newUser;
            await _saveUserToLocal(_currentUser!);
            print('⚠️ Usuario creado solo localmente');
          }
        } else {
          throw insertError;
        }
      }
    } catch (e) {
      print('❌ Error creando usuario en tabla users: $e');
      // Si falla, usar solo datos de sesión
      _currentUser = app_models.User(
        id: session.user.id,
        email: session.user.email ?? '',
        name: session.user.userMetadata?['name'] ?? 
              session.user.userMetadata?['full_name'] ??
              session.user.email?.split('@')[0] ?? 
              'Usuario',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isEmailVerified: session.user.emailConfirmedAt != null,
        avatar: session.user.userMetadata?['avatar_url'] ?? 
                session.user.userMetadata?['picture'],
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
      // Mantener la llamada actual a signUp (aunque Supabase ya no envíe correos)
      // Usar URLs sin puerto específico para que funcione con cualquier puerto dinámico de Flutter Web
      String? emailRedirectTo;
      if (kIsWeb) {
        // Detectar si estamos en producción o desarrollo usando Uri.base (funciona en todas las plataformas)
        final hostname = Uri.base.host;
        final isProduction = !hostname.contains('localhost') && !hostname.contains('127.0.0.1');
        emailRedirectTo = isProduction
            ? 'https://manigrab.app/auth/callback'
            : 'http://localhost/auth/callback';
      } else {
        emailRedirectTo = 'com.manifestacion.grabovoi://login-callback';
      }

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
        emailRedirectTo: emailRedirectTo,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('No se pudo crear el usuario');
      }

      print('✅ Usuario registrado en auth.users');

      // Crear / cargar usuario en tabla users
      try {
        // Esperar un instante por triggers
        await Future.delayed(const Duration(seconds: 1));
        final userData = await _supabase
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (userData != null) {
          _currentUser = app_models.User.fromJson(userData);
          print('✅ Usuario cargado desde tabla users');
        } else {
          print('⚠️ Usuario no encontrado en tabla users, creando manualmente...');
          final newUser = app_models.User(
            id: user.id,
            email: email,
            name: name,
            createdAt: DateTime.now(),
            isEmailVerified: false,
          );
          // Insertar usuario con campo confirmado-correo = FALSE
          final userJson = newUser.toJson();
          userJson['confirmado-correo'] = false;
          await _supabase.from('users').insert(userJson);
          _currentUser = newUser;
          print('✅ Usuario creado manualmente en tabla users (confirmado-correo = FALSE)');
        }
      } catch (e) {
        print('⚠️ Error manejando usuario en tabla users: $e');
        final fallbackUser = app_models.User(
          id: user.id,
          email: email,
          name: name,
          createdAt: DateTime.now(),
          isEmailVerified: false,
        );
        _currentUser = fallbackUser;
      }

      if (_currentUser != null) {
        await _saveUserToLocal(_currentUser!);
      }

      // Verificar estado de suscripción (no debe romper el registro)
      try {
        await SubscriptionService().checkSubscriptionStatus();
        print('✅ Estado de suscripción verificado después de registro');
      } catch (e) {
        print('⚠️ Error verificando suscripción después de registro: $e');
      }

      // Enviar email de bienvenida/confirmación vía Edge Function (SendGrid)
      try {
        print('📧 Invocando send-email para $email');
        
        // Construir action_url para el correo de bienvenida
        String? actionUrl;
        if (kIsWeb) {
          final hostname = Uri.base.host;
          final isProduction = !hostname.contains('localhost') && !hostname.contains('127.0.0.1');
          actionUrl = isProduction
              ? 'https://manigrab.app/auth/callback'
              : 'http://localhost/auth/callback';
        } else {
          actionUrl = 'com.manifestacion.grabovoi://login-callback';
        }
        
        final res = await _supabase.functions.invoke('send-email', body: {
          'to': email,
          'template': 'welcome_or_confirm',
          'userId': user.id,
          'name': name,
          'actionUrl': actionUrl,
        });

        dynamic data = res.data;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {}
        }
        if (data is Map && data['ok'] != true) {
          throw Exception('email_send_failed');
        }
      } catch (e) {
        print('❌ Error enviando correo de bienvenida/confirmación: $e');
        // Propagar un error controlado para que la UI muestre mensaje genérico
        throw Exception('email_send_failed');
      }

      // Set flag to force login on next app start y cerrar sesión automática
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('force_login', true);
      await _supabase.auth.signOut();

      return response;
    } catch (e) {
      print('❌ Error en registro: $e');
      print('❌ Tipo de error: ${e.runtimeType}');
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
        // Verificar si el usuario ha confirmado su correo
        try {
          final userData = await _supabase
              .from('users')
              .select('"confirmado-correo"')
              .eq('id', response.user!.id)
              .maybeSingle();
          
          final emailConfirmado = userData != null && 
                                  userData['confirmado-correo'] == true;
          
          if (!emailConfirmado) {
            // Cerrar sesión si el email no está confirmado
            await _supabase.auth.signOut();
            throw Exception('EMAIL_NOT_CONFIRMED');
          }
        } catch (e) {
          if (e.toString().contains('EMAIL_NOT_CONFIRMED')) {
            rethrow;
          }
          // Si hay error al verificar, continuar (no bloquear login por error de DB)
          print('⚠️ Error verificando confirmado-correo: $e');
        }
        
        await _loadUserFromSession(response.session!);
        
        // Guardar credenciales de forma segura si se solicita
        if (saveForBiometric) {
          await saveBiometricCredentials(email: email, password: password);
        }
        // Clear force_login flag after successful login
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('force_login');
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
      print('❌ Error en login: $e');
      print('❌ Tipo de error: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
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
      print('🔐 Iniciando login con Google...');
      
      // Configurar redirect URL según la plataforma
      // Usar URLs sin puerto específico para que funcione con cualquier puerto dinámico de Flutter Web
      String redirectTo;
      if (kIsWeb) {
        // Detectar si estamos en producción o desarrollo usando Uri.base (funciona en todas las plataformas)
        final hostname = Uri.base.host;
        final isProduction = !hostname.contains('localhost') && !hostname.contains('127.0.0.1');
        redirectTo = isProduction
            ? 'https://manigrab.app/auth/callback'
            : 'http://localhost/auth/callback';
        print('🌐 Usando redirect para web: $redirectTo');
      } else {
        // En móvil, usar deep link
        redirectTo = 'com.manifestacion.grabovoi://login-callback';
        print('📱 Usando redirect para móvil: $redirectTo');
      }
      
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        authScreenLaunchMode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );
      print('✅ Redirección a Google iniciada');
    } catch (e) {
      print('❌ Error en login con Google: $e');
      // Si el error es que el proveedor no está habilitado, mostrar mensaje más claro
      if (e.toString().contains('not enabled') || e.toString().contains('Unsupported provider')) {
        throw Exception('Google OAuth no está habilitado en Supabase. Por favor, habilítalo en el Dashboard de Supabase > Authentication > Providers > Google');
      }
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

  // SOLUCIÓN: Usar Edge Function que envía email a través del servidor personalizado (whitelist)
  Future<void> resetPassword({required String email}) async {
    try {
      print('📧 Solicitando recuperación de contraseña: $email');
      print('   Usando Edge Function send-otp (envía email desde servidor personalizado)');
      
      // Determinar redirectTo según el entorno
      String redirectTo;
      if (kIsWeb) {
        // Detectar si estamos en desarrollo (localhost) o producción
        final currentUrl = Uri.base;
        final isLocalhost = currentUrl.host == 'localhost' || 
                           currentUrl.host == '127.0.0.1' ||
                           currentUrl.host.isEmpty;
        
        if (isLocalhost) {
          // En desarrollo, incluir el puerto actual para que el link funcione en Chrome
          final port = currentUrl.hasPort ? ':${currentUrl.port}' : '';
          redirectTo = 'http://localhost${port}/auth/callback';
          print('   🔧 Modo desarrollo detectado - usando localhost${port}');
        } else {
          // En producción, usar el dominio de producción
          redirectTo = 'https://manigrab.app/auth/callback';
          print('   🌐 Modo producción detectado - usando manigrab.app');
        }
      } else {
        // En móvil, usar deep link
        redirectTo = 'com.manifestacion.grabovoi://login-callback';
        print('   📱 Modo móvil detectado - usando deep link');
      }
      
      print('   🔗 RedirectTo: $redirectTo');
      
      // Llamar a la Edge Function que genera el recovery link oficial y lo envía por email
      final res = await _supabase.functions.invoke('send-otp', body: {
        'email': email,
        'redirectTo': redirectTo, // Pasar el redirectTo desde el cliente
      });
      
      dynamic data = res.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (e) {
          print('   ⚠️ Error parseando JSON: $e');
        }
      }
      
      if (res.status != 200) {
        final errorMsg = data is Map ? (data['error'] ?? 'Error desconocido') : 'Error en la solicitud';
        print('❌ Error HTTP ${res.status}: $errorMsg');
        // Por seguridad, no revelar si el email existe o no
        print('⚠️  Error capturado, pero respondiendo éxito por seguridad');
        return;
      }
      
      if (data == null || (data is Map && data['ok'] != true)) {
        final errorMsg = data is Map ? (data['error'] ?? 'No se pudo enviar el email') : 'Respuesta inválida';
        print('❌ Error en respuesta: $errorMsg');
        // Por seguridad, no revelar si el email existe o no
        print('⚠️  Error capturado, pero respondiendo éxito por seguridad');
        return;
      }
      
      print('✅ Solicitud de recuperación enviada correctamente');
      print('   Revisa tu email para obtener el link de recuperación');
      
    } catch (e, stackTrace) {
      print('❌ Error solicitando recuperación: $e');
      print('📚 Stack trace: $stackTrace');
      // Por seguridad, siempre responder éxito aunque haya error
      // (no revelar si el email existe o no)
      print('⚠️  Error capturado, pero respondiendo éxito por seguridad');
    }
  }

  // SISTEMA NUEVO: Actualizar contraseña usando flujo OFICIAL de Supabase
  // Este método recibe un recovery_token del email y la nueva contraseña
  // Usa el método estándar updateUser() que SIEMPRE funciona
  Future<void> updatePasswordWithRecoveryToken({
    required String recoveryToken,
    required String newPassword,
  }) async {
    try {
      print('🔐 Actualizando contraseña con token de recuperación...');
      print('   Token: ${recoveryToken.substring(0, 20)}...');
      print('   Nueva contraseña: ${newPassword.length} caracteres');
      
      // Usar el endpoint oficial que hace todo el proceso
      final res = await _supabase.functions.invoke('auth-update-password', body: {
        'recovery_token': recoveryToken,
        'new_password': newPassword,
      });
      
      dynamic data = res.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }
      
      if (res.status != 200 || (data is Map && data['ok'] != true)) {
        final err = (data is Map ? (data['error'] ?? 'Error actualizando contraseña') : 'Error actualizando contraseña');
        final details = data is Map ? (data['details'] ?? '') : '';
        print('❌ Error HTTP ${res.status}: $err');
        if (details.isNotEmpty) {
          print('   Detalles: $details');
        }
        throw Exception(err);
      }
      
      print('✅ Contraseña actualizada exitosamente');
      print('   La contraseña está lista para usar');
      
    } catch (e, stackTrace) {
      print('❌ Error actualizando contraseña: $e');
      print('📚 Stack trace: $stackTrace');
      rethrow;
    }
  }

  // NUEVO: Verificar OTP y obtener recovery_link (NO actualiza contraseña aquí)
  Future<String> verifyOTPAndGetRecoveryLink({
    required String email,
    required String token,
  }) async {
    try {
      print('🔐 Verificando OTP para obtener recovery link...');
      print('   Email: $email');
      print('   Token OTP: ${token.substring(0, 3)}...');
      
      // Llamar a la Edge Function que verifica OTP y devuelve recovery_link
      final res = await _supabase.functions.invoke('verify-otp', body: {
        'email': email,
        'otp_code': token,
      });
      
      dynamic data = res.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }
      
      if (res.status != 200 || (data is Map && data['ok'] != true)) {
        final err = (data is Map ? (data['error'] ?? 'Verificación OTP fallida') : 'Verificación OTP fallida');
        throw Exception(err);
      }
      
      // Nueva implementación: verificar continue_url (solución IVO)
      final continueUrl = (data as Map)['continue_url'] as String?;
      final recoveryLink = (data as Map)['recovery_link'] as String?; // Fallback para compatibilidad
      
      final urlToOpen = continueUrl ?? recoveryLink;
      
      if (urlToOpen == null || urlToOpen.isEmpty) {
        throw Exception('Continue URL no recibida del servidor');
      }
      
      print('✅ OTP verificado, continue URL obtenida: ${urlToOpen.substring(0, 50)}...');
      return urlToOpen;
      
    } catch (e, stackTrace) {
      print('❌ Error en verificación OTP: $e');
      print('📚 Stack trace: $stackTrace');
      rethrow;
    }
  }

  // DEPRECATED: Mantener por compatibilidad pero no usar
  @Deprecated('Usar verifyOTPAndGetRecoveryLink en su lugar')
  Future<void> verifyOTPAndResetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    // Este método ya no funciona con el nuevo flujo
    throw Exception('Este método está deprecado. Usa verifyOTPAndGetRecoveryLink y luego updateUser con sesión de recovery');
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
