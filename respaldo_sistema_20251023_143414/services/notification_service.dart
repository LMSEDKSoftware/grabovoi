import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    _isInitialized = true;
  }

  Future<void> showChallengeProgressNotification({
    required String title,
    required String body,
    required int progress,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'challenge_progress',
      'Progreso de Desafíos',
      channelDescription: 'Notificaciones de progreso en desafíos',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }

  Future<void> showActionCompletedNotification({
    required String actionName,
    required String challengeName,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'action_completed',
      'Acción Completada',
      channelDescription: 'Notificaciones cuando se completa una acción',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '¡Acción Completada! 🎉',
      'Has completado: $actionName en $challengeName',
      details,
    );
  }

  Future<void> showChallengeCompletedNotification({
    required String challengeName,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'challenge_completed',
      'Desafío Completado',
      channelDescription: 'Notificaciones cuando se completa un desafío',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '¡Desafío Completado! 🏆',
      '¡Felicidades! Has completado $challengeName',
      details,
    );
  }
}
