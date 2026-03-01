import '../../models/user_progress.dart';
import '../user_progress_service.dart';
import '../auth_service_simple.dart';

/// Maneja los registros de uso y hábitos del usuario.
class HabitTracker {
  static final HabitTracker _instance = HabitTracker._internal();
  factory HabitTracker() => _instance;
  HabitTracker._internal();

  final UserProgressService _progressService = UserProgressService();
  final AuthServiceSimple _authService = AuthServiceSimple();

  /// Registrar una sesión del usuario
  Future<void> registrarSesion({
    String sessionType = 'general',
    String? codeId,
    String? codeName,
    int durationMinutes = 0,
    String? category,
  }) async {
    if (!_authService.isLoggedIn) {
      print('⚠️ Usuario no autenticado, sesión no registrada');
      return;
    }

    try {
      await _progressService.recordSession(
        sessionType: sessionType,
        codeId: codeId,
        codeName: codeName,
        durationMinutes: durationMinutes,
        category: category,
      );

      // Actualizar días consecutivos
      await _updateConsecutiveDays();
      
      print('✅ Sesión registrada: $sessionType');
    } catch (e) {
      print('Error registrando sesión: $e');
    }
  }

  /// Obtener progreso del usuario
  Future<UserProgress> obtenerProgreso() async {
    if (!_authService.isLoggedIn) {
      return UserProgress(0, 0);
    }

    try {
      final progress = await _progressService.getUserProgress();
      if (progress == null) {
        return UserProgress(0, 0);
      }

      final diasConsecutivos = progress['consecutive_days'] ?? 0;
      final totalSesiones = progress['total_sessions'] ?? 0;
      
      return UserProgress(diasConsecutivos, totalSesiones);
    } catch (e) {
      print('Error obteniendo progreso: $e');
      return UserProgress(0, 0);
    }
  }

  /// Actualizar días consecutivos
  Future<void> _updateConsecutiveDays() async {
    try {
      final progress = await _progressService.getUserProgress();
      if (progress == null) return;

      final lastSessionDate = progress['last_session_date'];
      final currentConsecutiveDays = progress['consecutive_days'] ?? 0;
      
      int newConsecutiveDays = 0;
      
      if (lastSessionDate != null) {
        final lastSession = DateTime.parse(lastSessionDate);
        final now = DateTime.now();
        final difference = now.difference(lastSession).inDays;
        
        if (difference == 0) {
          // Mismo día, mantener racha
          newConsecutiveDays = currentConsecutiveDays;
        } else if (difference == 1) {
          // Día siguiente, incrementar racha
          newConsecutiveDays = currentConsecutiveDays + 1;
        } else {
          // Más de un día de diferencia, reiniciar racha
          newConsecutiveDays = 1;
        }
      } else {
        // Primera sesión
        newConsecutiveDays = 1;
      }

      await _progressService.updateUserProgress(
        diasConsecutivos: newConsecutiveDays,
      );

      // Actualizar racha más larga si es necesario
      // NOTA: UserProgressService actualmente no soporta longest_streak en su método update
      // pero se mantiene la lógica aquí por si se extiende en el futuro.
    } catch (e) {
      print('Error actualizando días consecutivos: $e');
    }
  }

  /// Resetear progreso del usuario
  Future<void> resetearProgreso() async {
    if (!_authService.isLoggedIn) return;

    try {
      await _progressService.updateUserProgress(
        diasConsecutivos: 0,
        totalPilotajes: 0,
        energyLevel: 1,
      );
      
      print('✅ Progreso del usuario reseteado');
    } catch (e) {
      print('Error reseteando progreso: $e');
    }
  }

  /// Obtener días consecutivos
  Future<int> obtenerDiasConsecutivos() async {
    if (!_authService.isLoggedIn) return 0;

    try {
      final progress = await _progressService.getUserProgress();
      return progress?['consecutive_days'] ?? 0;
    } catch (e) {
      print('Error obteniendo días consecutivos: $e');
      return 0;
    }
  }

  /// Obtener total de sesiones
  Future<int> obtenerTotalSesiones() async {
    if (!_authService.isLoggedIn) return 0;

    try {
      final progress = await _progressService.getUserProgress();
      return progress?['total_sessions'] ?? 0;
    } catch (e) {
      print('Error obteniendo total de sesiones: $e');
      return 0;
    }
  }

  /// Obtener estadísticas completas
  Future<Map<String, dynamic>> obtenerEstadisticas() async {
    if (!_authService.isLoggedIn) {
      return {
        'dias_consecutivos': 0,
        'total_sesiones': 0,
        'total_tiempo_pilotaje': 0,
        'total_tiempo_meditacion': 0,
        'nivel_energetico': 50,
        'racha_actual': 0,
        'racha_mas_larga': 0,
      };
    }

    try {
      final progress = await _progressService.getUserProgress();
      if (progress == null) {
        return {
          'dias_consecutivos': 0,
          'total_sesiones': 0,
          'total_tiempo_pilotaje': 0,
          'total_tiempo_meditacion': 0,
          'nivel_energetico': 50,
          'racha_actual': 0,
          'racha_mas_larga': 0,
        };
      }

      return {
        'dias_consecutivos': progress['consecutive_days'] ?? 0,
        'total_sesiones': progress['total_sessions'] ?? 0,
        'total_tiempo_pilotaje': progress['total_pilotage_time'] ?? 0,
        'total_tiempo_meditacion': progress['total_meditation_time'] ?? 0,
        'nivel_energetico': progress['energy_level'] ?? 50,
        'racha_actual': progress['current_streak'] ?? 0,
        'racha_mas_larga': progress['longest_streak'] ?? 0,
      };
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return {
        'dias_consecutivos': 0,
        'total_sesiones': 0,
        'total_tiempo_pilotaje': 0,
        'total_tiempo_meditacion': 0,
        'nivel_energetico': 50,
        'racha_actual': 0,
        'racha_mas_larga': 0,
      };
    }
  }
}