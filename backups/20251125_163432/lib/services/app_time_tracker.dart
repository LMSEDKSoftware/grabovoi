import 'dart:async';
import 'package:flutter/foundation.dart';
import 'challenge_tracking_service.dart';

class AppTimeTracker extends ChangeNotifier {
  static final AppTimeTracker _instance = AppTimeTracker._internal();
  factory AppTimeTracker() => _instance;
  AppTimeTracker._internal();

  final ChallengeTrackingService _trackingService = ChallengeTrackingService();
  DateTime? _sessionStartTime;
  Timer? _sessionTimer;
  Duration _currentSessionDuration = Duration.zero;

  // Getters
  Duration get currentSessionDuration => _currentSessionDuration;
  bool get isSessionActive => _sessionStartTime != null;

  // Iniciar sesión de tiempo en la app
  void startSession() {
    if (_sessionStartTime != null) return; // Ya hay una sesión activa

    _sessionStartTime = DateTime.now();
    _currentSessionDuration = Duration.zero;

    // Timer para actualizar cada minuto
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_sessionStartTime != null) {
        _currentSessionDuration = DateTime.now().difference(_sessionStartTime!);
        
        // Registrar tiempo en la app cada 5 minutos
        if (_currentSessionDuration.inMinutes % 5 == 0 && _currentSessionDuration.inMinutes > 0) {
          _trackingService.recordAppTime(const Duration(minutes: 5));
        }
        
        notifyListeners();
      }
    });

    notifyListeners();
  }

  // Finalizar sesión de tiempo en la app
  void endSession() {
    if (_sessionStartTime == null) return;

    final sessionDuration = DateTime.now().difference(_sessionStartTime!);
    
    // Registrar el tiempo total de la sesión
    if (sessionDuration.inMinutes > 0) {
      _trackingService.recordAppTime(sessionDuration);
    }

    _sessionStartTime = null;
    _currentSessionDuration = Duration.zero;
    _sessionTimer?.cancel();
    _sessionTimer = null;

    notifyListeners();
  }

  // Obtener tiempo total de la sesión actual
  Duration getCurrentSessionTime() {
    if (_sessionStartTime == null) return Duration.zero;
    return DateTime.now().difference(_sessionStartTime!);
  }

  // Obtener tiempo formateado
  String getFormattedSessionTime() {
    final duration = getCurrentSessionTime();
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  void dispose() {
    endSession();
    super.dispose();
  }
}
