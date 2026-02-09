import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../utils/code_voice_tokens.dart';
import 'audio_manager_service.dart';

/// Servicio de voz numérica: reproduce la secuencia dígito a dígito durante pilotaje/repetición.
/// Usa un AudioPlayer dedicado (audioplayers); no comparte con la música.
class NumbersVoiceService {
  static final NumbersVoiceService _instance = NumbersVoiceService._internal();
  factory NumbersVoiceService() => _instance;
  NumbersVoiceService._internal();

  final AudioPlayer _voicePlayer = AudioPlayer();
  bool _sessionActive = false;
  int _sessionId = 0;

  static const Duration _microPause = Duration(milliseconds: 450);
  static const Duration _betweenCyclesPause = Duration(seconds: 4);

  /// Inicia la sesión de voz (loop hasta sessionDuration o cancelación).
  /// Si [enabled] es false, no hace nada.
  Future<void> startSession({
    required String code,
    required bool enabled,
    required String gender,
    required Duration sessionDuration,
  }) async {
    if (!enabled) return;
    final tokens = voiceTokensFromCode(code);
    if (tokens.isEmpty) return;

    _sessionActive = true;
    final localSessionId = ++_sessionId;

    // Ducking: bajar volumen de la música
    await AudioManagerService().setVolume(0.55);

    Future<void> runLoop() async {
      final endAt = DateTime.now().add(sessionDuration);
      while (_sessionActive &&
          DateTime.now().isBefore(endAt) &&
          localSessionId == _sessionId) {
        for (final token in tokens) {
          if (!_sessionActive || localSessionId != _sessionId) break;
          if (token == '_') {
            await Future.delayed(_microPause);
          } else {
            final digit = token;
            if (digit.length == 1 &&
                digit.compareTo('0') >= 0 &&
                digit.compareTo('9') <= 0) {
              await _playDigit(digit, gender, localSessionId);
            }
          }
        }
        if (!_sessionActive || localSessionId != _sessionId) break;
        await Future.delayed(_betweenCyclesPause);
      }
      if (localSessionId == _sessionId) {
        await AudioManagerService().setVolume(1.0);
      }
    }

    runLoop();
  }

  Future<void> _playDigit(String digit, String gender, int localSessionId) async {
    if (!_sessionActive || localSessionId != _sessionId) return;
    try {
      final path = 'audios/voice_numbers/$gender/$digit.mp3';
      await _voicePlayer.setSource(AssetSource(path));
      await _voicePlayer.resume();
      await _voicePlayer.onPlayerComplete.first
          .timeout(const Duration(seconds: 5), onTimeout: (_) {});
    } catch (_) {}
    if (!_sessionActive || localSessionId != _sessionId) return;
  }

  /// Detiene la sesión de voz de inmediato y restaura volumen de música.
  Future<void> stopSession() async {
    _sessionActive = false;
    _sessionId++;
    try {
      await _voicePlayer.stop();
    } catch (_) {}
    await AudioManagerService().setVolume(1.0);
  }

  Future<void> dispose() async {
    await stopSession();
    await _voicePlayer.dispose();
  }
}
