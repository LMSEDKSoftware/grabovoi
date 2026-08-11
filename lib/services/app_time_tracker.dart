import 'dart:async';
import 'package:flutter/widgets.dart';
import 'challenge_tracking_service.dart';

class AppTimeTracker extends ChangeNotifier with WidgetsBindingObserver {
  static final AppTimeTracker _instance = AppTimeTracker._internal();
  factory AppTimeTracker() => _instance;
  AppTimeTracker._internal();

  final ChallengeTrackingService _trackingService = ChallengeTrackingService();
  Timer? _sessionTimer;
  bool _observing = false;
  bool _isActive = false;

  // Tiempo activo acumulado (excluye segundos en segundo plano): la suma de
  // tramos ya cerrados más, si hay uno abierto, lo transcurrido desde que
  // empezó. Antes el cronómetro no escuchaba el ciclo de vida de la app, así
  // que minimizarla (sin cerrarla) seguía sumando "tiempo en app" — eso
  // inflaba el Nivel Energético y el requisito de minutos de los Desafíos.
  Duration _accumulatedActiveDuration = Duration.zero;
  DateTime? _activeSegmentStart;

  bool get isSessionActive => _isActive;

  // Iniciar sesión de tiempo en la app
  void startSession() {
    if (_isActive) return; // Ya hay una sesión activa

    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }

    _accumulatedActiveDuration = Duration.zero;
    _resumeActiveSegment();
  }

  // Finalizar sesión de tiempo en la app
  void endSession() {
    if (!_isActive) return;

    _pauseActiveSegment();

    final sessionDuration = _accumulatedActiveDuration;
    if (sessionDuration.inMinutes > 0) {
      _trackingService.recordAppTime(sessionDuration);
    }

    _accumulatedActiveDuration = Duration.zero;
    _isActive = false;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isActive) _resumeActiveSegment();
    } else {
      // paused, inactive, detached, hidden: deja de contar como tiempo activo.
      _pauseActiveSegment();
    }
  }

  void _resumeActiveSegment() {
    _isActive = true;
    _activeSegmentStart = DateTime.now();
    _sessionTimer?.cancel();
    // Timer para actualizar y registrar cada 5 minutos de tiempo activo.
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) => _onTick());
    notifyListeners();
  }

  void _pauseActiveSegment() {
    if (_activeSegmentStart != null) {
      _accumulatedActiveDuration += DateTime.now().difference(_activeSegmentStart!);
      _activeSegmentStart = null;
    }
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  void _onTick() {
    if (_activeSegmentStart == null) return;
    final current = _accumulatedActiveDuration + DateTime.now().difference(_activeSegmentStart!);
    // Registrar tiempo en la app cada 5 minutos (activos, no de reloj).
    if (current.inMinutes % 5 == 0 && current.inMinutes > 0) {
      _trackingService.recordAppTime(const Duration(minutes: 5));
    }
    notifyListeners();
  }

  // Obtener tiempo total de la sesión actual (solo tiempo activo/foreground)
  Duration getCurrentSessionTime() {
    if (_activeSegmentStart == null) return _accumulatedActiveDuration;
    return _accumulatedActiveDuration + DateTime.now().difference(_activeSegmentStart!);
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
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
    endSession();
    super.dispose();
  }
}
