import 'package:flutter/foundation.dart';
import '../models/notification_preferences.dart';
import '../models/challenge_model.dart';
import 'notification_service.dart';
import 'auth_service_simple.dart';
import 'user_progress_service.dart';
import 'challenge_service.dart';

/// Servicio para gestionar la programación y lógica de notificaciones
/// LOCALES (recordatorios diarios y feedback inmediato de acciones que el
/// propio dispositivo acaba de originar). Todo lo demás — primer pilotaje,
/// hitos de pilotajes/racha, nivel energético, racha en riesgo/perdida,
/// desafíos — lo maneja el servidor (triggers de Postgres + crons en
/// Supabase Edge Functions) como única fuente de verdad, para no mandar la
/// misma notificación dos veces por dos caminos distintos.
class NotificationScheduler {
  static final NotificationScheduler _instance = NotificationScheduler._internal();
  factory NotificationScheduler() => _instance;
  NotificationScheduler._internal();

  final NotificationService _notificationService = NotificationService();
  final AuthServiceSimple _authService = AuthServiceSimple();
  final UserProgressService _progressService = UserProgressService();
  int? _lastKnownStreakDays;

  /// Inicializar el scheduler: programa los recordatorios diarios locales.
  Future<void> initialize() async {
    debugPrint('🚀 Inicializando NotificationScheduler...');
    final preferences = await NotificationPreferences.load();
    await _notificationService.scheduleDailyNotifications(preferences);
    debugPrint('✅ NotificationScheduler inicializado');
  }

  /// Registra una sesión de pilotaje y envía el feedback local inmediato.
  /// Primer pilotaje, hitos de pilotajes/racha y cambios de nivel energético
  /// ya NO se mandan aquí: los cubre el trigger de servidor sobre
  /// usuario_progreso (single source of truth).
  Future<void> onPilotageCompleted({String? codeNumber}) async {
    final preferences = await NotificationPreferences.load();
    if (!preferences.enabled) return;

    final userProgress = await _progressService.getUserProgress();
    if (userProgress == null) return;

    final totalPilotages = userProgress['total_pilotajes'] ?? 0;
    final consecutiveDays = userProgress['dias_consecutivos'] ?? 0;
    final energyLevel = userProgress['nivel_energetico'] ?? 1;
    final userName = _authService.currentUser?.name ?? 'Piloto Consciente';

    // Feedback inmediato por mantener racha (una vez por día, baja prioridad)
    final streakMaintained = consecutiveDays >= 3 &&
                             _lastKnownStreakDays != null &&
                             _lastKnownStreakDays != consecutiveDays &&
                             consecutiveDays == _lastKnownStreakDays! + 1;
    if (streakMaintained) {
      await _notificationService.notifyThanksForStreak(userName);
      _lastKnownStreakDays = consecutiveDays;
      return;
    }

    // Feedback genérico de acción completada (siempre que haya código),
    // una sola vez por código gracias al dedupe interno del servicio.
    if (codeNumber != null && codeNumber.isNotEmpty) {
      String challengeName = 'Desafío Activo';
      try {
        final challengeService = ChallengeService();
        final userChallenges = challengeService.getUserChallenges();
        final activeChallenge = userChallenges.firstWhere(
          (c) => c.status == ChallengeStatus.enProgreso,
          orElse: () => userChallenges.first,
        );
        challengeName = activeChallenge.title;
      } catch (e) {
        // Sin desafío activo: usar el nombre por defecto
      }

      await _notificationService.showActionCompletedNotification(
        actionName: 'Pilotaje',
        challengeName: challengeName,
        codeNumber: codeNumber,
        actionType: 'sesionPilotaje',
      );
    }

    _lastKnownStreakDays = consecutiveDays;
    // energyLevel/totalPilotages ya no se usan localmente, pero se leyeron
    // arriba junto con el resto del progreso en una sola consulta.
    debugPrint('📊 Progreso tras pilotaje: $totalPilotages pilotajes, nivel $energyLevel');
  }

  /// Registra completar una repetición: feedback inmediato local.
  Future<void> onRepetitionCompleted() async {
    final preferences = await NotificationPreferences.load();
    if (!preferences.enabled) return;
    await _notificationService.notifyEnjoyPilotage();
  }

  /// Actualizar preferencias y reprogramar los recordatorios diarios locales.
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    await preferences.save();
    await _notificationService.initialize();
    await _notificationService.scheduleDailyNotifications(preferences);
  }
}
