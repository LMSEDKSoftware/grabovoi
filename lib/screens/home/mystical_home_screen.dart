import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/codes_provider.dart';
import '../../providers/tracker_provider.dart';
import '../../providers/auth_provider.dart';

class MysticalHomeScreen extends StatefulWidget {
  const MysticalHomeScreen({super.key});

  @override
  State<MysticalHomeScreen> createState() => _MysticalHomeScreenState();
}

class _MysticalHomeScreenState extends State<MysticalHomeScreen> with TickerProviderStateMixin {
  late AnimationController _starsController;
  late AnimationController _glowController;
  late Animation<double> _starsAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _starsController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _starsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _starsController, curve: Curves.easeInOut),
    );
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    _starsController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _starsController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A0B3D), // Deep purple
              Color(0xFF2D1B69), // Medium purple
              Color(0xFF4A2C7A), // Lighter purple
            ],
          ),
        ),
        child: Stack(
          children: [
            // Estrellas de fondo
            _buildStarField(),
            // Contenido principal
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildMysticalHeader(),
                    const SizedBox(height: 60),
                    _buildMainButtons(),
                    const SizedBox(height: 40),
                    _buildBottomNavigation(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarField() {
    return AnimatedBuilder(
      animation: _starsAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: StarFieldPainter(_starsAnimation.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildMysticalHeader() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Column(
          children: [
            // Icono místico central
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFF59E0B).withOpacity(0.35 + _glowAnimation.value * 0.25),
                    const Color(0xFFF59E0B).withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.55 + _glowAnimation.value * 0.35),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.9),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome,
                    color: Color(0xFFFDE68A),
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Título
            const Text(
              'Manifestación\nNumérica Grabovoi',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w300,
                height: 1.2,
                letterSpacing: 1.5,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainButtons() {
    final buttons = [
      {
        'title': 'Secuencias Numéricas',
        'number': '519 7148',
        'color': const Color(0xFF8B5CF6),
        'route': '/codes',
      },
      {
        'title': 'Búsqueda por Palabras Clave',
        'number': '71042',
        'color': const Color(0xFF06B6D4),
        'route': '/codes',
      },
      {
        'title': 'Pilotaje',
        'number': '888885888888',
        'color': const Color(0xFFF59E0B),
        'route': '/pilotaje',
      },
      {
        'title': 'Favoritos',
        'number': '9181971848448',
        'color': const Color(0xFFEC4899),
        'route': '/favorites',
      },
    ];

    return Column(
      children: buttons.map((button) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: _buildMysticalButton(
            title: button['title'] as String,
            number: button['number'] as String,
            color: button['color'] as Color,
            onTap: () => context.push(button['route'] as String),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMysticalButton({
    required String title,
    required String number,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0F172A),
                  const Color(0xFF0B1224),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.9),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.25 + _glowAnimation.value * 0.15),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFFFDE68A),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        number,
                        style: TextStyle(
                          color: const Color(0xFFFBBF24),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: const Color(0xFFF59E0B),
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Inicio', true),
          _buildNavItem(Icons.search, 'Buscar', false),
          _buildNavItem(Icons.favorite, 'Favoritos', false),
          _buildNavItem(Icons.person, 'Perfil', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? const Color(0xFF8B5CF6) : Colors.white.withOpacity(0.6),
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF8B5CF6) : Colors.white.withOpacity(0.6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class StarFieldPainter extends CustomPainter {
  final double animationValue;

  StarFieldPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = const Color(0xFF8B5CF6).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Dibujar estrellas pequeñas
    for (int i = 0; i < 50; i++) {
      final x = (i * 37.0) % size.width;
      final y = (i * 23.0) % size.height;
      final opacity = (0.3 + (i % 3) * 0.2) * (0.5 + 0.5 * animationValue);
      
      canvas.drawCircle(
        Offset(x, y),
        1.0 + (i % 2),
        paint..color = Colors.white.withOpacity(opacity),
      );
    }

    // Dibujar estrellas más grandes con brillo
    for (int i = 0; i < 15; i++) {
      final x = (i * 67.0) % size.width;
      final y = (i * 41.0) % size.height;
      final starSize = 2.0 + (i % 3);
      final opacity = (0.6 + (i % 2) * 0.3) * (0.7 + 0.3 * animationValue);
      
      // Brillo
      canvas.drawCircle(
        Offset(x, y),
        starSize * 3,
        glowPaint..color = const Color(0xFF8B5CF6).withOpacity(opacity * 0.3),
      );
      
      // Estrella
      canvas.drawCircle(
        Offset(x, y),
        starSize,
        paint..color = Colors.white.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
