import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Verificar si el usuario ya vio el onboarding
  Future<bool> hasSeenOnboarding() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final row = await _supabase
          .from('users')
          .select('onboarding_seen_at')
          .eq('id', user.id)
          .maybeSingle();

      final seenAt = row?['onboarding_seen_at'];
      return seenAt != null;
    } catch (e) {
      // Por compatibilidad, si la columna no existe o hay cualquier error,
      // por defecto mostrar tour (comportamiento anterior).
      // El fix definitivo requiere aplicar la migración SQL correspondiente.
      // ignore: avoid_print
      print('⚠️ Error verificando onboarding (DB): $e');
      return false; // Por defecto, mostrar tour si hay error
    }
  }

  // Marcar el onboarding como visto
  Future<void> markOnboardingAsSeen() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final now = DateTime.now().toIso8601String();
      await _supabase
          .from('users')
          .update({'onboarding_seen_at': now})
          .eq('id', user.id);
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ Error marcando onboarding como visto (DB): $e');
    }
  }
  
  // Resetear onboarding (para pruebas)
  Future<void> resetOnboarding() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('users')
          .update({'onboarding_seen_at': null})
          .eq('id', user.id);
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ Error reseteando onboarding (DB): $e');
    }
  }
}
