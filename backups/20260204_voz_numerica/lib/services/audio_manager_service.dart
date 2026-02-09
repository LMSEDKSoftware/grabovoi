import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class AudioManagerService {
  static final AudioManagerService _instance = AudioManagerService._internal();
  factory AudioManagerService() => _instance;
  AudioManagerService._internal();

  final AudioPlayer _globalPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _currentTrack;
  
  // Streams para notificar cambios
  final StreamController<bool> _isPlayingController = StreamController<bool>.broadcast();
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<String?> _currentTrackController = StreamController<String?>.broadcast();

  Stream<bool> get isPlayingStream => _isPlayingController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<String?> get currentTrackStream => _currentTrackController.stream;

  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  String? get currentTrack => _currentTrack;

  void _initializeListeners() {
    _stateSub = _globalPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      _isPlayingController.add(_isPlaying);
    });
    
    _posSub = _globalPlayer.onPositionChanged.listen((pos) {
      _position = pos;
      _positionController.add(_position);
    });
    
    _durSub = _globalPlayer.onDurationChanged.listen((dur) {
      _duration = dur;
      _durationController.add(_duration);
    });
  }

  Future<void> playTrack(String trackFile, {bool autoPlay = true}) async {
    // Detener cualquier reproducción actual
    await stop();
    
    // Inicializar listeners si no están activos
    if (_stateSub == null) {
      _initializeListeners();
    }
    
    try {
      _currentTrack = trackFile;
      _currentTrackController.add(_currentTrack);
      
      await _globalPlayer.setSource(AssetSource(trackFile.replaceFirst('assets/', '')));
      
      if (autoPlay) {
        await _globalPlayer.resume();
      }
    } catch (e) {
      print('Error reproduciendo audio: $e');
    }
  }

  Future<void> pause() async {
    await _globalPlayer.pause();
  }

  Future<void> resume() async {
    await _globalPlayer.resume();
  }

  Future<void> stop() async {
    await _globalPlayer.stop();
    _isPlaying = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _currentTrack = null;
    
    _isPlayingController.add(_isPlaying);
    _positionController.add(_position);
    _durationController.add(_duration);
    _currentTrackController.add(_currentTrack);
  }

  Future<void> setVolume(double volume) async {
    await _globalPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> dispose() async {
    await _stateSub?.cancel();
    await _posSub?.cancel();
    await _durSub?.cancel();
    await _globalPlayer.dispose();
    await _isPlayingController.close();
    await _positionController.close();
    await _durationController.close();
    await _currentTrackController.close();
  }
}
