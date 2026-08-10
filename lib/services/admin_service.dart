import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AdminService {
  static final SupabaseClient _client = SupabaseConfig.client;

  static Future<Map<String, dynamic>> _invoke(String action, [Map<String, dynamic>? params]) async {
    final response = await _client.functions.invoke(
      'admin-users',
      body: {'action': action, ...?params},
    );
    if (response.status != 200) {
      final error = (response.data is Map) ? response.data['error'] : response.data;
      throw Exception(error?.toString() ?? 'Error en admin-users ($action)');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Verificar si el usuario actual es administrador
  static Future<bool> esAdmin() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _client.rpc('es_admin', params: {'user_uuid': userId});
      return response as bool;
    } catch (e) {
      print('⚠️ Error verificando si es admin: $e');
      return false;
    }
  }

  /// Agregar un usuario como administrador (requiere ser admin; validado server-side)
  static Future<void> agregarAdmin(String userId) async {
    try {
      print('👤 Agregando usuario como admin: $userId');
      await _invoke('add_admin', {'userId': userId});
      print('✅ Usuario agregado como admin');
    } catch (e) {
      print('❌ Error agregando admin: $e');
      rethrow;
    }
  }

  /// Obtener todos los administradores con datos de la tabla users (solo para admins)
  static Future<List<Map<String, dynamic>>> getAdmins() async {
    try {
      final result = await _invoke('list_admins');
      return List<Map<String, dynamic>>.from(result['data'] as List);
    } catch (e) {
      print('❌ Error obteniendo admins: $e');
      return [];
    }
  }

  /// Remover permisos de administrador (solo para admins)
  static Future<void> removerAdmin(String userId) async {
    try {
      await _invoke('remove_admin', {'userId': userId});
      print('✅ Permisos de admin removidos');
    } catch (e) {
      print('❌ Error removiendo admin: $e');
      rethrow;
    }
  }

  // ===== MANIGRAB LOVERS (Suscripciones otorgadas por admin) =====

  /// Buscar usuario por email y obtener su UID (solo para admins)
  static Future<String?> buscarUsuarioPorEmail(String email) async {
    try {
      final result = await _invoke('search_user_by_email', {'email': email});
      return result['userId'] as String?;
    } catch (e) {
      print('❌ Error buscando usuario por email: $e');
      rethrow;
    }
  }

  /// Otorgar suscripción ManiGrabLovers a un usuario
  ///
  /// [email] Email del usuario al que se le otorgará la suscripción
  /// [tipo] 'monthly' para mensual, 'yearly' para anual
  static Future<void> otorgarManiGrabLovers(String email, String tipo) async {
    try {
      if (tipo != 'monthly' && tipo != 'yearly') {
        throw Exception('Tipo de suscripción inválido. Debe ser "monthly" o "yearly"');
      }
      final result = await _invoke('grant_subscription', {'email': email, 'tipo': tipo});
      print('✅ Suscripción ManiGrabLovers otorgada: $email - $tipo hasta ${result['expiresAt']}');
    } catch (e) {
      print('❌ Error otorgando suscripción ManiGrabLovers: $e');
      rethrow;
    }
  }

  /// Obtener información de suscripción ManiGrabLovers de un usuario
  static Future<Map<String, dynamic>?> obtenerSuscripcionManiGrabLovers(String email) async {
    try {
      final result = await _invoke('get_subscription', {'email': email});
      return result['data'] as Map<String, dynamic>?;
    } catch (e) {
      print('❌ Error obteniendo suscripción ManiGrabLovers: $e');
      return null;
    }
  }

  /// Revocar suscripción ManiGrabLovers de un usuario
  static Future<void> revocarManiGrabLovers(String email) async {
    try {
      await _invoke('revoke_subscription', {'email': email});
      print('✅ Suscripción ManiGrabLovers revocada: $email');
    } catch (e) {
      print('❌ Error revocando suscripción ManiGrabLovers: $e');
      rethrow;
    }
  }

  /// Listar todos los usuarios con suscripción ManiGrabLovers activa
  static Future<List<Map<String, dynamic>>> listarManiGrabLovers() async {
    try {
      final result = await _invoke('list_subscriptions');
      return List<Map<String, dynamic>>.from(result['data'] as List);
    } catch (e) {
      print('❌ Error listando suscripciones ManiGrabLovers: $e');
      return [];
    }
  }
}
