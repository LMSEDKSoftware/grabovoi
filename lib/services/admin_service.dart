import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
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

  // ===== FOUNDERS EDITION (Origen 369): pago único vitalicio vía Hotmart =====

  /// Otorgar Founders Edition (acceso premium vitalicio + insignia
  /// founder_369) a un usuario, tras confirmar su pago único por Hotmart.
  static Future<void> otorgarFoundersEdition(String email) async {
    try {
      final result = await _invoke('grant_founder', {'email': email});
      print('✅ Founders Edition otorgada: $email hasta ${result['expiresAt']}');
    } catch (e) {
      print('❌ Error otorgando Founders Edition: $e');
      rethrow;
    }
  }

  /// Revocar Founders Edition de un usuario
  static Future<void> revocarFoundersEdition(String email) async {
    try {
      await _invoke('revoke_founder', {'email': email});
      print('✅ Founders Edition revocada: $email');
    } catch (e) {
      print('❌ Error revocando Founders Edition: $e');
      rethrow;
    }
  }

  /// Listar todos los usuarios con Founders Edition activa
  static Future<List<Map<String, dynamic>>> listarFounders() async {
    try {
      final result = await _invoke('list_founders');
      return List<Map<String, dynamic>>.from(result['data'] as List);
    } catch (e) {
      print('❌ Error listando Founders: $e');
      return [];
    }
  }

  /// Enviar un push de prueba al propio admin (usado por "Probar
  /// Notificaciones"). El push secret nunca sale del servidor.
  static Future<void> sendTestNotification({
    required String title,
    required String body,
  }) async {
    await _invoke('send_test_notification', {'title': title, 'body': body});
  }

  /// Anunciar el Código Especial del Mes a todos los usuarios (broadcast).
  static Future<void> broadcastSpecialCode({
    required String codigo,
    String? nombre,
  }) async {
    await _invoke('broadcast_special_code', {'codigo': codigo, 'nombre': nombre ?? ''});
  }

  /// Notifica al usuario que reportó un código cuando su reporte cambia de
  /// estatus (push real vía notify_push_from_db, no historial local).
  static Future<void> notifyReportStatus({
    required String userId,
    required String title,
    required String body,
  }) async {
    await _invoke('notify_report_status', {'userId': userId, 'title': title, 'body': body});
  }

  // ===== MURAL: CRUD (solo admin) =====

  /// Sube una imagen para una publicación del mural (server-side, service
  /// role) y retorna su URL pública. Usa bytes en vez de dart:io File para
  /// funcionar también en Flutter Web, no solo en móvil.
  static Future<String> muralUploadImage(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final ext = imageFile.name.contains('.') ? imageFile.name.split('.').last : 'jpg';
    final result = await _invoke('mural_upload_image', {
      'fileName': 'imagen.$ext',
      'base64Data': base64Encode(bytes),
      'contentType': 'image/$ext',
    });
    return result['url'] as String;
  }

  /// Listar TODAS las publicaciones del mural, activas e inactivas.
  static Future<List<Map<String, dynamic>>> muralListAll() async {
    final result = await _invoke('mural_list_all');
    return List<Map<String, dynamic>>.from(result['data'] as List);
  }

  static Future<void> muralCreate({
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
    String type = 'info',
    DateTime? expiresAt,
  }) async {
    await _invoke('mural_create', {
      'title': title,
      'message': message,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'type': type,
      'expiresAt': expiresAt?.toIso8601String(),
    });
  }

  static Future<void> muralUpdate({
    required int id,
    String? title,
    String? message,
    String? imageUrl,
    String? actionUrl,
    String? type,
    bool? isActive,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
  }) async {
    await _invoke('mural_update', {
      'id': id,
      if (title != null) 'title': title,
      if (message != null) 'message': message,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (actionUrl != null) 'actionUrl': actionUrl,
      if (type != null) 'type': type,
      if (isActive != null) 'isActive': isActive,
      if (expiresAt != null || clearExpiresAt) 'expiresAt': expiresAt?.toIso8601String(),
    });
  }

  static Future<void> muralDelete(int id) async {
    await _invoke('mural_delete', {'id': id});
  }
}
