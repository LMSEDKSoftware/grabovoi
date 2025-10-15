import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_service.dart';

class MusicController extends StatefulWidget {
  final VoidCallback? onMusicChanged;
  final bool showMusicList;
  
  const MusicController({
    super.key,
    this.onMusicChanged,
    this.showMusicList = false,
  });

  @override
  State<MusicController> createState() => _MusicControllerState();
}

class _MusicControllerState extends State<MusicController> {
  final AudioService _audioService = AudioService();
  int _selectedMusicIndex = 0;
  Duration _currentPosition = Duration.zero;
  Duration? _totalDuration;

  @override
  void initState() {
    super.initState();
    _audioService.initialize();
    _setupListeners();
  }

  void _setupListeners() {
    _audioService.positionStream.listen((position) {
      if (mounted) {
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
              Text(
                'Música Energizante',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
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

          // Información de la música actual
          if (_audioService.isPlaying) ...[
            Text(
              _audioService.pilotajeMusic[_selectedMusicIndex]['title']!,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _audioService.pilotajeMusic[_selectedMusicIndex]['description']!,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Barra de progreso
            if (_totalDuration != null) ...[
              Row(
                children: [
                  Text(
                    _formatDuration(_currentPosition),
                    style: GoogleFonts.spaceMono(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFFFD700),
                        inactiveTrackColor: Colors.white30,
                        thumbColor: const Color(0xFFFFD700),
                        overlayColor: const Color(0xFFFFD700).withOpacity(0.2),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: _currentPosition.inMilliseconds.toDouble(),
                        max: _totalDuration!.inMilliseconds.toDouble(),
                        onChanged: (value) {
                          _audioService.seekTo(Duration(milliseconds: value.toInt()));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_totalDuration!),
                    style: GoogleFonts.spaceMono(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],

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
                  });
                  _audioService.stopMusic();
                  _audioService.playPilotajeMusic(_selectedMusicIndex);
                  widget.onMusicChanged?.call();
                },
                icon: const Icon(
                  Icons.skip_previous,
                  color: Color(0xFFFFD700),
                  size: 28,
                ),
              ),

              // Botón play/pause
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    if (_audioService.isPlaying) {
                      _audioService.pauseMusic();
                    } else {
                      _audioService.resumeMusic();
                    }
                    setState(() {});
                  },
                  icon: Icon(
                    _audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: const Color(0xFFFFD700),
                    size: 32,
                  ),
                ),
              ),

              // Botón siguiente
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedMusicIndex = (_selectedMusicIndex + 1) % 
                        _audioService.pilotajeMusic.length;
                  });
                  _audioService.stopMusic();
                  _audioService.playPilotajeMusic(_selectedMusicIndex);
                  widget.onMusicChanged?.call();
                },
                icon: const Icon(
                  Icons.skip_next,
                  color: Color(0xFFFFD700),
                  size: 28,
                ),
              ),

              // Botón stop
              IconButton(
                onPressed: () {
                  _audioService.stopMusic();
                  setState(() {});
                },
                icon: const Icon(
                  Icons.stop,
                  color: Colors.red,
                  size: 24,
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
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
