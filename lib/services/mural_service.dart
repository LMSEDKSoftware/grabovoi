import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mural_message.dart';

class MuralService {
  static final MuralService _instance = MuralService._internal();
  factory MuralService() => _instance;
  MuralService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _readsTable = 'mural_message_reads';
  bool _readsDbAvailable = true;

  /// Obtener mensajes activos del mural
  Future<List<MuralMessage>> getActiveMessages() async {
    try {
      debugPrint('🔍 [MURAL] Obteniendo mensajes activos...');
      final response = await _supabase
          .from('mural_messages')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      debugPrint('✅ [MURAL] Mensajes activos encontrados: ${data.length}');
      return data.map((json) => MuralMessage.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo mensajes del mural: $e');
      return [];
    }
  }

  /// Obtener TODOS los mensajes del mural (para historial)
  Future<List<MuralMessage>> getAllMessages() async {
    try {
      debugPrint('🔍 [MURAL] Obteniendo todos los mensajes...');
      final response = await _supabase
          .from('mural_messages')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      debugPrint('✅ [MURAL] Total de mensajes encontrados: ${data.length}');
      return data.map((json) => MuralMessage.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo todos los mensajes del mural: $e');
      return [];
    }
  }

  /// Obtener IDs de mensajes leídos (persistente en DB por usuario)
  Future<List<int>> getReadMessageIds() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from(_readsTable)
          .select('message_id')
          .eq('user_id', user.id);

      final data = response as List<dynamic>;
      final readIds = data
          .map((row) => (row['message_id'] as num).toInt())
          .toList(growable: false);
      _readsDbAvailable = true;
      debugPrint('📖 [MURAL] Mensajes leídos (DB): ${readIds.length}');
      return readIds;
    } catch (e) {
      _readsDbAvailable = false;
      debugPrint('❌ Error obteniendo mensajes leídos (DB): $e');
      return [];
    }
  }

  /// Deshacer "no mostrar de nuevo": el mensaje volverá a aparecer.
  Future<void> markAsUnread(int messageId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from(_readsTable)
          .delete()
          .eq('user_id', user.id)
          .eq('message_id', messageId);
      debugPrint('↩️ [MURAL] Mensaje $messageId desmarcado como leído (DB)');
    } catch (e) {
      debugPrint('❌ Error desmarcando mensaje como leído (DB): $e');
    }
  }

  /// Marcar mensaje como leído
  Future<void> markAsRead(int messageId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from(_readsTable).upsert(
        {
          'user_id': user.id,
          'message_id': messageId,
          'seen_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,message_id',
      );
      debugPrint('✅ [MURAL] Mensaje $messageId marcado como leído (DB)');
    } catch (e) {
      debugPrint('❌ Error marcando mensaje como leído (DB): $e');
    }
  }

  /// Verificar si hay mensajes nuevos (no leídos)
  Future<bool> hasUnreadMessages() async {
    final messages = await getActiveMessages();
    if (messages.isEmpty) return false;

    final readIds = await getReadMessageIds();
    if (!_readsDbAvailable) return false;
    
    // Si hay algún mensaje activo que no esté en la lista de leídos
    final hasUnread = messages.any((msg) => !readIds.contains(msg.id));
    debugPrint('🔔 [MURAL] ¿Hay mensajes no leídos? $hasUnread');
    return hasUnread;
  }
  
  /// Obtener conteo de mensajes no leídos
  Future<int> getUnreadCount() async {
    try {
      final messages = await getActiveMessages();
      if (messages.isEmpty) return 0;

      final readIds = await getReadMessageIds();
      if (!_readsDbAvailable) return 0;
      
      return messages.where((msg) => !readIds.contains(msg.id)).length;
    } catch (e) {
      return 0;
    }
  }
}
