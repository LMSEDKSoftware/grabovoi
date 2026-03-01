import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../services/audio_preload_service.dart';

class PreloadedMusicController extends StatefulWidget {
  final bool autoPlay;
  final Function(String)? onMusicChanged;

  const PreloadedMusicController({
    super.key,
    this.autoPlay = false,
    this.onMusicChanged,
  });

  @override
  State<PreloadedMusicController> createState() => _PreloadedMusicControllerState();
}

class _PreloadedMusicControllerState extends State<PreloadedMusicController> {
  final AudioPreloadService _preloadService = AudioPreloadService();
  
  int _selectedMusicIndex = 0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  bool _isInitialized = false;
  
  AudioPlayer? _currentPlayer;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    if (!_isInitialized) {
      // Esperar a que la precarga esté completa
      await _waitForPreload();
      
      // Configurar el primer audio
      await _setupCurrentAudio();
      
      if (widget.autoPlay) {
        await _startPlayback();
      }
      
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _waitForPreload() async {
    while (!_preloadService.isPreloadComplete) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    debugPrint('✅ Precarga completada, iniciando reproductor');
  }

  Future<void> _setupCurrentAudio() async {
    final audioInfo = _preloadService.getAudioInfo(_selectedMusicIndex);
    final audioId = audioInfo['id']!;
    
    // Obtener el player precargado
    _currentPlayer = _preloadService.getPreloadedPlayer(audioId);
    
    if (_currentPlayer != null) {
      // Configurar listeners
      _setupListeners();
      
      // Obtener duración total
      _totalDuration = _currentPlayer!.duration ?? Duration.zero;
      
      debugPrint('🎵 Audio configurado: ${audioInfo['title']}');
    } else {
      debugPrint('❌ No se encontró el player precargado para: $audioId');
    }
  }

  void _setupListeners() {
    if (_currentPlayer == null) return;
    
    // Listener de posición
    _positionSubscription?.cancel();
    _positionSubscription = _currentPlayer!.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
    
    // Listener de duración
    _durationSubscription?.cancel();
    _durationSubscription = _currentPlayer!.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration ?? Duration.zero;
        });
      }
    });
    
    // Listener de estado del player
    _playerStateSubscription?.cancel();
    _playerStateSubscription = _currentPlayer!.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });
  }

  Future<void> _startPlayback() async {
    if (_currentPlayer != null && _preloadService.isPreloadComplete) {
      try {
        await _currentPlayer!.play();
        debugPrint('🎵 Reproducción iniciada');
      } catch (e) {
        debugPrint('❌ Error iniciando reproducción: $e');
      }
    }
  }

  Future<void> _playPrevious() async {
    if (_selectedMusicIndex > 0) {
      await _changeMusic(_selectedMusicIndex - 1);
    } else {
      await _changeMusic(_preloadService.allAudioFiles.length - 1);
    }
  }

  Future<void> _playNext() async {
    if (_selectedMusicIndex < _preloadService.allAudioFiles.length - 1) {
      await _changeMusic(_selectedMusicIndex + 1);
    } else {
      await _changeMusic(0);
    }
  }

  Future<void> _changeMusic(int newIndex) async {
    if (newIndex == _selectedMusicIndex) return;
    
    // Detener audio actual
    if (_currentPlayer != null) {
      await _currentPlayer!.stop();
    }
    
    // Cambiar índice
    setState(() {
      _selectedMusicIndex = newIndex;
      _currentPosition = Duration.zero;
    });
    
    // Configurar nuevo audio
    await _setupCurrentAudio();
    
    // Notificar cambio
    final audioInfo = _preloadService.getAudioInfo(_selectedMusicIndex);
    widget.onMusicChanged?.call(audioInfo['title']!);
    
    // Iniciar reproducción si estaba reproduciendo
    if (_isPlaying) {
      await _startPlayback();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds s';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
        ),
      );
    }

    final audioInfo = _preloadService.getAudioInfo(_selectedMusicIndex);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1a1a2e),
            Color(0xFF16213e),
            Color(0xFF0f3460),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header con título y estado
          Row(
            children: [
              const Icon(
                Icons.music_note,
                color: Color(0xFFFFD700),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Música Energizante',
                  style: GoogleFonts.spaceMono(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isPlaying 
                    ? const Color(0xFFFFD700) 
                    : Colors.grey.withOpacity(0.5),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Título del audio actual
          Text(
            audioInfo['title']!,
            style: GoogleFonts.spaceMono(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 16),
          
          // Contador de tiempo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer,
                  color: Color(0xFFFFD700),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDuration(_currentPosition),
                  style: GoogleFonts.spaceMono(
                    color: const Color(0xFFFFD700),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Controles de navegación
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Botón anterior
              IconButton(
                onPressed: _playPrevious,
                icon: const Icon(
                  Icons.skip_previous,
                  color: Color(0xFFFFD700),
                  size: 32,
                ),
              ),
              
              // Indicador de reproducción automática
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_arrow,
                        color: Color(0xFFFFD700),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Auto',
                          style: GoogleFonts.spaceMono(
                            color: const Color(0xFFFFD700),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Botón siguiente
              IconButton(
                onPressed: _playNext,
                icon: const Icon(
                  Icons.skip_next,
                  color: Color(0xFFFFD700),
                  size: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    super.dispose();
  }
}
