import 'package:flutter/material.dart';
import '../services/auth_service_simple.dart';
import '../services/user_progress_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/user_assessment_screen.dart';
import '../main.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthServiceSimple _authService = AuthServiceSimple();
  final UserProgressService _progressService = UserProgressService();
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _needsAssessment = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
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
    try {
      await _authService.initialize();
      final isAuth = await _authService.checkAuthStatus();
      
      print('🔐 Estado de autenticación: $isAuth');
      
      if (isAuth) {
        // Verificar si el usuario ya completó la evaluación
        final assessment = await _progressService.getUserAssessment();
        
        print('📋 Usuario autenticado');
        print('📋 Assessment data: $assessment');
        
        // Verificar si la evaluación está completa
        final needsAssessment = assessment == null || !_isAssessmentComplete(assessment);
        
        print('📋 Necesita evaluación: $needsAssessment');
        
        if (mounted) {
          setState(() {
            _isAuthenticated = true;
            _needsAssessment = needsAssessment;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isAuthenticated = false;
            _needsAssessment = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error verificando autenticación: $e');
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _needsAssessment = false;
          _isLoading = false;
        });
      }
    }
  }


  /// Verificar si la evaluación está completa y válida
  bool _isAssessmentComplete(Map<String, dynamic> assessment) {
    // Verificar primero el flag is_complete (prioritario)
    if (assessment['is_complete'] == true) {
      print('✅ Evaluación marcada como completa');
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
        print('❌ Campo faltante en evaluación: $field');
        return false;
      }
      
      // Verificar que los campos de lista no estén vacíos
      if (field == 'goals' || field == 'preferences') {
        final value = assessment[field];
        if (value is! List || value.isEmpty) {
          print('❌ Lista vacía en evaluación: $field');
          return false;
        }
      }
      
      // Verificar que los campos de string no estén vacíos
      if (field == 'knowledge_level' || field == 'experience_level' || 
          field == 'time_available' || field == 'motivation') {
        final value = assessment[field];
        if (value is! String || value.isEmpty) {
          print('❌ String vacío en evaluación: $field');
          return false;
        }
      }
    }
    
    print('✅ Evaluación completa y válida');
    return true;
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ AuthWrapper build - isLoading: $_isLoading, isAuthenticated: $_isAuthenticated, needsAssessment: $_needsAssessment');
    
    if (_isLoading) {
      print('⏳ Mostrando loading...');
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

    // Mostrar evaluación solo si es necesaria
    if (_isAuthenticated && _needsAssessment) {
      print('📋 Mostrando UserAssessmentScreen - Evaluación necesaria');
      return const UserAssessmentScreen();
    } else if (_isAuthenticated && !_needsAssessment) {
      print('✅ Usuario autenticado con evaluación completa - Mostrando MainNavigation');
      return const MainNavigation();
    } else {
      // Mostrar onboarding comercial antes del login cada vez que esté desautenticado
      print('❌ Mostrando Onboarding antes de Login - Usuario no autenticado');
      return const OnboardingScreen();
    }
  }
}
