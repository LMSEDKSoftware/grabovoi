import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/audio_manager_service.dart';

class StreamedMusicController extends StatefulWidget {
  final bool autoPlay;
  final bool isActive; // Nuevo parámetro para controlar si está activo
  const StreamedMusicController({super.key, this.autoPlay = false, this.isActive = false});

  @override
  State<StreamedMusicController> createState() => _StreamedMusicControllerState();
}

class _StreamedMusicControllerState extends State<StreamedMusicController> {
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
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _wireListeners();
    // Solo cargar y reproducir si está activo y autoPlay está habilitado
    if (widget.isActive && widget.autoPlay) {
      _loadAndMaybePlay(_index);
    }
  }

  @override
  void didUpdateWidget(StreamedMusicController oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el widget se activa, iniciar reproducción
    if (widget.isActive && !oldWidget.isActive) {
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

  Future<void> _loadAndMaybePlay(int i) async {
    if (!mounted) return;
    
    setState(() {
      _isBuffering = true;
    });

    final file = _tracks[i]['file']!;
    
    // Usar el servicio global de audio
    await _audioManager.playTrack(file, autoPlay: widget.isActive && widget.autoPlay);
    
    if (!mounted) return;
    setState(() => _isBuffering = false);
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

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))} s';
    }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          // Botón anterior
          IconButton(
            onPressed: _isBuffering ? null : _prev,
            icon: Icon(Icons.skip_previous, color: const Color(0xFFFFD700), size: 28),
          ),
          
          // Tiempo transcurrido
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer, color: const Color(0xFFFFD700), size: 16),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(_position),
                  style: GoogleFonts.spaceMono(
                    color: const Color(0xFFFFD700), 
                    fontSize: 12, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),
          
          // Botón siguiente
          IconButton(
            onPressed: _isBuffering ? null : _next,
            icon: Icon(Icons.skip_next, color: const Color(0xFFFFD700), size: 28),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isPlayingSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _currentTrackSub?.cancel();
    super.dispose();
  }
}

