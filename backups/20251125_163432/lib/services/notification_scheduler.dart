import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_preferences.dart';
import '../models/notification_type.dart';
import '../models/challenge_model.dart';
import 'notification_service.dart';
import 'auth_service_simple.dart';
import 'user_progress_service.dart';
import 'supabase_service.dart';
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
  
  /// Verificar estado de racha y enviar notificaciones si corresponde
  Future<void> _checkStreakStatus(NotificationPreferences preferences) async {
    if (!preferences.streakReminders) return;
    
    final userProgress = await _progressService.getUserProgress();
    if (userProgress == null) return;
    
    final consecutiveDays = userProgress['consecutive_days'] ?? 0;
    final lastSessionDateStr = userProgress['last_session_date'];
    final now = DateTime.now();
    
    // Si tiene racha, verificar si está en riesgo
    if (consecutiveDays >= 1) { // Cambiado de 3 a 1 para alertar a principiantes también
      if (lastSessionDateStr != null) {
        final lastSession = DateTime.parse(lastSessionDateStr);
        final hoursSinceLastSession = now.difference(lastSession).inHours;
        
        // Racha en riesgo: Han pasado más de 20 horas (aviso antes de las 24h)
        // O si es tarde en el día (después de las 6 PM) y no ha practicado hoy
        final isLateAndNoPractice = now.hour >= 18 && 
                                    (lastSession.day != now.day || lastSession.month != now.month || lastSession.year != now.year);
                                    
        if ((hoursSinceLastSession >= 20 && hoursSinceLastSession < 24) || isLateAndNoPractice) {
          final userName = _authService.currentUser?.name ?? 'Piloto Consciente';
          await _notificationService.notifyStreakAtRisk(userName, consecutiveDays);
        }
        
        // Racha perdida: Han pasado más de 24 horas (y un poco más de margen, ej. 26h para no ser tan estricto inmediatamente)
        // O si ya es el día siguiente y no practicó ayer
        if (hoursSinceLastSession >= 26) {
          final userName = _authService.currentUser?.name ?? 'Piloto Consciente';
          await _notificationService.notifyStreakLost(userName, consecutiveDays);
        }
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
    
    final totalPilotages = userProgress['total_pilotages'] ?? 0;
    final consecutiveDays = userProgress['consecutive_days'] ?? 0;
    final energyLevel = userProgress['energy_level'] ?? 1;
    final userName = _authService.currentUser?.name ?? 'Piloto Consciente';
    
    // Priorizar notificaciones (solo enviar la más importante)
    // Orden de prioridad: Milestones > Primer pilotaje > Nivel máximo > Subida de nivel > Gracias por racha
    
    // 1. Verificar si es primer pilotaje (máxima prioridad para nuevos usuarios)
    if (totalPilotages == 1) {
      await _notificationService.notifyFirstPilotage(userName);
      _updateLastKnownValues(energyLevel, totalPilotages, consecutiveDays);
      return; // Primer pilotaje es único, no verificar más
    }
    
    // 2. Verificar milestones de pilotajes (alta prioridad)
    final isPilotageMilestone = _lastKnownTotalPilotages == null || totalPilotages > _lastKnownTotalPilotages!;
    if (isPilotageMilestone && [10, 50, 100, 500, 1000].contains(totalPilotages)) {
      await _notificationService.notifyPilotageMilestone(totalPilotages, userName);
      _updateLastKnownValues(energyLevel, totalPilotages, consecutiveDays);
      return; // Milestone de pilotajes tiene prioridad
    }
    
    // 3. Verificar milestones de racha (alta prioridad)
    final isStreakMilestone = _lastKnownStreakDays == null || consecutiveDays > _lastKnownStreakDays!;
    if (isStreakMilestone && [3, 7, 14, 21, 30].contains(consecutiveDays)) {
      await _notificationService.notifyStreakMilestone(userName, consecutiveDays);
      _updateLastKnownValues(energyLevel, totalPilotages, consecutiveDays);
      return; // Milestone de racha tiene prioridad
    }
    
    // 4. Verificar nivel energético máximo
    if (energyLevel >= 10) {
      await _notificationService.notifyEnergyMaxReached(userName);
      _updateLastKnownValues(energyLevel, totalPilotages, consecutiveDays);
      return; // Nivel máximo tiene prioridad
    }
    
    // 5. Verificar cambio en nivel energético (solo si aumentó)
    final energyLevelIncreased = _lastKnownEnergyLevel != null && energyLevel > _lastKnownEnergyLevel!;
    if (energyLevelIncreased && preferences.energyLevelAlerts) {
      await _notificationService.notifyEnergyLevelUp(energyLevel);
      _updateLastKnownValues(energyLevel, totalPilotages, consecutiveDays);
      return; // Subida de nivel tiene prioridad sobre feedback general
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
        if (activeChallenge != null) {
          challengeName = activeChallenge.title;
        }
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

