import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service_simple.dart';
import '../models/supabase_models.dart';

/// Servicio para gestionar códigos personalizados del usuario
/// Estos códigos NO se agregan a la base central, son exclusivos del usuario
class UserCustomCodesService {
  static final UserCustomCodesService _instance = UserCustomCodesService._internal();
  factory UserCustomCodesService() => _instance;
  UserCustomCodesService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthServiceSimple _authService = AuthServiceSimple();
  
  // Cache interno para evitar consultas repetitivas
  List<CodigoGrabovoi>? _cachedCustomCodes;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  /// Guardar un código personalizado del usuario
  /// Este código se guarda en user_custom_codes y también se agrega a favoritos
  Future<bool> saveCustomCode({
    required String codigo,
    required String nombre,
    required String categoria,
    String? descripcion,
  }) async {
    if (!_authService.isLoggedIn) {
      print('❌ Usuario no autenticado');
      return false;
    }

    try {
      final userId = _authService.currentUser!.id;

      // 1. Guardar en user_custom_codes
      await _supabase.from('user_custom_codes').insert({
        'user_id': userId,
        'codigo': codigo,
        'nombre': nombre,
        'descripcion': descripcion ?? 'Código personalizado del usuario',
        'categoria': categoria,
      });

      print('✅ Código personalizado guardado: $codigo');

      // Invalidar cache para forzar recarga
      _cachedCustomCodes = null;
      _cacheTime = null;

      // 2. Agregar a favoritos con etiqueta "pilotaje manual"
      // Como usuario_favoritos tiene foreign key a codigos_grabovoi y no podemos
      // agregar códigos personalizados directamente, los códigos personalizados
      // se consideran automáticamente como favoritos y se mostrarán cuando se
      // consulten favoritos con la etiqueta "pilotaje manual"

      return true;
    } catch (e) {
      if (e.toString().contains('duplicate key') || e.toString().contains('unique constraint')) {
        print('⚠️ El código personalizado ya existe para este usuario');
        return false;
      }
      print('❌ Error guardando código personalizado: $e');
      return false;
    }
  }

  /// Obtener todos los códigos personalizados del usuario
  /// Usa cache interno para evitar consultas repetitivas
  Future<List<CodigoGrabovoi>> getUserCustomCodes({bool forceRefresh = false}) async {
    if (!_authService.isLoggedIn) return [];

    // Usar cache si está disponible y no ha expirado
    if (!forceRefresh && 
        _cachedCustomCodes != null && 
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedCustomCodes!;
    }

    try {
      final response = await _supabase
          .from('user_custom_codes')
          .select()
          .eq('user_id', _authService.currentUser!.id)
          .order('created_at', ascending: false);

      final codes = response.map<CodigoGrabovoi>((row) {
        return CodigoGrabovoi(
          id: row['id'].toString(),
          codigo: row['codigo'] as String,
          nombre: row['nombre'] as String,
          descripcion: row['descripcion'] as String? ?? 'Código personalizado del usuario',
          categoria: row['categoria'] as String,
          color: _getCategoryColor(row['categoria'] as String),
        );
      }).toList();
      
      // Actualizar cache
      _cachedCustomCodes = codes;
      _cacheTime = DateTime.now();
      
      return codes;
    } catch (e) {
      print('Error obteniendo códigos personalizados: $e');
      return [];
    }
  }
  
  /// Invalidar el cache de códigos personalizados
  void invalidateCache() {
    _cachedCustomCodes = null;
    _cacheTime = null;
  }

  /// Verificar si un código es personalizado del usuario
  Future<bool> isCustomCode(String codigo) async {
    if (!_authService.isLoggedIn) return false;

    try {
      final response = await _supabase
          .from('user_custom_codes')
          .select('id')
          .eq('user_id', _authService.currentUser!.id)
          .eq('codigo', codigo)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error verificando código personalizado: $e');
      return false;
    }
  }

  /// Eliminar código personalizado
  Future<bool> deleteCustomCode(String codigo) async {
    if (!_authService.isLoggedIn) return false;

    try {
      await _supabase
          .from('user_custom_codes')
          .delete()
          .eq('user_id', _authService.currentUser!.id)
          .eq('codigo', codigo);

      // Invalidar cache después de eliminar
      _cachedCustomCodes = null;
      _cacheTime = null;

      print('✅ Código personalizado eliminado: $codigo');
      return true;
    } catch (e) {
      print('Error eliminando código personalizado: $e');
      return false;
    }
  }

  /// Obtener color por categoría (mismo mapeo que en la app)
  String _getCategoryColor(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'abundancia y prosperidad':
      case 'abundancia':
        return '#FFD700';
      case 'salud y regeneración':
      case 'salud':
        return '#4CAF50';
      case 'amor y relaciones':
      case 'amor':
        return '#E91E63';
      case 'protección energética':
      case 'protección':
        return '#2196F3';
      case 'limpieza y reconexión':
        return '#9C27B0';
      case 'conciencia espiritual':
        return '#00BCD4';
      case 'liberación emocional':
        return '#FF9800';
      default:
        return '#FFD700';
    }
  }
}

