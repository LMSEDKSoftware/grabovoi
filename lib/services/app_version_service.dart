import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Resultado de la verificación de versión.
enum AppVersionStatus {
  /// La app está actualizada — no se requiere ninguna acción.
  upToDate,

  /// Hay una versión más reciente, pero la actualización es opcional.
  updateAvailable,

  /// La versión instalada es inferior a la mínima — actualización obligatoria.
  updateRequired,
}

/// Información de actualización retornada por el servicio.
class AppVersionInfo {
  final AppVersionStatus status;
  final String versionActual;       // versión instalada en el dispositivo
  final String versionRemota;       // versión más reciente en tiendas
  final String versionMinima;       // versión mínima requerida
  final bool forzarActualizacion;   // campo explícito de Supabase
  final String mensaje;
  final String urlPlayStore;
  final String urlAppStore;

  const AppVersionInfo({
    required this.status,
    required this.versionActual,
    required this.versionRemota,
    required this.versionMinima,
    required this.forzarActualizacion,
    required this.mensaje,
    required this.urlPlayStore,
    required this.urlAppStore,
  });
}

/// Servicio que verifica si hay una nueva versión de la app disponible
/// consultando la tabla [app_config] en Supabase.
///
/// No depende de ningún plugin nativo — funciona en Android, iOS y Web.
class AppVersionService {
  static final AppVersionService _instance = AppVersionService._internal();
  factory AppVersionService() => _instance;
  AppVersionService._internal();

  static const _tag = '🔄 [AppVersion]';

  // ─── DEBUG: Forzar dialog para demostración ───────────────────────────────
  // Cambiar a true para probar el dialog sin necesitar una nueva versión en Supabase
  static const bool _debugForceUpdate = false;
  // ─────────────────────────────────────────────────────────────────────────

  /// Consulta Supabase y retorna el estado de la versión.
  /// Maneja todos los errores internamente y nunca lanza excepciones al caller.
  Future<AppVersionInfo?> checkVersion() async {
    try {
      // Modo debug: forzar el dialog sin consultar Supabase
      if (_debugForceUpdate) {
        debugPrint('$_tag 🧪 MODO DEBUG — forzando dialog de actualización');
        return const AppVersionInfo(
          status: AppVersionStatus.updateAvailable,
          versionActual: '2.3.51',
          versionRemota: '2.4.0',
          versionMinima: '2.3.0',
          forzarActualizacion: false,
          mensaje: 'Nueva versión 2.4.0 disponible. Actualiza para disfrutar las últimas mejoras.',
          urlPlayStore: 'https://play.google.com/store/apps/details?id=com.manifestacion.grabovoi',
          urlAppStore: 'https://apps.apple.com/app/id000000000',
        );
      }
      // 1. Obtener versión instalada en el dispositivo
      final packageInfo = await PackageInfo.fromPlatform();
      final versionInstalada = packageInfo.version; // ej. "2.3.51"

      debugPrint('$_tag Versión instalada: $versionInstalada');

      // 2. Leer configuración remota de Supabase (incluyendo nuevos campos)
      final rows = await Supabase.instance.client
          .from('app_config')
          .select('key, value, fecha_visualizacion, implementada');

      if (rows == null || (rows as List).isEmpty) {
        debugPrint('$_tag No se encontró configuración en app_config');
        return null;
      }

      // Convertir lista a Map<String,String> para valores simples
      // y extraer campos especiales de la fila 'version_actual'
      final config = <String, String>{};
      String? implementadaVersion;     // 'OK', 'PENDIENTE' o null
      String? fechaVisualizacionStr;   // ISO 8601 string o null

      for (final row in rows) {
        final key = row['key'] as String;
        config[key] = row['value'] as String;

        // Capturar campos de control solo de la fila version_actual
        if (key == 'version_actual') {
          implementadaVersion  = row['implementada'] as String?;
          fechaVisualizacionStr = row['fecha_visualizacion'] as String?;
        }
      }

      // ── Verificar si la versión está lista para mostrarse ──────────────────
      // Regla: solo mostrar si implementada = 'OK'
      // Fallback: si pg_cron aún no la activó pero la fecha ya pasó → activar localmente
      bool versionActivada;
      if (implementadaVersion == 'OK') {
        versionActivada = true;
      } else if (implementadaVersion == 'PENDIENTE' && fechaVisualizacionStr != null) {
        // Fallback: evaluar si la fecha de visualización ya llegó
        try {
          final fechaViz = DateTime.parse(fechaVisualizacionStr).toUtc();
          final ahora    = DateTime.now().toUtc();
          versionActivada = ahora.isAfter(fechaViz);
          if (versionActivada) {
            debugPrint('$_tag ⏰ Fallback: fecha_visualizacion ya pasó — mostrando dialog');
          } else {
            final restante = fechaViz.difference(ahora);
            debugPrint('$_tag ⏳ Versión PENDIENTE — faltan ${restante.inHours}h ${restante.inMinutes.remainder(60)}m para activarse');
          }
        } catch (_) {
          versionActivada = false;
        }
      } else {
        // Sin datos de control → asumir activa (compatibilidad con datos sin columnas nuevas)
        versionActivada = implementadaVersion == null;
      }

      // Si la versión no está activa todavía, no mostrar dialog
      if (!versionActivada) {
        debugPrint('$_tag 🔒 Versión no activada aún — dialog suprimido');
        return AppVersionInfo(
          status: AppVersionStatus.upToDate,
          versionActual: versionInstalada,
          versionRemota: versionInstalada,
          versionMinima: versionInstalada,
          forzarActualizacion: false,
          mensaje: '',
          urlPlayStore: '',
          urlAppStore: '',
        );
      }
      // ────────────────────────────────────────────────────────────────────────

      final versionRemota  = config['version_actual'] ?? versionInstalada;
      final versionMinima  = config['version_minima'] ?? versionInstalada;
      final forzar         = config['forzar_actualizacion']?.toLowerCase() == 'true';
      final mensaje        = config['mensaje_actualizacion'] ?? '¡Nueva versión disponible! Actualiza para disfrutar las últimas mejoras.';
      final urlPlayStore   = config['url_playstore'] ?? '';
      final urlAppStore    = config['url_appstore'] ?? '';

      debugPrint('$_tag Versión remota: $versionRemota | Mínima: $versionMinima | Forzar: $forzar');

      // 3. Comparar versiones
      final status = _evaluateStatus(
        instalada: versionInstalada,
        remota: versionRemota,
        minima: versionMinima,
        forzar: forzar,
      );

      debugPrint('$_tag Status: $status');

      return AppVersionInfo(
        status: status,
        versionActual: versionInstalada,
        versionRemota: versionRemota,
        versionMinima: versionMinima,
        forzarActualizacion: forzar,
        mensaje: mensaje,
        urlPlayStore: urlPlayStore,
        urlAppStore: urlAppStore,
      );
    } catch (e, st) {
      debugPrint('$_tag Error verificando versión: $e\n$st');
      return null; // Silencioso — no queremos bloquear la app por un error de red
    }
  }

  /// Compara versiones semánticas (Mayor.Menor.Parche).
  /// Retorna negativo si [a] < [b], 0 si son iguales, positivo si [a] > [b].
  int _compareVersions(String a, String b) {
    final partsA = a.split('.').map(int.tryParse).toList();
    final partsB = b.split('.').map(int.tryParse).toList();

    // Normalizar longitudes
    while (partsA.length < 3) partsA.add(0);
    while (partsB.length < 3) partsB.add(0);

    for (int i = 0; i < 3; i++) {
      final diff = (partsA[i] ?? 0) - (partsB[i] ?? 0);
      if (diff != 0) return diff;
    }
    return 0;
  }

  AppVersionStatus _evaluateStatus({
    required String instalada,
    required String remota,
    required String minima,
    required bool forzar,
  }) {
    // Primero verificar si la versión instalada es menor que la mínima
    if (_compareVersions(instalada, minima) < 0) {
      return AppVersionStatus.updateRequired;
    }

    // Luego verificar si hay una versión más reciente disponible
    if (_compareVersions(instalada, remota) < 0) {
      // Si forzar_actualizacion está activado, también tratar como requerido
      return forzar
          ? AppVersionStatus.updateRequired
          : AppVersionStatus.updateAvailable;
    }

    return AppVersionStatus.upToDate;
  }
}
