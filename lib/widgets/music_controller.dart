import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_service.dart';

class MusicController extends StatefulWidget {
  final VoidCallback? onMusicChanged;
  final bool showMusicList;
  final bool autoPlay;
  
  const MusicController({
    super.key,
    this.onMusicChanged,
    this.showMusicList = false,
    this.autoPlay = false,
  });

  @override
  State<MusicController> createState() => _MusicControllerState();
}

class _MusicControllerState extends State<MusicController> {
  final AudioService _audioService = AudioService();
  int _selectedMusicIndex = 0;
  Duration _currentPosition = Duration.zero;
  Duration? _totalDuration;
  Timer? _simulationTimer;
  StreamSubscription<Duration>? _positionSubscription;
  bool _isUsingRealAudio = false;

  @override
  void initState() {
    super.initState();
    _audioService.initialize();
    _setupListeners();
    
    // Reproducir automáticamente si autoPlay está habilitado
    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAutoPlay();
      });
    }
  }

  void _setupListeners() {
    // Cancelar suscripción anterior si existe
    _positionSubscription?.cancel();
    
    // Suscribirse al stream de posición del audio real
    _positionSubscription = _audioService.positionStream.listen((position) {
      if (mounted && _isUsingRealAudio) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _audioService.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });
  }

  Future<void> _startAutoPlay() async {
    try {
      // Pequeño delay para asegurar que el widget esté completamente montado
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        // Detener timer de simulación si existe
        _simulationTimer?.cancel();
        
        // Intentar reproducir audio real
        await _audioService.playPilotajeMusic(_selectedMusicIndex);
        
        // Verificar si el audio se está reproduciendo realmente
        await Future.delayed(const Duration(milliseconds: 2000));
        
        if (_audioService.isActuallyPlaying && _audioService.isPlaying) {
          // Usar audio real
          _isUsingRealAudio = true;
          debugPrint('✅ Usando audio real - reproducción confirmada');
        } else {
          // Usar simulación
          _isUsingRealAudio = false;
          _startSimulationTimer();
          debugPrint('⚠️ Usando simulación de audio - audio real no disponible');
        }
        
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Error al reproducir música automáticamente: $e');
      // Usar simulación en caso de error
      _isUsingRealAudio = false;
      _startSimulationTimer();
    }
  }

  void _startSimulationTimer() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isUsingRealAudio) {
        setState(() {
          _currentPosition = Duration(seconds: _currentPosition.inSeconds + 1);
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título del control de música
          Row(
            children: [
              const Icon(
                Icons.music_note,
                color: Color(0xFFFFD700),
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Música Energizante',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Indicador de estado
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _audioService.isPlaying 
                      ? Colors.green 
                      : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Información de la música actual (solo título)
          Text(
            _audioService.pilotajeMusic[_selectedMusicIndex]['title']!,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Contador de segundos de reproducción
          Container(
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

          // Controles principales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Botón anterior
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedMusicIndex = (_selectedMusicIndex - 1 + 
                        _audioService.pilotajeMusic.length) % 
                        _audioService.pilotajeMusic.length;
                    _currentPosition = Duration.zero; // Reiniciar contador
                  });
                  _audioService.stopMusic();
                  _simulationTimer?.cancel(); // Detener timer actual
                  _audioService.playPilotajeMusic(_selectedMusicIndex);
                  
                  // Verificar si usar audio real o simulación
                  Future.delayed(const Duration(milliseconds: 2000), () {
                    if (_audioService.isActuallyPlaying && _audioService.isPlaying) {
                      _isUsingRealAudio = true;
                      debugPrint('✅ Cambio a audio real');
                    } else {
                      _isUsingRealAudio = false;
                      _startSimulationTimer();
                      debugPrint('⚠️ Cambio a simulación');
                    }
                  });
                  
                  widget.onMusicChanged?.call();
                },
                icon: const Icon(
                  Icons.skip_previous,
                  color: Color(0xFFFFD700),
                  size: 28,
                ),
              ),

              // Indicador de reproducción automática
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_circle_filled,
                        color: Color(0xFFFFD700),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Auto',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFFD700),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
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
                onPressed: () {
                  setState(() {
                    _selectedMusicIndex = (_selectedMusicIndex + 1) % 
                        _audioService.pilotajeMusic.length;
                    _currentPosition = Duration.zero; // Reiniciar contador
                  });
                  _audioService.stopMusic();
                  _simulationTimer?.cancel(); // Detener timer actual
                  _audioService.playPilotajeMusic(_selectedMusicIndex);
                  
                  // Verificar si usar audio real o simulación
                  Future.delayed(const Duration(milliseconds: 2000), () {
                    if (_audioService.isActuallyPlaying && _audioService.isPlaying) {
                      _isUsingRealAudio = true;
                      debugPrint('✅ Cambio a audio real');
                    } else {
                      _isUsingRealAudio = false;
                      _startSimulationTimer();
                      debugPrint('⚠️ Cambio a simulación');
                    }
                  });
                  
                  widget.onMusicChanged?.call();
                },
                icon: const Icon(
                  Icons.skip_next,
                  color: Color(0xFFFFD700),
                  size: 28,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),


          // Lista de música (si está habilitada)
          if (widget.showMusicList) ...[
            const SizedBox(height: 16),
            Container(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _audioService.pilotajeMusic.length,
                itemBuilder: (context, index) {
                  final music = _audioService.pilotajeMusic[index];
                  final isSelected = index == _selectedMusicIndex;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMusicIndex = index;
                      });
                      _audioService.stopMusic();
                      _audioService.playPilotajeMusic(index);
                      widget.onMusicChanged?.call();
                    },
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFFFFD700).withOpacity(0.2)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                              ? const Color(0xFFFFD700)
                              : Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.music_note,
                            color: isSelected 
                                ? const Color(0xFFFFD700)
                                : Colors.white70,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            music['title']!,
                            style: GoogleFonts.inter(
                              color: isSelected 
                                  ? const Color(0xFFFFD700)
                                  : Colors.white70,
                              fontSize: 10,
                              fontWeight: isSelected 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds s';
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _positionSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
