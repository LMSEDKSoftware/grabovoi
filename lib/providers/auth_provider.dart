import 'package:flutter/foundation.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// Mock User class para desarrollo sin Supabase
class MockUser {
  final String id;
  final String? email;
  MockUser({required this.id, this.email});
}

class AuthProvider with ChangeNotifier {
  // final _supabase = Supabase.instance.client;
  MockUser? _user;
  bool _isLoading = false;

  MockUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    // En modo mock, crear usuario automáticamente
    _user = MockUser(id: 'mock-user-id', email: 'usuario@ejemplo.com');
  }

  Future<void> signInAnonymously() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Mock: crear usuario anónimo
      await Future.delayed(const Duration(milliseconds: 500));
      _user = MockUser(id: 'mock-anonymous-${DateTime.now().millisecondsSinceEpoch}');
    } catch (e) {
      print('Error en inicio de sesión anónimo: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Mock: simular inicio de sesión
      await Future.delayed(const Duration(milliseconds: 500));
      _user = MockUser(id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}', email: email);
    } catch (e) {
      print('Error en inicio de sesión: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Mock: simular registro
      await Future.delayed(const Duration(milliseconds: 500));
      _user = MockUser(id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}', email: email);
    } catch (e) {
      print('Error en registro: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Mock: cerrar sesión
      await Future.delayed(const Duration(milliseconds: 300));
      _user = null;
    } catch (e) {
      print('Error cerrando sesión: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? getUserId() {
    return _user?.id;
  }
}

