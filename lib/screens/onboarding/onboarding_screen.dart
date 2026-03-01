import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../services/permissions_service.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Mantener la lista como `static const` evita que el tree-shaking de iconos
  // elimine glifos de Material Icons en builds release (especialmente en web).
  static const List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Tu esfera de pilotaje',
      description: 'No es solo una imagen, es una antena cuántica de propósito.\n\nAquí, el enfoque se convierte en dirección.\n\nEl número en vibración.',
      mentalShift: 'No estás enfocando la mente. Estás alineando tu campo.',
      icon: Icons.auto_awesome,
      color: Color(0xFFFFD700),
    ),
    OnboardingSlide(
      title: 'Biblioteca Viva',
      description: 'Cada número es una llave.\n\nLa app no busca secuencias, despierta rutas. Puedes explorar con intención o dejar que la Inteligencia Cuántica Vibracional sugiera lo que tu alma ya sabe que necesita.',
      mentalShift: 'No estás navegando una base de datos. Estás explorando el lenguaje de tu destino.',
      icon: Icons.search,
      color: Color(0xFF42A5F5),
    ),
    OnboardingSlide(
      title: 'Sesión de Repetición',
      description: 'La constancia es un llamado.\n\nAquí no solo repites un número: lo vibras.',
      mentalShift: 'No estás haciendo un ritual. Estás habitando tu nueva frecuencia.',
      icon: Icons.access_time,
      color: Color(0xFF26A69A),
    ),
    OnboardingSlide(
      title: 'Pilotaje Consciente',
      description: 'Manifestar no es desear. Es conducir.\n\nEl pilotaje no guía al universo. Te guía a ti.\n\nEs el momento en que la app deja de ser app… y se convierte en brújula energética.',
      mentalShift: 'No estás esperando un milagro. Estás activando tu rol de creador.',
      icon: Icons.self_improvement,
      color: Color(0xFF4CAF50),
    ),
    OnboardingSlide(
      title: 'Portal Energético',
      description: 'Sí, tu frecuencia tiene forma.\n\nCada pilotaje sube tu nivel. Cada sesión suma luz.\n\nVisualiza tu energía con 💎 y ✨ porque lo que no se ve, aquí… se revela.',
      mentalShift: 'No estás acumulando puntos. Estás calibrando tu campo.',
      icon: Icons.show_chart,
      color: Color(0xFF9C27B0),
    ),
    OnboardingSlide(
      title: 'Notificaciones',
      description: 'No es spam. Es sincronía.\n\nLas notificaciones son mensajes diseñados para llegar en el momento exacto.\n\nNada es casual. Todo es secuencia.',
      mentalShift: 'No son alertas. Son llamados vibracionales.',
      icon: Icons.notifications_active,
      color: Color(0xFFFF7043),
    ),
    OnboardingSlide(
      title: 'Recompensas de Luz',
      description: 'Cada sesión te devuelve energía.\n\nCristales, luz cuántica, restauradores… no son premios.\n\nSon anclas que confirman que estás en expansión.',
      mentalShift: 'No estás gamificando tu progreso. Estás recibiendo evidencia energética.',
      icon: Icons.diamond,
      color: Color(0xFFFFD54F),
    ),
    OnboardingSlide(
      title: 'Comparte tu Vibración',
      description: 'Una imagen que lleva intención',
      mentalShift: 'No estás mandando una imagen. Estás irradiando una activación',
      icon: Icons.share,
      color: Color(0xFF7E57C2),
    ),
    OnboardingSlide(
      title: 'Inteligencia Cuántica Vibracional',
      description: 'El sistema reconoce si tu secuencia existe, vibra o necesita otro camino.\n\nLa Inteligencia Cuántica Vibracional no reemplaza tu intención, la respalda.',
      mentalShift: 'No es un sistema que aprueba o rechaza. Es un oráculo digital que confirma tu frecuencia.',
      icon: Icons.verified,
      color: Color(0xFF00BCD4),
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

  void _goToLogin() async {
    // Solicitar permisos antes de ir al login
    await PermissionsService().requestInitialPermissions();
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
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
              // Indicadores de página (más compactos)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              
              // Botones de navegación (más compactos)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                                fontSize: 15,
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
                    
                    const SizedBox(height: 8),
                    
                    // Botón Saltar
                    TextButton(
                      onPressed: _skipOnboarding,
                      child: Text(
                        'Saltar',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 13,
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Esfera dorada simple (más pequeña)
            Container(
              width: 100,
              height: 100,
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
                  size: 45,
                  color: slide.color,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Título (más compacto)
            Text(
              slide.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
                shadows: [
                  Shadow(
                    color: slide.color.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Descripción (texto más compacto, sin espacios extra)
            Text(
              slide.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.white70,
                height: 1.4,
                letterSpacing: 0.2,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Mental Shift (más compacto)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: slide.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: slide.color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: slide.color,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      slide.mentalShift,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: slide.color,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Espacio adicional al final para asegurar que el contenido sea scrolleable
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class OnboardingSlide {
  final String title;
  final String description;
  final String mentalShift;
  final IconData icon;
  final Color color;

  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.mentalShift,
    required this.icon,
    required this.color,
  });
}
