import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Utilidad para diagnosticar problemas de notificaciones en iOS
class IOSNotificationDebug {
  static Future<Map<String, dynamic>> diagnose() async {
    if (kIsWeb || !Platform.isIOS) {
      return {'error': 'Solo disponible en iOS'};
    }

    final results = <String, dynamic>{};
    final notifications = FlutterLocalNotificationsPlugin();

    try {
      // 1. Verificar si hay notificaciones pendientes (esto verifica que el plugin funciona)
      try {
        final pendingNotifications = await notifications.pendingNotificationRequests();
        results['pending_notifications_count'] = pendingNotifications.length;
        results['plugin_working'] = true;
      } catch (e) {
        results['pending_error'] = e.toString();
        results['plugin_working'] = false;
      }
      
      // 2. Los permisos se solicitan automáticamente durante initialize()
      // con DarwinInitializationSettings(requestAlertPermission: true)
      results['permissions_note'] = 'Los permisos se solicitan automáticamente durante initialize()';

      // 4. Intentar mostrar una notificación de prueba
      try {
        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.active,
        );
        
        const details = NotificationDetails(iOS: iosDetails);
        
        await notifications.show(
          999999, // ID único para prueba
          'Prueba de Notificación',
          'Si ves esto, las notificaciones funcionan',
          details,
        );
        
        results['test_notification_sent'] = true;
      } catch (e) {
        results['test_notification_error'] = e.toString();
      }

      return results;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<void> printDiagnostics() async {
    print('🔍 Iniciando diagnóstico de notificaciones iOS...');
    final results = await diagnose();
    
    print('\n📊 Resultados del diagnóstico:');
    results.forEach((key, value) {
      print('  $key: $value');
    });
    
    if (results['permissions_granted'] == false) {
      print('\n⚠️ PROBLEMA DETECTADO: Permisos no otorgados');
      print('   Solución: Ve a Configuración > MANIGRAB > Notificaciones y habilítalas');
    }
    
    if (results['test_notification_sent'] == true) {
      print('\n✅ Notificación de prueba enviada correctamente');
    } else if (results['test_notification_error'] != null) {
      print('\n❌ Error al enviar notificación de prueba: ${results['test_notification_error']}');
    }
  }
}
