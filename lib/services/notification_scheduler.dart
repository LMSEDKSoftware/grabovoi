import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_preferences.dart';
import '../models/notification_type.dart';
import 'notification_service.dart';
import 'auth_service_simple.dart';
import 'user_progress_service.dart';
import 'supabase_service.dart';

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
    final lastSessionDate = userProgress['last_session_date'];
    final now = DateTime.now();
    
    // Si tiene racha, verificar si está en riesgo
    if (consecutiveDays >= 3) {
      if (lastSessionDate != null) {
        final lastSession = DateTime.parse(lastSessionDate);
        final hoursSinceLastSession = now.difference(lastSession).inHours;
        
        // Si han pasado más de 12 horas sin practicar (y son las 6 PM)
        if (hoursSinceLastSession >= 12 && now.hour == 18 && now.minute < 30) {
          final userName = _authService.currentUser?.name ?? 'Piloto Consciente';
          await _notificationService.notifyStreakAtRisk(userName, consecutiveDays);
        }
        
        // Si han pasado más de 24 horas, la racha se perdió
        if (hoursSinceLastSession >= 24) {
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
  Future<void> onPilotageCompleted() async {
    final preferences = await NotificationPreferences.load();
    
    // Obtener progreso actualizado
    final userProgress = await _progressService.getUserProgress();
    if (userProgress == null) return;
    
    final totalPilotages = userProgress['total_pilotages'] ?? 0;
    final consecutiveDays = userProgress['consecutive_days'] ?? 0;
    final energyLevel = userProgress['energy_level'] ?? 1;
    final userName = _authService.currentUser?.name ?? 'Piloto Consciente';
    
    // Verificar cambio en nivel energético
    if (_lastKnownEnergyLevel != null && energyLevel > _lastKnownEnergyLevel!) {
      await _notificationService.notifyEnergyLevelUp(energyLevel);
    }
    
    // Verificar si es primer pilotaje
    if (totalPilotages == 1) {
      await _notificationService.notifyFirstPilotage(userName);
    }
    
    // Verificar milestones de pilotajes
    if (_lastKnownTotalPilotages == null || totalPilotages > _lastKnownTotalPilotages!) {
      if ([10, 50, 100, 500, 1000].contains(totalPilotages)) {
        await _notificationService.notifyPilotageMilestone(totalPilotages, userName);
      }
    }
    
    // Verificar milestones de racha
    if (_lastKnownStreakDays == null || consecutiveDays > _lastKnownStreakDays!) {
      if ([3, 7, 14, 21, 30].contains(consecutiveDays)) {
        await _notificationService.notifyStreakMilestone(userName, consecutiveDays);
      }
    }
    
    // Verificar nivel energético máximo
    if (energyLevel >= 10) {
      await _notificationService.notifyEnergyMaxReached(userName);
    }
    
    // Feedback inmediato (solo una vez por día)
    if (consecutiveDays >= 3 && _lastKnownStreakDays != consecutiveDays) {
      await _notificationService.notifyThanksForStreak(userName);
    }
    
    // Actualizar valores conocidos
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

