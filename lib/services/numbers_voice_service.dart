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
  /// Pausa antes de "nuevamente" para que quede en medio del tiempo entre repeticiones.
  static const Duration _pauseBeforeNuevamente = Duration(milliseconds: 1800);
  /// Pausa después de "nuevamente" antes de la siguiente repetición.
  static const Duration _pauseAfterNuevamente = Duration(milliseconds: 1800);
  /// Espera inicial para que la música comience antes de la repetición guiada.
  static const Duration _initialDelay = Duration(seconds: 2);
  /// Pausa entre cada número (un poco más de espacio).
  static const Duration _gapBetweenDigits = Duration(milliseconds: 280);
  /// Silencios pequeños antes y después de espacio.mp3.
  static const Duration _silenceAroundEspacio = Duration(milliseconds: 100);
  /// Duración por dígito cuando no se puede usar onPlayerComplete (p. ej. web).
  static const Duration _digitDurationFallback = Duration(milliseconds: 1300);
  /// Duración aproximada para clip "espacio" o "nuevamente" (por si no hay onComplete fiable).
  static const Duration _namedClipDurationFallback = Duration(milliseconds: 1200);
  static const Duration _nuevamenteClipDurationFallback = Duration(milliseconds: 2200);
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
      // 1. Esperar para que la música comience antes de la repetición guiada
      await Future.delayed(_initialDelay);
      if (!_sessionActive || localSessionId != _sessionId) return;

      final endAt = DateTime.now().add(sessionDuration);
      while (_sessionActive &&
          DateTime.now().isBefore(endAt) &&
          localSessionId == _sessionId) {
        for (final token in tokens) {
          if (!_sessionActive || localSessionId != _sessionId) break;
          if (token == '_') {
            await _playNamedClip('espacio', gender, localSessionId);
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
        // 4. Nuevamente "en medio" del tiempo entre repeticiones: pausa -> nuevamente -> pausa
        await Future.delayed(_pauseBeforeNuevamente);
        if (!_sessionActive || localSessionId != _sessionId) break;
        await _playNamedClip('nuevamente', gender, localSessionId);
        await Future.delayed(_pauseAfterNuevamente);
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
        final path = 'assets/audios/voice_numbers/$gender/$digit.mp3';
        final data = await rootBundle.load(path);
        final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await _voicePlayer.setSource(BytesSource(bytes));
      } else {
        final path = 'audios/voice_numbers/$gender/$digit.mp3';
        await _voicePlayer.setSource(AssetSource(path));
      }
      await _voicePlayer.resume();

      await _waitUntilPlaying(const Duration(milliseconds: 800));
      await Future.delayed(_digitDurationFallback);
      await _voicePlayer.stop();
      await Future.delayed(_gapBetweenDigits);
    } catch (_) {}
    if (!_sessionActive || localSessionId != _sessionId) return;
  }

  /// Reproduce un clip por nombre (ej. espacio.mp3, nuevamente.mp3) en voice_numbers/[gender]/.
  Future<void> _playNamedClip(String name, String gender, int localSessionId) async {
    if (!_sessionActive || localSessionId != _sessionId) return;
    try {
      // 3. Para espacio.mp3: silencios pequeños antes y después
      if (name == 'espacio') {
        await Future.delayed(_silenceAroundEspacio);
        if (!_sessionActive || localSessionId != _sessionId) return;
      }

      await _voicePlayer.stop();
      final fileName = '$name.mp3';
      if (kIsWeb) {
        final path = 'assets/audios/voice_numbers/$gender/$fileName';
        final data = await rootBundle.load(path);
        final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await _voicePlayer.setSource(BytesSource(bytes));
      } else {
        final path = 'audios/voice_numbers/$gender/$fileName';
        await _voicePlayer.setSource(AssetSource(path));
      }
      await _voicePlayer.resume();

      final duration = name == 'nuevamente' ? _nuevamenteClipDurationFallback : _namedClipDurationFallback;
      await _waitUntilPlaying(const Duration(milliseconds: 800));
      await Future.delayed(duration);
      await _voicePlayer.stop();

      if (name == 'espacio') {
        await Future.delayed(_silenceAroundEspacio);
      } else if (name != 'nuevamente') {
        await Future.delayed(_gapBetweenDigits);
      }
    } catch (_) {}
    if (!_sessionActive || localSessionId != _sessionId) return;
  }

  Future<void> _waitUntilPlaying(Duration timeout) async {
    if (_voicePlayer.state == PlayerState.playing) return;
    try {
      await _voicePlayer.onPlayerStateChanged
          .firstWhere((s) => s == PlayerState.playing)
          .timeout(timeout, onTimeout: () => PlayerState.stopped);
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 50));
  }

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
