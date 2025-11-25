import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/subscription/subscription_screen.dart';

class SubscriptionRequiredModal extends StatelessWidget {
  final String? message;
  final VoidCallback? onDismiss;

  const SubscriptionRequiredModal({
    super.key,
    this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 360;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 24,
        vertical: 24,
      ),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 20 : 24),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2541),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFD700),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de candado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFD700),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.lock_outline,
                color: Color(0xFFFFD700),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),

            // Título
            Text(
              'Contenido Premium',
              style: GoogleFonts.inter(
                color: const Color(0xFFFFD700),
                fontSize: isCompact ? 24 : 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Mensaje
            Text(
              message ??
                  'Esta función está disponible solo para usuarios Premium. Suscríbete para acceder a todas las funciones de la app.',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: isCompact ? 14 : 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Botón de suscripción
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cerrar modal
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFFFFD700).withOpacity(0.5),
                ),
                child: Text(
                  'Ver Planes Premium',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Botón cancelar
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDismiss?.call();
              },
              child: Text(
                'Cancelar',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void show(BuildContext context, {String? message, VoidCallback? onDismiss}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SubscriptionRequiredModal(
        message: message,
        onDismiss: onDismiss,
      ),
    );
  }
}

