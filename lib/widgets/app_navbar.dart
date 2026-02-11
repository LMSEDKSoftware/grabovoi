import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppNavbar extends StatelessWidget {
  final List<Widget>? rightIcons;
  final VoidCallback? onBackPressed;
  final bool showBackButton;

  const AppNavbar({
    super.key,
    this.rightIcons,
    this.onBackPressed,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0B132B),
            const Color(0xFF1C2541),
            const Color(0xFF0B132B).withOpacity(0.8),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Botón de regreso (si aplica)
            if (showBackButton)
              IconButton(
                onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: 'Volver',
              )
            else
              const SizedBox(width: 8),
            
            // Nombre de la app centrado
            Expanded(
              child: Center(
                child: Text(
                  'ManiGraB',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: const Color(0xFFFFD700).withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Iconos a la derecha
            if (rightIcons != null && rightIcons!.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: rightIcons!,
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

