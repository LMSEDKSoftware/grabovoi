// Este archivo solo se importa en web
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

/// Utilidades para manejar imágenes en web con soporte CORS
class WebImageHelper {
  /// Registra un elemento HTML <img> para evitar problemas de CORS en web
  static void registerWebImage(String url, String viewType) {
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final img = html.ImageElement()
          ..src = url
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'contain'
          ..crossOrigin = 'anonymous'; // Permite CORS
        
        return img;
      },
    );
  }
}
