import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IlluminatedCodeText extends StatelessWidget {
  final String code;
  final double fontSize;
  final Color? color;
  final double letterSpacing;
  final TextAlign textAlign;
  final bool isAnimated;
  final Animation<double>? animation;

  const IlluminatedCodeText({
    super.key,
    required this.code,
    this.fontSize = 36,
    this.color,
    this.letterSpacing = 6,
    this.textAlign = TextAlign.center,
    this.isAnimated = false,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFFFFD700);
    
    Widget textWidget = Text(
      code,
      style: GoogleFonts.spaceMono(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: letterSpacing,
        shadows: [
          // Sombra oscura para profundidad (primera capa)
          Shadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 6.0,
            offset: const Offset(2.0, 2.0),
          ),
          Shadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 3.0,
            offset: const Offset(-1.0, -1.0),
          ),
          // Sombra principal del color vibracional
          Shadow(
            color: effectiveColor.withOpacity(1.0),
            blurRadius: 30,
            offset: const Offset(0, 0),
          ),
          // Sombra blanca para brillo
          Shadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 20,
            offset: const Offset(0, 0),
          ),
          // Sombra adicional para profundidad
          Shadow(
            color: effectiveColor.withOpacity(0.6),
            blurRadius: 40,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      textAlign: textAlign,
    );

    if (isAnimated && animation != null) {
      return AnimatedBuilder(
        animation: animation!,
        builder: (context, child) {
          return Transform.scale(
            scale: animation!.value,
            child: textWidget,
          );
        },
      );
    }

    return textWidget;
  }
}
