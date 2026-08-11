import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service_simple.dart';
import '../services/user_progress_service.dart';
import '../services/subscription_service.dart';
import '../services/onboarding_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/user_assessment_screen.dart';
import '../main.dart';
import 'permissions_request_modal.dart';
import 'timezone_confirm_modal.dart';
import '../services/app_update_dialog.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthServiceSimple _authService = AuthServiceSimple();
  final UserProgressService _progressService = UserProgressService();
  final OnboardingService _onboardingService = OnboardingService();

  StreamSubscription<AuthState>? _authSubscription;
  bool _isCheckingAuth = false;

  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _needsAssessment = false;
  bool _needsTour = false;
  bool _forceLogin = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();

    // Escuchar cambios de autenticación (para OAuth/Google)
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn && mounted) {
        // Verificar si estamos en modo recuperación - NO redirigir en ese caso
        final prefs = await SharedPreferences.getInstance();
        final isRecoveryMode = prefs.getBool('is_recovery_mode') ?? false;

        if (isRecoveryMode) {
          debugPrint('🚩 Modo recuperación activo - ignorando evento de autenticación para evitar redirección al tour');
          return;
        }

        debugPrint('🔄 Cambio de autenticación detectado (OAuth/Google), verificando estado...');
        _checkAuthStatus();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Solo verificar una vez después del primer mount para actualizar el estado
    // después de navegaciones desde login
    if (!_isLoading && !_isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _checkAuthStatus();
        }
      });
    }
  }

  Future<void> _checkAuthStatus() async {
    if (_isCheckingAuth) return;
    _isCheckingAuth = true;
    try {
      await _authService.initialize();
      // TEMPORAL: Resetear onboarding para que el usuario pueda ver el tour
      // await _onboardingService.resetOnboarding(); // Comentado para no mostrar tour siempre
      
      final isAuth = await _authService.checkAuthStatus();
      
      debugPrint('🔐 Estado de autenticación: $isAuth');
        final prefs = await SharedPreferences.getInstance();
        _forceLogin = prefs.getBool('force_login') ?? false;
      
      if (isAuth) {
        // Verificar si el usuario ya completó la evaluación
        final assessment = await _progressService.getUserAssessment();
        
        debugPrint('📋 Usuario autenticado');
        debugPrint('📋 Assessment data: $assessment');
        
        // Verificar si la evaluación está completa
        final needsAssessment = assessment == null || !_isAssessmentComplete(assessment);
        
        // Verificar si necesita ver el tour
        final hasSeenTour = await _onboardingService.hasSeenOnboarding();
        final needsTour = !hasSeenTour;
        
        debugPrint('📋 Necesita evaluación: $needsAssessment');
        debugPrint('📋 Necesita tour: $needsTour');
        
        // IMPORTANTE: Verificar estado de suscripción después de autenticación
        // Esto asegura que usuarios nuevos obtengan su período de prueba de 7 días
        try {
          await SubscriptionService().checkSubscriptionStatus();
          debugPrint('✅ Estado de suscripción verificado después de autenticación');
        } catch (e) {
          debugPrint('⚠️ Error verificando suscripción después de autenticación: $e');
        }

        // Verificar si hay nueva versión disponible (no bloqueante — se muestra en background)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                AppUpdateDialog.checkAndShow(context);
              }
            });
          }
        });
        
        if (mounted) {
          setState(() {
            if (_forceLogin) {
              _isAuthenticated = false;
              _needsAssessment = false;
              _needsTour = false;
            } else {
              _isAuthenticated = true;
              _needsAssessment = needsAssessment;
              _needsTour = needsTour;
            }
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isAuthenticated = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error verificando estado de autenticación: $e');
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
    } finally {
      _isCheckingAuth = false;
    }
  }


  /// Verificar si la evaluación está completa y válida
  bool _isAssessmentComplete(Map<String, dynamic> assessment) {
    // Verificar primero el flag is_complete (prioritario)
    if (assessment['is_complete'] == true) {
      debugPrint('✅ Evaluación marcada como completa');
      return true;
    }
    
    // Si no tiene el flag, verificar que todos los campos requeridos estén presentes
    final requiredFields = [
      'knowledge_level',
      'goals',
      'experience_level', 
      'time_available',
      'preferences',
      'motivation'
    ];
    
    for (final field in requiredFields) {
      if (!assessment.containsKey(field) || assessment[field] == null) {
        debugPrint('❌ Campo faltante en evaluación: $field');
        return false;
      }
      
      // Verificar que los campos de lista no estén vacíos
      if (field == 'goals' || field == 'preferences') {
        final value = assessment[field];
        if (value is! List || value.isEmpty) {
          debugPrint('❌ Lista vacía en evaluación: $field');
          return false;
        }
      }
      
      // Verificar que los campos de string no estén vacíos
      if (field == 'knowledge_level' || field == 'experience_level' || 
          field == 'time_available' || field == 'motivation') {
        final value = assessment[field];
        if (value is! String || value.isEmpty) {
          debugPrint('❌ String vacío en evaluación: $field');
          return false;
        }
      }
    }
    
    debugPrint('✅ Evaluación completa y válida');
    return true;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️ AuthWrapper build - isLoading: $_isLoading, isAuthenticated: $_isAuthenticated, needsAssessment: $_needsAssessment, needsTour: $_needsTour');
    
    if (_isLoading) {
      debugPrint('⏳ Mostrando loading...');
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFFFFD700),
                strokeWidth: 3,
              ),
              SizedBox(height: 24),
              Text(
                'Cargando...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // NUEVO FLUJO: Tour primero, luego evaluación, luego WelcomeModal y MuralModal
    // 1. Si necesita tour, mostrar MainNavigation con tour
    // 2. Después del tour, mostrar evaluación si es necesaria
    // 3. Después de evaluación, mostrar WelcomeModal y MuralModal
    if (_isAuthenticated && _needsTour) {
      // Mostrar tour primero
      debugPrint('✨ Mostrando MainNavigation con tour');
      return MainNavigation(
        showTour: true,
        onTourFinished: () {
          // Después del tour, verificar si necesita evaluación
          _checkAuthStatus();
        },
      );
    } else if (_isAuthenticated && _needsAssessment) {
      // Después del tour, mostrar evaluación si es necesaria
      debugPrint('📋 Mostrando UserAssessmentScreen - Evaluación necesaria (después del tour)');
      
      // Mostrar modal de permisos después de la evaluación
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Esperar un poco para que la evaluación se muestre primero
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _showPermissionsModalIfNeeded();
            }
          });
        }
      });
      
      return const UserAssessmentScreen();
    } else if (_isAuthenticated && !_needsAssessment) {
      // Usuario autenticado sin tour ni evaluación pendiente
      // Mostrar MainNavigation y activar WelcomeModal/MuralModal
      debugPrint('✅ Usuario autenticado - Mostrando MainNavigation (sin tour, sin evaluación)');
      
      // Mostrar modal de permisos después de que se construya la pantalla
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showPermissionsModalIfNeeded();
        }
      });
      
      return const MainNavigation(showTour: false);
    } else if (_forceLogin) {
        // Forzar pantalla de login después de registro
        return const LoginScreen();
      } else {
        // Mostrar onboarding comercial antes del login cada vez que esté desautenticado
        debugPrint('❌ Mostrando Onboarding antes de Login - Usuario no autenticado');
        return const OnboardingScreen();
      }
  }

  /// Mostrar modal de permisos si es necesario
  Future<void> _showPermissionsModalIfNeeded() async {
    try {
      final shouldShow = await PermissionsRequestModal.shouldShowModal();
      if (shouldShow && mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const PermissionsRequestModal(),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error mostrando modal de permisos: $e');
    }

    await _showTimezoneConfirmIfNeeded();
  }

  /// Mostrar el modal de zona horaria (una sola vez, mientras
  /// user_metadata.timezone no exista) después de permisos, para no
  /// apilar diálogos al mismo tiempo.
  Future<void> _showTimezoneConfirmIfNeeded() async {
    try {
      final shouldShow = await TimezoneConfirmModal.shouldShow();
      if (shouldShow && mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const TimezoneConfirmModal(),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error mostrando modal de zona horaria: $e');
    }
  }
}
