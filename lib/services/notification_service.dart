import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/notification_type.dart';
import '../models/notification_preferences.dart';
import '../models/notification_history_item.dart';
import 'auth_service_simple.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final AuthServiceSimple _authService = AuthServiceSimple();
  bool _isInitialized = false;
  DateTime? _lastLowPriorityNotification;
  
  // Intervalo mínimo entre notificaciones de baja prioridad (6 horas)
  static const _minLowPriorityInterval = Duration(hours: 6);

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // En web, no inicializar notificaciones locales
    if (kIsWeb) {
      _isInitialized = true;
      print('⚠️ NotificationService: Web no soporta notificaciones locales');
      return;
    }
    
    try {
      // Inicializar timezone
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      _isInitialized = true;
      
      print('✅ NotificationService inicializado');
    } catch (e) {
      print('⚠️ Error inicializando NotificationService: $e');
      _isInitialized = true; // Marcar como inicializado para no volver a intentar
    }
  }

  /// Callback cuando el usuario toca una notificación
  void _onNotificationTapped(NotificationResponse response) {
    print('📱 Notificación tocada: ${response.payload}');
    // Aquí se puede manejar la navegación específica según el payload
  }

  /// Verificar si se debe mostrar una notificación de baja prioridad
  bool _shouldShowLowPriorityNotification() {
    if (_lastLowPriorityNotification == null) return true;
    
    final now = DateTime.now();
    final difference = now.difference(_lastLowPriorityNotification!);
    
    return difference >= _minLowPriorityInterval;
  }

  /// Mostrar notificación genérica
  Future<void> showNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.weeklyMotivational,
    String? payload,
  }) async {
    await initialize();
    
    // En web, no mostrar notificaciones
    if (kIsWeb) {
      print('⚠️ Notificaciones locales no disponibles en web');
      return;
    }
    
    // Verificar si se debe mostrar (evitar spam de baja prioridad)
    if (type.priority == NotificationPriority.low) {
      if (!_shouldShowLowPriorityNotification()) {
        print('⏭️ Notificación de baja prioridad omitida por intervalo mínimo');
        return;
      }
      _lastLowPriorityNotification = DateTime.now();
    }

    // Obtener preferencias del usuario
    final preferences = await NotificationPreferences.load();
    if (!preferences.enabled) {
      print('🔕 Notificaciones deshabilitadas por el usuario');
      return;
    }

    // Verificar si es día silencioso
    final now = DateTime.now();
    if (preferences.isDaySilent(now.weekday % 7)) {
      print('🔇 Día silencioso, notificación omitida');
      return;
    }

    final priority = type.priority;
    final shouldPlaySound = type.shouldPlaySound() && preferences.soundEnabled;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'manigrab_notifications',
      'ManiGrab',
      channelDescription: 'Notificaciones de ManiGrab - Manifestaciones Cuánticas Grabovoi',
      importance: _getImportance(priority),
      priority: _getPriority(priority),
      showWhen: true,
      enableVibration: preferences.vibrationEnabled,
      playSound: shouldPlaySound,
      styleInformation: BigTextStyleInformation(body),
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      type.id,
      title,
      body,
      details,
      payload: payload ?? type.toString(),
    );
    
    // Guardar en historial
    await NotificationHistory.addNotification(
      title: title,
      body: body,
      type: type.toString(),
    );
    
    print('📤 Notificación enviada: $title');
  }

  /// Programar notificación local
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    NotificationType type = NotificationType.dailyCodeReminder,
    String? payload,
  }) async {
    await initialize();
    
    // En web, no programar notificaciones
    if (kIsWeb) {
      print('⚠️ Programación de notificaciones no disponible en web');
      return;
    }

    final preferences = await NotificationPreferences.load();
    if (!preferences.enabled) {
      return;
    }

    final shouldPlaySound = type.shouldPlaySound() && preferences.soundEnabled;
    final priority = type.priority;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'manigrab_scheduled',
      'ManiGrab Programadas',
      channelDescription: 'Notificaciones programadas de ManiGrab',
      importance: _getImportance(priority),
      priority: _getPriority(priority),
      showWhen: true,
      enableVibration: preferences.vibrationEnabled,
      playSound: shouldPlaySound,
      styleInformation: BigTextStyleInformation(body),
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      type.id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      payload: payload ?? type.toString(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    
    print('📅 Notificación programada: $title para ${scheduledDate.toString()}');
  }

  /// Cancelar todas las notificaciones
  Future<void> cancelAll() async {
    await initialize();
    await _notifications.cancelAll();
    print('🗑️ Todas las notificaciones canceladas');
  }

  /// Cancelar notificación específica por ID
  Future<void> cancel(int id) async {
    await initialize();
    await _notifications.cancel(id);
  }

  /// Programar notificaciones diarias
  Future<void> scheduleDailyNotifications(NotificationPreferences preferences) async {
    await cancelAll();

    if (!preferences.enabled) return;

    // Recordatorio de código del día - 9:00 AM
    if (preferences.dailyCodeReminders) {
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, 9, 0);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      await scheduleNotification(
        title: '🌅 Tu Código Grabovoi de Hoy',
        body: 'Tu código de hoy espera por ti. ¡Recuerda que tu energía se eleva con cada pilotaje consciente!',
        scheduledDate: scheduledDate,
        type: NotificationType.dailyCodeReminder,
      );
    }

    // Recordatorio matutino - hora preferida
    if (preferences.morningReminders) {
      final morningTime = _parseTime(preferences.preferredMorningTime);
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, morningTime.hour, morningTime.minute);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      // Programar para toda la semana para días no silenciosos
      for (int i = 0; i < 7; i++) {
        final targetDate = scheduledDate.add(Duration(days: i));
        if (!preferences.isDaySilent(targetDate.weekday % 7)) {
          await scheduleNotification(
            title: '☀️ Buenos días, Piloto Consciente',
            body: '¿Listo para comenzar el día con energía cuántica? Un pilotaje consciente de 2 minutos transformará tu mañana.',
            scheduledDate: targetDate,
            type: NotificationType.morningRoutineReminder,
          );
        }
      }
    }

    // Recordatorio vespertino - hora preferida
    if (preferences.eveningReminders) {
      final eveningTime = _parseTime(preferences.preferredEveningTime);
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, eveningTime.hour, eveningTime.minute);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      // Programar para toda la semana para días no silenciosos
      for (int i = 0; i < 7; i++) {
        final targetDate = scheduledDate.add(Duration(days: i));
        if (!preferences.isDaySilent(targetDate.weekday % 7)) {
          await scheduleNotification(
            title: '🌙 Completa tu práctica cuántica',
            body: 'Excelente día. ¿Completas tu práctica cuántica de hoy? Tu disciplina está transformando tu realidad.',
            scheduledDate: targetDate,
            type: NotificationType.eveningRoutineReminder,
          );
        }
      }
    }
  }

  DateTime _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  }

  Importance _getImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.medium:
        return Importance.defaultImportance;
      case NotificationPriority.low:
        return Importance.low;
    }
  }

  Priority _getPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.medium:
        return Priority.defaultPriority;
      case NotificationPriority.low:
        return Priority.low;
    }
  }

  // ===== NOTIFICACIONES ESPECÍFICAS =====

  /// Notificación de racha en riesgo (12 horas)
  Future<void> notifyStreakAtRisk(String userName, int streakDays) async {
    await showNotification(
      title: '⚠️ Racha en Riesgo',
      body: 'Atención $userName: Tu racha de $streakDays días está en riesgo. ¡Hay tiempo aún! Realiza tu pilotaje de hoy para mantenerla viva.',
      type: NotificationType.streakAtRisk12h,
    );
  }

  /// Notificación de racha perdida
  Future<void> notifyStreakLost(String userName, int streakDays) async {
    await showNotification(
      title: '😔 Racha Interrumpida',
      body: 'Tu racha de $streakDays días se ha interrumpido, pero es solo un nuevo comienzo. El Piloto Consciente persevera. ¡Comienza de nuevo hoy!',
      type: NotificationType.streakLost,
    );
  }

  /// Notificación de hito de racha
  Future<void> notifyStreakMilestone(String userName, int days) async {
    String title;
    String body;
    NotificationType type;

    switch (days) {
      case 3:
        title = '🎉 ¡Felicidades!';
        body = '3 días consecutivos. Tu energía comienza a estabilizarse.';
        type = NotificationType.streakMilestone3;
        break;
      case 7:
        title = '🌟 ¡Increíble!';
        body = '7 días consecutivos. Estás creando un hábito poderoso.';
        type = NotificationType.streakMilestone7;
        break;
      case 14:
        title = '💎 ¡Extraordinario!';
        body = '14 días consecutivos. Tu disciplina está transformando tu realidad.';
        type = NotificationType.streakMilestone14;
        break;
      case 21:
        title = '👑 ¡Épico!';
        body = '21 días consecutivos. El hábito está formado. Eres un Piloto Consciente.';
        type = NotificationType.streakMilestone21;
        break;
      case 30:
        title = '🏆 ¡Legendario!';
        body = '30 días consecutivos. Has alcanzado Maestría en Constancia.';
        type = NotificationType.streakMilestone30;
        break;
      default:
        return;
    }

    await showNotification(title: title, body: body, type: type);
  }

  /// Notificación de nivel energético sube
  Future<void> notifyEnergyLevelUp(int newLevel) async {
    await showNotification(
      title: '⚡ ¡Tu energía ha subido!',
      body: 'Ahora estás en nivel $newLevel/10. ¡Sigue así!',
      type: NotificationType.energyLevelUp,
    );
  }

  /// Notificación de nivel máximo
  Future<void> notifyEnergyMaxReached(String userName) async {
    await showNotification(
      title: '👑 ¡MAESTRÍA!',
      body: 'Has alcanzado el nivel máximo de energía (10/10). Eres un Piloto Consciente cuántico.',
      type: NotificationType.energyMaxReached,
    );
  }

  /// Notificación de desafío completado
  Future<void> notifyChallengeCompleted(String challengeName, String awards) async {
    await showNotification(
      title: '🏆 ¡DESAFÍO COMPLETADO!',
      body: '$challengeName. Has desbloqueado: $awards. ¡Felicidades Piloto Consciente!',
      type: NotificationType.challengeCompleted,
    );
  }

  /// Notificación de día de desafío completado
  Future<void> notifyChallengeDayCompleted(int day, int total, String challengeName) async {
    await showNotification(
      title: '✅ ¡Día completado!',
      body: 'Día $day/$total del desafío $challengeName. ¡Excelente trabajo!',
      type: NotificationType.challengeDayCompleted,
    );
  }

  /// Notificación de primer pilotaje
  Future<void> notifyFirstPilotage(String userName) async {
    await showNotification(
      title: '🎉 ¡Bienvenido al viaje cuántico!',
      body: 'Has completado tu primer pilotaje consciente. El viaje de transformación comienza.',
      type: NotificationType.firstPilotage,
    );
  }

  /// Notificación de logro (hito de pilotajes)
  Future<void> notifyPilotageMilestone(int totalPilotages, String userName) async {
    String title;
    String body;
    NotificationType type;

    switch (totalPilotages) {
      case 10:
        title = '💪 ¡10 pilotajes completados!';
        body = 'Estás construyendo un hábito poderoso.';
        type = NotificationType.milestone10Pilotages;
        break;
      case 50:
        title = '⭐ 50 pilotajes completados';
        body = 'Eres un Piloto Intermedio.';
        type = NotificationType.milestone50Pilotages;
        break;
      case 100:
        title = '🌟 100 pilotajes completados';
        body = '¡Maestría Intermedia alcanzada!';
        type = NotificationType.milestone100Pilotages;
        break;
      case 500:
        title = '👑 500 pilotajes completados';
        body = 'Eres un Experto en Piloto Cuántico.';
        type = NotificationType.milestone500Pilotages;
        break;
      case 1000:
        title = '🏆 1000 pilotajes completados';
        body = '¡LEYENDA VIVIENTE! Has dominado el arte.';
        type = NotificationType.milestone1000Pilotages;
        break;
      default:
        return;
    }

    await showNotification(title: title, body: body, type: type);
  }

  /// Notificación de código recomendado
  Future<void> notifyPersonalizedCode(String code, String userName) async {
    await showNotification(
      title: '✨ Código Personalizado para Ti',
      body: 'Basado en tu actividad, este código podría ser perfecto para ti hoy: $code',
      type: NotificationType.personalizedCodeRecommendation,
    );
  }

  /// Notificación de resumen semanal
  Future<void> notifyWeeklySummary(int pilotages, int codesUsed, int energyLevel) async {
    await showNotification(
      title: '📊 Tu semana cuántica',
      body: '$pilotages pilotajes, $codesUsed códigos usados, nivel $energyLevel/10. ¡Sigue así!',
      type: NotificationType.weeklyProgressSummary,
    );
  }

  /// Notificación feedback - gracias por mantener racha
  Future<void> notifyThanksForStreak(String userName) async {
    await showNotification(
      title: '👏 Gracias por mantener tu racha activa',
      body: 'Tu disciplina cuántica está transformando tu realidad.',
      type: NotificationType.thanksForMaintainingStreak,
    );
  }

  /// Notificación feedback - disfruta tu pilotaje
  Future<void> notifyEnjoyPilotage() async {
    await showNotification(
      title: '🎧 Disfruta tu pilotaje',
      body: 'Respira, siente, transforma.',
      type: NotificationType.enjoyYourPilotage,
    );
  }

  /// Notificación de desafío diario
  Future<void> notifyChallengeDailyReminder(String challengeName, int day, int total) async {
    await showNotification(
      title: '🎯 Tienes un desafío activo',
      body: '$challengeName. Día $day de $total. ¡Completa tus acciones hoy!',
      type: NotificationType.challengeDailyReminder,
    );
  }

  /// Notificación de desafío en riesgo
  Future<void> notifyChallengeAtRisk(String challengeName, int day) async {
    await showNotification(
      title: '⚠️ Tu desafío está en riesgo',
      body: '$challengeName está en riesgo. ¡Completa el día $day hoy!',
      type: NotificationType.challengeAtRisk,
    );
  }

  // ===== MÉTODOS LEGACY (mantener compatibilidad) =====

  Future<void> showChallengeProgressNotification({
    required String title,
    required String body,
    required int progress,
  }) async {
    await showNotification(title: title, body: body, type: NotificationType.challengeDayCompleted);
  }

  Future<void> showActionCompletedNotification({
    required String actionName,
    required String challengeName,
  }) async {
    await showNotification(
      title: '¡Acción Completada! 🎉',
      body: 'Has completado: $actionName en $challengeName',
      type: NotificationType.challengeDayCompleted,
    );
  }

  Future<void> showChallengeCompletedNotification({
    required String challengeName,
  }) async {
    await notifyChallengeCompleted(challengeName, '');
  }
}
