import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_progress.dart';

/// Maneja los registros de uso y hábitos del usuario.
class HabitTracker {
  Future<void> registrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final hoy = DateTime.now().toIso8601String();
    prefs.setString('ultimaSesion', hoy);

    int sesiones = prefs.getInt('totalSesiones') ?? 0;
    prefs.setInt('totalSesiones', sesiones + 1);
  }

  Future<UserProgress> obtenerProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    int sesiones = prefs.getInt('totalSesiones') ?? 0;
    String? ultimaSesion = prefs.getString('ultimaSesion');
    int diasConsecutivos = _calcularConsecutivos(ultimaSesion);
    return UserProgress(diasConsecutivos, sesiones);
  }

  Future<void> resetearProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ultimaSesion');
    await prefs.remove('totalSesiones');
  }

  int _calcularConsecutivos(String? ultimaSesion) {
    if (ultimaSesion == null) return 0;
    final ultima = DateTime.parse(ultimaSesion);
    final diferencia = DateTime.now().difference(ultima).inDays;
    if (diferencia == 0) return 1;
    if (diferencia == 1) return 2; // Asume que si la última sesión fue ayer, son 2 días consecutivos.
    return 0; // Si hay un salto, se reinicia.
  }
}