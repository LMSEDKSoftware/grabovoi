import 'package:supabase_flutter/supabase_flutter.dart';
import 'cache_service.dart';
import 'auth_service_simple.dart';

/// Servicio centralizado para cargar todos los datos del usuario de una vez
/// Evita múltiples consultas duplicadas desde diferentes pantallas
class UserDataService {
  static final UserDataService _instance = UserDataService._internal();
  factory UserDataService() => _instance;
  UserDataService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthServiceSimple _authService = AuthServiceSimple();
  final CacheService _cacheService = CacheService();
  
  // Debouncing: evitar múltiples llamadas simultáneas
  Future<Map<String, dynamic>>? _loadingFuture;
  DateTime? _lastLoadTime;
  static const Duration _debounceDuration = Duration(seconds: 2);
  
  /// Cargar todos los datos del usuario de una vez (con caché y debouncing)
  Future<Map<String, dynamic>> loadUserData({bool forceRefresh = false}) async {
    if (!_authService.isLoggedIn) {
      return {};
    }
    
    final userId = _authService.currentUser!.id;
    
    // Debouncing: si hay una carga en progreso, esperar a que termine
    if (_loadingFuture != null && !forceRefresh) {
      print('⏳ Esperando carga previa de datos del usuario...');
      return await _loadingFuture!;
    }
    
    // Si se cargó recientemente y no es force refresh, usar caché
    if (!forceRefresh && 
        _lastLoadTime != null && 
        DateTime.now().difference(_lastLoadTime!) < _debounceDuration) {
      print('📦 Usando datos del usuario desde caché (cargados hace ${DateTime.now().difference(_lastLoadTime!).inSeconds}s)');
      return await _cacheService.getUserDataBatch(userId);
    }
    
    // Cargar datos
    _loadingFuture = _loadUserDataInternal(userId);
    try {
      final result = await _loadingFuture!;
      _lastLoadTime = DateTime.now();
      return result;
    } finally {
      _loadingFuture = null;
    }
  }
  
  Future<Map<String, dynamic>> _loadUserDataInternal(String userId) async {
    try {
      // Usar batch query del CacheService
      final batchData = await _cacheService.getUserDataBatch(userId);
      return batchData;
    } catch (e) {
      print('❌ Error cargando datos del usuario: $e');
      return {};
    }
  }
  
  /// Invalidar caché y forzar recarga
  void invalidateCache() {
    if (_authService.isLoggedIn) {
      _cacheService.invalidateUserCache(_authService.currentUser!.id);
    }
    _lastLoadTime = null;
    _loadingFuture = null;
  }
}


