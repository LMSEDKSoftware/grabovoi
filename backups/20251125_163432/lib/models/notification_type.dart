/// Enum para prioridad de notificaciones
enum NotificationPriority {
  high,    // Racha en riesgo, desafío fallido
  medium,  // Resumen semanal, hitos
  low      // Consejos, rutinas
}

/// Enum para tipos de notificaciones
enum NotificationType {
  // Consejos/Recordatorios
  dailyCodeReminder,
  morningRoutineReminder,
  eveningRoutineReminder,
  weeklyMotivational,
  
  // Racha/Progreso
  streakAtRisk12h,
  streakLost,
  streakMilestone3,
  streakMilestone7,
  streakMilestone14,
  streakMilestone21,
  streakMilestone30,
  streakPerfectDay,
  
  // Nivel Energético
  energyLevelUp,
  energyLowAlert,
  energyMaxReached,
  
  // Desafíos
  challengeDailyReminder,
  challengeDayCompleted,
  challengeAtRisk,
  challengeCompleted,
  challengeNewAvailable,
  
  // Logros
  firstPilotage,
  milestone10Pilotages,
  milestone50Pilotages,
  milestone100Pilotages,
  milestone500Pilotages,
  milestone1000Pilotages,
  favoriteCode10x,
  diverseCodes20x,
  
  // Contenido Personalizado
  personalizedCodeRecommendation,
  weeklyProgressSummary,
  monthlyTrendsAnalysis,
  
  // Temporales
  registrationAnniversary,
  seasonalChange,
  monthlySpecialCode,
  
  // Social (opcional)
  weeklyRankings,
  shareAchievement,
  
  // Feedback Loop
  thanksForMaintainingStreak,
  enjoyYourPilotage,
}

extension NotificationTypeExtension on NotificationType {
  /// Retorna la prioridad de la notificación
  NotificationPriority get priority {
    switch (this) {
      case NotificationType.streakAtRisk12h:
      case NotificationType.challengeAtRisk:
      case NotificationType.energyLowAlert:
        return NotificationPriority.high;
      
      case NotificationType.weeklyProgressSummary:
      case NotificationType.monthlyTrendsAnalysis:
      case NotificationType.weeklyRankings:
      case NotificationType.streakMilestone3:
      case NotificationType.streakMilestone7:
      case NotificationType.streakMilestone14:
      case NotificationType.streakMilestone21:
      case NotificationType.milestone10Pilotages:
      case NotificationType.milestone50Pilotages:
      case NotificationType.milestone100Pilotages:
        return NotificationPriority.medium;
      
      case NotificationType.dailyCodeReminder:
      case NotificationType.morningRoutineReminder:
      case NotificationType.eveningRoutineReminder:
      case NotificationType.weeklyMotivational:
      case NotificationType.personalizedCodeRecommendation:
      case NotificationType.seasonalChange:
      case NotificationType.monthlySpecialCode:
        return NotificationPriority.low;
      
      default:
        return NotificationPriority.medium;
    }
  }
  
  /// ID único para el tipo de notificación
  int get id {
    return NotificationType.values.indexOf(this);
  }
  
  /// Retorna true si la notificación debe tener sonido
  bool shouldPlaySound() {
    switch (this) {
      case NotificationType.streakMilestone21:
      case NotificationType.streakMilestone30:
      case NotificationType.challengeCompleted:
      case NotificationType.energyMaxReached:
      case NotificationType.milestone1000Pilotages:
        return true;
      default:
        return false;
    }
  }
}

