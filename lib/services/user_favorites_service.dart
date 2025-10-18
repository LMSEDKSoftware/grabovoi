import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart' as app_models;
import 'auth_service_simple.dart';

class UserFavoritesService {
  static final UserFavoritesService _instance = UserFavoritesService._internal();
  factory UserFavoritesService() => _instance;
  UserFavoritesService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthServiceSimple _authService = AuthServiceSimple();

  // ===== FAVORITOS DEL USUARIO =====

  /// Obtener favoritos del usuario
  Future<List<String>> getUserFavorites() async {
    if (!_authService.isLoggedIn) return [];

    try {
      final response = await _supabase
          .from('user_favorites')
          .select('code_id')
          .eq('user_id', _authService.currentUser!.id)
          .order('added_at', ascending: false);

      return response.map((item) => item['code_id'] as String).toList();
    } catch (e) {
      print('Error obteniendo favoritos: $e');
      return [];
    }
  }

  /// Agregar código a favoritos
  Future<bool> addToFavorites(String codeId) async {
    if (!_authService.isLoggedIn) return false;

    try {
      await _supabase.from('user_favorites').insert({
        'user_id': _authService.currentUser!.id,
        'code_id': codeId,
      });

      print('✅ Código agregado a favoritos: $codeId');
      return true;
    } catch (e) {
      if (e.toString().contains('duplicate key')) {
        print('⚠️ El código ya está en favoritos');
        return false;
      }
      print('Error agregando a favoritos: $e');
      return false;
    }
  }

  /// Remover código de favoritos
  Future<bool> removeFromFavorites(String codeId) async {
    if (!_authService.isLoggedIn) return false;

    try {
      await _supabase
          .from('user_favorites')
          .delete()
          .eq('user_id', _authService.currentUser!.id)
          .eq('code_id', codeId);

      print('✅ Código removido de favoritos: $codeId');
      return true;
    } catch (e) {
      print('Error removiendo de favoritos: $e');
      return false;
    }
  }

  /// Verificar si un código está en favoritos
  Future<bool> isFavorite(String codeId) async {
    if (!_authService.isLoggedIn) return false;

    try {
      final response = await _supabase
          .from('user_favorites')
          .select('id')
          .eq('user_id', _authService.currentUser!.id)
          .eq('code_id', codeId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error verificando favorito: $e');
      return false;
    }
  }

  /// Alternar estado de favorito
  Future<bool> toggleFavorite(String codeId) async {
    final isCurrentlyFavorite = await isFavorite(codeId);
    
    if (isCurrentlyFavorite) {
      return await removeFromFavorites(codeId);
    } else {
      return await addToFavorites(codeId);
    }
  }

  /// Obtener favoritos con información completa
  Future<List<Map<String, dynamic>>> getFavoritesWithDetails() async {
    if (!_authService.isLoggedIn) return [];

    try {
      final response = await _supabase
          .from('user_favorites')
          .select('''
            code_id,
            added_at,
            codigos_grabovoi!inner(
              id,
              codigo,
              nombre,
              descripcion,
              categoria,
              color
            )
          ''')
          .eq('user_id', _authService.currentUser!.id)
          .order('added_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error obteniendo favoritos con detalles: $e');
      return [];
    }
  }

  /// Limpiar todos los favoritos
  Future<bool> clearAllFavorites() async {
    if (!_authService.isLoggedIn) return false;

    try {
      await _supabase
          .from('user_favorites')
          .delete()
          .eq('user_id', _authService.currentUser!.id);

      print('✅ Todos los favoritos eliminados');
      return true;
    } catch (e) {
      print('Error limpiando favoritos: $e');
      return false;
    }
  }

  /// Obtener cantidad de favoritos
  Future<int> getFavoritesCount() async {
    if (!_authService.isLoggedIn) return 0;

    try {
      final response = await _supabase
          .from('user_favorites')
          .select('id')
          .eq('user_id', _authService.currentUser!.id);

      return response.length;
    } catch (e) {
      print('Error obteniendo cantidad de favoritos: $e');
      return 0;
    }
  }

  /// Obtener favoritos por categoría
  Future<Map<String, List<Map<String, dynamic>>>> getFavoritesByCategory() async {
    if (!_authService.isLoggedIn) return {};

    try {
      final response = await _supabase
          .from('user_favorites')
          .select('''
            code_id,
            added_at,
            codigos_grabovoi!inner(
              id,
              codigo,
              nombre,
              descripcion,
              categoria,
              color
            )
          ''')
          .eq('user_id', _authService.currentUser!.id)
          .order('added_at', ascending: false);

      final Map<String, List<Map<String, dynamic>>> favoritesByCategory = {};
      
      for (final item in response) {
        final categoria = item['codigos_grabovoi']['categoria'] as String;
        if (!favoritesByCategory.containsKey(categoria)) {
          favoritesByCategory[categoria] = [];
        }
        favoritesByCategory[categoria]!.add(item);
      }

      return favoritesByCategory;
    } catch (e) {
      print('Error obteniendo favoritos por categoría: $e');
      return {};
    }
  }
}
