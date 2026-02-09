import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../utils/ios_notification_debug.dart';
import '../models/notification_type.dart';
import 'dart:io' show Platform;

/// Script para probar notificaciones en iOS
/// Ejecutar desde la app para diagnosticar problemas
void testIOSNotifications(BuildContext context) async {
  if (!Platform.isIOS) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Este test solo funciona en iOS'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AlertDialog(
      title: Text('Probando Notificaciones iOS'),
      content: CircularProgressIndicator(),
    ),
  );

  try {
    // 1. Ejecutar diagnóstico
    print('\n🔍 === DIAGNÓSTICO DE NOTIFICACIONES iOS ===');
    await IOSNotificationDebug.printDiagnostics();

    // 2. Inicializar servicio
    print('\n📱 === INICIALIZANDO SERVICIO ===');
    final service = NotificationService();
    await service.initialize();

    // 3. Probar notificación directa
    print('\n📤 === ENVIANDO NOTIFICACIÓN DE PRUEBA ===');
    await service.showNotification(
      title: 'Prueba iOS',
      body: 'Si ves esto, las notificaciones funcionan correctamente',
      type: NotificationType.dailyCodeReminder,
      bypassQueue: true,
    );

    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Prueba completada. Revisa los logs en la consola.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 5),
      ),
    );
  } catch (e) {
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Error: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
