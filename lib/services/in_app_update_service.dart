import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_update/in_app_update.dart';

/// Servicio para manejar actualizaciones in-app en Android
/// 
/// Este servicio verifica si hay actualizaciones disponibles en Google Play
/// y permite actualizar la app sin salir de ella.
/// 
/// Nota: Solo funciona en Android y requiere que la app esté instalada
/// desde Google Play Store. No funciona en iOS ni en web.
class InAppUpdateService {
  static final InAppUpdateService _instance = InAppUpdateService._internal();
  factory InAppUpdateService() => _instance;
  InAppUpdateService._internal();

  /// Verifica si hay una actualización disponible
  /// 
  /// Retorna:
  /// - `AppUpdateInfo` con información sobre la actualización disponible
  /// - `null` si no hay actualización o si hay un error
  Future<AppUpdateInfo?> checkForUpdate() async {
    // Solo funciona en Android, no en web ni iOS
    if (kIsWeb || !Platform.isAndroid) {
      print('⚠️ [InAppUpdate] Solo disponible en Android');
      return null;
    }

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      print('✅ [InAppUpdate] Verificación completada: ${updateInfo.updateAvailability}');
      return updateInfo;
    } catch (e) {
      print('❌ [InAppUpdate] Error verificando actualización: $e');
      return null;
    }
  }

  /// Realiza una actualización inmediata (pantalla completa)
  /// 
  /// Esta actualización bloquea la app hasta que se complete.
  /// Ideal para actualizaciones críticas.
  Future<bool> performImmediateUpdate() async {
    if (kIsWeb || !Platform.isAndroid) {
      return false;
    }

    try {
      final updateInfo = await checkForUpdate();
      if (updateInfo == null) {
        return false;
      }

      // Solo proceder si hay una actualización disponible
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
        print('✅ [InAppUpdate] Actualización inmediata iniciada');
        return true;
      }

      print('ℹ️ [InAppUpdate] No hay actualización disponible para actualización inmediata');
      return false;
    } catch (e) {
      print('❌ [InAppUpdate] Error en actualización inmediata: $e');
      return false;
    }
  }

  /// Inicia una actualización flexible (en segundo plano)
  /// 
  /// Esta actualización permite usar la app mientras se descarga.
  /// El usuario puede continuar usando la app y se le notificará
  /// cuando la actualización esté lista para instalar.
  Future<bool> startFlexibleUpdate() async {
    if (kIsWeb || !Platform.isAndroid) {
      return false;
    }

    try {
      final updateInfo = await checkForUpdate();
      if (updateInfo == null) {
        return false;
      }

      // Solo proceder si hay una actualización disponible
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.startFlexibleUpdate();
        print('✅ [InAppUpdate] Actualización flexible iniciada');
        return true;
      }

      print('ℹ️ [InAppUpdate] No hay actualización disponible para actualización flexible');
      return false;
    } catch (e) {
      print('❌ [InAppUpdate] Error en actualización flexible: $e');
      return false;
    }
  }

  /// Completa una actualización flexible
  /// 
  /// Debe llamarse después de que `startFlexibleUpdate()` haya descargado
  /// la actualización. Esto reiniciará la app para aplicar la actualización.
  Future<bool> completeFlexibleUpdate() async {
    if (kIsWeb || !Platform.isAndroid) {
      return false;
    }

    try {
      await InAppUpdate.completeFlexibleUpdate();
      print('✅ [InAppUpdate] Actualización flexible completada');
      return true;
    } catch (e) {
      print('❌ [InAppUpdate] Error completando actualización flexible: $e');
      return false;
    }
  }

  /// Verifica y maneja actualizaciones automáticamente
  /// 
  /// Esta función verifica si hay actualizaciones y decide automáticamente
  /// qué tipo de actualización usar:
  /// - Si es una actualización crítica (updatePriority >= 5), usa actualización inmediata
  /// - Si no es crítica, usa actualización flexible
  /// 
  /// Retorna `true` si se inició una actualización, `false` en caso contrario.
  Future<bool> checkAndUpdate({bool forceImmediate = false}) async {
    if (kIsWeb || !Platform.isAndroid) {
      return false;
    }

    try {
      final updateInfo = await checkForUpdate();
      if (updateInfo == null) {
        return false;
      }

      // Verificar si hay actualización disponible
      if (updateInfo.updateAvailability != UpdateAvailability.updateAvailable) {
        print('ℹ️ [InAppUpdate] No hay actualización disponible');
        return false;
      }

      // Decidir tipo de actualización
      final isCritical = updateInfo.immediateUpdateAllowed && 
                        (updateInfo.clientVersionStalenessDays ?? 0) > 7;
      
      if (forceImmediate || isCritical) {
        // Actualización inmediata para actualizaciones críticas
        return await performImmediateUpdate();
      } else {
        // Actualización flexible para actualizaciones normales
        return await startFlexibleUpdate();
      }
    } catch (e) {
      print('❌ [InAppUpdate] Error en checkAndUpdate: $e');
      return false;
    }
  }
}

