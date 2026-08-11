import '../services/notification_service.dart';
import '../services/admin_service.dart';
import '../models/notification_type.dart';

/// Prueba, una por una, las 40 notificaciones del catálogo (NotificationType)
/// para que un admin pueda confirmar visualmente que todas llegan bien.
///
/// Cada una se manda por su canal REAL (ver matriz acordada):
/// - Local: se llama directo al método de NotificationService (flutter_local_notifications).
/// - Servidor: se pide a admin-users -> send_test_notification, que reenvía
///   por notify_push_from_db (el mismo camino que usan los triggers/crons
///   reales), sin exponer ningún secreto al cliente.
///
/// morningRoutineReminder queda fuera de esta lista a propósito: se fusionó
/// con dailyCodeReminder para no generar el mismo duplicado matutino que
/// esto está pensado para detectar.
class TestAllNotifications {
  static final NotificationService _notificationService = NotificationService();

  static Future<void> _server(String title, String body) =>
      AdminService.sendTestNotification(title: title, body: body);

  static Future<void> sendAllTestNotifications({
    String userName = 'Piloto Consciente',
    int delaySeconds = 10,
  }) async {
    print('🧪 Iniciando prueba de todas las notificaciones...');
    await _notificationService.initialize();

    final tests = <MapEntry<String, Future<void> Function()>>[
      // ── Recordatorios Diarios ──
      MapEntry('dailyCodeReminder (local)', () => _notificationService.showNotification(
            title: '✨ ¡Nueva Secuencia Diaria Disponible!',
            body: 'Descúbrelo ahora y eleva tu energía con tu sesión de repetición diaria. ¡Toca para comenzar!',
            type: NotificationType.dailyCodeReminder,
            bypassQueue: true,
          )),
      MapEntry('eveningRoutineReminder (local)', () => _notificationService.showNotification(
            title: '🌙 Completa tu práctica cuántica',
            body: 'Excelente día. ¿Completas tu práctica cuántica de hoy? Tu disciplina está transformando tu realidad.',
            type: NotificationType.eveningRoutineReminder,
            bypassQueue: true,
          )),
      MapEntry('weeklyMotivational (local)', () => _notificationService.showNotification(
            title: '💫 Mensaje de la Semana',
            body: 'Recuerda: cada pilotaje consciente es un paso hacia tu transformación.',
            type: NotificationType.weeklyMotivational,
            bypassQueue: true,
          )),

      // ── Racha/Progreso ──
      MapEntry('streakAtRisk12h (servidor)', () => _server('🔥 ¡Racha en Peligro!', 'Tu racha de 5 días está por expirar. Realiza un pilotaje ahora para mantenerla.')),
      MapEntry('streakLost (servidor)', () => _server('💔 Racha perdida', 'Tu racha se ha reiniciado. ¡Comienza de nuevo hoy!')),
      MapEntry('streakMilestone3 (servidor)', () => _server('🎖️ ¡3 días de racha!', '$userName, llevas 3 días consecutivos. ¡Vas muy bien!')),
      MapEntry('streakMilestone7 (servidor)', () => _server('🎖️ ¡7 días de racha!', '$userName, una semana completa de práctica constante.')),
      MapEntry('streakMilestone14 (servidor)', () => _server('🎖️ ¡14 días de racha!', '$userName, dos semanas de compromiso cuántico.')),
      MapEntry('streakMilestone21 (servidor)', () => _server('🎖️ ¡21 días de racha!', '$userName, ¡estás formando un hábito imparable!')),
      MapEntry('streakMilestone30 (servidor)', () => _server('🎖️ ¡30 días de racha!', '$userName, un mes entero de disciplina cuántica.')),
      MapEntry('streakPerfectDay (servidor)', () => _server('🌟 ¡Día Perfecto!', 'Hoy completaste pilotaje, repetición, compartir y tiempo en la app. ¡Día cuántico completo!')),

      // ── Nivel Energético ──
      MapEntry('energyLevelUp (servidor)', () => _server('⚡ ¡Nivel Energético Aumentado!', '¡Felicidades! Tu nivel de energía cuántica ha subido a 5.')),
      MapEntry('energyLowAlert (servidor)', () => _server('🔋 Tu energía cuántica bajó', 'Tu nivel de energía bajó a 2. Un pilotaje hoy te ayuda a recuperarlo.')),
      MapEntry('energyMaxReached (servidor)', () => _server('🌟 ¡Nivel Energético Máximo!', 'Has alcanzado el nivel máximo de energía cuántica. Eres una fuente de luz pura.')),

      // ── Desafíos ──
      MapEntry('challengeDailyReminder (servidor)', () => _server('🎯 Tienes un desafío activo', 'Desafío de Iniciación Energética. Día 2 de 7. ¡Completa tus acciones hoy!')),
      MapEntry('challengeDayCompleted (local)', () => _notificationService.notifyChallengeDayCompleted(3, 7, 'Desafío de Iniciación')),
      MapEntry('challengeAtRisk (servidor)', () => _server('⚠️ Tu desafío está en riesgo', 'Desafío de Iniciación Energética está en riesgo. ¡Completa el día 3 hoy!')),
      MapEntry('challengeCompleted (local)', () => _notificationService.notifyChallengeCompleted('Desafío de Iniciación', '100 cristales')),
      MapEntry('challengeNewAvailable (local)', () => _notificationService.showNotification(
            title: '🎯 Nuevo desafío disponible',
            body: 'Ya puedes comenzar el Desafío de Armonización Intermedia.',
            type: NotificationType.challengeNewAvailable,
            bypassQueue: true,
          )),

      // ── Logros ──
      MapEntry('firstPilotage (servidor)', () => _server('🎉 ¡Bienvenido al viaje cuántico!', 'Has completado tu primer pilotaje consciente. El viaje de transformación comienza.')),
      MapEntry('milestone10Pilotages (servidor)', () => _server('🏆 ¡Hito Alcanzado!', '$userName, has completado 10 pilotajes. ¡Tu compromiso con el campo cuántico es inspirador!')),
      MapEntry('milestone50Pilotages (servidor)', () => _server('🏆 ¡Hito Alcanzado!', '$userName, has completado 50 pilotajes. ¡Tu compromiso con el campo cuántico es inspirador!')),
      MapEntry('milestone100Pilotages (servidor)', () => _server('🏆 ¡Hito Alcanzado!', '$userName, has completado 100 pilotajes. ¡Tu compromiso con el campo cuántico es inspirador!')),
      MapEntry('milestone500Pilotages (servidor)', () => _server('🏆 ¡Hito Alcanzado!', '$userName, has completado 500 pilotajes. ¡Tu compromiso con el campo cuántico es inspirador!')),
      MapEntry('milestone1000Pilotages (servidor)', () => _server('🏆 ¡Hito Alcanzado!', '$userName, has completado 1000 pilotajes. ¡Tu compromiso con el campo cuántico es inspirador!')),
      MapEntry('favoriteCode10x (servidor)', () => _server('❤️ Código Favorito', 'Has usado "528 741" más de 10 veces. ¡Ya es parte de tu rutina!')),
      MapEntry('diverseCodes20x (servidor)', () => _server('🌈 Explorador Cuántico', 'Has probado 20 códigos diferentes. ¡Tu viaje de exploración es admirable!')),

      // ── Contenido Personalizado ──
      MapEntry('personalizedCodeRecommendation (servidor)', () => _server('✨ Secuencia Personalizada para Ti', 'Basado en tu actividad, este código podría ser perfecto para ti hoy: 528 741')),
      MapEntry('weeklyProgressSummary (servidor)', () => _server('📊 Tu semana cuántica', '15 pilotajes, 8 códigos usados, nivel 7/10. ¡Sigue así!')),
      MapEntry('monthlyTrendsAnalysis (servidor)', () => _server('📈 Tu mes en números', 'Este mes completaste 45 pilotajes y subiste 3 niveles de energía.')),

      // ── Temporales ──
      MapEntry('registrationAnniversary (servidor)', () => _server('🎂 ¡Feliz aniversario!', 'Hace 1 año comenzaste tu viaje cuántico con ManiGraB.')),
      MapEntry('seasonalChange (servidor)', () => _server('🍂 Cambio de estación', 'Una nueva estación trae nueva energía. Descubre los códigos especiales de temporada.')),
      MapEntry('monthlySpecialCode (servidor)', () => _server('🔑 Código Especial del Mes', 'Este mes desbloqueamos un código exclusivo para ti.')),

      // ── Social ──
      MapEntry('weeklyRankings (servidor)', () => _server('🏅 Ranking Semanal', 'Estás entre los pilotos más constantes esta semana.')),
      MapEntry('shareAchievement (local)', () => _notificationService.showNotification(
            title: '🎉 ¡Gracias por compartir!',
            body: 'Tu logro inspira a otros pilotos conscientes.',
            type: NotificationType.shareAchievement,
            bypassQueue: true,
          )),

      // ── Feedback Loop ──
      MapEntry('thanksForMaintainingStreak (local)', () => _notificationService.notifyThanksForStreak(userName)),
      MapEntry('enjoyYourPilotage (local)', () => _notificationService.notifyEnjoyPilotage()),

      // ── Suscripción/Premium ──
      MapEntry('premiumWelcome (local)', () => _notificationService.notifyPremiumWelcome()),
      MapEntry('trialEndingSoon (servidor)', () => _server('⏳ Tu prueba gratis termina pronto', 'Te quedan 2 días de acceso Premium gratis. Suscríbete para no perder tus beneficios.')),
    ];

    print('📋 Total de notificaciones a enviar: ${tests.length}');
    print('⏱️  Delay entre notificaciones: $delaySeconds segundos');
    print('⏳ Tiempo estimado total: ${(tests.length * delaySeconds / 60).toStringAsFixed(1)} minutos\n');
    print('ℹ️ morningRoutineReminder no se prueba por separado: se fusionó con dailyCodeReminder para no duplicar el aviso matutino.\n');

    for (int i = 0; i < tests.length; i++) {
      final entry = tests[i];
      try {
        print('📤 [${i + 1}/${tests.length}] Enviando: ${entry.key}...');
        await entry.value();
        print('✅ Enviada: ${entry.key}\n');

        if (i < tests.length - 1) {
          await Future.delayed(Duration(seconds: delaySeconds));
        }
      } catch (e) {
        print('❌ Error enviando ${entry.key}: $e\n');
      }
    }

    print('✅ Prueba completada. ${tests.length} notificaciones procesadas.');
  }
}
