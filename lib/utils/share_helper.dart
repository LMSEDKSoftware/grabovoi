import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Helper para compartir archivos con soporte específico para iOS
class ShareHelper {
  /// Compartir una imagen desde bytes
  /// 
  /// [pngBytes] - Los bytes de la imagen PNG
  /// [fileName] - Nombre del archivo (sin extensión)
  /// [text] - Texto opcional para compartir junto con la imagen
  /// [context] - Contexto de Flutter (necesario para iOS para obtener sharePositionOrigin)
  static Future<void> shareImage({
    required Uint8List pngBytes,
    required String fileName,
    String? text,
    BuildContext? context,
  }) async {
    if (kIsWeb) {
      // En web, no se puede compartir archivos
      return;
    }

    try {
      // En iOS, usar getTemporaryDirectory() en lugar de getExternalStorageDirectory()
      final Directory dir = Platform.isIOS
          ? await getTemporaryDirectory()
          : await getTemporaryDirectory(); // También usar temporal para Android por consistencia

      final safeFileName = fileName.replaceAll(RegExp(r'[^\w\s-]'), '_');
      final file = File('${dir.path}/$safeFileName.png');
      await file.writeAsBytes(pngBytes);

      // Para iOS, necesitamos sharePositionOrigin si está disponible
      if (Platform.isIOS && context != null) {
        // Guardar valores del contexto antes de operaciones asíncronas
        final BuildContext? safeContext = context;
        Rect? sharePositionOrigin;
        
        try {
          // Obtener el RenderBox del contexto para calcular la posición
          final RenderBox? box = safeContext?.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize) {
            final Offset position = box.localToGlobal(Offset.zero);
            final Size size = box.size;
            
            // Asegurar que el rectángulo sea válido y no cero
            if (size.width > 0 && size.height > 0) {
              sharePositionOrigin = Rect.fromLTWH(
                position.dx,
                position.dy,
                size.width,
                size.height,
              );
            }
          }
        } catch (e) {
          // Ignorar error, usaremos fallback
        }
        
        // Si no pudimos obtener la posición válida, usar el centro de la pantalla como fallback
        if (sharePositionOrigin == null && safeContext != null) {
          try {
            final mediaQuery = MediaQuery.of(safeContext);
            final screenSize = mediaQuery.size;
            sharePositionOrigin = Rect.fromLTWH(
              screenSize.width / 2 - 50,
              screenSize.height / 2 - 50,
              100,
              100,
            );
          } catch (e) {
            // Si falla, usar un valor por defecto
            sharePositionOrigin = const Rect.fromLTWH(0, 0, 100, 100);
          }
        }
        
        // Usar shareXFiles con sharePositionOrigin para iOS
        await Share.shareXFiles(
          [XFile(file.path)],
          text: text ?? 'Compartido desde ManiGraB - Manifestaciones Cuánticas Grabovoi',
          sharePositionOrigin: sharePositionOrigin ?? const Rect.fromLTWH(0, 0, 100, 100),
        );
      } else {
        // Para Android o si no hay contexto, compartir normalmente
      await Share.shareXFiles(
        [XFile(file.path)],
        text: text ?? 'Compartido desde ManiGraB - Manifestaciones Cuánticas Grabovoi',
        );
      }
    } catch (e) {
      print('❌ Error al compartir imagen: $e');
      rethrow;
    }
  }

  /// Compartir solo texto
  static Future<void> shareText({
    required String text,
    BuildContext? context,
  }) async {
    if (kIsWeb) {
      // En web, copiar al portapapeles
      await Clipboard.setData(ClipboardData(text: text));
      return;
    }

    try {
      if (Platform.isIOS && context != null) {
        // Guardar valores del contexto antes de operaciones asíncronas
        final BuildContext? safeContext = context;
        Rect? sharePositionOrigin;
        
        try {
          // Para iOS, intentar obtener la posición del contexto
          final RenderBox? box = safeContext?.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize) {
            final Offset position = box.localToGlobal(Offset.zero);
            final Size size = box.size;
            
            if (size.width > 0 && size.height > 0) {
              sharePositionOrigin = Rect.fromLTWH(
                position.dx,
                position.dy,
                size.width,
                size.height,
              );
            }
          }
        } catch (e) {
          // Ignorar error, usaremos fallback
        }
        
        // Si no pudimos obtener la posición válida, usar el centro de la pantalla como fallback
        if (sharePositionOrigin == null && safeContext != null) {
          try {
            final mediaQuery = MediaQuery.of(safeContext);
            final screenSize = mediaQuery.size;
            sharePositionOrigin = Rect.fromLTWH(
              screenSize.width / 2 - 50,
              screenSize.height / 2 - 50,
              100,
              100,
            );
          } catch (e) {
            // Si falla, usar un valor por defecto
            sharePositionOrigin = const Rect.fromLTWH(0, 0, 100, 100);
          }
        }
        
        await Share.share(
          text,
          sharePositionOrigin: sharePositionOrigin ?? const Rect.fromLTWH(0, 0, 100, 100),
        );
      } else {
        await Share.share(text);
      }
    } catch (e) {
      print('❌ Error al compartir texto: $e');
      rethrow;
    }
  }
}
