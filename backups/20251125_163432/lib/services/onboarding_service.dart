import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _onboardingSeenKey = 'has_seen_onboarding_v2';

  // Verificar si el usuario ya vio el onboarding
  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  // Marcar el onboarding como visto
  Future<void> markOnboardingAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }
  
  // Resetear onboarding (para pruebas)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingSeenKey);
  }
}
