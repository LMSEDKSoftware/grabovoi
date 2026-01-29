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

  // ===== MANIGRAB LOVERS (Suscripciones otorgadas por admin) =====

  /// Buscar usuario por email y obtener su UID
  static Future<String?> buscarUsuarioPorEmail(String email) async {
    try {
      if (!await esAdmin()) {
        throw Exception('No tienes permisos para buscar usuarios');
      }

      // Buscar en la tabla users
      final response = await _serviceClient
          .from('users')
          .select('id')
          .eq('email', email.toLowerCase().trim())
          .maybeSingle();

      if (response != null) {
        return response['id'] as String;
      }

      return null;
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
      if (!await esAdmin()) {
        throw Exception('No tienes permisos para otorgar suscripciones');
      }

      // Validar tipo
      if (tipo != 'monthly' && tipo != 'yearly') {
        throw Exception('Tipo de suscripción inválido. Debe ser "monthly" o "yearly"');
      }

      // Buscar usuario por email
      final userId = await buscarUsuarioPorEmail(email);
      if (userId == null) {
        throw Exception('Usuario no encontrado con el email: $email');
      }

      // Calcular fecha de expiración
      final DateTime expiryDate;
      final String productId;
      
      if (tipo == 'monthly') {
        expiryDate = DateTime.now().add(const Duration(days: 30));
        productId = 'manigrab_lovers_monthly';
      } else {
        expiryDate = DateTime.now().add(const Duration(days: 365));
        productId = 'manigrab_lovers_yearly';
      }

      // Desactivar suscripciones activas anteriores del usuario
      await _serviceClient
          .from('user_subscriptions')
          .update({'is_active': false})
          .eq('user_id', userId)
          .eq('is_active', true);

      // Crear nueva suscripción ManiGrabLovers
      await _serviceClient.from('user_subscriptions').insert({
        'user_id': userId,
        'product_id': productId,
        'purchase_id': 'manigrab_lovers_admin_${DateTime.now().millisecondsSinceEpoch}',
        'transaction_date': DateTime.now().toIso8601String(),
        'expires_at': expiryDate.toIso8601String(),
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Suscripción ManiGrabLovers otorgada: $email - $tipo hasta $expiryDate');
    } catch (e) {
      print('❌ Error otorgando suscripción ManiGrabLovers: $e');
      rethrow;
    }
  }

  /// Obtener información de suscripción ManiGrabLovers de un usuario
  static Future<Map<String, dynamic>?> obtenerSuscripcionManiGrabLovers(String email) async {
    try {
      if (!await esAdmin()) {
        throw Exception('No tienes permisos para ver suscripciones');
      }

      final userId = await buscarUsuarioPorEmail(email);
      if (userId == null) {
        return null;
      }

      final response = await _serviceClient
          .from('user_subscriptions')
          .select()
          .eq('user_id', userId)
          // Usamos filter con operador IN para evitar problemas con métodos helpers
          .filter(
            'product_id',
            'in',
            '("manigrab_lovers_monthly","manigrab_lovers_yearly")',
          )
          .eq('is_active', true)
          .order('expires_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      print('❌ Error obteniendo suscripción ManiGrabLovers: $e');
      return null;
    }
  }

  /// Revocar suscripción ManiGrabLovers de un usuario
  static Future<void> revocarManiGrabLovers(String email) async {
    try {
      if (!await esAdmin()) {
        throw Exception('No tienes permisos para revocar suscripciones');
      }

      final userId = await buscarUsuarioPorEmail(email);
      if (userId == null) {
        throw Exception('Usuario no encontrado con el email: $email');
      }

      await _serviceClient
          .from('user_subscriptions')
          .update({'is_active': false})
          .eq('user_id', userId)
          .filter(
            'product_id',
            'in',
            '("manigrab_lovers_monthly","manigrab_lovers_yearly")',
          )
          .eq('is_active', true);

      print('✅ Suscripción ManiGrabLovers revocada: $email');
    } catch (e) {
      print('❌ Error revocando suscripción ManiGrabLovers: $e');
      rethrow;
    }
  }

  /// Listar todos los usuarios con suscripción ManiGrabLovers activa
  static Future<List<Map<String, dynamic>>> listarManiGrabLovers() async {
    try {
      if (!await esAdmin()) {
        throw Exception('No tienes permisos para listar suscripciones');
      }

      // 1) Traer suscripciones activas desde user_subscriptions
      final response = await _serviceClient
          .from('user_subscriptions')
          .select('id, user_id, product_id, expires_at, created_at')
          .filter(
            'product_id',
            'in',
            '("manigrab_lovers_monthly","manigrab_lovers_yearly")',
          )
          .eq('is_active', true)
          .order('expires_at', ascending: false);

      final List<Map<String, dynamic>> raw =
          List<Map<String, dynamic>>.from(response);

      // 2) Enriquecer cada fila con datos de la tabla users (email, name)
      final List<Map<String, dynamic>> result = [];

      for (final row in raw) {
        final userId = row['user_id'] as String?;
        Map<String, dynamic>? userData;

        if (userId != null) {
          try {
            final userResponse = await _serviceClient
                .from('users')
                .select('email, name')
                .eq('id', userId)
                .maybeSingle();

            if (userResponse != null) {
              userData = Map<String, dynamic>.from(userResponse);
            }
          } catch (e) {
            print('⚠️ Error obteniendo datos de usuario para $userId: $e');
          }
        }

        result.add({
          ...row,
          'user_email': userData?['email'],
          'user_name': userData?['name'],
        });
      }

      return result;
    } catch (e) {
      print('❌ Error listando suscripciones ManiGrabLovers: $e');
      return [];
    }
  }
}

