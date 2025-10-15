import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _isInitialized = false;

  AudioPlayer get player => _player;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  Future<void> playMeditationAudio(String audioUrl) async {
    try {
      await _player.setUrl(audioUrl);
      await _player.play();
    } catch (e) {
      print('Error reproduciendo audio: $e');
      rethrow;
    }
  }

  Future<void> playLocalAudio(String assetPath) async {
    try {
      await _player.setAsset(assetPath);
      await _player.play();
    } catch (e) {
      print('Error reproduciendo audio local: $e');
      rethrow;
    }
  }

  Future<void> playAmbientSound(String soundType) async {
    final soundMap = {
      'rain': 'assets/audios/rain.mp3',
      'ocean': 'assets/audios/ocean.mp3',
      'forest': 'assets/audios/forest.mp3',
      'wind': 'assets/audios/wind.mp3',
      'fire': 'assets/audios/fire.mp3',
      'bells': 'assets/audios/bells.mp3',
      'singing_bowls': 'assets/audios/singing_bowls.mp3',
    };

    final soundPath = soundMap[soundType];
    if (soundPath != null) {
      await playLocalAudio(soundPath);
      await _player.setLoopMode(LoopMode.one);
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  void dispose() {
    _player.dispose();
  }
}

