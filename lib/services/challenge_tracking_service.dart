import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Cache local para evitar escribir uso de app en Supabase demasiado frecuente
  String? _lastAppUsageDayKey;
  int _lastAppUsageTotalSeconds = 0;

  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

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
        // Para tiempo en app, evitar escribir registros demasiado frecuentes.
        if (type == ActionType.tiempoEnApp) {
          final todayKey = _getTodayKey();
          final totalSeconds = (metadata['total_seconds'] as int?) ?? duration?.inSeconds ?? 0;

          // Si el incremento es menor a 60s respecto al último registro de hoy, omitir escritura.
          if (_lastAppUsageDayKey == todayKey &&
              totalSeconds > 0 &&
              (totalSeconds - _lastAppUsageTotalSeconds) < 60) {
            _lastAppUsageTotalSeconds = totalSeconds;
          } else {
            _lastAppUsageDayKey = todayKey;
            _lastAppUsageTotalSeconds = totalSeconds;
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
          }
        } else {
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
        }
      } catch (e) {
        print('Error guardando acción en Supabase: $e');
      }
    }

    // Actualizar progreso de desafíos activos
    await _updateActiveChallenges(action);
    
    // Mostrar notificación de acción completada
    // NOTA:
    // - Para sesiones de pilotaje, la notificación principal viene de onPilotageCompleted()
    //   que ya incluye el código. NO enviar notificación aquí para evitar duplicados.
    // - Para tiempo en app, preferimos no enviar notificaciones de "acción completada"
    //   en cada actualización parcial para evitar ruido y consumo innecesario.
    if (action.type != ActionType.sesionPilotaje &&
        action.type != ActionType.tiempoEnApp) {
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
      // IMPORTANTE: Verificar que haya al menos un desafío activo antes de enviar notificación
      if (_challengesProgress.isEmpty) {
        print('⏭️ No hay desafíos activos, omitiendo notificación de acción completada');
        return;
      }
      
      // Verificar que haya al menos un desafío con progreso (iniciado)
      bool hasActiveChallenge = false;
      String? activeChallengeId;
      for (final entry in _challengesProgress.entries) {
        if (entry.value.currentDay > 0) {
          hasActiveChallenge = true;
          activeChallengeId = entry.key;
          break;
        }
      }
      
      if (!hasActiveChallenge) {
        print('⏭️ No hay desafíos iniciados, omitiendo notificación de acción completada');
        return;
      }
      
      // Verificar también en ChallengeService que el desafío esté realmente en progreso
      try {
        final challengeService = ChallengeService();
        if (activeChallengeId != null) {
          final challenge = challengeService.getChallenge(activeChallengeId);
          if (challenge == null || challenge.status != ChallengeStatus.enProgreso) {
            print('⏭️ Desafío no está en progreso, omitiendo notificación de acción completada');
            return;
          }
        }
      } catch (e) {
        print('⚠️ Error verificando estado del desafío: $e');
        // Continuar de todas formas si hay error
      }
      
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
      if (activeChallengeId != null) {
        try {
          final challengeService = ChallengeService();
          final challenge = challengeService.getChallenge(activeChallengeId);
          if (challenge != null) {
            challengeName = challenge.title;
          }
        } catch (e) {
          print('⚠️ Error obteniendo nombre del desafío: $e');
        }
      }

      // Incluir el código en la notificación si está disponible
      await _notificationService.showActionCompletedNotification(
        actionName: actionName,
        challengeName: challengeName,
        codeNumber: codeNumber, // Incluir el código
        actionType: action.type.toString().split('.').last, // Pasar el tipo de acción
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

    // Lógica especial para el desafío Maestro de Abundancia (30 días)
    if (challengeId == 'maestro_abundancia') {
      await _verificarMaestroAbundancia(challengeId, challenge, progress);
      return;
    }

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

  // Lógica especial para el desafío Maestro de Abundancia
  Future<void> _verificarMaestroAbundancia(String challengeId, Challenge challenge, ChallengeProgress progress) async {
    final today = DateTime.now();
    final startDate = challenge.startDate!;
    final todayNormalized = DateTime(today.year, today.month, today.day);
    
    // Encontrar días perdidos consecutivos más recientes
    // Verificar desde ayer hacia atrás para encontrar la secuencia más reciente de días perdidos
    int consecutiveLostDays = 0;
    bool foundLostDay = false;
    
    // Buscar desde ayer hacia atrás
    for (int offset = 1; offset <= challenge.durationDays; offset++) {
      final checkDate = todayNormalized.subtract(Duration(days: offset));
      final dayNumber = checkDate.difference(startDate).inDays + 1;
      
      // Solo verificar días dentro del rango del desafío
      if (dayNumber < 1 || dayNumber > challenge.durationDays) {
        break;
      }
      
      // Solo verificar días pasados
      if (checkDate.isBefore(todayNormalized)) {
        final dayProgress = progress.dayProgress[dayNumber];
        final isLost = dayProgress == null || !dayProgress.isCompleted;
        
        if (isLost) {
          if (!foundLostDay) {
            // Primer día perdido encontrado
            foundLostDay = true;
            consecutiveLostDays = 1;
          } else {
            // Verificar si es consecutivo al día anterior
            final previousDayNumber = dayNumber + 1;
            if (previousDayNumber <= challenge.durationDays) {
              final previousDayProgress = progress.dayProgress[previousDayNumber];
              final previousDayDate = startDate.add(Duration(days: previousDayNumber - 1));
              final previousDayDateNormalized = DateTime(previousDayDate.year, previousDayDate.month, previousDayDate.day);
              
              // Si el día anterior también está perdido y es consecutivo, incrementar
              if (previousDayDateNormalized.isBefore(todayNormalized) &&
                  (previousDayProgress == null || !previousDayProgress.isCompleted)) {
                consecutiveLostDays++;
              } else {
                // No es consecutivo, romper el ciclo
                break;
              }
            } else {
              consecutiveLostDays++;
            }
          }
        } else {
          // Si encontramos un día completado, romper la secuencia
          if (foundLostDay) {
            break;
          }
        }
      }
    }
    
    print('🔍 Maestro de Abundancia: Días perdidos consecutivos más recientes: $consecutiveLostDays');
    
    // Si hay 2 o más días consecutivos perdidos, bajar de nivel
    if (consecutiveLostDays >= 2) {
      print('⚠️ Maestro de Abundancia: 2 días consecutivos perdidos. Bajando de nivel...');
      await _bajarDeNivelMaestro();
      return;
    }
    
    // Si hay 1 día perdido, reiniciar el desafío
    if (consecutiveLostDays == 1) {
      print('⚠️ Maestro de Abundancia: 1 día perdido. Reiniciando desafío...');
      await _reiniciarDesafio(challengeId);
      return;
    }
    
    // Si no hay días perdidos consecutivos, verificar si hay días individuales perdidos (no consecutivos)
    // En este caso, intentar usar anclas
    for (int day = 1; day <= challenge.durationDays; day++) {
      final dayDate = startDate.add(Duration(days: day - 1));
      final dayDateNormalized = DateTime(dayDate.year, dayDate.month, dayDate.day);
      
      if (dayDateNormalized.isBefore(todayNormalized)) {
        final dayProgress = progress.dayProgress[day];
        
        if (dayProgress == null || !dayProgress.isCompleted) {
          // Intentar usar ancla para salvar el día
          final anclaUsada = await _intentarUsarAnclaContinuidad(challengeId, day);
          if (!anclaUsada) {
            // Si no hay anclas y es un día perdido, reiniciar
            print('⚠️ Maestro de Abundancia: Día $day perdido sin anclas. Reiniciando...');
            await _reiniciarDesafio(challengeId);
            return;
          }
        }
      }
    }
  }

  // Bajar de nivel del Maestro de Abundancia al desafío de 21 días
  Future<void> _bajarDeNivelMaestro() async {
    try {
      if (!_authService.isLoggedIn) return;
      
      final challengeService = ChallengeService();
      
      // Eliminar el desafío maestro de la base de datos para que pueda volver a intentarlo después
      await _supabase
          .from('user_challenges')
          .delete()
          .eq('user_id', _authService.currentUser!.id)
          .eq('challenge_id', 'maestro_abundancia');
      
      // Eliminar el progreso del desafío maestro de memoria
      _challengesProgress.remove('maestro_abundancia');
      _progressControllers['maestro_abundancia']?.close();
      _progressControllers.remove('maestro_abundancia');
      
      // Eliminar también el desafío de 21 días para que pueda reiniciarlo
      await _supabase
          .from('user_challenges')
          .delete()
          .eq('user_id', _authService.currentUser!.id)
          .eq('challenge_id', 'luz_dorada_avanzada');
      
      // Eliminar el progreso del desafío de 21 días de memoria
      _challengesProgress.remove('luz_dorada_avanzada');
      _progressControllers['luz_dorada_avanzada']?.close();
      _progressControllers.remove('luz_dorada_avanzada');
      
      // El servicio de desafíos se actualizará automáticamente cuando se recargue desde Supabase
      
      // Notificar al usuario
      await _notificationService.showNotification(
        title: '⚠️ Nivel Bajado',
        body: 'Has perdido 2 días consecutivos en el Desafío Maestro de Abundancia. Debes completar nuevamente el Desafío Avanzado de Luz Dorada (21 días) antes de volver al nivel Maestro.',
        type: NotificationType.challengeAtRisk,
      );
      
      print('📉 Usuario bajado de nivel Maestro. Debe completar el desafío de 21 días nuevamente.');
      notifyListeners();
    } catch (e) {
      print('❌ Error bajando de nivel maestro: $e');
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

  // Verificar si ya se envió notificación de reinicio para este desafío con este startDate
  Future<bool> _yaSeNotificoReinicio(String challengeId, DateTime startDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startDateNormalized = DateTime(startDate.year, startDate.month, startDate.day);
      final key = 'challenge_restart_notified_${challengeId}_${startDateNormalized.toIso8601String().split('T')[0]}';
      return prefs.getBool(key) ?? false;
    } catch (e) {
      print('❌ Error verificando si ya se notificó reinicio: $e');
      return false;
    }
  }

  // Marcar que se envió notificación de reinicio para este desafío con este startDate
  Future<void> _marcarReinicioNotificado(String challengeId, DateTime startDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startDateNormalized = DateTime(startDate.year, startDate.month, startDate.day);
      final key = 'challenge_restart_notified_${challengeId}_${startDateNormalized.toIso8601String().split('T')[0]}';
      await prefs.setBool(key, true);
      
      // Limpiar notificaciones antiguas (más de 30 días)
      final allKeys = prefs.getKeys();
      final now = DateTime.now();
      for (final key in allKeys) {
        if (key.startsWith('challenge_restart_notified_')) {
          final timestampStr = prefs.getString('${key}_timestamp');
          if (timestampStr != null) {
            try {
              final timestamp = DateTime.parse(timestampStr);
              if (now.difference(timestamp).inDays > 30) {
                await prefs.remove(key);
                await prefs.remove('${key}_timestamp');
              }
            } catch (e) {
              // Si no se puede parsear, eliminar la clave
              await prefs.remove(key);
            }
          }
        }
      }
      
      // Guardar timestamp de esta notificación
      await prefs.setString('${key}_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      print('❌ Error marcando reinicio como notificado: $e');
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

      // Verificar si ya se notificó este reinicio
      final yaNotificado = await _yaSeNotificoReinicio(challengeId, newStartDate);
      
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
        
        // Solo notificar si no se ha notificado antes para este reinicio
        if (!yaNotificado) {
          await _notificationService.showNotification(
            title: '⚠️ Desafío Reiniciado',
            body: 'El desafío "${challenge.title}" ha sido reiniciado al día 1 porque se perdió la racha. ¡Puedes comenzar de nuevo!',
            type: NotificationType.challengeAtRisk,
          );
          
          // Marcar como notificado
          await _marcarReinicioNotificado(challengeId, newStartDate);
          
          print('📢 Notificación de reinicio enviada para desafío $challengeId (startDate: ${newStartDate.toString().split(' ')[0]})');
        } else {
          print('⚠️ Ya se notificó el reinicio de desafío $challengeId para startDate ${newStartDate.toString().split(' ')[0]}. No se enviará notificación duplicada.');
        }
        
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
    final isDayCompleted = _checkDayCompletion(challengeId, dayNumber, updatedActionCounts, updatedActionDurations);
    
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

    // Notificar si el día se completó y no estaba completado antes
    if (isDayCompleted && !dayProgress.isCompleted) {
      final challenge = ChallengeService().getChallenge(challengeId);
      final userName = _authService.currentUser?.email?.split('@').first ?? 'Usuario';
      final daysCompleted = updatedDayProgressMap.values.where((dp) => dp.isCompleted).length;

      await _notificationService.showNotification(
        title: '🎉 ¡DÍA COMPLETADO!',
        body: '¡Felicidades, $userName! Has completado el día $dayNumber del desafío "${challenge?.title ?? 'Desafío'}". Llevas $daysCompleted días completados. ¡Sigue así!',
        type: NotificationType.challengeDayCompleted,
      );
      print('📢 Notificación de día completado enviada para desafío $challengeId, día $dayNumber');
    }

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
  bool _checkDayCompletion(String challengeId, int dayNumber, Map<ActionType, int> actionCounts, Map<ActionType, Duration> actionDurations) {
    try {
      final challengeService = ChallengeService();
      final challenge = challengeService.getChallenge(challengeId);
      
      if (challenge == null) {
        // Fallback a lógica por defecto si no se encuentra el desafío
        return _checkDayCompletionDefault(dayNumber, actionCounts, actionDurations);
      }
      
      // Verificar cada acción requerida definida en el desafío
      for (final action in challenge.dailyActions) {
        final type = action.type;
        final requiredCount = action.requiredCount;
        final requiredDuration = action.requiredDuration;
        
        // Verificar conteo
        final currentCount = actionCounts[type] ?? 0;
        if (currentCount < requiredCount) {
          return false;
        }
        
        // Verificar duración (solo para tiempo en app o sesiones)
        if (requiredDuration != null && requiredDuration > Duration.zero) {
          final currentDuration = actionDurations[type] ?? Duration.zero;
          if (currentDuration < requiredDuration) {
            return false;
          }
        }
        
        // Verificar código específico si aplica
        if (action.specificCode != null) {
          // Esta verificación requeriría acceso al detalle de las acciones, 
          // que no tenemos en los mapas agregados.
          // Por ahora asumimos que si el conteo de 'codigoEspecifico' es suficiente, se cumplió.
          // TODO: Mejorar validación de código específico
        }
      }
      
      return true;
    } catch (e) {
      print('Error verificando completitud del día: $e');
      return false;
    }
  }

  // Lógica por defecto (legacy) para compatibilidad
  bool _checkDayCompletionDefault(int dayNumber, Map<ActionType, int> actionCounts, Map<ActionType, Duration> actionDurations) {
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

  // Sincronizar progreso desde Supabase (reconstruir estado desde acciones)
  Future<void> syncProgressFromSupabase(String challengeId) async {
    try {
      if (!_authService.isLoggedIn) return;

      final challengeService = ChallengeService();
      final challenge = challengeService.getChallenge(challengeId);
      if (challenge == null) return;

      // Determinar fecha de inicio para buscar acciones
      // Si el desafío tiene fecha de inicio, usarla. Si no, buscar desde hace 30 días por seguridad
      final startDate = challenge.startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final startOfHistory = DateTime(startDate.year, startDate.month, startDate.day).toUtc();
      final now = DateTime.now().toUtc();

      // 1. Obtener TODAS las acciones desde el inicio del desafío hasta ahora
      final response = await _supabase
          .from('user_actions')
          .select()
          .eq('user_id', _authService.currentUser!.id)
          .gte('recorded_at', startOfHistory.toIso8601String())
          .lte('recorded_at', now.toIso8601String());

      if (response == null) return;

      // 2. Inicializar progreso
      var progress = _challengesProgress[challengeId];
      if (progress == null) {
        progress = ChallengeProgress(
          challengeId: challengeId,
          currentDay: 1,
          dayProgress: {},
          totalActionsCompleted: 0,
          totalTimeSpent: Duration.zero,
          recentActions: [],
          lastActivity: DateTime.now(),
        );
      }

      // 3. Agrupar acciones por día del desafío
      final Map<int, Map<ActionType, int>> dailyCounts = {};
      final Map<int, Map<ActionType, Duration>> dailyDurations = {};

      for (final row in response as List) {
        final recordedAt = DateTime.parse(row['recorded_at'] as String).toLocal();
        
        // Calcular a qué día del desafío corresponde esta acción
        // Usamos la misma lógica que _getDayNumber pero para la fecha de la acción
        final daysSinceStart = recordedAt.difference(startDate).inDays;
        final actionDayNumber = daysSinceStart + 1;
        
        if (actionDayNumber < 1 || actionDayNumber > challenge.durationDays) continue;

        final typeStr = row['action_type'] as String;
        final data = row['action_data'] as Map<String, dynamic>?;
        
        ActionType type;
        switch (typeStr) {
          case 'codigoRepetido': type = ActionType.codigoRepetido; break;
          case 'sesionPilotaje': type = ActionType.sesionPilotaje; break;
          case 'pilotajeCompartido': type = ActionType.pilotajeCompartido; break;
          case 'tiempoEnApp': type = ActionType.tiempoEnApp; break;
          case 'codigoEspecifico': type = ActionType.codigoEspecifico; break;
          default: continue;
        }

        // Inicializar mapas para este día si no existen
        dailyCounts.putIfAbsent(actionDayNumber, () => {});
        dailyDurations.putIfAbsent(actionDayNumber, () => {});

        // Actualizar contadores
        dailyCounts[actionDayNumber]![type] = (dailyCounts[actionDayNumber]![type] ?? 0) + 1;

        // Actualizar duraciones
        if (type == ActionType.tiempoEnApp && data != null) {
          // Revisar si es un registro de total acumulado o duración individual
          if (data.containsKey('total_seconds')) {
             final totalSeconds = data['total_seconds'] as int;
             // Mantener el máximo tiempo registrado para ese día
             final currentMax = dailyDurations[actionDayNumber]![type]?.inSeconds ?? 0;
             if (totalSeconds > currentMax) {
               dailyDurations[actionDayNumber]![type] = Duration(seconds: totalSeconds);
             }
          } else {
             final durationMinutes = data['duration'] as int? ?? 0;
             final currentDuration = dailyDurations[actionDayNumber]![type] ?? Duration.zero;
             dailyDurations[actionDayNumber]![type] = currentDuration + Duration(minutes: durationMinutes);
          }
        } else if (type == ActionType.sesionPilotaje && data != null) {
           final durationMinutes = data['duration'] as int? ?? 0;
           final currentDuration = dailyDurations[actionDayNumber]![type] ?? Duration.zero;
           dailyDurations[actionDayNumber]![type] = currentDuration + Duration(minutes: durationMinutes);
        }
      }

      // 4. Reconstruir el mapa de progreso día por día
      final updatedDayProgressMap = Map<int, DayProgress>.from(progress.dayProgress);
      
      // Iterar sobre los días que tienen acciones
      for (final dayNum in dailyCounts.keys) {
        final counts = dailyCounts[dayNum]!;
        final durations = dailyDurations[dayNum]!;
        
        final isDayCompleted = _checkDayCompletion(challengeId, dayNum, counts, durations);
        
        // Preservar la fecha original si ya existía, o usar una aproximada
        final existingDayProgress = updatedDayProgressMap[dayNum];
        final date = existingDayProgress?.date ?? startDate.add(Duration(days: dayNum - 1));

        updatedDayProgressMap[dayNum] = DayProgress(
          day: dayNum,
          date: date,
          actionCounts: counts,
          actionDurations: durations,
          isCompleted: isDayCompleted,
          completedAt: isDayCompleted ? (existingDayProgress?.completedAt ?? DateTime.now()) : null,
          completedActions: [], // No necesitamos reconstruir la lista exacta de IDs por ahora
        );
      }

      // 5. Actualizar el progreso general
      final updatedProgress = progress.copyWith(
        dayProgress: updatedDayProgressMap,
        // Recalcular día actual basado en la fecha real
        currentDay: _getDayNumber(progress, DateTime.now()),
      );

      _challengesProgress[challengeId] = updatedProgress;
      _progressControllers[challengeId]?.add(updatedProgress);
      
      print('✅ Progreso HISTÓRICO sincronizado para desafío $challengeId');
      print('   - Días con actividad: ${dailyCounts.keys.toList()}');

    } catch (e) {
      print('❌ Error sincronizando progreso histórico: $e');
    }
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
