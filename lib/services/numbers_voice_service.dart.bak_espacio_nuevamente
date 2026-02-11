import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

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

  static const Duration _microPause = Duration(milliseconds: 580);
  static const Duration _betweenCyclesPause = Duration(seconds: 4);
  /// Pausa entre cada número para que no suenen pegados.
  static const Duration _gapBetweenDigits = Duration(milliseconds: 160);
  /// Duración por dígito cuando no se puede usar onPlayerComplete (p. ej. web).
  /// Suficiente para que el clip termine antes del siguiente y no se pisen.
  static const Duration _digitDurationFallback = Duration(milliseconds: 1300);
  /// Espera mínima por dígito para que se oiga antes de pasar al siguiente.
  static const Duration _minDigitWait = Duration(milliseconds: 500);

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

    // En Android: pedir "transient may duck" para que la música siga sonando (reducida) y no se pare.
    await _voicePlayer.setAudioContext(AudioContext(
      android: AudioContextAndroid(audioFocus: AndroidAudioFocus.gainTransientMayDuck),
    ));
    await _voicePlayer.setVolume(1.0);
    await AudioManagerService().setVolume(0.4);

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
      await _voicePlayer.stop();
      if (kIsWeb) {
        // Web: BytesSource evita problemas de Content-Type con assets.
        final path = 'assets/audios/voice_numbers/$gender/$digit.mp3';
        final data = await rootBundle.load(path);
        final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await _voicePlayer.setSource(BytesSource(bytes));
      } else {
        // Android/iOS: AssetSource con path sin prefijo "assets/" (lo añade el plugin).
        final path = 'audios/voice_numbers/$gender/$digit.mp3';
        await _voicePlayer.setSource(AssetSource(path));
      }
      await _voicePlayer.resume();

      // Mismo timing en todas las plataformas: onPlayerComplete no es fiable en web ni en algunos Android.
      await _waitUntilPlaying(const Duration(milliseconds: 800));
      await Future.delayed(_digitDurationFallback);
      await _voicePlayer.stop();
      await Future.delayed(_gapBetweenDigits);
    } catch (_) {}
    if (!_sessionActive || localSessionId != _sessionId) return;
  }

  /// Espera a que el reproductor esté en [PlayerState.playing] o [timeout].
  /// Evita contar el retraso antes de que el clip empiece en web.
  Future<void> _waitUntilPlaying(Duration timeout) async {
    if (_voicePlayer.state == PlayerState.playing) return;
    try {
      await _voicePlayer.onPlayerStateChanged
          .firstWhere((s) => s == PlayerState.playing)
          .timeout(timeout, onTimeout: () => PlayerState.stopped);
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 50));
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
