import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  late AudioPlayer _audioPlayer;
  bool _isInitialized = false;
  bool _isPlaying = false;

  // Lista de música energizante para pilotaje
  final List<Map<String, String>> _pilotajeMusic = [
    {
      'title': 'Frecuencia 432Hz - Armonía Universal',
      'file': 'assets/audios/432hz_harmony.mp3',
      'description': 'Frecuencia de sanación y armonía',
    },
    {
      'title': 'Códigos Solfeggio 528Hz - Amor',
      'file': 'assets/audios/528hz_love.mp3',
      'description': 'Frecuencia del amor y transformación',
    },
    {
      'title': 'Binaural Beats - Manifestación',
      'file': 'assets/audios/binaural_manifestation.mp3',
      'description': 'Ondas cerebrales para manifestación',
    },
    {
      'title': 'Crystal Bowls - Chakra Healing',
      'file': 'assets/audios/crystal_bowls.mp3',
      'description': 'Sanación con cuencos de cristal',
    },
    {
      'title': 'Nature Sounds - Forest Meditation',
      'file': 'assets/audios/forest_meditation.mp3',
      'description': 'Sonidos naturales para concentración',
    },
  ];

  Future<void> initialize() async {
    if (!_isInitialized) {
      _audioPlayer = AudioPlayer();
      _isInitialized = true;
    }
  }

  List<Map<String, String>> get pilotajeMusic => _pilotajeMusic;

  bool get isPlaying => _isPlaying;
  
  bool get isActuallyPlaying => _isInitialized && _audioPlayer.playing;

  Future<void> playPilotajeMusic(int index) async {
    if (!_isInitialized) await initialize();
    
    try {
      final music = _pilotajeMusic[index];
      debugPrint('Intentando reproducir: ${music['title']} - ${music['file']}');
      
      // Detener reproducción anterior
      await _audioPlayer.stop();
      _isPlaying = false;
      
      await _audioPlayer.setAsset(music['file']!);
      await _audioPlayer.play();
      
      // Esperar un momento para que el audio se inicie
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Verificar múltiples veces si realmente está reproduciendo
      bool isActuallyPlaying = false;
      for (int i = 0; i < 3; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (_audioPlayer.playing && _audioPlayer.position.inSeconds > 0) {
          isActuallyPlaying = true;
          break;
        }
      }
      
      if (isActuallyPlaying) {
        _isPlaying = true;
        debugPrint('✅ Confirmado: Audio reproduciéndose correctamente');
      } else {
        _isPlaying = false;
        debugPrint('❌ Audio no se está reproduciendo realmente');
        debugPrint('Estado del player: playing=${_audioPlayer.playing}, position=${_audioPlayer.position}');
      }
      
    } catch (e) {
      debugPrint('❌ Error playing music: $e');
      debugPrint('Archivo intentado: ${_pilotajeMusic[index]['file']}');
      _isPlaying = false;
    }
  }

  Future<void> pauseMusic() async {
    if (_isInitialized && _isPlaying) {
      await _audioPlayer.pause();
      _isPlaying = false;
    }
  }

  Future<void> resumeMusic() async {
    if (_isInitialized && !_isPlaying) {
      await _audioPlayer.play();
      _isPlaying = true;
    }
  }

  Future<void> stopMusic() async {
    if (_isInitialized) {
      await _audioPlayer.stop();
      _isPlaying = false;
    }
  }


  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  Future<void> seekTo(Duration position) async {
    if (_isInitialized) {
      await _audioPlayer.seek(position);
    }
  }

  Future<void> dispose() async {
    if (_isInitialized) {
      await _audioPlayer.dispose();
      _isInitialized = false;
    }
  }

  // Método para obtener música aleatoria
  Map<String, String> getRandomMusic() {
    final randomIndex = DateTime.now().millisecondsSinceEpoch % _pilotajeMusic.length;
    return _pilotajeMusic[randomIndex];
  }

  // Método para obtener música por categoría
  List<Map<String, String>> getMusicByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'frecuencias':
        return _pilotajeMusic.where((music) => 
          music['title']!.contains('Hz') || music['title']!.contains('Frecuencia')).toList();
      case 'naturaleza':
        return _pilotajeMusic.where((music) => 
          music['title']!.contains('Nature') || music['title']!.contains('Forest')).toList();
      case 'sanación':
        return _pilotajeMusic.where((music) => 
          music['title']!.contains('Healing') || music['title']!.contains('Crystal')).toList();
      default:
        return _pilotajeMusic;
    }
  }
}
