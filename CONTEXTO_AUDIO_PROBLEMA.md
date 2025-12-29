# CONTEXTO: PROBLEMA DE AUDIO EN REPETICIÓN DE CÓDIGOS

## PROBLEMA
El audio NO se reproduce automáticamente cuando el usuario completa el flujo paso a paso en la pantalla de repetición de códigos (Biblioteca).

## FLUJO ACTUAL

### 1. Usuario inicia repetición
- Archivo: `lib/screens/biblioteca/static_biblioteca_screen.dart`
- El usuario hace clic en "Comenzar Repetición" en el modal de instrucciones
- Navega a `RepetitionSessionScreen`

### 2. RepetitionSessionScreen se inicializa
- Archivo: `lib/screens/codes/repetition_session_screen.dart`
- En `didChangeDependencies()`, se llama a `_startRepetition()` después de que el widget está montado
- `_startRepetition()` activa el flujo paso a paso (`_showSequentialSteps = true`)

### 3. Usuario completa pasos
- El usuario avanza por 6 pasos usando `_nextStep()`
- En el último paso (índice 5), se ejecuta:
  ```dart
  setState(() {
    _showSequentialSteps = false;
    _isRepetitionActive = true;
    _secondsRemaining = 120;
  });
  ```

### 4. Inicio de audio (PROBLEMA AQUÍ)
- Después de `setState`, se espera un frame
- Se llama a `AudioManagerService().playTrack(tracks[0], autoPlay: true)`
- El audio se inicia, PERO `StreamedMusicController` no lo detecta o no se activa

### 5. StreamedMusicController
- Archivo: `lib/widgets/streamed_music_controller.dart`
- Se renderiza con: `StreamedMusicController(autoPlay: _isRepetitionActive, isActive: true)`
- El problema: cuando `_isRepetitionActive` cambia a `true`, el widget ya está renderizado
- `didUpdateWidget` debería detectar el cambio, pero parece que no funciona correctamente

## ARCHIVOS CLAVE

### lib/screens/codes/repetition_session_screen.dart
```dart
// Línea ~265-312: Método _nextStep() donde se inicia el audio
Future<void> _nextStep() async {
  // ... código de pasos ...
  
  // Cuando es el último paso:
  setState(() {
    _showSequentialSteps = false;
    _isRepetitionActive = true;  // <-- Esto debería activar StreamedMusicController
    _secondsRemaining = 120;
  });
  
  await WidgetsBinding.instance.endOfFrame;
  
  // Iniciar audio
  final audioManager = AudioManagerService();
  await audioManager.playTrack(tracks[0], autoPlay: true);
  
  // ... resto del código ...
}

// Línea ~1173: Renderizado de StreamedMusicController
StreamedMusicController(autoPlay: _isRepetitionActive, isActive: true),
```

### lib/widgets/streamed_music_controller.dart
```dart
// Línea ~42-54: initState
@override
void initState() {
  super.initState();
  _syncWithExistingPlayback();
  _wireListeners();
  if (widget.isActive && widget.autoPlay) {
    _showVolumeMessageOnFirstPlay();
    _loadAndMaybePlay(_index);
  }
}

// Línea ~57-63: didUpdateWidget (PROBLEMA POTENCIAL)
@override
void didUpdateWidget(StreamedMusicController oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (widget.isActive && !oldWidget.isActive) {
    _showVolumeMessageOnFirstPlay();
    _loadAndMaybePlay(_index);
  }
  // ⚠️ NO detecta cuando autoPlay cambia de false a true si isActive ya era true
}
```

### lib/services/audio_manager_service.dart
```dart
// Línea ~52-73: Método playTrack
Future<void> playTrack(String trackFile, {bool autoPlay = true}) async {
  await stop();
  
  if (_stateSub == null) {
    _initializeListeners();
  }
  
  try {
    _currentTrack = trackFile;
    _currentTrackController.add(_currentTrack);
    
    await _globalPlayer.setSource(AssetSource(trackFile.replaceFirst('assets/', '')));
    
    if (autoPlay) {
      await _globalPlayer.resume();  // <-- Esto debería iniciar el audio
    }
  } catch (e) {
    print('Error reproduciendo audio: $e');
  }
}
```

## POSIBLES CAUSAS

1. **Timing Issue**: `StreamedMusicController` se renderiza antes de que `_isRepetitionActive` sea `true`
2. **didUpdateWidget no detecta cambio**: Cuando `autoPlay` cambia de `false` a `true` pero `isActive` ya era `true`, `didUpdateWidget` no se activa correctamente
3. **AudioManagerService no notifica**: El audio se inicia pero `StreamedMusicController` no escucha los eventos
4. **Widget no se reconstruye**: Después de `setState`, el widget no se reconstruye correctamente

## SOLUCIONES INTENTADAS

1. ✅ Agregar `setState()` después de iniciar audio
2. ✅ Esperar múltiples frames con `endOfFrame`
3. ✅ Mejorar `didUpdateWidget` para detectar cambios en `autoPlay`
4. ✅ Sincronizar con playback existente

## ARCHIVOS COMPLETOS PARA ANÁLISIS

Los siguientes archivos contienen el código completo relacionado:

1. `lib/screens/codes/repetition_session_screen.dart` - Pantalla principal de repetición
2. `lib/widgets/streamed_music_controller.dart` - Widget del controlador de audio
3. `lib/services/audio_manager_service.dart` - Servicio de gestión de audio
4. `lib/screens/biblioteca/static_biblioteca_screen.dart` - Pantalla de biblioteca que navega a repetición

## INSTRUCCIONES PARA CHATGPT

Por favor, analiza estos archivos y determina por qué el audio no se reproduce automáticamente cuando:
1. El usuario completa el flujo paso a paso
2. `_isRepetitionActive` cambia a `true`
3. `AudioManagerService().playTrack()` se llama con `autoPlay: true`
4. `StreamedMusicController` está renderizado con `autoPlay: _isRepetitionActive, isActive: true`

El problema parece ser que `StreamedMusicController` no detecta que debe iniciar la reproducción cuando `autoPlay` cambia de `false` a `true` después de que el widget ya está montado.

