import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../services/onboarding_service.dart';
import 'static_screens/static_home_screen.dart';
import 'static_screens/static_search_screen.dart';
import 'static_screens/static_challenge_screen.dart';
import 'static_screens/static_evolution_screen.dart';
import '../home/home_screen.dart';

class AppTourScreen extends StatefulWidget {
  const AppTourScreen({super.key});

  @override
  State<AppTourScreen> createState() => _AppTourScreenState();
}

class _AppTourScreenState extends State<AppTourScreen> {
  final PageController _controller = PageController();
  final OnboardingService _onboardingService = OnboardingService();
  int _currentPage = 0;
  bool _isLastPage = false;

  final List<Widget> _pages = [
    const StaticHomeScreen(),
    const StaticSearchScreen(),
    const StaticChallengeScreen(),
    const StaticEvolutionScreen(),
  ];

  final List<Map<String, String>> _tourData = [
    {
      'title': 'Bienvenido al Portal',
      'description': 'Tu espacio cuántico para la transformación personal a través de los códigos de Grabovoi.',
    },
    {
      'title': 'Encuentra tu Código',
      'description': 'Explora nuestra biblioteca de códigos para salud, abundancia, amor y protección.',
    },
    {
      'title': 'Desafíos Vibracionales',
      'description': 'Participa en desafíos guiados de 7, 14 o 21 días para crear hábitos poderosos.',
    },
    {
      'title': 'Sigue tu Evolución',
      'description': 'Visualiza tu progreso, mantén tu racha y desbloquea logros en tu camino.',
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finishTour() async {
    await _onboardingService.markOnboardingAsSeen();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo de pantallas estáticas
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
                _isLastPage = index == _pages.length - 1;
              });
            },
            children: _pages,
          ),

          // Capa oscura para resaltar el texto
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
                stops: const [0.0, 0.5, 0.8],
              ),
            ),
          ),

          // Contenido del Tour (Texto y Botones)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _tourData[_currentPage]['title']!,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFD700),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _tourData[_currentPage]['description']!,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Indicador de páginas
                  SmoothPageIndicator(
                    controller: _controller,
                    count: _pages.length,
                    effect: const ExpandingDotsEffect(
                      activeDotColor: Color(0xFFFFD700),
                      dotColor: Colors.white24,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 4,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Botones de Navegación
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botón Saltar
                      TextButton(
                        onPressed: _finishTour,
                        child: Text(
                          'Saltar',
                          style: GoogleFonts.lato(
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      
                      // Botón Siguiente / Empezar
                      ElevatedButton(
                        onPressed: () {
                          if (_isLastPage) {
                            _finishTour();
                          } else {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        child: Text(
                          _isLastPage ? 'Comenzar' : 'Siguiente',
                          style: GoogleFonts.lato(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
