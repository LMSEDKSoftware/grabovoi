import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Helper para solicitar permisos de fotos en iOS usando PHPhotoLibrary nativo
/// Esto hace que el permiso aparezca en Configuración sin mostrar el selector de imágenes
class IOSPhotoPermissionHelper {
  static const MethodChannel _channel = MethodChannel('com.manigrab/photos_permission');

  /// Solicitar permiso de fotos en iOS usando PHPhotoLibrary.requestAuthorization
  /// Esto hace que el permiso aparezca inmediatamente en Configuración > MANIGRAB > Fotos
  /// sin necesidad de intentar acceder a ImagePicker
  static Future<bool> requestPhotoPermission() async {
    if (kIsWeb || !Platform.isIOS) {
      return false; // Solo funciona en iOS
    }

    try {
      final bool? granted = await _channel.invokeMethod<bool>('requestPhotoPermission');
      return granted ?? false;
    } catch (e) {
      print('❌ Error solicitando permiso de fotos iOS nativo: $e');
      return false;
    }
  }
}
