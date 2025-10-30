import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'challenge_tracking_service.dart';
import '../models/challenge_model.dart';

class ChallengeProgressTracker extends ChangeNotifier {
  static final ChallengeProgressTracker _instance = ChallengeProgressTracker._internal();
  factory ChallengeProgressTracker() => _instance;
  ChallengeProgressTracker._internal();

  final ChallengeTrackingService _trackingService = ChallengeTrackingService();
  
  // Mapas para rastrear el progreso diario
  Map<String, Map<String, bool>> _dailyProgress = {};
  Map<String, Map<String, int>> _dailyCounts = {};
  
  // Timers para rastrear tiempo en la app
  Timer? _appUsageTimer;
  DateTime? _appStartTime;
  int _totalAppUsageSeconds = 0;

  // Contadores de acciones
  int _codesRepeatedToday = 0;
  int _codesPilotedToday = 0;
  int _meditationMinutesToday = 0;

  // Inicializar el tracker
  Future<void> initialize() async {
    await _loadProgressFromStorage();
    _startAppUsageTracking();
  }

  // Rastrear cuando el usuario repite un código
  void trackCodeRepeated() {
    _codesRepeatedToday++;
    _updateDailyProgress('codes_repeated', _codesRepeatedToday);
    
    // Registrar en el sistema de tracking existente
    _trackingService.recordUserAction(
      type: ActionType.codigoRepetido,
      metadata: {'count': _codesRepeatedToday},
    );
    
    _saveProgressToStorage();
    notifyListeners();
    print('✅ trackCodeRepeated: $_codesRepeatedToday códigos repetidos hoy');
  }

  // Rastrear cuando el usuario pilota un código
  void trackCodePiloted() {
    _codesPilotedToday++;
    _updateDailyProgress('codes_piloted', _codesPilotedToday);
    
    // Registrar en el sistema de tracking existente
    _trackingService.recordUserAction(
      type: ActionType.sesionPilotaje,
      metadata: {'count': _codesPilotedToday},
    );
    
    _saveProgressToStorage();
  }

  // Rastrear tiempo de meditación (tiempo en la app)
  void trackMeditationTime(int minutes) {
    _meditationMinutesToday += minutes;
    _updateDailyProgress('meditation_minutes', _meditationMinutesToday);
    
    // Registrar en el sistema de tracking existente
    _trackingService.recordUserAction(
      type: ActionType.meditacionCompletada,
      duration: Duration(minutes: minutes),
      metadata: {'total_minutes': _meditationMinutesToday},
    );
    
    _saveProgressToStorage();
  }

  // Rastrear tiempo total de uso de la app
  void trackAppUsage(int seconds) {
    _totalAppUsageSeconds += seconds;
    _updateDailyProgress('app_usage_seconds', _totalAppUsageSeconds);
    
    // Registrar en el sistema de tracking existente
    _trackingService.recordUserAction(
      type: ActionType.tiempoEnApp,
      duration: Duration(seconds: seconds),
      metadata: {'total_seconds': _totalAppUsageSeconds},
    );
    
    _saveProgressToStorage();
  }

  // Verificar si una acción específica está completada
  bool isActionCompleted(String action, int requiredAmount) {
    final today = _getTodayKey();
    final counts = _dailyCounts[today] ?? {};
    
    print('🔍 isActionCompleted - action: $action');
    print('🔍 _dailyCounts keys: ${_dailyCounts.keys}');
    print('🔍 today: $today, counts: $counts');
    print('🔍 codesRepeatedToday: $_codesRepeatedToday');
    
    switch (action) {
      case '🔄 Repetir al menos 1 código':
        return (counts['codes_repeated'] ?? 0) >= 1;
      case '🔄 Repetir 2 códigos diferentes':
        return (counts['codes_repeated'] ?? 0) >= 2;
      case '🔄 Repetir 3 códigos diferentes':
        return (counts['codes_repeated'] ?? 0) >= 3;
      case '🔄 Repetir 5 códigos diferentes':
        return (counts['codes_repeated'] ?? 0) >= 5;
      case '🚀 Pilotar 1 código':
        return (counts['codes_piloted'] ?? 0) >= 1;
      case '🚀 Pilotar 2 códigos':
        return (counts['codes_piloted'] ?? 0) >= 2;
      case '🚀 Pilotar 3 códigos':
        return (counts['codes_piloted'] ?? 0) >= 3;
      case '🧘 Meditar 10 minutos':
        return (counts['meditation_minutes'] ?? 0) >= 10;
      case '🧘 Meditar 15 minutos':
        return (counts['meditation_minutes'] ?? 0) >= 15;
      case '🧘 Meditar 20 minutos':
        return (counts['meditation_minutes'] ?? 0) >= 20;
      case '🧘 Meditar 30 minutos':
        return (counts['meditation_minutes'] ?? 0) >= 30;
      case '⏱️ Usar la app 15 minutos':
        return (counts['app_usage_seconds'] ?? 0) >= (15 * 60);
      case '⏱️ Usar la app 20 minutos':
        return (counts['app_usage_seconds'] ?? 0) >= (20 * 60);
      case '⏱️ Usar la app 30 minutos':
        return (counts['app_usage_seconds'] ?? 0) >= (30 * 60);
      case '⏱️ Usar la app 45 minutos':
        return (counts['app_usage_seconds'] ?? 0) >= (45 * 60);
      default:
        return false;
    }
  }

  // Obtener el progreso actual de una acción
  int getActionProgress(String action) {
    final today = _getTodayKey();
    final counts = _dailyCounts[today] ?? {};
    
    if (action.contains('🔄')) {
      return counts['codes_repeated'] ?? 0;
    } else if (action.contains('🚀')) {
      return counts['codes_piloted'] ?? 0;
    } else if (action.contains('🧘')) {
      return counts['meditation_minutes'] ?? 0;
    } else if (action.contains('⏱️')) {
      return (counts['app_usage_seconds'] ?? 0) ~/ 60; // Convertir a minutos
    }
    return 0;
  }

  // Obtener el requerimiento de una acción
  int getActionRequirement(String action) {
    if (action.contains('🔄')) {
      if (action.contains('1 código')) return 1;
      if (action.contains('2 códigos')) return 2;
      if (action.contains('3 códigos')) return 3;
      if (action.contains('5 códigos')) return 5;
    } else if (action.contains('🚀')) {
      if (action.contains('1 código')) return 1;
      if (action.contains('2 códigos')) return 2;
      if (action.contains('3 códigos')) return 3;
    } else if (action.contains('🧘')) {
      if (action.contains('10 minutos')) return 10;
      if (action.contains('15 minutos')) return 15;
      if (action.contains('20 minutos')) return 20;
      if (action.contains('30 minutos')) return 30;
    } else if (action.contains('⏱️')) {
      if (action.contains('15 minutos')) return 15;
      if (action.contains('20 minutos')) return 20;
      if (action.contains('30 minutos')) return 30;
      if (action.contains('45 minutos')) return 45;
    }
    return 0;
  }

  // Actualizar el progreso diario
  void _updateDailyProgress(String actionType, int count) {
    final today = _getTodayKey();
    _dailyCounts[today] ??= {};
    _dailyCounts[today]![actionType] = count;
    print('✅ _updateDailyProgress: $actionType = $count (today: $today)');
    print('✅ _dailyCounts: $_dailyCounts');
  }

  // Iniciar el seguimiento del tiempo de uso de la app
  void _startAppUsageTracking() {
    _appStartTime = DateTime.now();
    _appUsageTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_appStartTime != null) {
        final elapsed = DateTime.now().difference(_appStartTime!).inSeconds;
        trackAppUsage(elapsed);
        _appStartTime = DateTime.now(); // Reset para el siguiente período
      }
    });
  }

  // Detener el seguimiento del tiempo de uso de la app
  void stopAppUsageTracking() {
    _appUsageTimer?.cancel();
    _appUsageTimer = null;
    _appStartTime = null;
  }

  // Obtener la clave del día actual
  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Guardar progreso en almacenamiento local
  Future<void> _saveProgressToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayKey();
    
    // Guardar conteos del día usando jsonEncode
    try {
      final countsJson = _dailyCounts[today]?.map((key, value) => MapEntry(key, value));
      if (countsJson != null && countsJson.isNotEmpty) {
        await prefs.setString('challenge_counts_$today', countsJson.toString());
        print('💾 Guardado en storage: $countsJson');
      }
    } catch (e) {
      print('❌ Error guardando en storage: $e');
    }
  }

  // Cargar progreso desde almacenamiento local
  Future<void> _loadProgressFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayKey();
    
    // Cargar conteos del día
    final countsString = prefs.getString('challenge_counts_$today');
    if (countsString != null) {
      // Parsear el string de vuelta a Map
      try {
        // Parsear formato: {codes_repeated: 1, app_usage_seconds: 200}
        final cleanString = countsString.replaceAll('{', '').replaceAll('}', '');
        final entries = cleanString.split(',');
        _dailyCounts[today] = {};
        for (var entry in entries) {
          final parts = entry.split(':');
          if (parts.length == 2) {
            final key = parts[0].trim();
            final value = int.tryParse(parts[1].trim());
            if (value != null) {
              _dailyCounts[today]![key] = value;
            }
          }
        }
        print('✅ Cargado desde storage: $_dailyCounts');
      } catch (e) {
        print('❌ Error parseando storage: $e');
        _dailyCounts[today] = {};
      }
    } else {
      _dailyCounts[today] = {};
    }
  }

  // Resetear progreso diario (llamar al inicio de cada día)
  Future<void> resetDailyProgress() async {
    final today = _getTodayKey();
    _dailyCounts[today] = {};
    _codesRepeatedToday = 0;
    _codesPilotedToday = 0;
    _meditationMinutesToday = 0;
    _totalAppUsageSeconds = 0;
    await _saveProgressToStorage();
  }

  // Limpiar recursos
  void dispose() {
    stopAppUsageTracking();
  }
}
