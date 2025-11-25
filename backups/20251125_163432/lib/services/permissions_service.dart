import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

/// Servicio para gestionar solicitud de permisos al inicio de la app
class PermissionsService {
  static final PermissionsService _instance = PermissionsService._internal();
  factory PermissionsService() => _instance;
  PermissionsService._internal();

  bool _permissionsRequested = false;

  /// Solicitar todos los permisos necesarios al inicio
  /// Se llama después del welcome/onboarding
  Future<void> requestInitialPermissions() async {
    if (_permissionsRequested) {
      print('📋 Permisos ya fueron solicitados en esta sesión');
      return;
    }

    print('🔐 Solicitando permisos iniciales...');
    _permissionsRequested = true;

    // Solicitar permiso de notificaciones (crítico para funcionar en segundo plano)
    await _requestNotificationPermission();

    // Solicitar permiso de galería/fotos (necesario para avatar)
    await _requestPhotoPermission();
  }

  /// Solicitar permiso de notificaciones
  Future<bool> _requestNotificationPermission() async {
    try {
      // Verificar si ya está otorgado
      final status = await Permission.notification.status;
      
      if (status.isGranted) {
        print('✅ Permiso de notificaciones ya otorgado');
        return true;
      }

      if (status.isPermanentlyDenied) {
        print('⚠️ Permiso de notificaciones permanentemente denegado');
        return false;
      }

      // Solicitar permiso
      print('📱 Solicitando permiso de notificaciones...');
      final result = await Permission.notification.request();
      
      if (result.isGranted) {
        print('✅ Permiso de notificaciones otorgado');
        return true;
      } else if (result.isDenied) {
        print('⚠️ Permiso de notificaciones denegado por el usuario');
        return false;
      } else if (result.isPermanentlyDenied) {
        print('❌ Permiso de notificaciones permanentemente denegado');
        return false;
      }

      return false;
    } catch (e) {
      print('❌ Error solicitando permiso de notificaciones: $e');
      return false;
    }
  }

  /// Solicitar permiso de fotos/galería
  Future<bool> _requestPhotoPermission() async {
    try {
      // En Android 13+ usar Permission.photos, en versiones anteriores Permission.storage
      Permission permissionToUse = Permission.photos;
      
      if (!kIsWeb) {
        // Verificar qué versión de Android
        try {
          final photosStatus = await Permission.photos.status;
          permissionToUse = Permission.photos;
        } catch (_) {
          // Si no está disponible, usar storage para versiones antiguas
          permissionToUse = Permission.storage;
        }
      }

      // Verificar si ya está otorgado
      final status = await permissionToUse.status;
      
      if (status.isGranted) {
        print('✅ Permiso de fotos ya otorgado');
        return true;
      }

      if (status.isPermanentlyDenied) {
        print('⚠️ Permiso de fotos permanentemente denegado');
        return false;
      }

      // Solicitar permiso
      print('📷 Solicitando permiso de fotos...');
      final result = await permissionToUse.request();
      
      if (result.isGranted) {
        print('✅ Permiso de fotos otorgado');
        return true;
      } else if (result.isDenied) {
        print('⚠️ Permiso de fotos denegado por el usuario');
        return false;
      } else if (result.isPermanentlyDenied) {
        print('❌ Permiso de fotos permanentemente denegado');
        return false;
      }

      return false;
    } catch (e) {
      print('❌ Error solicitando permiso de fotos: $e');
      return false;
    }
  }

  /// Verificar si los permisos están otorgados
  Future<Map<String, bool>> checkPermissionsStatus() async {
    final notificationStatus = await Permission.notification.status;
    
    Permission photoPermission = Permission.photos;
    try {
      await Permission.photos.status;
    } catch (_) {
      photoPermission = Permission.storage;
    }
    
    final photoStatus = await photoPermission.status;

    return {
      'notifications': notificationStatus.isGranted,
      'photos': photoStatus.isGranted,
    };
  }

  /// Resetear estado (útil para testing)
  void reset() {
    _permissionsRequested = false;
  }
}

