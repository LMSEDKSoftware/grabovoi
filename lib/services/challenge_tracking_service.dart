import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/challenge_model.dart';
import '../models/notification_type.dart';
import 'auth_service_simple.dart';
import 'notification_service.dart';
import 'challenge_service.dart';
import 'rewards_service.dart';

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
    // NOTA: Para sesiones de pilotaje, la notificación principal viene de onPilotageCompleted()
    // que ya incluye el código. NO enviar notificación aquí para evitar duplicados.
    if (action.type != ActionType.sesionPilotaje) {
      await _showActionNotification(action);
    } else {
      // Para pilotajes, solo log (la notificación principal viene de NotificationScheduler.onPilotageCompleted())
      // que ya incluye el código en la notificación
      print('📝 Pilotaje registrado. La notificación principal se enviará desde NotificationScheduler con código ${action.codeId ?? action.codeName}.');
    }
    
    notifyListeners();
  }

  // Mostrar notificación de acción completada
  Future<void> _showActionNotification(UserAction action) async {
    try {
      String actionName = '';
      String? codeNumber = action.codeName ?? action.codeId;
      
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

      // Incluir el código en la notificación si está disponible
      await _notificationService.showActionCompletedNotification(
        actionName: actionName,
        challengeName: challengeName,
        codeNumber: codeNumber, // Incluir el código
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
    
    // Verificar racha al iniciar
    await verificarYActualizarRacha(challenge.id);
    
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
      // Actualizar lastActivity para indicar que el desafío está completado
      final updatedProgress = progress.copyWith(
        lastActivity: DateTime.now(),
      );
      _challengesProgress[challengeId] = updatedProgress;
      
      // Notificar cambios
      _progressControllers[challengeId]?.add(updatedProgress);
      notifyListeners();
    }
  }

  // Actualizar desafíos activos basándose en la acción del usuario
  Future<void> _updateActiveChallenges(UserAction action) async {
    for (final challengeId in _challengesProgress.keys) {
      await _updateChallengeProgress(challengeId, action);
    }
  }

  // Verificar y manejar pérdida de racha (llamar al cargar desafío o al iniciar app)
  Future<void> verificarYActualizarRacha(String challengeId) async {
    await _verificarYManejarPerdidaRacha(challengeId);
  }

  // Verificar si hay días perdidos y manejar pérdida de racha
  Future<void> _verificarYManejarPerdidaRacha(String challengeId) async {
    final progress = _challengesProgress[challengeId];
    if (progress == null) return;

    final challengeService = ChallengeService();
    final challenge = challengeService.getChallenge(challengeId);
    if (challenge == null || challenge.startDate == null) return;

    final today = DateTime.now();
    final startDate = challenge.startDate!;
    final todayNormalized = DateTime(today.year, today.month, today.day);
    
    // Verificar cada día desde el inicio hasta ayer (no verificamos hoy porque aún se puede completar)
    for (int day = 1; day <= challenge.durationDays; day++) {
      final dayDate = startDate.add(Duration(days: day - 1));
      final dayDateNormalized = DateTime(dayDate.year, dayDate.month, dayDate.day);
      
      // Solo verificar días pasados (no el día de hoy)
      if (dayDateNormalized.isBefore(todayNormalized)) {
        final dayProgress = progress.dayProgress[day];
        
        // Si el día pasó y no está completado, es un día perdido
        if (dayProgress == null || !dayProgress.isCompleted) {
          print('⚠️ Día $day perdido (${dayDateNormalized.toString().split(' ')[0]}). Intentando usar ancla...');
          
          // Día perdido - intentar usar ancla automáticamente
          final anclaUsada = await _intentarUsarAnclaContinuidad(challengeId, day);
          
          if (!anclaUsada) {
            // No hay anclas disponibles - reiniciar desafío
            print('❌ No hay anclas disponibles. Reiniciando desafío...');
            await _reiniciarDesafio(challengeId);
            return; // Salir después de reiniciar
          } else {
            print('✅ Ancla usada para salvar día $day');
          }
        }
      }
    }
  }

  // Intentar usar una ancla de continuidad para salvar un día perdido
  Future<bool> _intentarUsarAnclaContinuidad(String challengeId, int dayNumber) async {
    try {
      final rewardsService = RewardsService();
      final rewards = await rewardsService.getUserRewards();
      
      if (rewards.anclasContinuidad <= 0) {
        return false; // No hay anclas disponibles
      }

      // Usar ancla automáticamente
      await rewardsService.usarAnclaContinuidad();
      
      // Marcar el día como completado con ancla
      final progress = _challengesProgress[challengeId];
      if (progress != null) {
        // Obtener o crear el progreso del día
        final dayProgress = progress.dayProgress[dayNumber] ?? DayProgress(
          day: dayNumber,
          date: DateTime.now(),
          actionCounts: {},
          actionDurations: {},
          isCompleted: false,
          completedActions: [],
        );
        
        final updatedDayProgress = dayProgress.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
        );
        
        final updatedDayProgressMap = Map<int, DayProgress>.from(progress.dayProgress);
        updatedDayProgressMap[dayNumber] = updatedDayProgress;
        
        final updatedProgress = progress.copyWith(
          dayProgress: updatedDayProgressMap,
          lastActivity: DateTime.now(),
        );
        
        _challengesProgress[challengeId] = updatedProgress;
        
        // Actualizar en Supabase
        try {
          final challengeService = ChallengeService();
          final challenge = challengeService.getChallenge(challengeId);
          if (challenge != null && _authService.isLoggedIn) {
            await _supabase
                .from('user_challenges')
                .update({
                  'day_progress': updatedDayProgressMap.map((k, v) => MapEntry(k.toString(), v.toJson())),
                  'last_activity': DateTime.now().toIso8601String(),
                })
                .eq('user_id', _authService.currentUser!.id)
                .eq('challenge_id', challengeId);
          }
        } catch (e) {
          print('⚠️ Error actualizando en Supabase: $e');
        }
        
        _progressControllers[challengeId]?.add(updatedProgress);
        
        // Obtener información del desafío y usuario para el mensaje
        final challengeService = ChallengeService();
        final challenge = challengeService.getChallenge(challengeId);
        final userName = _authService.currentUser?.email?.split('@').first ?? 'Usuario';
        
        // Calcular días completados para el mensaje
        final daysCompleted = updatedProgress.dayProgress.values.where((dp) => dp.isCompleted).length;
        
        // Notificar al usuario con mensaje motivacional
        await _notificationService.showNotification(
          title: '🔗 ¡TU ANCLA TE SALVÓ!',
          body: 'Tu ancla de continuidad salvó tu racha en el día $dayNumber. ¡No pierdas la racha que llevas! Llevas $daysCompleted días completados en el desafío "${challenge?.title ?? 'Desafío'}". Sigue así, $userName.',
          type: NotificationType.challengeDayCompleted,
        );
        
        print('✅ Ancla de continuidad usada para salvar día $dayNumber del desafío $challengeId');
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Error intentando usar ancla de continuidad: $e');
      return false;
    }
  }

  // Reiniciar desafío al día 1
  Future<void> _reiniciarDesafio(String challengeId) async {
    try {
      final challengeService = ChallengeService();
      final challenge = challengeService.getChallenge(challengeId);
      if (challenge == null) return;

      final now = DateTime.now();
      final newStartDate = DateTime(now.year, now.month, now.day);
      final newEndDate = newStartDate.add(Duration(days: challenge.durationDays));
      final newDayProgress = DayProgress(
        day: 1,
        date: newStartDate,
        actionCounts: {},
        actionDurations: {},
        isCompleted: false,
        completedActions: [],
      );

      // Actualizar en Supabase
      await _supabase
          .from('user_challenges')
          .update({
            'start_date': newStartDate.toIso8601String(),
            'end_date': newEndDate.toIso8601String(),
            'current_day': 1,
            'total_progress': 0,
            'day_progress': {'1': newDayProgress.toJson()},
          })
          .eq('user_id', _authService.currentUser!.id)
          .eq('challenge_id', challengeId);

      // Actualizar el Challenge en ChallengeService también
      final updatedChallenge = challenge.copyWith(
        startDate: newStartDate,
        endDate: newEndDate,
        currentDay: 1,
        dayProgress: {1: newDayProgress},
        totalProgress: 0,
      );
      challengeService.actualizarDesafio(challengeId, updatedChallenge);
      
      // Actualizar en memoria
      final progress = _challengesProgress[challengeId];
      if (progress != null) {
        final updatedProgress = progress.copyWith(
          currentDay: 1,
          dayProgress: {1: newDayProgress},
          lastActivity: DateTime.now(),
        );
        
        _challengesProgress[challengeId] = updatedProgress;
        _progressControllers[challengeId]?.add(updatedProgress);
        
        // Notificar al usuario
        await _notificationService.showNotification(
          title: '⚠️ Desafío Reiniciado',
          body: 'El desafío "${challenge.title}" ha sido reiniciado al día 1 porque se perdió la racha. ¡Puedes comenzar de nuevo!',
          type: NotificationType.challengeAtRisk,
        );
        
        print('🔄 Desafío $challengeId reiniciado al día 1 (nuevo startDate: ${newStartDate.toString().split(' ')[0]})');
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error reiniciando desafío: $e');
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

  // Calcular número de día basándose en la fecha de inicio del desafío
  int _getDayNumber(ChallengeProgress progress, DateTime currentDate) {
    // Obtener el desafío para obtener startDate
    final challengeService = ChallengeService();
    final challenge = challengeService.getChallenge(progress.challengeId);
    
    if (challenge == null || challenge.startDate == null) {
      return progress.currentDay; // Fallback si no hay fecha de inicio
    }
    
    // Calcular días transcurridos desde el inicio
    final startDate = challenge.startDate!;
    final daysSinceStart = currentDate.difference(startDate).inDays;
    final calculatedDay = daysSinceStart + 1; // Día 1 es el día de inicio
    
    // Asegurar que el día esté dentro del rango válido
    return calculatedDay.clamp(1, challenge.durationDays);
  }

  // Crear controlador de progreso para un desafío
  void _createProgressController(String challengeId) {
    if (!_progressControllers.containsKey(challengeId)) {
      _progressControllers[challengeId] = StreamController<ChallengeProgress>.broadcast();
    }
  }

  // Método público para registrar progreso (usado por ChallengeService)
  void registrarProgreso(ChallengeProgress progress) {
    _challengesProgress[progress.challengeId] = progress;
    _createProgressController(progress.challengeId);
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
