import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_version_service.dart';

/// Dialog de actualización estilizado con la temática dorada de la app.
///
/// Uso:
/// ```dart
/// await AppUpdateDialog.checkAndShow(context);
/// ```
class AppUpdateDialog {
  /// Verifica la versión y muestra el dialog si hay actualización disponible.
  /// No hace nada si la app está actualizada o si ocurre un error.
  static Future<void> checkAndShow(BuildContext context) async {
    // En web no aplica la actualización de tiendas
    if (kIsWeb) return;

    final info = await AppVersionService().checkVersion();
    if (info == null) return;

    if (info.status == AppVersionStatus.upToDate) return;

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: info.status != AppVersionStatus.updateRequired,
      builder: (ctx) => _AppUpdateDialogWidget(info: info),
    );
  }
}

class _AppUpdateDialogWidget extends StatelessWidget {
  final AppVersionInfo info;
  const _AppUpdateDialogWidget({required this.info});

  bool get _isRequired => info.status == AppVersionStatus.updateRequired;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isRequired, // Bloquear botón Back si es obligatorio
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFFFD700).withOpacity(0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.15),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildBody(context),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withOpacity(0.15),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          // Ícono animado
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _isRequired ? Icons.system_update_rounded : Icons.update_rounded,
              size: 36,
              color: const Color(0xFF0B132B),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isRequired ? '⚡ Actualización Requerida' : '✨ Nueva Versión Disponible',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFD700),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Badge de versión
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.4),
              ),
            ),
            child: Text(
              'v${info.versionActual} → v${info.versionRemota}',
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                color: const Color(0xFFFFD700),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      child: Column(
        children: [
          // Separador
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFFFFD700).withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Mensaje
          Text(
            info.mensaje,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.85),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (_isRequired) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta actualización es obligatoria para continuar usando la app.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.orange.shade200,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          // Botón principal: ir a la tienda
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _abrirTienda(context),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(
                'Actualizar ahora',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF0B132B),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                shadowColor: const Color(0xFFFFD700).withOpacity(0.4),
              ),
            ),
          ),
          // Botón secundario: solo si NO es obligatoria
          if (!_isRequired) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Más tarde',
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _abrirTienda(BuildContext context) async {
    // Determinar URL según plataforma
    // En Android → Play Store; en iOS → App Store
    String url;
    try {
      // Intentar detectar plataforma sin dart:io (funciona en web también)
      url = Theme.of(context).platform == TargetPlatform.iOS
          ? info.urlAppStore
          : info.urlPlayStore;
    } catch (_) {
      url = info.urlPlayStore;
    }

    if (url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
