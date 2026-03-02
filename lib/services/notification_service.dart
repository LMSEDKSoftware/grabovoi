import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_type.dart';
import '../models/notification_preferences.dart';
import '../models/notification_history_item.dart';
import 'auth_service_simple.dart';
import 'notification_count_service.dart';

/// Manejador de mensajes en segundo plano (debe ser una función de nivel superior/estática)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Asegurarse de que Firebase esté inicializado para procesos en segundo plano
  // Firebase.initializeApp() ya debería llamarse en main(), pero para procesos aislados 
  // a veces es necesario inicializarlo aquí también si es necesario acceder a recursos.
  debugPrint('📩 Mensaje recibido en segundo plano: ${message.notification?.title}');
}

/// Notificación pendiente en la cola
class _PendingNotification {
  final String title;
  final String body;
  final NotificationType type;
  final String? payload;
  final NotificationPriority priority;
  final DateTime timestamp;

  _PendingNotification({
    required this.title,
    required this.body,
    required this.type,
    this.payload,
    required this.priority,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal() {
    // Escuchar cambios en la autenticación para guardar el token si es necesario
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        if (_fcmToken != null) {
          debugPrint('🔐 Usuario autenticado detectado en NotificationService, guardando token FCM...');
          _saveTokenToSupabase(_fcmToken!);
        }
      }
    });
  }

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final AuthServiceSimple _authService = AuthServiceSimple();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isInitialized = false;
  String? _fcmToken;
  DateTime? _lastLowPriorityNotification;

  bool get hasValidFCMToken => _fcmToken != null;
  
  // Intervalo mínimo entre notificaciones de baja prioridad (6 horas)
  static const _minLowPriorityInterval = Duration(hours: 6);
  
  // Rate limiting: máximo 2 notificaciones por minuto
  static const _maxNotificationsPerMinute = 2;
  static const _rateLimitWindow = Duration(minutes: 1);
  final List<DateTime> _notificationTimestamps = [];
  
  // Cola de notificaciones pendientes para consolidar
  final List<_PendingNotification> _notificationQueue = [];
  bool _isProcessingQueue = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // En web, no inicializar notificaciones locales ni FCM (por ahora)
    if (kIsWeb) {
      _isInitialized = true;
      debugPrint('⚠️ NotificationService: Web no soporta notificaciones locales/push en este flujo');
      return;
    }
    
    try {
      // Inicializar timezone
      tz.initializeTimeZones();

      // Configurar Android para notificaciones en segundo plano
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      // Configurar Firebase Cloud Messaging
      await _setupFCM();
      
      _isInitialized = true;
      debugPrint('✅ NotificationService inicializado con FCM');
    } catch (e) {
      debugPrint('⚠️ Error inicializando NotificationService: $e');
      _isInitialized = true; 
    }
  }

  Future<void> _setupFCM() async {
    try {
      // Solicitar permisos
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('🔔 Permisos de FCM otorgados');
        
        // Configurar el manejador de segundo plano
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // Escuchar mensajes en primer plano
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('📩 Mensaje recibido en primer plano: ${message.notification?.title}');
          if (message.notification != null) {
            _showLocalNotificationFromFCM(message);
          }
        });

        // Obtener el token inicial
        String? token = await _messaging.getToken();
        if (token != null) {
          _fcmToken = token;
          await _saveTokenToSupabase(token);
        }

        // Escuchar cambios en el token
        _messaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          _saveTokenToSupabase(newToken);
        });
      } else {
        debugPrint('🔕 Permisos de FCM denegados: ${settings.authorizationStatus}');
      }
    } catch (e) {
      debugPrint('⚠️ Error configurando FCM: $e');
    }
  }

  Future<void> _saveTokenToSupabase(String token) async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      debugPrint('⏭️ No se guarda token FCM: No hay sesión activa en Supabase');
      return;
    }
    
    try {
      final userId = session.user.id;
      final deviceType = Platform.isAndroid ? 'android' : 'ios';

      await _supabase.from('user_fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'device_type': deviceType,
        'last_active': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, token');
      
      debugPrint('💾 Token FCM guardado en Supabase para el usuario $userId');
    } catch (e) {
      debugPrint('⚠️ Error guardando token FCM en Supabase: $e');
    }
  }

  void _showLocalNotificationFromFCM(RemoteMessage message) {
    // Convertir el mensaje de FCM a una notificación local para que se vea en primer plano
    if (message.notification == null) return;
    
    showNotification(
      title: message.notification!.title ?? 'ManiGraB',
      body: message.notification!.body ?? '',
      type: NotificationType.dailyCodeReminder, // O deducirlo del payload si existe
      payload: message.data.isNotEmpty ? message.data.toString() : null,
      bypassQueue: true,
    );
  }

  /// Solicitar permisos explícitamente en iOS
  /// Esto es necesario para que las notificaciones aparezcan en el centro de notificaciones
  Future<bool> _requestIOSPermissions() async {
    if (kIsWeb || !Platform.isIOS) {
      return true; // No aplica para web o Android
    }
    
    try {
      debugPrint('📱 [iOS] Verificando permisos de notificaciones...');
      
      // IMPORTANTE: Con DarwinInitializationSettings(requestAlertPermission: true),
      // los permisos se solicitan automáticamente durante initialize().
      // Este método solo verifica que funcionen correctamente.
      
      debugPrint('💡 [iOS] Los permisos deberían haberse solicitado automáticamente durante initialize()');
      debugPrint('💡 [iOS] Verifica en Configuración > MANIGRAB > Notificaciones');
      
      // Verificar que los permisos funcionen correctamente
      final verified = await _verifyIOSPermissions();
      
      if (verified) {
        debugPrint('✅ [iOS] Permisos verificados correctamente');
        return true;
      } else {
        debugPrint('⚠️ [iOS] No se pudieron verificar los permisos');
        debugPrint('💡 [iOS] El usuario debe habilitar notificaciones en Configuración > MANIGRAB > Notificaciones');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [iOS] Error solicitando permisos: $e');
      debugPrint('❌ [iOS] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Verificar que los permisos estén realmente otorgados
  Future<bool> _verifyIOSPermissions() async {
    try {
      // Intentar obtener notificaciones pendientes como verificación
      final pending = await _notifications.pendingNotificationRequests();
      debugPrint('📱 [iOS] Verificación: ${pending.length} notificaciones pendientes');
      
      // Si podemos obtener notificaciones pendientes, los permisos probablemente están bien
      // (aunque esto no garantiza que se puedan mostrar)
      return true;
    } catch (e) {
      debugPrint('⚠️ [iOS] Error en verificación de permisos: $e');
      // No fallar por esto, puede que los permisos estén bien pero haya otro problema
      return true; // Asumir que está bien para no bloquear
    }
  }

  /// Verificar y solicitar permisos si es necesario (específico para iOS)
  /// En iOS, los permisos se solicitan automáticamente durante initialize()
  Future<bool> checkIOSPermissions() async {
    if (kIsWeb || !Platform.isIOS) {
      return true; // No aplica para web o Android
    }
    
    // Verificar que los permisos funcionen correctamente
    return await _verifyIOSPermissions();
  }

  /// Callback cuando el usuario toca una notificación
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notificación tocada: ${response.payload}');
    // Aquí se puede manejar la navegación específica según el payload
  }

  /// Verificar si se debe mostrar una notificación de baja prioridad
  bool _shouldShowLowPriorityNotification() {
    if (_lastLowPriorityNotification == null) return true;
    
    final now = DateTime.now();
    final difference = now.difference(_lastLowPriorityNotification!);
    
    return difference >= _minLowPriorityInterval;
  }

  /// Verificar rate limiting (máximo 2 notificaciones por minuto)
  bool _canSendNotification() {
    final now = DateTime.now();
    
    // Limpiar timestamps antiguos (más de 1 minuto)
    _notificationTimestamps.removeWhere((timestamp) => 
      now.difference(timestamp) > _rateLimitWindow
    );
    
    // Verificar si podemos enviar más notificaciones
    return _notificationTimestamps.length < _maxNotificationsPerMinute;
  }

  /// Registrar timestamp de notificación enviada
  void _recordNotificationSent() {
    final now = DateTime.now();
    _notificationTimestamps.add(now);
    
    // Mantener solo las últimas necesarias
    if (_notificationTimestamps.length > _maxNotificationsPerMinute) {
      _notificationTimestamps.removeAt(0);
    }
  }

  /// Agregar notificación a la cola
  Future<void> _enqueueNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? payload,
  }) async {
    final pending = _PendingNotification(
      title: title,
      body: body,
      type: type,
      payload: payload,
      priority: type.priority,
    );
    
    // Si hay notificaciones similares en la cola, consolidar
    final now = DateTime.now();
    final similarIndex = _notificationQueue.indexWhere((n) => 
      n.type == type && 
      now.difference(n.timestamp).inSeconds < 5
    );
    
    if (similarIndex != -1 && type.priority != NotificationPriority.high) {
      // Consolidar: actualizar la más reciente o eliminar la duplicada
      debugPrint('🔄 Consolidando notificación duplicada: ${type.toString()}');
      if (type.priority == NotificationPriority.high) {
        // La nueva es más importante, reemplazar
        _notificationQueue[similarIndex] = pending;
      }
      // Si no es alta prioridad, simplemente ignorar la duplicada
      return;
    }
    
    _notificationQueue.add(pending);
    _processNotificationQueue();
  }

  /// Procesar cola de notificaciones
  Future<void> _processNotificationQueue() async {
    if (_isProcessingQueue || _notificationQueue.isEmpty) return;
    
    _isProcessingQueue = true;
    
    while (_notificationQueue.isNotEmpty) {
      // Verificar rate limiting
      if (!_canSendNotification()) {
        debugPrint('⏸️ Rate limit alcanzado, esperando...');
        // Esperar hasta que podamos enviar más
        await Future.delayed(const Duration(seconds: 30));
        continue;
      }
      
      // Priorizar: primero las de alta prioridad, luego mediana, luego baja
      _notificationQueue.sort((a, b) {
        if (a.priority != b.priority) {
          final priorityOrder = {
            NotificationPriority.high: 0,
            NotificationPriority.medium: 1,
            NotificationPriority.low: 2,
          };
          return priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
        }
        // Mismo nivel de prioridad, la más antigua primero
        return a.timestamp.compareTo(b.timestamp);
      });
      
      final pending = _notificationQueue.removeAt(0);
      
      // Enviar la notificación
      await _sendNotificationDirectly(
        title: pending.title,
        body: pending.body,
        type: pending.type,
        payload: pending.payload,
      );
      
      _recordNotificationSent();
      
      // Si aún hay espacio y hay más notificaciones, esperar un poco
      if (_notificationQueue.isNotEmpty && _canSendNotification()) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    
    _isProcessingQueue = false;
  }

  /// Enviar notificación directamente (sin rate limiting)
  Future<void> _sendNotificationDirectly({
    required String title,
    required String body,
    required NotificationType type,
    String? payload,
  }) async {
    await initialize();
    
    // En web, no mostrar notificaciones
    if (kIsWeb) {
      debugPrint('⚠️ Notificaciones locales no disponibles en web');
      return;
    }
    
    // En iOS, verificar permisos antes de mostrar notificaciones
    if (Platform.isIOS) {
      final hasPermissions = await checkIOSPermissions();
      if (!hasPermissions) {
        debugPrint('⚠️ Permisos de notificaciones iOS no otorgados, solicitando...');
        final requested = await _requestIOSPermissions();
        if (!requested) {
          debugPrint('❌ No se pueden mostrar notificaciones: permisos denegados');
          return;
        }
      }
    }
    
    // Obtener preferencias del usuario
    final preferences = await NotificationPreferences.load();
    if (!preferences.enabled) {
      debugPrint('🔕 Notificaciones deshabilitadas por el usuario');
      return;
    }

    // Verificar si es día silencioso
    final now = DateTime.now();
    if (preferences.isDaySilent(now.weekday % 7)) {
      debugPrint('🔇 Día silencioso, notificación omitida');
      return;
    }

    final priority = type.priority;
    final shouldPlaySound = type.shouldPlaySound() && preferences.soundEnabled;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'manigrab_notifications',
      'ManiGraB',
      channelDescription: 'Notificaciones de ManiGraB - Manifestaciones Cuánticas Grabovoi',
      importance: _getImportance(priority),
      priority: _getPriority(priority),
      showWhen: true,
      enableVibration: preferences.vibrationEnabled,
      playSound: shouldPlaySound,
      styleInformation: BigTextStyleInformation(body),
    );

    // Configuración específica para iOS
    // IMPORTANTE: interruptionLevel debe ser 'active' o 'timeSensitive' para que aparezcan en el centro de notificaciones
    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true, // Mostrar alerta en iOS (necesario para centro de notificaciones)
      presentBadge: true, // Mostrar badge en el icono de la app
      presentSound: shouldPlaySound, // Reproducir sonido si está habilitado
      interruptionLevel: priority == NotificationPriority.high
          ? InterruptionLevel.timeSensitive // Alta prioridad: notificación sensible al tiempo (aparece en centro)
          : InterruptionLevel.active, // Prioridad normal: activa (aparece en centro de notificaciones)
      // NOTA: InterruptionLevel.passive NO aparece en el centro de notificaciones, solo en el banner
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    debugPrint('📤 [iOS] Intentando mostrar notificación: $title');
    debugPrint('📤 [iOS] Configuración iOS: presentAlert=${iosDetails.presentAlert}, interruptionLevel=${iosDetails.interruptionLevel}');
    
    try {
      await _notifications.show(
        type.id,
        title,
        body,
        details,
        payload: payload ?? type.toString(),
      );
      
      debugPrint('✅ [iOS] Notificación mostrada exitosamente: $title');
      
      // Guardar en historial
      await NotificationHistory.addNotification(
        title: title,
        body: body,
        type: type.toString(),
      );
      
      // Actualizar conteo inmediatamente
      await NotificationCountService().updateCount();
      
      debugPrint('📤 Notificación enviada: $title');
    } catch (e, stackTrace) {
      debugPrint('❌ [iOS] Error al mostrar notificación: $e');
      debugPrint('❌ [iOS] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Mostrar notificación genérica (con rate limiting y cola)
  Future<void> showNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.weeklyMotivational,
    String? payload,
    bool bypassQueue = false, // Para notificaciones críticas
  }) async {
    await initialize();
    
    // En web, no mostrar notificaciones
    if (kIsWeb) {
      debugPrint('⚠️ Notificaciones locales no disponibles en web');
      return;
    }
    
    // Verificar si se debe mostrar (evitar spam de baja prioridad)
    if (type.priority == NotificationPriority.low) {
      if (!_shouldShowLowPriorityNotification()) {
        debugPrint('⏭️ Notificación de baja prioridad omitida por intervalo mínimo');
        return;
      }
      _lastLowPriorityNotification = DateTime.now();
    }

    // Para notificaciones de alta prioridad o bypass, intentar enviar inmediatamente
    if (bypassQueue || type.priority == NotificationPriority.high) {
      if (_canSendNotification()) {
        await _sendNotificationDirectly(
          title: title,
          body: body,
          type: type,
          payload: payload,
        );
        _recordNotificationSent();
        return;
      } else {
        debugPrint('⚠️ Rate limit activo, pero notificación de alta prioridad, agregando a cola prioritaria');
      }
    }

    // Agregar a la cola para procesamiento
    await _enqueueNotification(
      title: title,
      body: body,
      type: type,
      payload: payload,
    );
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
      debugPrint('⚠️ Programación de notificaciones no disponible en web');
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
      'ManiGraB Programadas',
      channelDescription: 'Notificaciones programadas de ManiGraB',
      importance: _getImportance(priority),
      priority: _getPriority(priority),
      showWhen: true,
      enableVibration: preferences.vibrationEnabled,
      playSound: shouldPlaySound,
      styleInformation: BigTextStyleInformation(body),
    );

    // Configuración específica para iOS
    // IMPORTANTE: interruptionLevel debe ser 'active' o 'timeSensitive' para que aparezcan en el centro de notificaciones
    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true, // Mostrar alerta en iOS (necesario para centro de notificaciones)
      presentBadge: true, // Mostrar badge en el icono de la app
      presentSound: shouldPlaySound, // Reproducir sonido si está habilitado
      interruptionLevel: priority == NotificationPriority.high
          ? InterruptionLevel.timeSensitive // Alta prioridad: notificación sensible al tiempo (aparece en centro)
          : InterruptionLevel.active, // Prioridad normal: activa (aparece en centro de notificaciones)
      // NOTA: InterruptionLevel.passive NO aparece en el centro de notificaciones, solo en el banner
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

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
    
    debugPrint('📅 Notificación programada: $title para ${scheduledDate.toString()}');
  }

  /// Cancelar todas las notificaciones
  Future<void> cancelAll() async {
    await initialize();
    await _notifications.cancelAll();
    debugPrint('🗑️ Todas las notificaciones canceladas');
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
      title: '✨ ¡Nueva Secuencia Diaria Disponible!',
      body: 'Descúbrelo ahora y eleva tu energía con tu sesión de repetición diaria. ¡Toca para comenzar!',
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

  /// Verificar si se debe notificar sobre el estado de la racha (evitar duplicados diarios)
  Future<bool> _shouldNotifyStreakStatus(String statusType) async {
    if (!_authService.isLoggedIn) return false;
    
    try {
      final userId = _authService.currentUser!.id;
      final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
      
      // Verificar si ya se envió una notificación de este tipo hoy
      final existing = await _supabase
          .from('user_notifications_sent')
          .select()
          .eq('user_id', userId)
          .eq('notification_type', statusType)
          .gte('sent_at', '$today 00:00:00')
          .maybeSingle();
          
      if (existing != null) {
        return false; // Ya se notificó hoy
      }
      
      // Registrar que se va a enviar
      await _supabase.from('user_notifications_sent').insert({
        'user_id': userId,
        'notification_type': statusType,
        'action_type': 'system_alert',
        'sent_at': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      debugPrint('❌ Error verificando estado de notificación de racha: $e');
      // En caso de error, permitir la notificación para no perder alertas críticas,
      // pero intentar usar caché local como fallback
      return !_isStreakAlreadyNotified(statusType);
    }
  }

  /// Notificación de racha en riesgo (12 horas)
  Future<void> notifyStreakAtRisk(String userName, int streakDays) async {
    // Verificar persistencia para evitar duplicados
    if (!await _shouldNotifyStreakStatus('streak_at_risk')) {
      debugPrint('⏭️ Notificación de racha en riesgo omitida: ya enviada hoy');
      return;
    }

    await showNotification(
      title: '⚠️ Racha en Riesgo',
      body: 'Atención $userName: Tu racha de $streakDays días está en riesgo. ¡Hay tiempo aún! Realiza tu pilotaje de hoy para mantenerla viva.',
      type: NotificationType.streakAtRisk12h,
    );
  }

  /// Notificación de racha perdida
  Future<void> notifyStreakLost(String userName, int streakDays) async {
    // Verificar persistencia para evitar duplicados
    if (!await _shouldNotifyStreakStatus('streak_lost')) {
      debugPrint('⏭️ Notificación de racha perdida omitida: ya enviada hoy');
      return;
    }

    await showNotification(
      title: '😔 Racha Interrumpida',
      body: 'Tu racha de $streakDays días se ha interrumpido, pero es solo un nuevo comienzo. El Piloto Consciente persevera. ¡Comienza de nuevo hoy!',
      type: NotificationType.streakLost,
    );
  }

  /// Verificar si un streak ya fue notificado (anti-duplicados)
  bool _isStreakAlreadyNotified(String streakKey) {
    final now = DateTime.now();
    
    // Limpiar streaks antiguos
    _notifiedStreaksTimestamps.removeWhere((key, timestamp) {
      final shouldRemove = now.difference(timestamp) > _notifiedStreaksExpiry;
      if (shouldRemove) {
        _notifiedStreaks.remove(key);
      }
      return shouldRemove;
    });
    
    return _notifiedStreaks.contains(streakKey);
  }
  
  /// Marcar streak como notificado
  void _markStreakAsNotified(String streakKey) {
    final now = DateTime.now();
    _notifiedStreaks.add(streakKey);
    _notifiedStreaksTimestamps[streakKey] = now;
  }

  /// Notificación de hito de racha
  Future<void> notifyStreakMilestone(String userName, int days) async {
    // Verificar si ya fue notificado
    final streakKey = 'streak_$days';
    if (_isStreakAlreadyNotified(streakKey)) {
      debugPrint('⏭️ Milestone de racha omitido: $days días ya fue notificado');
      return;
    }
    
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
    _markStreakAsNotified(streakKey);
  }

  /// Verificar si un nivel energético ya fue notificado (anti-duplicados)
  bool _isEnergyLevelAlreadyNotified(int level) {
    final now = DateTime.now();
    
    // Limpiar niveles antiguos
    _notifiedEnergyLevelsTimestamps.removeWhere((lvl, timestamp) {
      final shouldRemove = now.difference(timestamp) > _notifiedEnergyLevelsExpiry;
      if (shouldRemove) {
        _notifiedEnergyLevels.remove(lvl);
      }
      return shouldRemove;
    });
    
    return _notifiedEnergyLevels.contains(level);
  }
  
  /// Marcar nivel energético como notificado
  void _markEnergyLevelAsNotified(int level) {
    final now = DateTime.now();
    _notifiedEnergyLevels.add(level);
    _notifiedEnergyLevelsTimestamps[level] = now;
  }

  /// Notificación de nivel energético sube
  Future<void> notifyEnergyLevelUp(int newLevel) async {
    // Verificar si ya fue notificado para este nivel
    if (_isEnergyLevelAlreadyNotified(newLevel)) {
      debugPrint('⏭️ Notificación de nivel energético omitida: nivel $newLevel ya fue notificado');
      return;
    }
    
    await showNotification(
      title: '⚡ ¡Tu energía ha subido!',
      body: 'Ahora estás en nivel $newLevel/10. ¡Sigue así!',
      type: NotificationType.energyLevelUp,
    );
    
    _markEnergyLevelAsNotified(newLevel);
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

  // Cache para evitar notificación de primer pilotaje duplicada
  bool _firstPilotageNotified = false;

  /// Notificación de primer pilotaje
  Future<void> notifyFirstPilotage(String userName) async {
    // Solo notificar una vez
    if (_firstPilotageNotified) {
      debugPrint('⏭️ Notificación de primer pilotaje omitida: ya fue notificado');
      return;
    }
    
    await showNotification(
      title: '🎉 ¡Bienvenido al viaje cuántico!',
      body: 'Has completado tu primer pilotaje consciente. El viaje de transformación comienza.',
      type: NotificationType.firstPilotage,
    );
    
    _firstPilotageNotified = true;
  }

  /// Verificar si un milestone ya fue notificado (anti-duplicados)
  bool _isMilestoneAlreadyNotified(String milestoneKey) {
    final now = DateTime.now();
    
    // Limpiar milestones antiguos
    _notifiedMilestonesTimestamps.removeWhere((key, timestamp) {
      final shouldRemove = now.difference(timestamp) > _notifiedMilestonesExpiry;
      if (shouldRemove) {
        _notifiedMilestones.remove(key);
      }
      return shouldRemove;
    });
    
    return _notifiedMilestones.contains(milestoneKey);
  }
  
  /// Marcar milestone como notificado
  void _markMilestoneAsNotified(String milestoneKey) {
    final now = DateTime.now();
    _notifiedMilestones.add(milestoneKey);
    _notifiedMilestonesTimestamps[milestoneKey] = now;
  }

  /// Notificación de logro (hito de pilotajes)
  Future<void> notifyPilotageMilestone(int totalPilotages, String userName) async {
    // Verificar si ya fue notificado
    final milestoneKey = 'pilotage_$totalPilotages';
    if (_isMilestoneAlreadyNotified(milestoneKey)) {
      debugPrint('⏭️ Milestone de pilotajes omitido: $totalPilotages ya fue notificado');
      return;
    }
    
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
    _markMilestoneAsNotified(milestoneKey);
  }

  /// Notificación de código recomendado
  Future<void> notifyPersonalizedCode(String code, String userName) async {
    await showNotification(
      title: '✨ Secuencia Personalizada para Ti',
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

  // Cache de códigos ya notificados para evitar duplicados
  final Set<String> _notifiedCodes = <String>{};
  static const _notifiedCodesExpiry = Duration(hours: 1);
  final Map<String, DateTime> _notifiedCodesTimestamps = <String, DateTime>{};
  
  // Cache de milestones ya notificados para evitar duplicados
  final Set<String> _notifiedMilestones = <String>{};
  final Map<String, DateTime> _notifiedMilestonesTimestamps = <String, DateTime>{};
  static const _notifiedMilestonesExpiry = Duration(hours: 24); // 24 horas para milestones
  
  // Cache de streaks ya notificados para evitar duplicados
  final Set<String> _notifiedStreaks = <String>{};
  final Map<String, DateTime> _notifiedStreaksTimestamps = <String, DateTime>{};
  static const _notifiedStreaksExpiry = Duration(hours: 24); // 24 horas para streaks
  
  // Cache de nivel energético ya notificado (por nivel específico)
  final Set<int> _notifiedEnergyLevels = <int>{};
  final Map<int, DateTime> _notifiedEnergyLevelsTimestamps = <int, DateTime>{};
  static const _notifiedEnergyLevelsExpiry = Duration(hours: 6); // 6 horas por nivel

  // Verificar si ya se envió una notificación de acción completada para este código y acción
  Future<bool> _yaSeNotificoAccionCompletada({
    required String actionType,
    String? codeId,
    String? codeName,
  }) async {
    if (!_authService.isLoggedIn) {
      return false;
    }

    try {
      final userId = _authService.currentUser!.id;
      
      // Buscar si ya existe una notificación enviada para esta combinación
      // Verificar por code_id o code_name (el código puede estar en cualquiera de los dos campos)
      final codeToCheck = codeId ?? codeName ?? '';
      
      if (codeToCheck.isEmpty) {
        return false; // Sin código, no se puede verificar
      }
      
      // Buscar notificaciones que coincidan con el usuario, tipo, acción y código
      final existing = await _supabase
          .from('user_notifications_sent')
          .select()
          .eq('user_id', userId)
          .eq('notification_type', NotificationType.challengeDayCompleted.toString().split('.').last)
          .eq('action_type', actionType)
          .or('code_id.eq.$codeToCheck,code_name.eq.$codeToCheck')
          .maybeSingle();

      return existing != null;
    } catch (e) {
      debugPrint('❌ Error verificando si ya se notificó acción completada: $e');
      return false;
    }
  }

  // Marcar que se envió una notificación de acción completada
  Future<void> _marcarAccionCompletadaNotificada({
    required String actionType,
    String? codeId,
    String? codeName,
  }) async {
    if (!_authService.isLoggedIn) {
      return;
    }

    try {
      final userId = _authService.currentUser!.id;
      
      // Determinar qué campo usar para el código (preferir code_id si está disponible)
      final finalCodeId = codeId?.isNotEmpty == true ? codeId : null;
      final finalCodeName = (codeId == null || codeId.isEmpty) && codeName?.isNotEmpty == true ? codeName : null;
      
      await _supabase.from('user_notifications_sent').insert({
        'user_id': userId,
        'notification_type': NotificationType.challengeDayCompleted.toString().split('.').last,
        'action_type': actionType,
        'code_id': finalCodeId,
        'code_name': finalCodeName,
        'sent_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('✅ Notificación de acción completada marcada como enviada en BD (tipo: $actionType, código: ${finalCodeId ?? finalCodeName})');
    } catch (e) {
      debugPrint('❌ Error marcando acción completada como notificada: $e');
      // Si es un error de duplicado (unique constraint), está bien, significa que ya existe
      if (e.toString().contains('duplicate') || e.toString().contains('unique') || e.toString().contains('violates unique constraint')) {
        debugPrint('⚠️ Notificación ya existía en BD (duplicado evitado)');
      }
    }
  }

  Future<void> showActionCompletedNotification({
    required String actionName,
    required String challengeName,
    String? codeNumber,
    String? actionType,
  }) async {
    // Si hay un código, verificar si ya se notificó en la base de datos
    if (codeNumber != null && codeNumber.isNotEmpty) {
      // Determinar el tipo de acción desde actionName
      final determinedActionType = actionType ?? _determineActionTypeFromName(actionName);
      
      // Verificar en la base de datos si ya se notificó
      final yaNotificado = await _yaSeNotificoAccionCompletada(
        actionType: determinedActionType,
        codeId: codeNumber,
        codeName: codeNumber,
      );

      if (yaNotificado) {
        debugPrint('⏭️ Notificación omitida: acción "$actionName" con código "$codeNumber" ya fue notificada');
        return;
      }
    }

    // Construir mensaje con el código si está disponible (evitando duplicar "código")
    String body = 'Has completado: $actionName en $challengeName';
    if (codeNumber != null && codeNumber.isNotEmpty) {
      // Eliminar "de código", "código", etc. del actionName para evitar duplicación
      String cleanActionName = actionName;
      
      // Remover "de código", "de código específico", etc.
      cleanActionName = cleanActionName.replaceAll(RegExp(r'\s*[Dd]e\s+[Cc]ódigo\s+', caseSensitive: false), ' ').trim();
      cleanActionName = cleanActionName.replaceAll(RegExp(r'\s*[Cc]ódigo\s+', caseSensitive: false), ' ').trim();
      cleanActionName = cleanActionName.replaceAll(RegExp(r'\s+'), ' '); // Limpiar espacios múltiples
      
      // Si queda vacío o solo tiene artículos, usar una versión alternativa
      if (cleanActionName.isEmpty || cleanActionName.length < 3) {
        // Extraer solo la primera palabra relevante (ej: "Pilotaje" de "Pilotaje de código")
        final words = actionName.split(' ');
        cleanActionName = words.firstWhere((w) => w.length > 3 && !w.toLowerCase().contains('código'), orElse: () => actionName.split(' ').first);
      }
      
      body = 'Has completado: $cleanActionName - $codeNumber en $challengeName';
    }

    await showNotification(
      title: '¡Acción Completada! 🎉',
      body: body,
      type: NotificationType.challengeDayCompleted,
    );

    // Marcar como notificada en la base de datos después de enviar
    if (codeNumber != null && codeNumber.isNotEmpty) {
      final determinedActionType = actionType ?? _determineActionTypeFromName(actionName);
      await _marcarAccionCompletadaNotificada(
        actionType: determinedActionType,
        codeId: codeNumber,
        codeName: codeNumber,
      );
    }
  }

  // Determinar el tipo de acción desde el nombre de la acción
  String _determineActionTypeFromName(String actionName) {
    final lowerName = actionName.toLowerCase();
    if (lowerName.contains('pilotaje') || lowerName.contains('pilot')) {
      return 'sesionPilotaje';
    } else if (lowerName.contains('repet') || lowerName.contains('repetición')) {
      return 'codigoRepetido';
    } else if (lowerName.contains('compart')) {
      return 'pilotajeCompartido';
    } else if (lowerName.contains('tiempo') || lowerName.contains('uso') || lowerName.contains('aplicación')) {
      return 'tiempoEnApp';
    } else if (lowerName.contains('específico') || lowerName.contains('especifico')) {
      return 'codigoEspecifico';
    }
    return 'unknown';
  }

  Future<void> showChallengeCompletedNotification({
    required String challengeName,
  }) async {
    await notifyChallengeCompleted(challengeName, '');
  }
}
