import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_preferences.dart';
import '../models/challenge_model.dart';
import 'notification_service.dart';
import 'auth_service_simple.dart';
import 'user_progress_service.dart';
import 'challenge_service.dart';

/// Servicio para gestionar la programación y lógica de notificaciones
class NotificationScheduler {
  static final NotificationScheduler _instance = NotificationScheduler._internal();
  factory NotificationScheduler() => _instance;
  NotificationScheduler._internal();

  final NotificationService _notificationService = NotificationService();
  final AuthServiceSimple _authService = AuthServiceSimple();
  final UserProgressService _progressService = UserProgressService();
  Timer? _schedulerTimer;
  int? _lastKnownEnergyLevel;
  int? _lastKnownTotalPilotages;
  int? _lastKnownStreakDays;
  
  /// Inicializar el scheduler
  Future<void> initialize() async {
    print('🚀 Inicializando NotificationScheduler...');
    
    // Programar notificaciones diarias
    final preferences = await NotificationPreferences.load();
    await _notificationService.scheduleDailyNotifications(preferences);
    
    // Iniciar verificación periódica de eventos (cada 30 minutos)
    _startPeriodicChecks();
    
    print('✅ NotificationScheduler inicializado');
  }
  
  /// Iniciar verificaciones periódicas
  void _startPeriodicChecks() {
    // Verificar cada 30 minutos
    _schedulerTimer?.cancel();
    _schedulerTimer = Timer.periodic(const Duration(minutes: 30), (_) async {
      await checkAndSendNotifications();
    });
    
    // Verificación inicial inmediata
    checkAndSendNotifications();
  }
  
  /// Verificar y enviar notificaciones según criterios
  Future<void> checkAndSendNotifications() async {
    try {
      if (!_authService.isLoggedIn) return;
      
      final preferences = await NotificationPreferences.load();
      if (!preferences.enabled) return;
      
      await _checkStreakStatus(preferences);
      await _checkEnergyLevel(preferences);
      await _checkChallenges(preferences);
      await _checkMilestones(preferences);
    } catch (e) {
      print('❌ Error verificando notificaciones: $e');
    }
  }
  
  /// Verificar estado de racha y enviar notificaciones si corresponde (MODO BACKUP)
  Future<void> _checkStreakStatus(NotificationPreferences preferences) async {
    if (!preferences.streakReminders) return;
    
    // Si tenemos FCM activo y el usuario tiene sesión, dejamos que el servidor sea el primario.
    // Esta función local actuará como "Plan B" si pasan más horas de lo esperado.
    final hasFCM = _notificationService.hasValidFCMToken;
    
    final userProgress = await _progressService.getUserProgress();
    if (userProgress == null) return;
    
    final consecutiveDays = userProgress['dias_consecutivos'] ?? 0;
    final lastSessionDateStr = userProgress['ultimo_pilotaje'];
    final now = DateTime.now();
    
    if (consecutiveDays >= 1 && lastSessionDateStr != null) {
      final lastSession = DateTime.parse(lastSessionDateStr);
      final hoursSinceLastSession = now.difference(lastSession).inHours;
      
      // MODO BACKUP: El servidor alerta a las 20h. 
      // Nosotros alertamos a las 22h si el usuario aún no ha entrado.
      final backupThreshold = hasFCM ? 22 : 20;

      if (hoursSinceLastSession >= backupThreshold && hoursSinceLastSession < 24) {
        final userName = _authService.currentUser?.name ?? 'Piloto Consciente';
        debugPrint('⏰ [PLAN B] Enviando recordatorio de racha local (Horas: $hoursSinceLastSession)...');
        await _notificationService.notifyStreakAtRisk(userName, consecutiveDays);
      }
      
      // Racha perdida: El servidor alerta a las 26h. Nosotros a las 28h.
      final lostThreshold = hasFCM ? 28 : 26;
      if (hoursSinceLastSession >= lostThreshold && hoursSinceLastSession < 48) {
        final userName = _authService.currentUser?.name ?? 'Piloto Consciente';
        debugPrint('⏰ [PLAN B] Enviando notificación de racha perdida local...');
        await _notificationService.notifyStreakLost(userName, consecutiveDays);
      }
    }
  }
  
  /// Verificar cambios en nivel energético
  Future<void> _checkEnergyLevel(NotificationPreferences preferences) async {
    if (!preferences.energyLevelAlerts) return;
    
    // Esta función se llamará después de que el usuario complete una sesión
    // y se detecte un cambio en el nivel energético
  }
  
  /// Verificar estado de desafíos
  Future<void> _checkChallenges(NotificationPreferences preferences) async {
    if (!preferences.challengeReminders) return;
    
    // Implementar lógica para verificar progreso de desafíos activos
    // y enviar recordatorios si corresponde
  }
  
  /// Verificar logros y milestones
  Future<void> _checkMilestones(NotificationPreferences preferences) async {
    if (!preferences.achievementCelebrations) return;
    
    // Esta función se llamará después de que el usuario complete acciones
    // y se detecte un milestone alcanzado
  }
  
  /// Registra una sesión de pilotaje y verifica notificaciones
  /// OPTIMIZADO: Solo envía la notificación más importante, consolidando múltiples eventos
  Future<void> onPilotageCompleted({String? codeNumber}) async {
    final preferences = await NotificationPreferences.load();
    if (!preferences.enabled) return;
    
    // Obtener progreso actualizado
    final userProgress = await _progressService.getUserProgress();
    if (userProgress == null) return;
    
    final totalPilotages = userProgress['total_pilotajes'] ?? 0;
    final consecutiveDays = userProgress['dias_consecutivos'] ?? 0;
    final energyLevel = userProgress['nivel_energetico'] ?? 1;
    final userName = _authService.currentUser?.name ?? 'Piloto Consciente';
    
    // Priorizar notificaciones (solo enviar la más importante)
    // Orden de prioridad: Milestones > Primer pilotaje > Nivel máximo > Subida de nivel > Gracias por racha
    
    // 1. Verificar si es primer pilotaje (máxima prioridad para nuevos usuarios)
    if (totalPilotages == 1) {
      if (!_notificationService.hasValidFCMToken) {
        await _notificationService.notifyFirstPilotage(userName);
      }
      _updateLastKnownValues(energyLevel, totalPilotages, consecutiveDays);
      return;
    }
    
    // 2. Verificar milestones de pilotajes (solo local si no hay FCM)
    final isPilotageMilestone = _lastKnownTotalPilotages == null || totalPilotages > _lastKnownTotalPilotages!;
    if (isPilotageMilestone && [10, 50, 100, 500, 1000].contains(totalPilotages)) {
      if (!_notificationService.hasValidFCMToken) {
        await _notificationService.notifyPilotageMilestone(totalPilotages, userName);
      }
      _updateLastKnownValues(energyLevel, totalPilotages, consecutiveDays);
      return; 
    }
    
    // 3. Verificar milestones de racha (solo local si no hay FCM)
    final isStreakMilestone = _lastKnownStreakDays == null || consecutiveDays > _lastKnownStreakDays!;
    if (isStreakMilestone && [3, 7, 14, 21, 30].contains(consecutiveDays)) {
      if (!_notificationService.hasValidFCMToken) {
        await _notificationService.notifyStreakMilestone(userName, consecutiveDays);
      }
      _updateLastKnownValues(energyLevel, totalPilotages, consecutiveDays);
      return;
    }
    
    // 4. Verificar nivel energético máximo
    if (energyLevel >= 10) {
      if (!_notificationService.hasValidFCMToken) {
        await _notificationService.notifyEnergyMaxReached(userName);
      }
      _updateLastKnownValues(energyLevel, totalPilotages, consecutiveDays);
      return;
    }
    
    // 5. Verificar cambio en nivel energético
    final energyLevelIncreased = _lastKnownEnergyLevel != null && energyLevel > _lastKnownEnergyLevel!;
    if (energyLevelIncreased && preferences.energyLevelAlerts) {
      if (!_notificationService.hasValidFCMToken) {
        await _notificationService.notifyEnergyLevelUp(energyLevel);
      }
      _updateLastKnownValues(energyLevel, totalPilotages, consecutiveDays);
      return;
    }
    
    // 6. Feedback inmediato por mantener racha (solo una vez por día, baja prioridad)
    final streakMaintained = consecutiveDays >= 3 && 
                             _lastKnownStreakDays != null && 
                             _lastKnownStreakDays != consecutiveDays &&
                             consecutiveDays == _lastKnownStreakDays! + 1;
    if (streakMaintained) {
      // Solo enviar si no hay otra notificación más importante
      await _notificationService.notifyThanksForStreak(userName);
      _updateLastKnownValues(energyLevel, totalPilotages, consecutiveDays);
      return; // Racha mantenida tiene prioridad sobre acción completada genérica
    }
    
    // 7. Si no hay ninguna notificación especial, enviar notificación de acción completada con el código
    // Esto asegura que siempre haya feedback, pero solo una vez por código
    if (codeNumber != null && codeNumber.isNotEmpty) {
      // Obtener nombre del desafío activo si existe
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
        // Si no hay desafío activo, usar el nombre por defecto
      }
      
      await _notificationService.showActionCompletedNotification(
        actionName: 'Pilotaje',
        challengeName: challengeName,
        codeNumber: codeNumber,
        actionType: 'sesionPilotaje', // Tipo de acción para tracking
      );
    }
    
    // Actualizar valores conocidos
    _updateLastKnownValues(energyLevel, totalPilotages, consecutiveDays);
  }
  
  /// Actualizar valores conocidos
  void _updateLastKnownValues(int energyLevel, int totalPilotages, int consecutiveDays) {
    _lastKnownEnergyLevel = energyLevel;
    _lastKnownTotalPilotages = totalPilotages;
    _lastKnownStreakDays = consecutiveDays;
  }
  
  /// Registra completar una repetición
  Future<void> onRepetitionCompleted() async {
    final preferences = await NotificationPreferences.load();
    if (!preferences.enabled) return;
    
    // Feedback inmediato
    await _notificationService.notifyEnjoyPilotage();
  }
  
  /// Actualizar preferencias y reprogramar
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    await preferences.save();
    
    // Asegurar que el servicio está inicializado
    await _notificationService.initialize();
    
    await _notificationService.scheduleDailyNotifications(preferences);
  }
  
  /// Cleanup
  void dispose() {
    _schedulerTimer?.cancel();
  }
}

