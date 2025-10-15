import 'package:flutter/material.dart';
import 'dart:math' as math;

class Sphere3D extends StatefulWidget {
  final double size;
  final Color color;
  final double glowIntensity;
  final bool isAnimated;

  const Sphere3D({
    super.key,
    this.size = 200,
    this.color = const Color(0xFFFFD700),
    this.glowIntensity = 0.3,
    this.isAnimated = true,
  });

  @override
  State<Sphere3D> createState() => _Sphere3DState();
}

class _Sphere3DState extends State<Sphere3D> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
        builder: (context, child) {
          return CustomPaint(
            painter: _Sphere3DPainter(
              rotationAngle: widget.isAnimated ? _rotationAnimation.value : 0,
              scale: widget.isAnimated ? _pulseAnimation.value : 1.0,
              color: widget.color,
              glowIntensity: widget.glowIntensity,
            ),
          );
        },
      ),
    );
  }
}

class _Sphere3DPainter extends CustomPainter {
  final double rotationAngle;
  final double scale;
  final Color color;
  final double glowIntensity;

  _Sphere3DPainter({
    required this.rotationAngle,
    required this.scale,
    required this.color,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * scale;

    // Crear gradiente radial para el efecto 3D sin círculo oscuro
    final radialGradient = RadialGradient(
      colors: [
        color.withOpacity(0.6),
        color.withOpacity(0.7),
        color.withOpacity(0.5),
        color.withOpacity(0.3),
        color.withOpacity(0.1),
        Colors.transparent,
      ],
      stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
    );

    // Dibujar esfera principal con gradiente
    final spherePaint = Paint()
      ..shader = radialGradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawCircle(center, radius, spherePaint);

    // Dibujar líneas de latitud (horizontales)
    _drawLatitudeLines(canvas, center, radius);
    
    // Dibujar líneas de longitud (verticales)
    _drawLongitudeLines(canvas, center, radius);

    // Dibujar reflejo/highlight para efecto 3D
    _drawHighlight(canvas, center, radius);

    // Dibujar glow exterior
    _drawGlow(canvas, center, radius);
  }

  void _drawLatitudeLines(Canvas canvas, Offset center, double radius) {
    final linePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Dibujar 5 líneas de latitud
    for (int i = 1; i <= 5; i++) {
      final y = center.dy - radius + (2 * radius * i / 6);
      final distanceFromCenter = (center.dy - y).abs();
      
      if (distanceFromCenter < radius) {
        final lineRadius = math.sqrt(radius * radius - distanceFromCenter * distanceFromCenter);
        final left = Offset(center.dx - lineRadius, y);
        final right = Offset(center.dx + lineRadius, y);
        
        canvas.drawLine(left, right, linePaint);
      }
    }
  }

  void _drawLongitudeLines(Canvas canvas, Offset center, double radius) {
    final linePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Dibujar 8 líneas de longitud
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) + rotationAngle;
      final start = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final end = Offset(
        center.dx - radius * math.cos(angle),
        center.dy - radius * math.sin(angle),
      );
      
      canvas.drawLine(start, end, linePaint);
    }
  }

  void _drawHighlight(Canvas canvas, Offset center, double radius) {
    // Highlight en la parte superior izquierda para efecto 3D
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.4),
          Colors.white.withOpacity(0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
          radius: radius * 0.4,
        ),
      );

    canvas.drawCircle(
      Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
      radius * 0.4,
      highlightPaint,
    );
  }

  void _drawGlow(Canvas canvas, Offset center, double radius) {
    // Glow exterior múltiple para efecto más realista
    final glowPaint = Paint()
      ..color = color.withOpacity(glowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    // Primer glow
    canvas.drawCircle(center, radius * 1.2, glowPaint);

    // Segundo glow más sutil
    final glowPaint2 = Paint()
      ..color = color.withOpacity(glowIntensity * 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    
    canvas.drawCircle(center, radius * 1.4, glowPaint2);

    // Tercer glow muy sutil
    final glowPaint3 = Paint()
      ..color = color.withOpacity(glowIntensity * 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35);
    
    canvas.drawCircle(center, radius * 1.6, glowPaint3);
  }

  @override
  bool shouldRepaint(covariant _Sphere3DPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
           oldDelegate.scale != scale ||
           oldDelegate.color != color ||
           oldDelegate.glowIntensity != glowIntensity;
  }
}
