import 'package:shared_preferences/shared_preferences.dart';

/// Servicio simple para manejar el estado del tour usando showcaseview
class ShowcaseTourService {
  static const String _keyTourCompleted = 'showcase_tour_completed';
  
  /// Verifica si el tour ya fue completado
  static Future<bool> isTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTourCompleted) ?? false;
  }
  
  /// Marca el tour como completado
  static Future<void> markTourAsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTourCompleted, true);
  }
  
  /// Reinicia el tour (para poder volver a verlo)
  static Future<void> resetTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTourCompleted, false);
  }
}

