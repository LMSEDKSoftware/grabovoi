import 'package:flutter/material.dart';
import 'dart:math' as math;

class GoldenSphere extends StatefulWidget {
  final double size;
  final Color color;
  final double glowIntensity;
  final bool isAnimated;

  const GoldenSphere({
    super.key,
    this.size = 200,
    this.color = const Color(0xFFFFD700),
    this.glowIntensity = 0.5,
    this.isAnimated = true,
  });

  @override
  State<GoldenSphere> createState() => _GoldenSphereState();
}

class _GoldenSphereState extends State<GoldenSphere> with TickerProviderStateMixin {
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
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutCubic),
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
            painter: _GoldenSpherePainter(
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

class _GoldenSpherePainter extends CustomPainter {
  final double rotationAngle;
  final double scale;
  final Color color;
  final double glowIntensity;

  _GoldenSpherePainter({
    required this.rotationAngle,
    required this.scale,
    required this.color,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * scale;

    // Dibujar múltiples capas de glow exterior
    _drawGlowLayers(canvas, center, radius);
    
    // Dibujar esfera principal con gradiente suave
    _drawMainSphere(canvas, center, radius);
    
    // Dibujar líneas de energía
    _drawEnergyLines(canvas, center, radius);
    
    // Dibujar highlight para efecto 3D
    _drawHighlight(canvas, center, radius);
  }

  void _drawGlowLayers(Canvas canvas, Offset center, double radius) {
    // Capa 1: Glow más externo
    final glowPaint1 = Paint()
      ..color = color.withOpacity(glowIntensity * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(center, radius * 1.8, glowPaint1);

    // Capa 2: Glow medio
    final glowPaint2 = Paint()
      ..color = color.withOpacity(glowIntensity * 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, radius * 1.4, glowPaint2);

    // Capa 3: Glow interno
    final glowPaint3 = Paint()
      ..color = color.withOpacity(glowIntensity * 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, radius * 1.1, glowPaint3);
  }

  void _drawMainSphere(Canvas canvas, Offset center, double radius) {
    // Gradiente radial suave sin círculo oscuro
    final radialGradient = RadialGradient(
      colors: [
        color.withOpacity(0.8),
        color.withOpacity(0.9),
        color.withOpacity(0.7),
        color.withOpacity(0.4),
        color.withOpacity(0.1),
        Colors.transparent,
      ],
      stops: const [0.0, 0.1, 0.3, 0.6, 0.8, 1.0],
    );

    final spherePaint = Paint()
      ..shader = radialGradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawCircle(center, radius, spherePaint);
  }

  void _drawEnergyLines(Canvas canvas, Offset center, double radius) {
    final linePaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Líneas horizontales
    for (int i = 1; i <= 3; i++) {
      final y = center.dy - radius + (2 * radius * i / 4);
      final distanceFromCenter = (center.dy - y).abs();
      
      if (distanceFromCenter < radius) {
        final lineRadius = math.sqrt(radius * radius - distanceFromCenter * distanceFromCenter);
        final left = Offset(center.dx - lineRadius, y);
        final right = Offset(center.dx + lineRadius, y);
        
        canvas.drawLine(left, right, linePaint);
      }
    }

    // Líneas verticales
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) + rotationAngle;
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
    // Highlight principal para efecto 3D
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.6),
          Colors.white.withOpacity(0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
          radius: radius * 0.5,
        ),
      );

    canvas.drawCircle(
      Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
      radius * 0.5,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoldenSpherePainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
           oldDelegate.scale != scale ||
           oldDelegate.color != color ||
           oldDelegate.glowIntensity != glowIntensity;
  }
}
