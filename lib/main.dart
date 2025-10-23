import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChrome, DeviceOrientation, SystemUiOverlayStyle;
import 'package:google_fonts/google_fonts.dart';
import 'config/supabase_config.dart';
import 'services/migration_service.dart';
import 'services/app_time_tracker.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/onboarding/user_assessment_screen.dart';
import 'screens/home/home_screen.dart';
import 'widgets/auth_wrapper.dart';
import 'widgets/glow_background.dart';
import 'screens/biblioteca/static_biblioteca_screen.dart';
import 'screens/pilotaje/quantum_pilotage_screen.dart';
import 'screens/desafios/desafios_screen.dart';
import 'screens/evolucion/evolucion_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase
  await SupabaseConfig.initialize();
  
  // Inicializar rastreador de tiempo
  AppTimeTracker().startSession();
  
  // Configurar orientación
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Configurar barra de estado
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manifestación Numérica Grabovoi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700), // Dorado
          secondary: Color(0xFF1C2541), // Azul medio
          surface: Color(0xFF0B132B), // Azul profundo
          onPrimary: Color(0xFF0B132B),
          onSecondary: Color(0xFFFFD700),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B132B),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFD700),
          ),
          displayMedium: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(onNavigateToTab: _changeTab),
      const StaticBibliotecaScreen(),
      // const PilotajeScreen(), // Oculto según solicitud
      const QuantumPilotageScreen(),
      const DesafiosScreen(),
      const EvolucionScreen(),
      const ProfileScreen(),
    ];
  }

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B132B),
              Color(0xFF1C2541),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon: Icons.home_filled,
                  label: 'Inicio',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.menu_book,
                  label: 'Biblioteca',
                  index: 1,
                ),
                // _buildNavItem(
                //   icon: Icons.my_location,
                //   label: 'Pilotaje',
                //   index: 2,
                // ), // Oculto según solicitud
                _buildNavItem(
                  icon: Icons.auto_awesome,
                  label: 'Cuántico',
                  index: 2, // Ajustado de 3 a 2
                  isCenter: true,
                ),
                _buildNavItem(
                  icon: Icons.emoji_events,
                  label: 'Desafíos',
                  index: 3, // Ajustado de 4 a 3
                ),
                _buildNavItem(
                  icon: Icons.show_chart,
                  label: 'Evolución',
                  index: 4, // Ajustado de 5 a 4
                ),
                _buildNavItem(
                  icon: Icons.person,
                  label: 'Perfil',
                  index: 5, // Ajustado de 6 a 5
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    bool isCenter = false,
  }) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFD700).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFFFFD700)
                  : Colors.white.withOpacity(0.5),
              size: 22, // Tamaño uniforme para todos los iconos
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: isSelected
                    ? const Color(0xFFFFD700)
                    : Colors.white.withOpacity(0.5),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
