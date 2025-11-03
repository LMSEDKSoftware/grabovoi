import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/golden_sphere.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Portal Energético',
      description: 'Explora un espacio diseñado para elevar tu vibración y manifestar desde la Norma del Creador.',
      icon: Icons.auto_awesome,
      color: const Color(0xFFFFD700),
    ),
    OnboardingSlide(
      title: 'Pilotaje Cuántico Consciente',
      description: 'Inicia pilotajes con códigos Grabovoi. Visualiza la esfera dorada y repite el código con intención.',
      icon: Icons.self_improvement,
      color: const Color(0xFF4CAF50),
    ),
    OnboardingSlide(
      title: 'Sesión de Repetición',
      description: 'Programa repeticiones automáticas del código con audio. Puedes cancelar con confirmación en cualquier momento.',
      icon: Icons.access_time,
      color: const Color(0xFF26A69A),
    ),
    OnboardingSlide(
      title: 'Biblioteca Cuántica + IA',
      description: 'Busca códigos por tema o número. Si no existe y la IA lo encuentra, se inserta automáticamente. Si difiere descripción, se crea sugerencia para admin.',
      icon: Icons.search,
      color: const Color(0xFF42A5F5),
    ),
    OnboardingSlide(
      title: 'Imágenes para Compartir 1:1',
      description: 'Comparte imágenes cuadradas con: nombre de la app, esfera con código y título + descripción (sin alterar la UI).',
      icon: Icons.share,
      color: const Color(0xFF7E57C2),
    ),
    OnboardingSlide(
      title: 'Notificaciones Inteligentes',
      description: 'Recordatorios con prioridad (rachas, rutinas, resúmenes). Anti-spam y registro de historial en Perfil → Notificaciones.',
      icon: Icons.notifications_active,
      color: const Color(0xFFFF7043),
    ),
    OnboardingSlide(
      title: 'Recompensas Cuánticas',
      description: 'Cristales de energía, Luz cuántica, Restauradores de armonía, Mantras y Códigos Premium. Todo se actualiza con tu práctica diaria.',
      icon: Icons.diamond,
      color: const Color(0xFFFFD54F),
    ),
    OnboardingSlide(
      title: 'Avatar y Permisos',
      description: 'Sube tu avatar (permiso de fotos). Si el permiso está denegado, la app te guía para habilitarlo en Configuración.',
      icon: Icons.verified_user,
      color: const Color(0xFF26C6DA),
    ),
    OnboardingSlide(
      title: 'Aprobación de Sugerencias (Admin)',
      description: 'Los administradores pueden aprobar o rechazar sugerencias de códigos alternos desde Perfil → Aprobar Sugerencias.',
      icon: Icons.admin_panel_settings,
      color: const Color(0xFF8D6E63),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void _skipOnboarding() {
    _goToLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Indicadores de página
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (index) => _buildPageIndicator(index),
                  ),
                ),
              ),
              
              // Contenido de las páginas
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    return _buildSlide(_slides[index]);
                  },
                ),
              ),
              
              // Botones de navegación
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentPage > 0)
                          TextButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Text(
                              'Atrás',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 60),
                        
                        CustomButton(
                          text: _currentPage == _slides.length - 1 ? 'Comenzar' : 'Siguiente',
                          onPressed: _nextPage,
                          icon: _currentPage == _slides.length - 1 ? Icons.rocket_launch : Icons.arrow_forward,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Botón Saltar
                    TextButton(
                      onPressed: _skipOnboarding,
                      child: Text(
                        'Saltar',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 32 : 8,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFFFD700)
            : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildSlide(OnboardingSlide slide) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Esfera dorada simple
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  slide.color.withOpacity(0.3),
                  slide.color.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: slide.color.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                slide.icon,
                size: 50,
                color: slide.color,
              ),
            ),
          ),
          
          const SizedBox(height: 60),
          
          // Título
          Text(
            slide.title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: slide.color.withOpacity(0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Descripción
          Text(
            slide.description,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
