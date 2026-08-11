import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service_simple.dart';
import 'challenge_tracking_service.dart';
import 'notification_service.dart';
import '../models/challenge_model.dart';
import '../models/notification_type.dart';

class ChallengeProgressTracker extends ChangeNotifier {
  static final ChallengeProgressTracker _instance = ChallengeProgressTracker._internal();
  factory ChallengeProgressTracker() => _instance;
  ChallengeProgressTracker._internal();

  final ChallengeTrackingService _trackingService = ChallengeTrackingService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthServiceSimple _authService = AuthServiceSimple();
  
  // Mapas para rastrear el progreso diario
  final Map<String, Map<String, bool>> _dailyProgress = {};
  final Map<String, Map<String, int>> _dailyCounts = {};
  
  // Timers para rastrear tiempo en la app
  Timer? _appUsageTimer;
  DateTime? _appStartTime;
  int _totalAppUsageSeconds = 0;

  // Contadores de acciones
  int _codesRepeatedToday = 0;
  int _codesPilotedToday = 0;
  int _pilotagesSharedToday = 0;

  // Inicializar el tracker
  Future<void> initialize() async {
    final loadedFromSupabase = await _loadProgressFromSupabase();
    if (!loadedFromSupabase) {
      await _loadProgressFromStorage(); // caché de emergencia
    }
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

  // Rastrear cuando el usuario comparte un pilotaje
  void trackPilotageShared({String? codeId, String? codeName}) {
    _pilotagesSharedToday++;
    _updateDailyProgress('pilotages_shared', _pilotagesSharedToday);

    _trackingService.recordPilotageShare(
      codeId: codeId,
      codeName: codeName,
    );

    // Feedback inmediato local: el propio dispositivo acaba de originar la
    // acción de compartir, no hace falta esperar al servidor.
    NotificationService().showNotification(
      title: '🎉 ¡Gracias por compartir!',
      body: 'Tu logro inspira a otros pilotos conscientes.',
      type: NotificationType.shareAchievement,
    );

    _saveProgressToStorage();
    notifyListeners();
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
      // Repeticiones de secuencias
      case '🔄 Repetir al menos 1 secuencia':
        return (counts['codes_repeated'] ?? 0) >= 1;
      case '🔄 Repetir 2 secuencias diferentes':
        return (counts['codes_repeated'] ?? 0) >= 2;
      case '🔄 Repetir 3 secuencias diferentes':
        return (counts['codes_repeated'] ?? 0) >= 3;
      case '🔄 Repetir 5 secuencias diferentes':
        return (counts['codes_repeated'] ?? 0) >= 5;
      // Pilotajes de secuencias
      case '🚀 Pilotar 1 secuencia':
        return (counts['codes_piloted'] ?? 0) >= 1;
      case '🚀 Pilotar 2 secuencias':
        return (counts['codes_piloted'] ?? 0) >= 2;
      case '🚀 Pilotar 3 secuencias':
        return (counts['codes_piloted'] ?? 0) >= 3;
      case '🖼️ Compartir 1 pilotaje':
        return (counts['pilotages_shared'] ?? 0) >= 1;
      case '🖼️ Compartir 2 pilotajes':
        return (counts['pilotages_shared'] ?? 0) >= 2;
      case '🖼️ Compartir 3 pilotajes':
        return (counts['pilotages_shared'] ?? 0) >= 3;
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
    } else if (action.contains('🖼️')) {
      return counts['pilotages_shared'] ?? 0;
    } else if (action.contains('⏱️')) {
      // Obtener el requerimiento de minutos
      final requiredMinutes = getActionRequirement(action);
      final currentMinutes = _totalAppUsageSeconds ~/ 60;
      
      // Si ya se cumplió el requerimiento, mostrar el requerimiento (ej: 15/15)
      // en vez de seguir contando (ej: 20/15)
      return currentMinutes >= requiredMinutes ? requiredMinutes : currentMinutes;
    }
    return 0;
  }

  // Obtener el requerimiento de una acción
  int getActionRequirement(String action) {
    if (action.contains('🔄')) {
      if (action.contains('1 secuencia')) return 1;
      if (action.contains('2 secuencias')) return 2;
      if (action.contains('3 secuencias')) return 3;
      if (action.contains('5 secuencias')) return 5;
    } else if (action.contains('🚀')) {
      if (action.contains('1 secuencia')) return 1;
      if (action.contains('2 secuencias')) return 2;
      if (action.contains('3 secuencias')) return 3;
    } else if (action.contains('🖼️')) {
      if (action.contains('1 pilotaje')) return 1;
      if (action.contains('2 pilotajes')) return 2;
      if (action.contains('3 pilotajes')) return 3;
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
    // Intervalo de 60 segundos para reducir escrituras y logs sin perder precisión útil
    _appUsageTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
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

  // Cargar progreso del día desde Supabase (fuente de verdad)
  Future<bool> _loadProgressFromSupabase() async {
    try {
      if (!_authService.isLoggedIn) return false;

      final todayKey = _getTodayKey();
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day).toUtc();
      final end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

      final actions = ['codigoRepetido', 'sesionPilotaje', 'pilotajeCompartido', 'tiempoEnApp'];

      final response = await _supabase
          .from('user_actions')
          .select()
          .eq('user_id', _authService.currentUser!.id)
          .inFilter('action_type', actions)
          .gte('recorded_at', start.toIso8601String())
          .lte('recorded_at', end.toIso8601String());

      // Repeticiones: contar SECUENCIAS ÚNICAS (la misma secuencia no cuenta dos veces)
      final Set<String> secuenciasRepetidasUnicas = {};
      int codesPiloted = 0;
      int pilotagesShared = 0;
      int appUsageSeconds = 0;

      for (final row in response as List) {
        final String type = row['action_type'] as String? ?? '';
        final Map<String, dynamic>? data = (row['action_data'] as Map?)?.cast<String, dynamic>();
        switch (type) {
          case 'codigoRepetido': {
            final codeId = (data?['codeId'] as String?)?.trim() ?? '';
            // Normalizar solo espacios → _ (333 333 3 = 333_333_3). NO colapsar: 3333333 ≠ 333_333_3
            final key = codeId.replaceAll(RegExp(r'\s+'), '_');
            if (key.isNotEmpty) {
              secuenciasRepetidasUnicas.add(key);
            } else {
              secuenciasRepetidasUnicas.add('legacy_${secuenciasRepetidasUnicas.length}');
            }
            break;
          }
          case 'sesionPilotaje':
            codesPiloted += 1;
            break;
          case 'pilotajeCompartido':
            pilotagesShared += 1;
            break;
          case 'tiempoEnApp':
            final minutes = (data?['duration'] as num?)?.toInt() ?? 0;
            appUsageSeconds += minutes * 60; // almacenamos en segundos
            break;
        }
      }

      final codesRepeated = secuenciasRepetidasUnicas.length;

      _dailyCounts[todayKey] = {
        if (codesRepeated > 0) 'codes_repeated': codesRepeated,
        if (codesPiloted > 0) 'codes_piloted': codesPiloted,
        if (pilotagesShared > 0) 'pilotages_shared': pilotagesShared,
        if (appUsageSeconds > 0) 'app_usage_seconds': appUsageSeconds,
      };

      // IMPORTANTE: Actualizar las variables en memoria con los valores cargados
      // para que persistan entre sesiones
      _codesRepeatedToday = codesRepeated;
      _codesPilotedToday = codesPiloted;
      _pilotagesSharedToday = pilotagesShared;
      _totalAppUsageSeconds = appUsageSeconds;
      
      print('✅ Progreso cargado desde Supabase:');
      print('   - Códigos repetidos: $_codesRepeatedToday');
      print('   - Códigos pilotados: $_codesPilotedToday');
      print('   - Pilotajes compartidos: $_pilotagesSharedToday');
      print('   - Tiempo de app: ${_totalAppUsageSeconds}s (${_totalAppUsageSeconds ~/ 60} min)');

      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error cargando progreso diario desde Supabase: $e');
      return false;
    }
  }

  // Resetear progreso diario (llamar al inicio de cada día)
  Future<void> resetDailyProgress() async {
    final today = _getTodayKey();
    _dailyCounts[today] = {};
    _codesRepeatedToday = 0;
    _codesPilotedToday = 0;
    _pilotagesSharedToday = 0;
    _totalAppUsageSeconds = 0;
    await _saveProgressToStorage();
  }

  // Limpiar recursos
  @override
  void dispose() {
    stopAppUsageTracking();
  }
}
