import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/audio_manager_service.dart';

class StreamedMusicController extends StatefulWidget {
  final bool autoPlay;
  final bool isActive;
  const StreamedMusicController({super.key, this.autoPlay = false, this.isActive = false});

  @override
  State<StreamedMusicController> createState() => _StreamedMusicControllerState();
}

class _StreamedMusicControllerState extends State<StreamedMusicController> with SingleTickerProviderStateMixin {
  final List<Map<String, String>> _tracks = const [
    {'title': 'Frecuencia 432Hz - Armonía Universal', 'file': 'assets/audios/432hz_harmony.mp3'},
    {'title': 'Códigos Solfeggio 528Hz - Amor', 'file': 'assets/audios/528hz_love.mp3'},
    {'title': 'Binaural Beats - Manifestación', 'file': 'assets/audios/binaural_manifestation.mp3'},
    {'title': 'Crystal Bowls - Chakra Healing', 'file': 'assets/audios/crystal_bowls.mp3'},
    {'title': 'Nature Sounds - Forest Meditation', 'file': 'assets/audios/forest_meditation.mp3'},
  ];

  final AudioManagerService _audioManager = AudioManagerService();
  StreamSubscription<bool>? _isPlayingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<String?>? _currentTrackSub;

  int _index = 0;
  bool _isBuffering = true;
  bool _isPlaying = false;
  bool _isMuted = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _hasShownVolumeMessage = false;
  static bool _globalVolumeMessageShown = false;
  AnimationController? _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _syncWithExistingPlayback();
    _wireListeners();
    if (widget.isActive && widget.autoPlay) {
      _showVolumeMessageOnFirstPlay();
      _loadAndMaybePlay(_index);
    }
  }

  @override
  void didUpdateWidget(StreamedMusicController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _showVolumeMessageOnFirstPlay();
      _loadAndMaybePlay(_index);
    }
  }

  void _wireListeners() {
    _isPlayingSub = _audioManager.isPlayingStream.listen((playing) {
      if (!mounted) return;
      setState(() => _isPlaying = playing);
    });
    
    _positionSub = _audioManager.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);
    });
    
    _durationSub = _audioManager.durationStream.listen((dur) {
      if (!mounted) return;
      setState(() => _duration = dur);
    });
    
    _currentTrackSub = _audioManager.currentTrackStream.listen((track) {
      if (!mounted) return;
      setState(() {
        _isBuffering = track != null && track != _tracks[_index]['file'];
      });
    });
  }

  void _showVolumeMessageOnFirstPlay() {
    if ((!_hasShownVolumeMessage && !_globalVolumeMessageShown) && mounted) {
      _hasShownVolumeMessage = true;
      _globalVolumeMessageShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _animationController != null) {
          final fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
            CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
          );
          
          showDialog(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.black.withOpacity(0.5),
            builder: (context) => FadeTransition(
              opacity: fadeAnimation,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a2e).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.volume_up,
                          color: Color(0xFFFFD700),
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '🔊 Ajusta el volumen',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'para una mejor experiencia',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && _animationController != null) {
              _animationController!.forward().then((_) {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              });
            }
          });
        }
      });
    }
  }

  Future<void> _loadAndMaybePlay(int i) async {
    if (!mounted) return;
    
    setState(() {
      _isBuffering = true;
    });

    final file = _tracks[i]['file']!;

    if (_audioManager.currentTrack == file && _audioManager.isPlaying) {
      _isPlaying = true;
      _position = _audioManager.position;
      _duration = _audioManager.duration;
      setState(() => _isBuffering = false);
      return;
    }
    
    await _audioManager.playTrack(file, autoPlay: widget.isActive && widget.autoPlay);
    
    if (!mounted) return;
    setState(() => _isBuffering = false);
  }

  void _syncWithExistingPlayback() {
    final currentTrack = _audioManager.currentTrack;
    if (currentTrack != null) {
      final existingIndex = _tracks.indexWhere((track) => track['file'] == currentTrack);
      if (existingIndex != -1) {
        _index = existingIndex;
      }
    }
    _isPlaying = _audioManager.isPlaying;
    _position = _audioManager.position;
    _duration = _audioManager.duration;
  }

  Future<void> _prev() async {
    _index = (_index - 1) < 0 ? _tracks.length - 1 : _index - 1;
    await _loadAndMaybePlay(_index);
  }

  Future<void> _next() async {
    _index = (_index + 1) % _tracks.length;
    await _loadAndMaybePlay(_index);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    
    if (_isMuted) {
      await _audioManager.setVolume(0.0);
    } else {
      await _audioManager.setVolume(1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _isBuffering ? null : _prev,
            icon: Icon(Icons.skip_previous, color: const Color(0xFFFFD700), size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer, color: const Color(0xFFFFD700), size: 14),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _formatDuration(_position),
                      style: GoogleFonts.spaceMono(
                        color: const Color(0xFFFFD700), 
                        fontSize: 11, 
                        fontWeight: FontWeight.bold
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Botón de silenciar/activar sonido
          IconButton(
            onPressed: _toggleMute,
            icon: Icon(
              _isMuted ? Icons.volume_off : Icons.volume_up,
              color: const Color(0xFFFFD700),
              size: 22,
            ),
            tooltip: _isMuted ? 'Activar sonido' : 'Silenciar',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          
          IconButton(
            onPressed: _isBuffering ? null : _next,
            icon: Icon(Icons.skip_next, color: const Color(0xFFFFD700), size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _isPlayingSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _currentTrackSub?.cancel();
    super.dispose();
  }
}
