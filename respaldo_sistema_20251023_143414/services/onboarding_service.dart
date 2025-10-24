class OnboardingService {
  // Variable en memoria que se resetea cada vez que se cierra la app
  static bool _onboardingSkipped = false;
  
  /// Verifica si el usuario saltó el onboarding en esta sesión
  static bool isOnboardingSkipped() {
    return _onboardingSkipped;
  }
  
  /// Marca el onboarding como saltado (solo para esta sesión)
  static void markOnboardingSkipped() {
    _onboardingSkipped = true;
  }
  
  /// Resetea el estado del onboarding (se llama automáticamente al iniciar la app)
  static void resetOnboarding() {
    _onboardingSkipped = false;
  }
}
