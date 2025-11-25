import 'package:flutter/material.dart';
import 'dart:math' as math;

class SacredCircle extends StatefulWidget {
  final double size;
  
  const SacredCircle({super.key, this.size = 200});

  @override
  State<SacredCircle> createState() => _SacredCircleState();
}

class _SacredCircleState extends State<SacredCircle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: SacredCirclePainter(),
          ),
        );
      },
    );
  }
}

class SacredCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Anillo exterior dorado
    final outerPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(center, radius, outerPaint);
    canvas.drawCircle(center, radius * 0.8, outerPaint);
    canvas.drawCircle(center, radius * 0.6, outerPaint);
    
    // Líneas radiantes
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final start = Offset(
        center.dx + radius * 0.6 * math.cos(angle),
        center.dy + radius * 0.6 * math.sin(angle),
      );
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      
      canvas.drawLine(start, end, outerPaint);
    }
    
    // Centro brillante
    final centerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700).withOpacity(0.8),
          const Color(0xFFFFD700).withOpacity(0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.3));
    
    canvas.drawCircle(center, radius * 0.3, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

