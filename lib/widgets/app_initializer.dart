import 'package:flutter/material.dart';
import '../services/onboarding_service.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../main.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  void _checkOnboardingStatus() {
    // Resetear el estado del onboarding al iniciar la app
    OnboardingService.resetOnboarding();
    
    // Verificar si el usuario ya saltó el onboarding en esta sesión
    final isSkipped = OnboardingService.isOnboardingSkipped();
    
    setState(() {
      _showOnboarding = !isSkipped;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B132B),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
          ),
        ),
      );
    }

    if (_showOnboarding) {
      return const OnboardingScreen();
    }

    return const MainNavigation();
  }
}
