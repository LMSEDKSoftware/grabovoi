import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

class StreamedMusicController extends StatefulWidget {
  final bool autoPlay;
  const StreamedMusicController({super.key, this.autoPlay = true});

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

  late final AudioPlayer _player;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;

  int _index = 0;
  bool _isBuffering = true;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _wireListeners();
    _loadAndMaybePlay(_index);
  }

  void _wireListeners() {
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() {
        _isPlaying = s == PlayerState.playing;
      });
    });
    _posSub = _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
    _durSub = _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
    });
  }

  Future<void> _loadAndMaybePlay(int i) async {
    setState(() {
      _isBuffering = true;
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
    });

    final file = _tracks[i]['file']!;
    // Precarga estilo streaming: setSource y espera duración
    await _player.stop();
    await _player.setSource(AssetSource(file.replaceFirst('assets/', '')));

    // Esperar a que tengamos duración (hasta 2.5s)
    for (int t = 0; t < 25 && (_duration == Duration.zero); t++) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;
    setState(() => _isBuffering = false);

    if (widget.autoPlay) {
      await _player.resume();
    }
  }

  Future<void> _prev() async {
    _index = (_index - 1) < 0 ? _tracks.length - 1 : _index - 1;
    await _loadAndMaybePlay(_index);
  }

  Future<void> _next() async {
    _index = (_index + 1) % _tracks.length;
    await _loadAndMaybePlay(_index);
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))} s';
    }

  @override
  Widget build(BuildContext context) {
    final title = _tracks[_index]['title']!;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.music_note, color: const Color(0xFFFFD700), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Música Energizante',
                  style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isPlaying ? const Color(0xFFFFD700) : Colors.grey.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          if (_isBuffering)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFFFFD700))),
                  ),
                  const SizedBox(width: 8),
                  Text('Precargando audio...', style: GoogleFonts.spaceMono(color: const Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer, color: const Color(0xFFFFD700), size: 16),
                  const SizedBox(width: 6),
                  Text(_fmt(_position), style: GoogleFonts.spaceMono(color: const Color(0xFFFFD700), fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _isBuffering ? null : _prev,
                icon: Icon(Icons.skip_previous, color: const Color(0xFFFFD700), size: 32),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow, color: const Color(0xFFFFD700), size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text('Auto', style: GoogleFonts.spaceMono(color: const Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: _isBuffering ? null : _next,
                icon: Icon(Icons.skip_next, color: const Color(0xFFFFD700), size: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _player.stop();
    _player.dispose();
    super.dispose();
  }
}

