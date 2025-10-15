import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioPreloadService {
  static final AudioPreloadService _instance = AudioPreloadService._internal();
  factory AudioPreloadService() => _instance;
  AudioPreloadService._internal();

  final Map<String, AudioPlayer> _preloadedPlayers = {};
  final Map<String, bool> _preloadStatus = {};
  bool _isPreloading = false;
  double _preloadProgress = 0.0;
  
  // Lista de archivos de audio para precargar
  final List<Map<String, String>> _audioFiles = [
    {
      'title': 'Frecuencia 432Hz - Armonía Universal',
      'file': 'assets/audios/432hz_harmony.mp3',
      'id': '432hz'
    },
    {
      'title': 'Códigos Solfeggio 528Hz - Amor',
      'file': 'assets/audios/528hz_love.mp3',
      'id': '528hz'
    },
    {
      'title': 'Binaural Beats - Manifestación',
      'file': 'assets/audios/binaural_manifestation.mp3',
      'id': 'binaural'
    },
    {
      'title': 'Crystal Bowls - Chakra Healing',
      'file': 'assets/audios/crystal_bowls.mp3',
      'id': 'crystal'
    },
    {
      'title': 'Nature Sounds - Forest Meditation',
      'file': 'assets/audios/forest_meditation.mp3',
      'id': 'forest'
    },
  ];

  // Getters
  bool get isPreloading => _isPreloading;
  double get preloadProgress => _preloadProgress;
  bool get isPreloadComplete => _preloadStatus.values.every((status) => status);
  Map<String, bool> get preloadStatus => Map.from(_preloadStatus);

  // Stream para notificar cambios en el progreso
  final StreamController<double> _progressController = StreamController<double>.broadcast();
  Stream<double> get progressStream => _progressController.stream;

  // Stream para notificar cambios en el estado
  final StreamController<bool> _statusController = StreamController<bool>.broadcast();
  Stream<bool> get statusStream => _statusController.stream;

  /// Inicia la precarga de todos los archivos de audio
  Future<void> startPreload() async {
    if (_isPreloading) return;
    
    _isPreloading = true;
    _preloadProgress = 0.0;
    _statusController.add(true);
    
    debugPrint('🎵 Iniciando precarga de ${_audioFiles.length} archivos de audio...');
    
    try {
      for (int i = 0; i < _audioFiles.length; i++) {
        final audioFile = _audioFiles[i];
        final audioId = audioFile['id']!;
        
        debugPrint('📥 Precargando: ${audioFile['title']}');
        
        try {
          // Crear nuevo AudioPlayer para este archivo
          final player = AudioPlayer();
          
          // Precargar el archivo
          await player.setAsset(audioFile['file']!);
          
          // Guardar el player precargado
          _preloadedPlayers[audioId] = player;
          _preloadStatus[audioId] = true;
          
          debugPrint('✅ Precargado: ${audioFile['title']}');
          
        } catch (e) {
          debugPrint('❌ Error precargando ${audioFile['title']}: $e');
          _preloadStatus[audioId] = false;
        }
        
        // Actualizar progreso
        _preloadProgress = (i + 1) / _audioFiles.length;
        _progressController.add(_preloadProgress);
        
        // Pequeña pausa para no sobrecargar
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      _isPreloading = false;
      _statusController.add(false);
      
      debugPrint('🎉 Precarga completada: ${_preloadedPlayers.length}/${_audioFiles.length} archivos');
      
    } catch (e) {
      debugPrint('❌ Error en precarga: $e');
      _isPreloading = false;
      _statusController.add(false);
    }
  }

  /// Obtiene un player precargado por ID
  AudioPlayer? getPreloadedPlayer(String audioId) {
    return _preloadedPlayers[audioId];
  }

  /// Obtiene el índice del audio por ID
  int getAudioIndex(String audioId) {
    for (int i = 0; i < _audioFiles.length; i++) {
      if (_audioFiles[i]['id'] == audioId) {
        return i;
      }
    }
    return 0;
  }

  /// Obtiene información del audio por índice
  Map<String, String> getAudioInfo(int index) {
    if (index >= 0 && index < _audioFiles.length) {
      return _audioFiles[index];
    }
    return _audioFiles[0];
  }

  /// Obtiene todos los archivos de audio
  List<Map<String, String>> get allAudioFiles => _audioFiles;

  /// Verifica si un audio específico está precargado
  bool isAudioPreloaded(String audioId) {
    return _preloadStatus[audioId] ?? false;
  }

  /// Libera todos los recursos
  Future<void> dispose() async {
    for (final player in _preloadedPlayers.values) {
      await player.dispose();
    }
    _preloadedPlayers.clear();
    _preloadStatus.clear();
    await _progressController.close();
    await _statusController.close();
  }
}
