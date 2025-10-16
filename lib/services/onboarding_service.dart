import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _onboardingKey = 'onboarding_completed';
  
  /// Verifica si el usuario ya completó el onboarding
  static Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingKey) ?? false;
    } catch (e) {
      // En caso de error, asumimos que no se completó
      return false;
    }
  }
  
  /// Marca el onboarding como completado
  static Future<void> markOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);
    } catch (e) {
      // Error al guardar, pero no es crítico
      print('Error al marcar onboarding como completado: $e');
    }
  }
  
  /// Resetea el estado del onboarding (útil para testing)
  static Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingKey);
    } catch (e) {
      print('Error al resetear onboarding: $e');
    }
  }
}
