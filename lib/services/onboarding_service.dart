import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingService {
  static const String _onboardingSeenKey = 'has_seen_onboarding_v2';

  // Verificar si el usuario ya vio el onboarding
  // Ahora es específico por usuario usando el user_id
  Future<bool> hasSeenOnboarding() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        // Si no hay sesión, asumir que no ha visto el tour
        return false;
      }
      
      final userId = session.user.id;
      final prefs = await SharedPreferences.getInstance();
      final key = '${_onboardingSeenKey}_$userId';
      return prefs.getBool(key) ?? false;
    } catch (e) {
      print('⚠️ Error verificando onboarding: $e');
      return false; // Por defecto, mostrar tour si hay error
    }
  }

  // Marcar el onboarding como visto
  // Ahora es específico por usuario usando el user_id
  Future<void> markOnboardingAsSeen() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return;
      
      final userId = session.user.id;
      final prefs = await SharedPreferences.getInstance();
      final key = '${_onboardingSeenKey}_$userId';
      await prefs.setBool(key, true);
    } catch (e) {
      print('⚠️ Error marcando onboarding como visto: $e');
    }
  }
  
  // Resetear onboarding (para pruebas)
  Future<void> resetOnboarding() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return;
      
      final userId = session.user.id;
      final prefs = await SharedPreferences.getInstance();
      final key = '${_onboardingSeenKey}_$userId';
      await prefs.remove(key);
    } catch (e) {
      print('⚠️ Error reseteando onboarding: $e');
    }
  }
}
