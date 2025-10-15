import 'package:flutter/foundation.dart';
import '../models/meditation.dart';
// import '../services/database_service.dart';
import '../services/audio_service.dart';
import '../data/mock_data.dart';

class MeditationProvider with ChangeNotifier {
  // final DatabaseService _db = DatabaseService();
  final AudioService _audio = AudioService();
  
  List<Meditation> _meditations = [];
  Meditation? _currentMeditation;
  MeditationSession? _currentSession;
  bool _isLoading = false;
  bool _isPlaying = false;

  List<Meditation> get meditations => _meditations;
  Meditation? get currentMeditation => _currentMeditation;
  MeditationSession? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  AudioService get audioService => _audio;

  Future<void> loadMeditations({String? type, int? maxDuration}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Usar datos mock
      await Future.delayed(const Duration(milliseconds: 500));
      _meditations = MockData.getMeditations();
      
      // Aplicar filtros
      if (type != null) {
        _meditations = _meditations.where((m) => m.type == type).toList();
      }
      if (maxDuration != null) {
        _meditations = _meditations.where((m) => m.durationMinutes <= maxDuration).toList();
      }
    } catch (e) {
      print('Error cargando meditaciones: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startMeditation(String meditationId) async {
    try {
      // Buscar en datos mock
      _currentMeditation = MockData.getMeditations().firstWhere(
        (m) => m.id == meditationId,
        orElse: () => MockData.getMeditations().first,
      );
      
      if (_currentMeditation == null) return;

      _currentSession = MeditationSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        meditationId: meditationId,
        startTime: DateTime.now(),
      );

      if (_currentMeditation!.audioUrl != null) {
        await _audio.playMeditationAudio(_currentMeditation!.audioUrl!);
        _isPlaying = true;
      }

      notifyListeners();
    } catch (e) {
      print('Error iniciando meditación: $e');
    }
  }

  Future<void> pauseMeditation() async {
    await _audio.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> resumeMeditation() async {
    await _audio.resume();
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> stopMeditation({String? userId, String? notes, int? rating}) async {
    await _audio.stop();
    _isPlaying = false;

    if (_currentSession != null && userId != null) {
      final completedSession = MeditationSession(
        id: _currentSession!.id,
        meditationId: _currentSession!.meditationId,
        startTime: _currentSession!.startTime,
        endTime: DateTime.now(),
        completedMinutes: DateTime.now().difference(_currentSession!.startTime).inMinutes,
        notes: notes,
        rating: rating ?? 0,
      );

      // En modo mock, solo imprimimos
      print('Sesión guardada (mock): ${completedSession.toJson()}');
    }

    _currentMeditation = null;
    _currentSession = null;
    notifyListeners();
  }

  List<Meditation> getMeditationsByDuration(int maxMinutes) {
    return _meditations.where((m) => m.durationMinutes <= maxMinutes).toList();
  }

  List<Meditation> getQuickMeditations() {
    return getMeditationsByDuration(5);
  }
}

