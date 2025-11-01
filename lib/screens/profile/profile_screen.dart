import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service_simple.dart';
import '../../services/user_progress_service.dart';
import '../../services/audio_service.dart';
import '../../services/audio_manager_service.dart';
import '../../repositories/codigos_repository.dart';
import '../auth/login_screen.dart';
import '../sugerencias/sugerencias_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final AuthServiceSimple _authService = AuthServiceSimple();
  final UserProgressService _progressService = UserProgressService();
  
  Map<String, dynamic>? _userProgress;
  bool _isLoading = true;
  
  // Animaciones
  late AnimationController _quantumController;
  late AnimationController _fadeController;
  late Animation<double> _quantumAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initAnimations();
  }
  
  void _initAnimations() {
    _quantumController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
    
    _quantumAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _quantumController, curve: Curves.linear),
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
  }
  
  @override
  void dispose() {
    _quantumController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!_authService.isLoggedIn) return;
    
    try {
      final progress = await _progressService.getUserProgress();
      setState(() {
        _userProgress = progress;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando datos del usuario: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      // Detener todos los servicios de audio antes de cerrar sesión
      final audioService = AudioService();
      await audioService.stopMusic();
      
      final audioManagerService = AudioManagerService();
      await audioManagerService.stop();
      
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error cerrando sesión: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: _buildQuantumBackground(
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Avatar circular con iniciales
                    _buildAvatar(),
                    const SizedBox(height: 24),
                    // Información del usuario
                    if (_authService.isLoggedIn && _authService.currentUser != null) ...[
                      Text(
                        _authService.currentUser!.name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _authService.currentUser!.email,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: const Color(0xFFFFD700),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 40),
                    // Botones de acción con tamaño optimizado
                    _buildButton(
                      text: 'Editar Perfil',
                      icon: Icons.edit,
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                        if (mounted) {
                          setState(() {});
                          await _loadUserData();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildButton(
                      text: 'Configuración',
                      icon: Icons.settings,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Función próximamente disponible'),
                            backgroundColor: Color(0xFFFFD700),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildButton(
                      text: 'Actualizar Códigos',
                      icon: Icons.refresh,
                      onPressed: () async {
                        try {
                          await CodigosRepository().refreshCodigos();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Códigos actualizados correctamente'),
                                backgroundColor: Color(0xFFFFD700),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Error al actualizar: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildButton(
                      text: 'Mis Sugerencias',
                      icon: Icons.lightbulb_outline,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SugerenciasScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildButton(
                      text: 'Cerrar Sesión',
                      icon: Icons.logout,
                      color: Colors.orange,
                      onPressed: _signOut,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Fondo cuántico con partículas animadas
  Widget _buildQuantumBackground({required Widget child}) {
    return AnimatedBuilder(
      animation: _quantumAnimation,
      builder: (context, _) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0B132B),
                Color(0xFF1C2541),
                Color(0xFF2C3E50),
              ],
            ),
          ),
          child: CustomPaint(
            painter: _QuantumFieldPainter(_quantumAnimation.value),
            child: child,
          ),
        );
      },
    );
  }
  
  // Avatar circular con iniciales
  Widget _buildAvatar() {
    if (_authService.currentUser == null) return const SizedBox();
    
    final name = _authService.currentUser!.name;
    final initials = name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase();
    
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFD700), width: 3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFD700).withOpacity(0.2),
            const Color(0xFFFFD700).withOpacity(0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.playfairDisplay(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFD700),
          ),
        ),
      ),
    );
  }
  
  // Botón con tamaño optimizado
  Widget _buildButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final buttonColor = color ?? const Color(0xFFFFD700);
    
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 60),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: buttonColor.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 0,
          ),
        ],
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: buttonColor,
          side: BorderSide(color: buttonColor, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFFFFD700),
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

// Custom painter para el campo cuántico animado
class _QuantumFieldPainter extends CustomPainter {
  final double rotationAngle;
  
  _QuantumFieldPainter(this.rotationAngle);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Partículas flotantes
    _drawParticles(canvas, size);
    
    // Ondas cuánticas concentradas arriba
    _drawQuantumWaves(canvas, center);
  }
  
  void _drawParticles(Canvas canvas, Size size) {
    final particlePaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.3);
    
    // Generar partículas aleatorias pero consistentes
    final random = math.Random(42);
    for (int i = 0; i < 80; i++) {
      final x = (random.nextDouble() * size.width);
      final y = (random.nextDouble() * size.height);
      final particleSize = random.nextDouble() * 3 + 1;
      
      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        particlePaint,
      );
    }
  }
  
  void _drawQuantumWaves(Canvas canvas, Offset center) {
    final wavePaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Ondas concentradas en la parte superior
    final topCenter = Offset(center.dx, center.dy * 0.3);
    
    for (int i = 1; i <= 6; i++) {
      final radius = 30.0 + (i * 20.0);
      final angle = rotationAngle + (i * 0.5);
      
      for (int j = 0; j < 3; j++) {
        final offsetAngle = angle + (j * (2 * math.pi / 3));
        final waveOffset = Offset(
          topCenter.dx + math.cos(offsetAngle) * 50,
          topCenter.dy + math.sin(offsetAngle) * 30,
        );
        
        canvas.drawCircle(waveOffset, radius, wavePaint);
      }
    }
    
    // Espirales cuánticas
    final spiralPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    for (int i = 0; i < 2; i++) {
      final path = Path();
      final startRadius = 20.0;
      final turns = 1.5;
      
      for (double angle = 0; angle < turns * 2 * math.pi; angle += 0.1) {
        final radius = startRadius + (angle * 3);
        final x = topCenter.dx + radius * math.cos(angle + rotationAngle + (i * math.pi));
        final y = topCenter.dy + radius * math.sin(angle + rotationAngle + (i * math.pi));
        
        if (angle == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      canvas.drawPath(path, spiralPaint);
    }
  }
  
  @override
  bool shouldRepaint(_QuantumFieldPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle;
  }
}
