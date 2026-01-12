import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationHistoryItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String type; // Tipo de notificación

  const NotificationHistoryItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type,
    };
  }

  factory NotificationHistoryItem.fromJson(Map<String, dynamic> json) {
    return NotificationHistoryItem(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool,
      type: json['type'] as String,
    );
  }
}

/// Gestor de historial de notificaciones
class NotificationHistory {
  static const String _key = 'notification_history';
  static const int _maxItems = 50; // Mantener últimas 50

  /// Agregar una notificación al historial
  static Future<void> addNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    final item = NotificationHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
    );

    history.insert(0, item);

    // Mantener solo las últimas N notificaciones
    final trimmedHistory = history.take(_maxItems).toList();

    final historyJson = trimmedHistory.map((item) => item.toJson()).toList();
    await prefs.setString(_key, jsonEncode(historyJson));

    print('📝 Notificación agregada al historial: $title');
  }

  /// Obtener historial completo
  static Future<List<NotificationHistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_key);

    if (historyJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(historyJson);
      return decoded.map((json) => NotificationHistoryItem.fromJson(json)).toList();
    } catch (e) {
      print('Error cargando historial: $e');
      return [];
    }
  }

  /// Obtener notificaciones no leídas
  static Future<List<NotificationHistoryItem>> getUnreadNotifications() async {
    final history = await getHistory();
    return history.where((item) => !item.isRead).toList();
  }

  /// Marcar una notificación como leída por su ID
  static Future<void> markAsRead(String id) async {
    final history = await getHistory();
    final prefs = await SharedPreferences.getInstance();

    final updatedHistory = history.map((item) {
      if (item.id == id) {
        return NotificationHistoryItem(
          id: item.id,
          title: item.title,
          body: item.body,
          timestamp: item.timestamp,
          isRead: true,
          type: item.type,
        );
      }
      return item;
    }).toList();

    final historyJson = updatedHistory.map((item) => item.toJson()).toList();
    await prefs.setString(_key, jsonEncode(historyJson));
    
    print('✅ Notificación marcada como leída: $id');
  }

  /// Marcar todas como leídas
  static Future<void> markAllAsRead() async {
    final history = await getHistory();
    final prefs = await SharedPreferences.getInstance();

    final updatedHistory = history.map((item) => NotificationHistoryItem(
      id: item.id,
      title: item.title,
      body: item.body,
      timestamp: item.timestamp,
      isRead: true,
      type: item.type,
    )).toList();

    final historyJson = updatedHistory.map((item) => item.toJson()).toList();
    await prefs.setString(_key, jsonEncode(historyJson));
    
    print('✅ Todas las notificaciones marcadas como leídas');
  }

  /// Eliminar todas las notificaciones
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Contar notificaciones no leídas
  static Future<int> getUnreadCount() async {
    final unread = await getUnreadNotifications();
    return unread.length;
  }
}

