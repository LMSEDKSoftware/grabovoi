import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mural_message.dart';

class MuralService {
  static final MuralService _instance = MuralService._internal();
  factory MuralService() => _instance;
  MuralService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _readMessagesKey = 'mural_read_messages';

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

  /// Obtener IDs de mensajes leídos localmente
  Future<List<int>> getReadMessageIds() async {
    final prefs = await SharedPreferences.getInstance();
    final readIdsString = prefs.getStringList(_readMessagesKey) ?? [];
    final readIds = readIdsString.map((id) => int.parse(id)).toList();
    debugPrint('📖 [MURAL] Mensajes leídos: $readIds');
    return readIds;
  }

  /// Marcar mensaje como leído
  Future<void> markAsRead(int messageId) async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = await getReadMessageIds();
    
    if (!readIds.contains(messageId)) {
      readIds.add(messageId);
      await prefs.setStringList(_readMessagesKey, readIds.map((id) => id.toString()).toList());
      debugPrint('✅ [MURAL] Mensaje $messageId marcado como leído');
    }
  }

  /// Verificar si hay mensajes nuevos (no leídos)
  Future<bool> hasUnreadMessages() async {
    final messages = await getActiveMessages();
    if (messages.isEmpty) return false;

    final readIds = await getReadMessageIds();
    
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
      
      return messages.where((msg) => !readIds.contains(msg.id)).length;
    } catch (e) {
      return 0;
    }
  }
}
