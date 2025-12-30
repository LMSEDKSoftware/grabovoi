import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_update/in_app_update.dart';
import '../services/in_app_update_service.dart';

/// Widget que muestra un diálogo cuando hay una actualización disponible
class UpdateAvailableDialog extends StatelessWidget {
  final bool isCritical;
  final VoidCallback? onUpdate;
  final VoidCallback? onLater;

  const UpdateAvailableDialog({
    super.key,
    this.isCritical = false,
    this.onUpdate,
    this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C2541),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isCritical ? Colors.red : const Color(0xFFFFD700),
          width: 2,
        ),
      ),
      title: Row(
        children: [
          Icon(
            isCritical ? Icons.warning : Icons.system_update,
            color: isCritical ? Colors.red : const Color(0xFFFFD700),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isCritical ? 'Actualización Crítica' : 'Actualización Disponible',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        isCritical
            ? 'Hay una actualización importante disponible. Se recomienda actualizar ahora para continuar usando la app de forma segura.'
            : 'Hay una nueva versión disponible. ¿Deseas actualizar ahora? Puedes continuar usando la app mientras se descarga.',
        style: GoogleFonts.inter(
          color: Colors.white70,
          fontSize: 16,
        ),
      ),
      actions: [
        if (!isCritical)
          TextButton(
            onPressed: onLater ?? () => Navigator.of(context).pop(),
            child: Text(
              'Más tarde',
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ),
        ElevatedButton(
          onPressed: onUpdate ??
              () async {
                Navigator.of(context).pop();
                if (isCritical) {
                  await InAppUpdateService().performImmediateUpdate();
                } else {
                  await InAppUpdateService().startFlexibleUpdate();
                }
              },
          style: ElevatedButton.styleFrom(
            backgroundColor: isCritical ? Colors.red : const Color(0xFFFFD700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Actualizar',
            style: GoogleFonts.inter(
              color: isCritical ? Colors.white : const Color(0xFF1a1a2e),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// Muestra el diálogo de actualización si hay una disponible
  static Future<void> showIfUpdateAvailable(BuildContext context) async {
    final updateService = InAppUpdateService();
    final updateInfo = await updateService.checkForUpdate();

    if (updateInfo == null) {
      return;
    }

    if (updateInfo.updateAvailability != UpdateAvailability.updateAvailable) {
      return;
    }

    // Determinar si es crítica
    final isCritical = updateInfo.immediateUpdateAllowed &&
        (updateInfo.clientVersionStalenessDays ?? 0) > 7;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: !isCritical, // No permitir cerrar si es crítica
      builder: (context) => UpdateAvailableDialog(
        isCritical: isCritical,
        onUpdate: () async {
          Navigator.of(context).pop();
          if (isCritical) {
            await updateService.performImmediateUpdate();
          } else {
            await updateService.startFlexibleUpdate();
          }
        },
      ),
    );
  }
}

