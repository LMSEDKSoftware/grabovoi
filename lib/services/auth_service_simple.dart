import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart' as app_models;

class AuthServiceSimple {
  static final AuthServiceSimple _instance = AuthServiceSimple._internal();
  factory AuthServiceSimple() => _instance;
  AuthServiceSimple._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
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
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadUserFromSession(response.session!);
      }

      return response;
    } catch (e) {
      print('Error en login: $e');
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
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _currentUser = null;
      
      // Limpiar datos locales
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
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
}
