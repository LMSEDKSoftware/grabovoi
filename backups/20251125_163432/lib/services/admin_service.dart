import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AdminService {
  static final SupabaseClient _client = SupabaseConfig.client;
  static final SupabaseClient _serviceClient = SupabaseConfig.serviceClient;

  /// Verificar si el usuario actual es administrador
  static Future<bool> esAdmin() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      // Usar función de Supabase para verificar si es admin
      final response = await _client.rpc('es_admin', params: {'user_uuid': userId});
      return response as bool;
    } catch (e) {
      print('⚠️ Error verificando si es admin: $e');
      // Fallback: buscar directamente en la tabla
      try {
        final userId = _client.auth.currentUser?.id;
        if (userId == null) return false;

        final response = await _serviceClient
            .from('users_admin')
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();

        return response != null;
      } catch (e2) {
        print('❌ Error en fallback de verificación admin: $e2');
        return false;
      }
    }
  }

  /// Agregar un usuario como administrador (solo para service client)
  static Future<void> agregarAdmin(String userId) async {
    try {
      print('👤 Agregando usuario como admin: $userId');
      
      await _serviceClient.from('users_admin').insert({
        'user_id': userId,
      });
      
      print('✅ Usuario agregado como admin');
    } catch (e) {
      print('❌ Error agregando admin: $e');
      rethrow;
    }
  }

  /// Obtener todos los administradores con datos de la tabla users (solo para admins)
  static Future<List<Map<String, dynamic>>> getAdmins() async {
    try {
      if (!await esAdmin()) {
        throw Exception('No tienes permisos para ver administradores');
      }

      // Obtener admins con JOIN a la tabla users para obtener email y nombre
      final response = await _serviceClient
          .from('users_admin')
          .select('''
            id,
            user_id,
            users!inner(id, email, name, created_at)
          ''')
          .order('id', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error obteniendo admins: $e');
      return [];
    }
  }

  /// Remover permisos de administrador (solo para admins)
  static Future<void> removerAdmin(String userId) async {
    try {
      if (!await esAdmin()) {
        throw Exception('No tienes permisos para remover administradores');
      }

      await _serviceClient
          .from('users_admin')
          .delete()
          .eq('user_id', userId);

      print('✅ Permisos de admin removidos');
    } catch (e) {
      print('❌ Error removiendo admin: $e');
      rethrow;
    }
  }
}

