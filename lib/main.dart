import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChrome, DeviceOrientation, SystemUiOverlayStyle, SystemUiMode;
import 'package:google_fonts/google_fonts.dart';
import 'config/supabase_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/migration_service.dart';
import 'services/app_time_tracker.dart';
import 'services/pilotage_state_service.dart';
import 'services/audio_service.dart';
import 'services/audio_manager_service.dart';
import 'services/notification_scheduler.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/onboarding/user_assessment_screen.dart';
import 'screens/onboarding/app_tour_screen.dart';
import 'screens/onboarding/static_screens/static_home_screen.dart';
import 'screens/onboarding/static_screens/static_search_screen.dart';
import 'screens/onboarding/static_screens/static_challenge_screen.dart';
import 'screens/onboarding/static_screens/static_evolution_screen.dart';
import 'services/onboarding_service.dart';
import 'services/user_progress_service.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'screens/home/home_screen.dart';
import 'widgets/auth_wrapper.dart';
import 'widgets/glow_background.dart';
import 'screens/biblioteca/static_biblioteca_screen.dart';
import 'screens/pilotaje/quantum_pilotage_screen.dart';
import 'screens/diario/diario_screen.dart';
import 'screens/desafios/desafios_screen.dart';
import 'screens/evolucion/evolucion_screen.dart';
import 'screens/auth/auth_callback_screen.dart';
import 'screens/auth/recovery_set_password_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'repositories/codigos_repository.dart';
import 'models/notification_history_item.dart';
import 'services/notification_count_service.dart';
import 'services/subscription_service.dart';
import 'widgets/subscription_required_modal.dart';
import 'services/auth_service_simple.dart';
import 'services/in_app_update_service.dart';
import 'screens/auth/auth_callback_screen.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cargar variables de entorno locales solo en no-web
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}
  }

  // Inicializar Supabase
  await SupabaseConfig.initialize();
  
  // Manejar deep links de OAuth (Google Sign In)
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final AuthChangeEvent event = data.event;
    final Session? session = data.session;
    
    if (event == AuthChangeEvent.signedIn && session != null) {
      print('✅ Usuario autenticado con OAuth (Google)');
      // El AuthWrapper se encargará de cargar el usuario y navegar
    }
  });
  
  // Inicializar rastreador de tiempo
  AppTimeTracker().startSession();
  
  // Inicializar códigos con caché local y actualización automática
  await CodigosRepository().initCodigos();
  
  // Inicializar notificaciones (solo en no-web)
  if (!kIsWeb) {
    try {
      await NotificationScheduler().initialize();
    } catch (e) {
      print('⚠️ Error inicializando NotificationScheduler: $e');
    }
  }
  
  // Inicializar servicio de suscripciones (solo en Android/iOS)
  if (!kIsWeb) {
    try {
      await SubscriptionService().initialize();
    } catch (e) {
      print('⚠️ Error inicializando SubscriptionService: $e');
    }
  }
  
  // Verificar actualizaciones in-app (solo en Android)
  // Se hace en segundo plano para no bloquear el inicio de la app
  if (!kIsWeb) {
    Future.delayed(const Duration(seconds: 2), () {
      try {
        InAppUpdateService().checkAndUpdate().catchError((e) {
          print('⚠️ Error verificando actualizaciones: $e');
        });
      } catch (e) {
        print('⚠️ Error inicializando InAppUpdateService: $e');
      }
    });
  }
  
  // Configurar orientación
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Configurar pantalla completa inmersiva
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
      ),
      child: MaterialApp(
        title: 'ManiGrab - Manifestaciones Cuánticas Grabovoi',
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
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
            ),
            child: child!,
          );
        },
        // Manejar rutas web para callbacks de autenticación y recovery
        onGenerateRoute: (settings) {
          // En web, capturar la ruta /auth/callback
          if (kIsWeb && settings.name == '/auth/callback') {
            return MaterialPageRoute(
              builder: (context) => const AuthCallbackScreen(),
              settings: settings,
            );
          }
          // En web, capturar la ruta /recovery para cambio de contraseña
          // IMPORTANTE: Verificar tanto el path como si la URL contiene /recovery
          final isRecoveryRoute = kIsWeb && (
            settings.name == '/recovery' || 
            settings.name?.startsWith('/recovery') == true ||
            (settings.name == null && Uri.base.path == '/recovery')
          );
          
          if (isRecoveryRoute) {
            final uri = Uri.base;
            
            String? accessToken;
            String? refreshToken;
            String? type;
            
            // PRIORIDAD 1: Los tokens vienen en el HASH (después de #)
            // Supabase redirige a: https://manigrab.app/recovery#access_token=...
            if (uri.hasFragment) {
              final fragment = uri.fragment;
              final hashParams = Uri.splitQueryString(fragment);
              accessToken = hashParams['access_token'];
              refreshToken = hashParams['refresh_token'];
              type = hashParams['type'];
              print('🔍 Recovery route - Tokens encontrados en HASH:');
            }
            
            // PRIORIDAD 2: Si no están en hash, intentar query params (por si acaso)
            if (accessToken == null) {
              accessToken = uri.queryParameters['access_token'];
              refreshToken = uri.queryParameters['refresh_token'];
              type = uri.queryParameters['type'];
              print('🔍 Recovery route - Tokens encontrados en QUERY PARAMS:');
            }
            
            print('   URL completa: ${uri.toString()}');
            print('   Path: ${uri.path}');
            print('   Fragment presente: ${uri.hasFragment}');
            if (uri.hasFragment) {
              print('   Fragment (primeros 100 chars): ${uri.fragment.substring(0, uri.fragment.length > 100 ? 100 : uri.fragment.length)}...');
            }
            print('   Access Token: ${accessToken != null ? "✅ presente (${accessToken.substring(0, 20)}...)" : "❌ ausente"}');
            print('   Refresh Token: ${refreshToken != null ? "✅ presente" : "❌ ausente"}');
            print('   Type: $type');
            
            return MaterialPageRoute(
              builder: (context) => RecoverySetPasswordScreen(
                accessToken: accessToken,
                refreshToken: refreshToken,
              ),
              settings: settings,
            );
          }
          // Para otras rutas, usar el comportamiento por defecto (home)
          return null;
        },
        // Verificar si estamos en /recovery al iniciar (para manejar hash en URL)
        home: kIsWeb && Uri.base.path == '/recovery' && Uri.base.hasFragment
          ? Builder(
              builder: (context) {
                final uri = Uri.base;
                String? accessToken;
                String? refreshToken;
                
                if (uri.hasFragment) {
                  final fragment = uri.fragment;
                  final hashParams = Uri.splitQueryString(fragment);
                  accessToken = hashParams['access_token'];
                  refreshToken = hashParams['refresh_token'];
                  print('🔍 Recovery detectado en home - Tokens en HASH');
                }
                
                if (accessToken != null) {
                  return RecoverySetPasswordScreen(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                  );
                }
                return const AuthWrapper();
              },
            )
          : const AuthWrapper(),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final bool showTour;
  final VoidCallback? onTourFinished; // Callback cuando el tour termina
  
  const MainNavigation({super.key, this.showTour = false, this.onTourFinished});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  late final List<Widget> _screens;
  final NotificationCountService _notificationCountService = NotificationCountService();
  bool _showTourOverlay = false;
  final GlobalKey _homeScreenKey = GlobalKey();
  final GlobalKey _diarioScreenKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(key: _homeScreenKey as Key?),
      const StaticBibliotecaScreen(),
      DiarioScreen(key: _diarioScreenKey), // Índice 2 - Diario (visualmente entre Biblioteca y Desafíos)
      const QuantumPilotageScreen(), // Índice 3 - Oculto en menú
      const DesafiosScreen(),
      const EvolucionScreen(),
      const ProfileScreen(),
    ];
    _notificationCountService.initialize();
    
    // Verificar si necesita mostrar el tour
    // Si showTour es false, verificar si el usuario nunca ha visto el tour
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        bool shouldShowTour = widget.showTour;
        
        // Si showTour es false, verificar si necesita tour
        if (!shouldShowTour) {
          final onboardingService = OnboardingService();
          final hasSeenTour = await onboardingService.hasSeenOnboarding();
          shouldShowTour = !hasSeenTour;
        }
        
        if (shouldShowTour) {
          setState(() {
            _showTourOverlay = true;
          });
        } else {
          // Si no hay tour, verificar WelcomeModal y MuralModal
          final homeState = _homeScreenKey.currentState;
          if (homeState != null) {
            try {
              (homeState as dynamic).triggerWelcomeAndMuralFlow();
            } catch (e) {
              print('⚠️ Error llamando triggerWelcomeAndMuralFlow: $e');
            }
          }
        }
      }
    });
  }
  
  @override
  void dispose() {
    // No cerramos el servicio aquí porque es un singleton compartido
    super.dispose();
  }

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _stopActivePilotage() {
    final audioService = AudioService();
    audioService.stopMusic();
    
    final audioManagerService = AudioManagerService();
    audioManagerService.stop();
    
    // Resetear estado del pilotaje
    final pilotageService = PilotageStateService();
    pilotageService.resetAllPilotageStates();
  }

  Future<bool?> _showPilotageActiveDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C2541),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFFFD700), width: 2),
          ),
          title: Row(
            children: [
              const Icon(Icons.music_off, color: Color(0xFFFFD700), size: 24),
              const SizedBox(width: 12),
              Text(
                'Pilotaje Activo',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que deseas abandonar el pilotaje cuántico y detener la música?',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancelar - no cambiar de tab
              },
              child: Text(
                'Cancelar',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Detener el pilotaje antes de cambiar de tab
                _stopActivePilotage();
                Navigator.of(context).pop(true); // Confirmar - cambiar de tab
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Sí, Abandonar',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  Future<void> _handleTabSelection(int index) async {
    final subscriptionService = SubscriptionService();
    
    // Verificar si el usuario es gratuito (sin suscripción después de los 7 días)
    final isFreeUser = subscriptionService.isFreeUser;
    
    // Permitir acceso a Inicio (index 0) y Perfil (index 6) siempre
    // Solo restringir otras pestañas para usuarios gratuitos
    if (isFreeUser && index != 0 && index != 6) {
      // Mostrar modal de suscripción requerida
      if (mounted) {
        SubscriptionRequiredModal.show(
          context,
          message: 'Esta función está disponible solo para usuarios Premium. Suscríbete para acceder a todas las funciones de la app.',
          onDismiss: () {
            // Mantener en la pantalla actual (Inicio) después de cerrar el modal
            setState(() {
              _currentIndex = 0; // Forzar volver a Inicio
            });
          },
        );
      }
      return;
    }
    
    // Interceptar cambio de tab si hay pilotaje activo
    // Nota: El pilotaje ahora está integrado en biblioteca (índice 1)
    if (_currentIndex == 1 && index != 1) { // Biblioteca ahora tiene el pilotaje
      final pilotageService = PilotageStateService();
      if (pilotageService.isAnyPilotageActive) {
        final result = await _showPilotageActiveDialog();
        if (result == false) {
          // Usuario canceló, no cambiar de tab
          return;
        }
      }
    }
    
    setState(() {
      _currentIndex = index;
    });
    
    // Recargar diario cuando se cambia a la pestaña del Diario
    if (index == 2) { // Diario está en índice 2
      final diarioState = _diarioScreenKey.currentState;
      if (diarioState != null) {
        try {
          (diarioState as dynamic).reloadDiario();
        } catch (e) {
          print('⚠️ Error recargando diario: $e');
        }
      }
    }
    
    // Actualizar conteo de notificaciones cuando se cambia a la pestaña de Perfil
    if (index == 6) { // Perfil ahora es índice 6
      _notificationCountService.updateCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        // Verificar si hay pilotaje activo
        final pilotageService = PilotageStateService();
        if (pilotageService.isAnyPilotageActive) {
          final result = await _showPilotageActiveDialog();
          if (result == true) {
            // Usuario confirmó, permitir pop
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          }
        } else {
          // No hay pilotaje activo, permitir pop
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Stack(
        children: [
          Scaffold(
            body: GlowBackground(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
            bottomNavigationBar: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.9, 1.05),
              ),
              child: Container(
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
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                        _buildNavItem(
                          icon: Icons.book,
                          label: 'Diario',
                          index: 2,
                        ),
                        // Cuántico oculto (índice 3) - funcionalidad preservada pero no visible en menú
                        // _buildNavItem(
                        //   icon: Icons.auto_awesome,
                        //   label: 'Cuántico',
                        //   index: 3,
                        //   isCenter: true,
                        // ),
                        _buildNavItem(
                          icon: Icons.emoji_events,
                          label: 'Desafíos',
                          index: 4,
                        ),
                        _buildNavItem(
                          icon: Icons.show_chart,
                          label: 'Evolución',
                          index: 5,
                        ),
                        _buildNavItem(
                          icon: Icons.person,
                          label: 'Perfil',
                          index: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Overlay del tour cuando es necesario
          if (_showTourOverlay)
            _TourOverlay(
              onFinish: () async {
                setState(() {
                  _showTourOverlay = false;
                });
                
                // Después del tour, verificar si necesita evaluación
                await Future.delayed(const Duration(milliseconds: 500));
                
                // Verificar si necesita evaluación
                final progressService = UserProgressService();
                final assessment = await progressService.getUserAssessment();
                final needsAssessment = assessment == null || 
                  !(assessment['is_complete'] == true || 
                    (assessment.containsKey('knowledge_level') && 
                     assessment.containsKey('goals') && 
                     assessment.containsKey('experience_level') && 
                     assessment.containsKey('time_available') && 
                     assessment.containsKey('preferences') && 
                     assessment.containsKey('motivation')));
                
                if (needsAssessment && mounted) {
                  // Navegar a UserAssessmentScreen
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const UserAssessmentScreen()),
                  );
                } else {
                  // Si no necesita evaluación, activar WelcomeModal y MuralModal
                  if (widget.onTourFinished != null) {
                    widget.onTourFinished!();
                  }
                  // También activar desde HomeScreen
                  final homeState = _homeScreenKey.currentState;
                  if (mounted && homeState != null) {
                    try {
                      (homeState as dynamic).triggerWelcomeAndMuralFlow();
                    } catch (e) {
                      print('⚠️ Error llamando triggerWelcomeAndMuralFlow: $e');
                    }
                  }
                }
              },
            ),
        ],
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
    final textScale = MediaQuery.of(context).textScaleFactor;
    final showLabel = textScale <= 1.15;
    final subscriptionService = SubscriptionService();
    
    return GestureDetector(
      onTap: () => _handleTabSelection(index),
      child: Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 600),
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: isSelected
                        ? const Color(0xFFFFD700)
                        : Colors.white.withOpacity(0.5),
                    size: 22, // Tamaño uniforme para todos los iconos
                  ),
                  // Burbuja de notificaciones solo para el icono de Perfil (index 6)
                  if (index == 6)
                    StreamBuilder<int>(
                      stream: _notificationCountService.countStream,
                      initialData: _notificationCountService.currentCount,
                      builder: (context, snapshot) {
                        final unreadCount = snapshot.data ?? 0;
                        if (unreadCount > 0) {
                          return Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF0B132B),
                                  width: 2,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                ],
              ),
              if (showLabel) ...[
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
            ],
          ),
        ),
      ),
    );
  }
}

// Widget para mostrar el tour como overlay sobre MainNavigation
class _TourOverlay extends StatefulWidget {
  final VoidCallback onFinish;
  
  const _TourOverlay({required this.onFinish});
  
  @override
  State<_TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<_TourOverlay> {
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
    widget.onFinish();
  }
  
  Widget _buildTourDescription(int pageIndex) {
    if (pageIndex == 0) {
      // Primera página con tarjetas profesionales para Luz Cuántica y Cristales
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Tu espacio cuántico para la transformación personal a través de los códigos de Grabovoi.',
            style: GoogleFonts.lato(
              fontSize: 16,
              color: Colors.white,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Tarjeta de Luz Cuántica
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFFFFD700),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Luz Cuántica',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Energía que acumulas con cada acción consciente. Crece con pilotajes, repeticiones y desafíos.',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Tarjeta de Cristales
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.diamond,
                    color: Color(0xFFFFD700),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cristales',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Recompensas que ganas al completar sesiones. Úsalos para desbloquear funciones especiales.',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // Otras páginas con descripción normal
      return Text(
        _tourData[pageIndex]['description']!,
        style: GoogleFonts.lato(
          fontSize: 16,
          color: Colors.white,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.95),
      child: Stack(
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

          // Capa sutil para mejorar contraste sin ocultar el contenido
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                ],
                stops: const [0.0, 0.4, 0.9],
              ),
            ),
          ),

          // Contenido del Tour (Texto y Botones) - Diseño profesional integrado
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.95),
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Título
                      Text(
                        _tourData[_currentPage]['title']!,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      // Descripción con contenido mejorado
                      Flexible(
                        child: SingleChildScrollView(
                          child: _buildTourDescription(_currentPage),
                        ),
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
                          spacing: 8,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Botón Siguiente / Comenzar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
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
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: const Color(0xFFFFD700).withOpacity(0.5),
                          ),
                          child: Text(
                            _isLastPage ? 'Comenzar' : 'Siguiente',
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
