import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/golden_sphere.dart';
import '../../services/auth_service_simple.dart';
import '../../services/user_progress_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthServiceSimple _authService = AuthServiceSimple();
  final UserProgressService _progressService = UserProgressService();
  
  Map<String, dynamic>? _userProgress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
      body: GlowBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                
                // Esfera dorada
                const GoldenSphere(
                  size: 150,
                  color: Color(0xFFFFD700),
                  glowIntensity: 0.7,
                  isAnimated: true,
                ),
                
                const SizedBox(height: 32),
                
                // Información del usuario
                if (_authService.isLoggedIn && _authService.currentUser != null) ...[
                  Text(
                    'Hola, ${_authService.currentUser!.name}',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
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
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                
                const SizedBox(height: 48),
                
                // Estadísticas del usuario
                if (_userProgress != null) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Tu Progreso',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFD700),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard(
                              'Sesiones',
                              '${_userProgress!['total_sessions'] ?? 0}',
                              Icons.play_circle_outline,
                            ),
                            _buildStatCard(
                              'Días Consecutivos',
                              '${_userProgress!['consecutive_days'] ?? 0}',
                              Icons.calendar_today,
                            ),
                            _buildStatCard(
                              'Nivel Energético',
                              '${_userProgress!['energy_level'] ?? 50}',
                              Icons.energy_savings_leaf,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
                
                // Botones de acción
                Column(
                  children: [
                    CustomButton(
                      text: 'Editar Perfil',
                      onPressed: () {
                        // TODO: Implementar edición de perfil
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Función próximamente disponible'),
                            backgroundColor: Color(0xFFFFD700),
                          ),
                        );
                      },
                      isOutlined: true,
                      icon: Icons.edit,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    CustomButton(
                      text: 'Configuración',
                      onPressed: () {
                        // TODO: Implementar configuración
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Función próximamente disponible'),
                            backgroundColor: Color(0xFFFFD700),
                          ),
                        );
                      },
                      isOutlined: true,
                      icon: Icons.settings,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    CustomButton(
                      text: 'Cerrar Sesión',
                      onPressed: _signOut,
                      color: Colors.red,
                      icon: Icons.logout,
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Información adicional
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Manifestación Numérica Grabovoi',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tu viaje de transformación personal',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
