import 'package:flutter/foundation.dart';
import '../models/tracker_session.dart';
// import '../services/database_service.dart';

class TrackerProvider with ChangeNotifier {
  // final DatabaseService _db = DatabaseService();
  
  TrackerSession? _currentSession;
  List<TrackerSession> _recentSessions = [];
  bool _isLoading = false;

  TrackerSession? get currentSession => _currentSession;
  List<TrackerSession> get recentSessions => _recentSessions;
  bool get isLoading => _isLoading;
  bool get isTracking => _currentSession != null && !_currentSession!.isCompleted;
  bool get isActive => _currentSession != null && !_currentSession!.isCompleted;
  int get currentCount => _currentSession?.repetitions ?? 0;

  Future<void> loadRecentSessions(String userId, {int limit = 10}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Mock: mantener sesiones en memoria
      await Future.delayed(const Duration(milliseconds: 300));
      // _recentSessions ya contiene las sesiones guardadas
    } catch (e) {
      print('Error cargando sesiones: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startSession(String code, {int targetRepetitions = 108}) {
    _currentSession = TrackerSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      codeId: 'custom',
      code: code,
      startTime: DateTime.now(),
      targetRepetitions: targetRepetitions,
    );
    notifyListeners();
  }

  void stopSession() {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        isCompleted: true,
        endTime: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void incrementCount() {
    if (_currentSession == null) return;
    incrementRepetition();
  }

  void incrementRepetition() {
    if (_currentSession == null) return;

    _currentSession = _currentSession!.copyWith(
      repetitions: _currentSession!.repetitions + 1,
    );

    if (_currentSession!.repetitions >= _currentSession!.targetRepetitions) {
      _currentSession = _currentSession!.copyWith(
        isCompleted: true,
        endTime: DateTime.now(),
      );
    }

    notifyListeners();
  }

  void setRepetitions(int count) {
    if (_currentSession == null) return;

    _currentSession = _currentSession!.copyWith(
      repetitions: count,
      isCompleted: count >= _currentSession!.targetRepetitions,
      endTime: count >= _currentSession!.targetRepetitions 
          ? DateTime.now() 
          : null,
    );

    notifyListeners();
  }

  Future<void> saveSession(String userId, {String? notes}) async {
    if (_currentSession == null) return;

    try {
      final sessionToSave = _currentSession!.copyWith(
        notes: notes,
        endTime: _currentSession!.endTime ?? DateTime.now(),
      );

      // Mock: guardar en memoria
      _recentSessions.insert(0, sessionToSave);
      _currentSession = null;
      notifyListeners();
      print('Sesión guardada (mock): ${sessionToSave.id}');
    } catch (e) {
      print('Error guardando sesión: $e');
      rethrow;
    }
  }

  void cancelSession() {
    _currentSession = null;
    notifyListeners();
  }

  int getTotalRepetitions({int days = 7}) {
    final now = DateTime.now();
    return _recentSessions
        .where((session) => now.difference(session.startTime).inDays <= days)
        .fold(0, (sum, session) => sum + session.repetitions);
  }

  int getCompletedSessionsCount({int days = 7}) {
    final now = DateTime.now();
    return _recentSessions
        .where((session) => 
            session.isCompleted && 
            now.difference(session.startTime).inDays <= days)
        .length;
  }
}

