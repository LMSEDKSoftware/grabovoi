import 'dart:async';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/notification_type.dart';

/// Script para probar todas las notificaciones
/// Uso: Llamar desde cualquier pantalla para enviar todas las notificaciones de prueba
class TestAllNotifications {
  static final NotificationService _notificationService = NotificationService();
  
  /// Enviar todas las notificaciones de prueba (una por una con delays)
  static Future<void> sendAllTestNotifications({
    String userName = 'Piloto Consciente',
    int delaySeconds = 30, // 30 segundos entre notificaciones = máximo 2 por minuto
  }) async {
    print('🧪 Iniciando prueba de todas las notificaciones...');
    
    // Inicializar el servicio
    await _notificationService.initialize();
    
    final notifications = [
      // 1. Primer pilotaje
      () => _notificationService.notifyFirstPilotage(userName),
      
      // 2. Subida de nivel energético
      () => _notificationService.notifyEnergyLevelUp(5),
      
      // 3. Nivel energético máximo
      () => _notificationService.notifyEnergyMaxReached(userName),
      
      // 4. Milestones de pilotajes
      () => _notificationService.notifyPilotageMilestone(10, userName),
      () => _notificationService.notifyPilotageMilestone(50, userName),
      () => _notificationService.notifyPilotageMilestone(100, userName),
      () => _notificationService.notifyPilotageMilestone(500, userName),
      () => _notificationService.notifyPilotageMilestone(1000, userName),
      
      // 5. Milestones de racha
      () => _notificationService.notifyStreakMilestone(userName, 3),
      () => _notificationService.notifyStreakMilestone(userName, 7),
      () => _notificationService.notifyStreakMilestone(userName, 14),
      () => _notificationService.notifyStreakMilestone(userName, 21),
      () => _notificationService.notifyStreakMilestone(userName, 30),
      
      // 6. Racha en riesgo
      () => _notificationService.notifyStreakAtRisk(userName, 5),
      
      // 7. Racha perdida
      () => _notificationService.notifyStreakLost(userName, 7),
      
      // 8. Gracias por mantener racha
      () => _notificationService.notifyThanksForStreak(userName),
      
      // 9. Disfruta tu pilotaje
      () => _notificationService.notifyEnjoyPilotage(),
      
      // 10. Desafío completado
      () => _notificationService.notifyChallengeCompleted('Desafío de Iniciación', '100 cristales'),
      
      // 11. Día de desafío completado
      () => _notificationService.notifyChallengeDayCompleted(3, 7, 'Desafío de Iniciación'),
      
      // 12. Recordatorio diario de desafío
      () => _notificationService.notifyChallengeDailyReminder('Desafío de Iniciación', 2, 7),
      
      // 13. Desafío en riesgo
      () => _notificationService.notifyChallengeAtRisk('Desafío de Iniciación', 3),
      
      // 14. Código personalizado
      () => _notificationService.notifyPersonalizedCode('528 741', userName),
      
      // 15. Resumen semanal
      () => _notificationService.notifyWeeklySummary(15, 8, 7),
      
      // 16. Recordatorio de código del día (directa)
      () => _notificationService.showNotification(
        title: '🌅 Tu Código Grabovoi de Hoy',
        body: 'Tu código de hoy espera por ti. ¡Recuerda que tu energía se eleva con cada pilotaje consciente!',
        type: NotificationType.dailyCodeReminder,
      ),
      
      // 17. Recordatorio matutino
      () => _notificationService.showNotification(
        title: '☀️ Buenos días, Piloto Consciente',
        body: '¿Listo para comenzar el día con energía cuántica? Un pilotaje consciente de 2 minutos transformará tu mañana.',
        type: NotificationType.morningRoutineReminder,
      ),
      
      // 18. Recordatorio vespertino
      () => _notificationService.showNotification(
        title: '🌙 Completa tu práctica cuántica',
        body: 'Excelente día. ¿Completas tu práctica cuántica de hoy? Tu disciplina está transformando tu realidad.',
        type: NotificationType.eveningRoutineReminder,
      ),
    ];
    
    print('📋 Total de notificaciones a enviar: ${notifications.length}');
    print('⏱️  Delay entre notificaciones: $delaySeconds segundos');
    print('⏳ Tiempo estimado total: ${(notifications.length * delaySeconds / 60).toStringAsFixed(1)} minutos\n');
    
    for (int i = 0; i < notifications.length; i++) {
      try {
        print('📤 [${i + 1}/${notifications.length}] Enviando notificación ${i + 1}...');
        await notifications[i]();
        print('✅ Notificación ${i + 1} enviada\n');
        
        // Esperar antes de enviar la siguiente (excepto la última)
        if (i < notifications.length - 1) {
          print('⏳ Esperando $delaySeconds segundos...\n');
          await Future.delayed(Duration(seconds: delaySeconds));
        }
      } catch (e) {
        print('❌ Error enviando notificación ${i + 1}: $e\n');
      }
    }
    
    print('✅ Prueba completada. Todas las notificaciones fueron procesadas.');
  }
  
  /// Enviar notificaciones rápidas (sin delays, usando el sistema de cola)
  /// Útil para verificar el rate limiting
  static Future<void> sendAllNotificationsRapid() async {
    print('⚡ Enviando todas las notificaciones rápidamente (con rate limiting)...');
    
    await _notificationService.initialize();
    
    final userName = 'Piloto Consciente';
    
    // Enviar todas al mismo tiempo - el sistema de rate limiting las procesará
    await Future.wait([
      _notificationService.notifyFirstPilotage(userName),
      _notificationService.notifyEnergyLevelUp(5),
      _notificationService.notifyEnergyMaxReached(userName),
      _notificationService.notifyPilotageMilestone(10, userName),
      _notificationService.notifyPilotageMilestone(50, userName),
      _notificationService.notifyStreakMilestone(userName, 3),
      _notificationService.notifyStreakMilestone(userName, 7),
      _notificationService.notifyThanksForStreak(userName),
      _notificationService.notifyEnjoyPilotage(),
      _notificationService.notifyChallengeCompleted('Desafío Test', 'Recompensa'),
    ]);
    
    print('✅ Todas las notificaciones agregadas a la cola. El sistema de rate limiting las procesará.');
  }
}

