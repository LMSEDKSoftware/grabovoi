import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/challenge_model.dart';
import 'auth_service_simple.dart';
import 'notification_service.dart';

class ChallengeTrackingService extends ChangeNotifier {
  static final ChallengeTrackingService _instance = ChallengeTrackingService._internal();
  factory ChallengeTrackingService() => _instance;
  ChallengeTrackingService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthServiceSimple _authService = AuthServiceSimple();
  final NotificationService _notificationService = NotificationService();
  
  final Map<String, ChallengeProgress> _challengesProgress = {};
  final List<UserAction> _userActions = [];
  final Map<String, StreamController<ChallengeProgress>> _progressControllers = {};

  // Getters
  Map<String, ChallengeProgress> get challengesProgress => Map.unmodifiable(_challengesProgress);
  List<UserAction> get userActions => List.unmodifiable(_userActions);
  
  // Obtener progreso de un desafío específico
  ChallengeProgress? getChallengeProgress(String challengeId) {
    return _challengesProgress[challengeId];
  }

  // Obtener acciones recientes del usuario
  List<UserAction> getRecentActions({int limit = 50}) {
    final sortedActions = List<UserAction>.from(_userActions)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sortedActions.take(limit).toList();
  }

  // Registrar una acción del usuario
  Future<void> recordUserAction({
    required ActionType type,
    String? codeId,
    String? codeName,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) async {
    final action = UserAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      timestamp: DateTime.now(),
      codeId: codeId,
      codeName: codeName,
      duration: duration,
      metadata: metadata,
    );

    _userActions.add(action);
    
    // Mantener solo las últimas 1000 acciones para optimizar memoria
    if (_userActions.length > 1000) {
      _userActions.removeRange(0, _userActions.length - 1000);
    }

    // Guardar en Supabase si el usuario está autenticado
    if (_authService.isLoggedIn) {
      try {
        await _supabase.from('user_actions').insert({
          'user_id': _authService.currentUser!.id,
          'action_type': type.toString().split('.').last,
          'action_data': {
            'codeId': codeId,
            'codeName': codeName,
            'duration': duration?.inMinutes,
            'metadata': metadata,
            'timestamp': action.timestamp.toIso8601String(),
          },
        });
      } catch (e) {
        print('Error guardando acción en Supabase: $e');
      }
    }

    // Actualizar progreso de desafíos activos
    await _updateActiveChallenges(action);
    
    // Mostrar notificación de acción completada
    await _showActionNotification(action);
    
    notifyListeners();
  }

  // Mostrar notificación de acción completada
  Future<void> _showActionNotification(UserAction action) async {
    try {
      String actionName = '';
      switch (action.type) {
        case ActionType.sesionPilotaje:
          actionName = 'Pilotaje de código';
          break;
        case ActionType.pilotajeCompartido:
          actionName = 'Pilotaje compartido';
          break;
        case ActionType.codigoRepetido:
          actionName = 'Repetición de código';
          break;
        case ActionType.tiempoEnApp:
          actionName = 'Uso de la aplicación';
          break;
        case ActionType.codigoEspecifico:
          actionName = 'Código específico';
          break;
      }

      // Obtener el nombre del desafío activo
      String challengeName = 'Desafío Activo';
      for (final progress in _challengesProgress.values) {
        if (progress.currentDay > 0) {
          challengeName = 'Desafío de Iniciación Energética';
          break;
        }
      }

      await _notificationService.showActionCompletedNotification(
        actionName: actionName,
        challengeName: challengeName,
      );
    } catch (e) {
      print('Error mostrando notificación: $e');
    }
  }

  // Iniciar un desafío
  Future<void> startChallenge(Challenge challenge) async {
    final progress = ChallengeProgress(
      challengeId: challenge.id,
      currentDay: 1,
      dayProgress: {},
      totalActionsCompleted: 0,
      totalTimeSpent: Duration.zero,
      recentActions: [],
      lastActivity: DateTime.now(),
    );

    _challengesProgress[challenge.id] = progress;
    _createProgressController(challenge.id);
    
    notifyListeners();
  }

  // Pausar un desafío
  Future<void> pauseChallenge(String challengeId) async {
    final progress = _challengesProgress[challengeId];
    if (progress != null) {
      // Aquí podrías implementar lógica para pausar
      notifyListeners();
    }
  }

  // Completar un desafío
  Future<void> completeChallenge(String challengeId) async {
    final progress = _challengesProgress[challengeId];
    if (progress != null) {
      // Aquí podrías implementar lógica para marcar como completado
      notifyListeners();
    }
  }

  // Actualizar desafíos activos basándose en la acción del usuario
  Future<void> _updateActiveChallenges(UserAction action) async {
    for (final challengeId in _challengesProgress.keys) {
      await _updateChallengeProgress(challengeId, action);
    }
  }

  // Actualizar progreso de un desafío específico
  Future<void> _updateChallengeProgress(String challengeId, UserAction action) async {
    final progress = _challengesProgress[challengeId];
    if (progress == null) return;

    final today = DateTime.now();
    final dayNumber = _getDayNumber(progress, today);
    
    if (dayNumber <= 0) return; // Desafío no ha comenzado o ya terminó

    // Obtener o crear progreso del día
    final dayProgress = progress.dayProgress[dayNumber] ?? DayProgress(
      day: dayNumber,
      date: today,
      actionCounts: {},
      actionDurations: {},
      isCompleted: false,
      completedActions: [],
    );

    // Actualizar contadores de acciones
    final updatedActionCounts = Map<ActionType, int>.from(dayProgress.actionCounts);
    updatedActionCounts[action.type] = (updatedActionCounts[action.type] ?? 0) + 1;

    // Actualizar duraciones si aplica
    final updatedActionDurations = Map<ActionType, Duration>.from(dayProgress.actionDurations);
    if (action.duration != null) {
      final currentDuration = updatedActionDurations[action.type] ?? Duration.zero;
      updatedActionDurations[action.type] = currentDuration + action.duration!;
    }

    // Verificar si el día está completado
    final isDayCompleted = _checkDayCompletion(dayNumber, updatedActionCounts, updatedActionDurations);
    
    final updatedDayProgress = dayProgress.copyWith(
      actionCounts: updatedActionCounts,
      actionDurations: updatedActionDurations,
      isCompleted: isDayCompleted,
      completedAt: isDayCompleted ? DateTime.now() : null,
      completedActions: isDayCompleted ? [...dayProgress.completedActions, action.id] : dayProgress.completedActions,
    );

    // Actualizar progreso del desafío
    final updatedDayProgressMap = Map<int, DayProgress>.from(progress.dayProgress);
    updatedDayProgressMap[dayNumber] = updatedDayProgress;

    final updatedProgress = progress.copyWith(
      dayProgress: updatedDayProgressMap,
      totalActionsCompleted: progress.totalActionsCompleted + 1,
      totalTimeSpent: progress.totalTimeSpent + (action.duration ?? Duration.zero),
      recentActions: [action, ...progress.recentActions.take(19)], // Mantener últimas 20
      lastActivity: DateTime.now(),
    );

    _challengesProgress[challengeId] = updatedProgress;

    // Notificar cambios a través del stream
    _progressControllers[challengeId]?.add(updatedProgress);
  }

  // Verificar si un día está completado
  bool _checkDayCompletion(int dayNumber, Map<ActionType, int> actionCounts, Map<ActionType, Duration> actionDurations) {
    // Aquí implementarías la lógica específica para cada desafío
    // Por ejemplo, para un desafío de 7 días:
    
    final codigosRepetidos = actionCounts[ActionType.codigoRepetido] ?? 0;
    final sesionesPilotaje = actionCounts[ActionType.sesionPilotaje] ?? 0;
    final pilotajesCompartidos = actionCounts[ActionType.pilotajeCompartido] ?? 0;
    final tiempoEnApp = actionDurations[ActionType.tiempoEnApp] ?? Duration.zero;
    
    if (dayNumber <= 7) {
      return codigosRepetidos >= 1 &&
          pilotajesCompartidos >= 1 &&
          tiempoEnApp.inMinutes >= 15;
    }
    
    if (dayNumber <= 14) {
      return codigosRepetidos >= 2 &&
          sesionesPilotaje >= 1 &&
          pilotajesCompartidos >= 1 &&
          tiempoEnApp.inMinutes >= 20;
    }
    
    if (dayNumber <= 21) {
      return codigosRepetidos >= 3 &&
          sesionesPilotaje >= 2 &&
          pilotajesCompartidos >= 2 &&
          tiempoEnApp.inMinutes >= 30;
    }
    
    return codigosRepetidos >= 5 &&
        sesionesPilotaje >= 3 &&
        pilotajesCompartidos >= 3 &&
        tiempoEnApp.inMinutes >= 45;
  }

  // Calcular número de día basándose en la fecha de inicio
  int _getDayNumber(ChallengeProgress progress, DateTime currentDate) {
    // Aquí implementarías la lógica para calcular el día actual
    // Por simplicidad, asumimos que el desafío comenzó hace X días
    return progress.currentDay;
  }

  // Crear controlador de progreso para un desafío
  void _createProgressController(String challengeId) {
    if (!_progressControllers.containsKey(challengeId)) {
      _progressControllers[challengeId] = StreamController<ChallengeProgress>.broadcast();
    }
  }

  // Obtener stream de progreso para un desafío
  Stream<ChallengeProgress>? getChallengeProgressStream(String challengeId) {
    return _progressControllers[challengeId]?.stream;
  }

  // Métodos de utilidad para registrar acciones específicas
  Future<void> recordCodeRepetition(String codeId, String codeName) async {
    await recordUserAction(
      type: ActionType.codigoRepetido,
      codeId: codeId,
      codeName: codeName,
      metadata: {'action': 'code_repetition'},
    );
  }

  Future<void> recordPilotageSession(String codeId, String codeName, Duration duration) async {
    await recordUserAction(
      type: ActionType.sesionPilotaje,
      codeId: codeId,
      codeName: codeName,
      duration: duration,
      metadata: {'action': 'pilotage_session'},
    );
  }

  Future<void> recordPilotageShare({String? codeId, String? codeName}) async {
    await recordUserAction(
      type: ActionType.pilotajeCompartido,
      codeId: codeId,
      codeName: codeName,
      metadata: {'action': 'pilotage_share'},
    );
  }

  Future<void> recordAppTime(Duration duration) async {
    await recordUserAction(
      type: ActionType.tiempoEnApp,
      duration: duration,
      metadata: {'action': 'app_usage'},
    );
  }

  Future<void> recordSpecificCode(String codeId, String codeName) async {
    await recordUserAction(
      type: ActionType.codigoEspecifico,
      codeId: codeId,
      codeName: codeName,
      metadata: {'action': 'specific_code'},
    );
  }

  @override
  void dispose() {
    for (final controller in _progressControllers.values) {
      controller.close();
    }
    _progressControllers.clear();
    super.dispose();
  }
}
