import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../utils/share_helper.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/golden_sphere.dart';
import '../../widgets/streamed_music_controller.dart';
import '../../widgets/session_tools_block.dart';
import '../../widgets/illuminated_code_text.dart';
import '../../widgets/custom_button.dart';
import '../../utils/code_formatter.dart';
import '../../services/challenge_progress_tracker.dart';
import '../../services/supabase_service.dart';
import '../../models/supabase_models.dart';
import '../../repositories/codigos_repository.dart';
import '../../services/biblioteca_supabase_service.dart';
import '../../services/audio_manager_service.dart';
import '../../services/numbers_voice_service.dart';
import '../../services/pilotage_state_service.dart';
import '../../widgets/sequencia_activada_modal.dart';
import '../../services/rewards_service.dart';
import '../../services/user_custom_codes_service.dart';
import '../../services/user_favorites_service.dart';
import '../diario/track_code_modal.dart';
import '../diario/nueva_entrada_diario_screen.dart';


class RepetitionSessionScreen extends StatefulWidget {
  final String codigo;
  final String? nombre;
  /// Si no es null, se acaba de guardar un pilotaje manual y se muestra un aviso
  /// indicando que la secuencia está en Favoritos con este nombre.
  final String? nombrePilotajeManualEnFavoritos;

  const RepetitionSessionScreen({
    super.key,
    required this.codigo,
    this.nombre,
    this.nombrePilotajeManualEnFavoritos,
  });

  @override
  State<RepetitionSessionScreen> createState() => _RepetitionSessionScreenState();
}

class _RepetitionSessionScreenState extends State<RepetitionSessionScreen> 
    with TickerProviderStateMixin {
  final ScreenshotController _screenshotController = ScreenshotController();
  
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  
  bool _isRepetitionActive = false;
  int _secondsRemaining = 120; // 2 minutos en segundos
  int _musicControllerKeySeed = 0;

  late Future<Map<String, dynamic>> _codigoInfoFuture;
  late Future<Map<String, String>> _shareableDataFuture;
  
  // Variables para el selector de colores (igual que en quantum_pilotage_screen)
  String _colorSeleccionado = 'dorado';
  final Map<String, Color> _coloresDisponibles = {
    'dorado': const Color(0xFFFFD700),
    'plateado': const Color(0xFFC0C0C0),
    'azul': const Color(0xFF87CEEB),
    'blanco': const Color(0xFFFFFFFF),
  };
  
  // Variables para la animación de la barra de colores
  bool _isColorBarExpanded = true;
  
  // Modo de concentración
  bool _isConcentrationMode = false;
  late AnimationController _colorBarController;
  late Animation<Offset> _colorBarAnimation;
  
  // Estado de favorito
  bool _esFavorito = false;
  bool _esCodigoPersonalizado = false;
  Future<void>? _favoritoFuture;

  bool _hasStartedRepetition = false; // Bandera para evitar múltiples llamadas
  bool _mostradoAvisoPilotajeManual = false;

  /// Voz numérica: estado local sincronizado con RewardsService (encender/apagar en sesión).
  bool _voiceNumbersEnabled = false;
  /// Si el usuario tiene adquirida la repetición guiada en la tienda cuántica (muestra u oculta la card).
  bool _hasGuidedRepetition = false;
  String _voiceGender = 'female';

  // Sistema de Steps Secuenciales (igual que en pilotaje)
  bool _showSequentialSteps = false;
  int _currentStepIndex = 0;
  List<bool> _stepCompleted = [false, false, false, false, false, false];
  String _intencionPersonal = '';
  TextEditingController _intencionPersonalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _codigoInfoFuture = _loadCodigoInfo();
    _shareableDataFuture = _loadShareableData();
    _favoritoFuture = _verificarFavorito();
    _loadVoiceNumbersPreference();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutCubic),
    );

    _colorBarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _colorBarAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.3, 0),
    ).animate(CurvedAnimation(
      parent: _colorBarController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadVoiceNumbersPreference() async {
    try {
      final rewards = await RewardsService().getUserRewards();
      if (mounted) {
        setState(() {
          _voiceNumbersEnabled = rewards.voiceNumbersEnabled;
          _hasGuidedRepetition = rewards.logros['voice_numbers_unlocked'] == true ||
              rewards.voiceNumbersEnabled == true;
          _voiceGender = rewards.voiceGender == 'male' ? 'male' : 'female';
        });
      }
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar estado de favoritos cuando la pantalla se vuelve visible
    // Esto asegura que si se guardó un código personalizado, se muestre el botón de favoritos
    _verificarFavorito();
    
    // Iniciar la repetición directamente después de que el widget esté completamente montado
    // Solo una vez, usando la bandera _hasStartedRepetition
    if (!_hasStartedRepetition) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasStartedRepetition) {
          _hasStartedRepetition = true;
          _startRepetition();
        }
        // Aviso central: secuencia de pilotaje manual guardada, disponible en Favoritos
        if (mounted && !_mostradoAvisoPilotajeManual && widget.nombrePilotajeManualEnFavoritos != null) {
          _mostradoAvisoPilotajeManual = true;
          _mostrarAvisoPilotajeManualEnFavoritos();
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _colorBarController.dispose();
    _intencionPersonalController.dispose();
    super.dispose();
  }

  /// Muestra un aviso central: la secuencia se generó solo para este usuario
  /// y está disponible en Favoritos con el nombre que le puso el usuario.
  Future<void> _mostrarAvisoPilotajeManualEnFavoritos() async {
    if (!mounted || widget.nombrePilotajeManualEnFavoritos == null) return;
    final nombre = widget.nombrePilotajeManualEnFavoritos!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFFD700), width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFFFFD700), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Secuencia guardada',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Esta secuencia se generó solo para ti.\n\n'
          'Está disponible en la sección Favoritos con el nombre:\n«$nombre»',
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Entendido',
              style: GoogleFonts.inter(
                color: const Color(0xFFFFD700),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startRepetition() async {
    // Verificar si ya se otorgaron recompensas antes de iniciar
    final rewardsService = RewardsService();
    final yaOtorgadas = await rewardsService.yaSeOtorgaronRecompensas(
      codigoId: widget.codigo,
      tipoAccion: 'repeticion',
    );

    // Si ya se otorgaron recompensas, mostrar diálogo de confirmación
    if (yaOtorgadas && mounted) {
      final continuar = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1C2541),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFFFD700), width: 2),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFFFFD700),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Recompensas ya otorgadas',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Ya recibiste cristales por esta secuencia hoy. Puedes seguir usándola, pero no recibirás más recompensas.\n\n¿Deseas continuar?',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancelar',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Continuar',
                style: GoogleFonts.inter(
                  color: const Color(0xFF1a1a2e),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      // Si el usuario cancela, no iniciar la repetición
      if (continuar != true) {
        Navigator.of(context).pop(); // Volver atrás
        return;
      }
    }

    // Iniciar el flujo de Steps secuenciales antes de la repetición
    if (mounted) {
      setState(() {
        _showSequentialSteps = true;
        _currentStepIndex = 0;
        _stepCompleted = [false, false, false, false, false, false];
      });
    }
  }
  
  

  Future<void> _nextStep() async {
    // Si estamos en el paso de intención personal (índice 5), guardar la intención antes de continuar
    if (_currentStepIndex == 5) {
      setState(() {
        _intencionPersonal = _intencionPersonalController.text;
      });
    }
    
    if (_currentStepIndex < 5) {
      // Avanzar al siguiente paso
      setState(() {
        _stepCompleted[_currentStepIndex] = true;
        _currentStepIndex++;
      });
    } else {
      // Completar el último paso y activar repetición
      await _iniciarRepeticion();
    }
  }

  Future<void> _iniciarRepeticion() async {
    setState(() {
      _stepCompleted[_currentStepIndex] = true;
      _isRepetitionActive = true;
      _showSequentialSteps = false;
      _secondsRemaining = 120; // 2 minutos
      _musicControllerKeySeed++;
    });
    
    // Esperar un frame para asegurar que el UI se actualice
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        // Iniciar audio automáticamente
        try {
          final audioManager = AudioManagerService();
          final tracks = [
            'assets/audios/432hz_harmony.mp3',
            'assets/audios/528hz_love.mp3',
            'assets/audios/binaural_manifestation.mp3',
            'assets/audios/crystal_bowls.mp3',
            'assets/audios/forest_meditation.mp3',
          ];
          await audioManager.playTrack(tracks[0], autoPlay: true);
          debugPrint('✅ Audio iniciado automáticamente');
          
          // Voz numérica (Premium): si está habilitada, iniciar sesión de voz
          try {
            final rewards = await RewardsService().getUserRewards();
            if (mounted) {
              setState(() {
                _voiceNumbersEnabled = rewards.voiceNumbersEnabled;
                _hasGuidedRepetition = rewards.logros['voice_numbers_unlocked'] == true ||
                    rewards.voiceNumbersEnabled == true;
                _voiceGender = rewards.voiceGender == 'male' ? 'male' : 'female';
              });
            }
            if (rewards.voiceNumbersEnabled) {
              NumbersVoiceService().startSession(
                code: widget.codigo,
                enabled: true,
                gender: rewards.voiceGender,
                sessionDuration: const Duration(minutes: 2),
              );
            }
          } catch (_) {}
          
          // Forzar rebuild para que StreamedMusicController detecte el audio
          if (mounted) {
            setState(() {});
          }
        } catch (e) {
          debugPrint('❌ Error iniciando audio: $e');
        }
        
        // Notificar al servicio global
        PilotageStateService().setRepetitionActive(true);
        
        // NO registrar aquí: solo se registra codigoRepetido al FINALIZAR los 2 min
        // cuando se entregan los cristales (en _registrarRepeticionYMostrarRecompensas)

        // Ocultar la barra de colores después de 3 segundos
        _hideColorBarAfterDelay();
        // Iniciar el temporizador de 2 minutos
        _startCountdown();
      }
    });
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
        _startCountdown();
      } else {
        setState(() {
          _isRepetitionActive = false;
        });
        
        // Notificar al servicio global
        PilotageStateService().setRepetitionActive(false);
        
        // Detener voz numérica y música
        try {
          NumbersVoiceService().stopSession();
        } catch (_) {}
        try {
          AudioManagerService().stop();
        } catch (_) {}
        
        // Registrar repetición y obtener recompensas
        _registrarRepeticionYMostrarRecompensas();
      }
    });
  }

  /// Toggle de repetición guiada solo para esta sesión: apaga/enciende la reproducción de voz
  /// para esta secuencia. No modifica la configuración global (esa solo se cambia en Ajustes).
  /// Si en configuración está encendido, la próxima secuencia comenzará de nuevo con voz activa.
  Future<void> _toggleVoiceNumbers() async {
    final newValue = !_voiceNumbersEnabled;
    setState(() => _voiceNumbersEnabled = newValue);
    if (!mounted) return;
    if (_isRepetitionActive) {
      if (newValue) {
        NumbersVoiceService().startSession(
          code: widget.codigo,
          enabled: true,
          gender: _voiceGender,
          sessionDuration: Duration(seconds: _secondsRemaining),
        );
      } else {
        NumbersVoiceService().stopSession();
      }
    }
  }

  /// Solo el contenido del toggle (Row) para usar dentro del bloque unificado.
  Widget _buildVoiceNumbersToggleContent() {
    final color = _getColorSeleccionado();
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.record_voice_over,
          color: _voiceNumbersEnabled ? color : Colors.white54,
          size: 24,
        ),
        const SizedBox(width: 10),
        Text(
          'Repetición guiada',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _voiceNumbersEnabled ? color : Colors.white70,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          _voiceNumbersEnabled ? Icons.toggle_on : Icons.toggle_off,
          color: _voiceNumbersEnabled ? color : Colors.white38,
          size: 32,
        ),
      ],
    );
  }

  Widget _buildVoiceNumbersToggle() {
    final color = _getColorSeleccionado();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleVoiceNumbers,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (_voiceNumbersEnabled ? color : color.withOpacity(0.35)).withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildVoiceNumbersToggleContent(),
        ),
      ),
    );
  }

  // Removed _formatCodeForDisplay method - now using CodeFormatter

  Future<void> _copyCodeInfo() async {
    try {
      // Usar los datos ya cargados en _codigoInfoFuture (sin consultas adicionales)
      final codigoInfo = await _codigoInfoFuture;
      final titulo = codigoInfo['titulo'] as String? ?? widget.nombre ?? 'Secuencia Cuántica';
      final descripcion = codigoInfo['descripcion'] as String? ?? 'Secuencia cuántica para la manifestación y transformación energética.';
      
      final textToCopy = '''${widget.codigo} : $titulo
$descripcion
Obtuve esta información en la app: ManiGraB - Manifestaciones Numéricas''';
      
      await Clipboard.setData(ClipboardData(text: textToCopy));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Secuencia ${widget.codigo} copiada con descripción'),
            backgroundColor: const Color(0xFFFFD700),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Fallback si hay error - usar datos básicos
      final titulo = widget.nombre ?? 'Secuencia Cuántica';
      final textToCopy = '''${widget.codigo} : $titulo
Esta secuencia ayuda a manifestar la abundancia de alimentos necesarios para una nutrición adecuada y equilibrada en la vida diaria.
Obtuve esta información en la app: ManiGraB - Manifestaciones Numéricas''';
      
      await Clipboard.setData(ClipboardData(text: textToCopy));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Secuencia ${widget.codigo} copiada'),
            backgroundColor: const Color(0xFFFFD700),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  Future<void> _shareImage() async {
    try {
      // Esperar a que el widget se renderice completamente
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Forzar rebuild para asegurar que el widget oculto esté renderizado
      if (mounted) {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      // Capturar la imagen del widget oculto
      final Uint8List? pngBytes = await _screenshotController.capture(pixelRatio: 2.0);
      
      if (pngBytes == null || pngBytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No se pudo generar la imagen. Intenta nuevamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Usar el helper para compartir la imagen (maneja iOS correctamente)
      await ShareHelper.shareImage(
        pngBytes: pngBytes,
        fileName: 'grabovoi_${widget.codigo}',
        text: 'Compartido desde ManiGraB - Manifestaciones Cuánticas Grabovoi',
        context: context,
      );

      ChallengeProgressTracker().trackPilotageShared(
        codeId: widget.codigo,
        codeName: widget.nombre ?? widget.codigo,
      );
    } catch (e) {
      debugPrint('Error al compartir imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Función helper para obtener la descripción del código desde la base de datos
  // Primero busca en códigos personalizados, luego en la base central
  Future<String> _getCodigoDescription() async {
    try {
      // 1. Buscar primero en códigos personalizados del usuario
      final customCodesService = UserCustomCodesService();
      final isCustom = await customCodesService.isCustomCode(widget.codigo);
      
      if (isCustom) {
        final customCodes = await customCodesService.getUserCustomCodes();
        final customCode = customCodes.firstWhere(
          (c) => c.codigo == widget.codigo,
          orElse: () => CodigoGrabovoi(
            id: '',
            codigo: widget.codigo,
            nombre: '',
            descripcion: '',
            categoria: '',
            color: '#FFD700',
          ),
        );
        if (customCode.descripcion.isNotEmpty) {
          return customCode.descripcion;
        }
      }
      
      // 2. Si no es personalizado o no tiene descripción, buscar en la base central
      return CodigosRepository().getDescripcionByCode(widget.codigo);
    } catch (e) {
      // 3. Si falla, usar el nombre pasado como parámetro o texto por defecto
      if (widget.nombre != null && widget.nombre!.isNotEmpty) {
        return widget.nombre!;
      }
      return 'Secuencia cuántica para la manifestación y transformación energética.';
    }
  }

  // Función helper para obtener el título del código desde la base de datos
  // Primero busca en códigos personalizados, luego en la base central
  Future<String> _getCodigoTitulo() async {
    try {
      // 1. Buscar primero en códigos personalizados del usuario
      final customCodesService = UserCustomCodesService();
      final isCustom = await customCodesService.isCustomCode(widget.codigo);
      
      if (isCustom) {
        final customCodes = await customCodesService.getUserCustomCodes();
        final customCode = customCodes.firstWhere(
          (c) => c.codigo == widget.codigo,
          orElse: () => CodigoGrabovoi(
            id: '',
            codigo: widget.codigo,
            nombre: '',
            descripcion: '',
            categoria: '',
            color: '#FFD700',
          ),
        );
        if (customCode.nombre.isNotEmpty) {
          return customCode.nombre;
        }
      }
      
      // 2. Si no es personalizado o no tiene nombre, buscar en la base central
      return CodigosRepository().getTituloByCode(widget.codigo);
    } catch (e) {
      // 3. Si falla, usar el nombre pasado como parámetro o texto por defecto
      if (widget.nombre != null && widget.nombre!.isNotEmpty) {
        return widget.nombre!;
      }
      return 'Campo Energético';
    }
  }

  void _stopActiveRepetition() {
    setState(() {
      _isRepetitionActive = false;
    });
    
    // Notificar al servicio global
    PilotageStateService().setRepetitionActive(false);
    
    // Detener voz numérica y música
    try {
      NumbersVoiceService().stopSession();
    } catch (_) {}
    AudioManagerService().stop();
  }

  Future<void> _handleBackNavigation() async {
    // Verificar si hay repetición activa
    if (_isRepetitionActive) {
      final result = await _showRepetitionActiveDialog();
      if (result == true) {
        // Usuario confirmó, mostrar mensaje de cancelación primero
        if (context.mounted) {
          _mostrarMensajeCancelacion();
        }
      }
    } else {
      // No hay repetición activa, permitir pop
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<bool?> _showRepetitionActiveDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C2541),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFFFD700), width: 2),
          ),
          title: Row(
            children: [
              const Icon(Icons.music_off, color: Color(0xFFFFD700), size: 24),
              const SizedBox(width: 12),
              Text(
                'Repetición Activa',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que deseas abandonar la sesión de repetición y detener la música?',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancelar
              },
              child: Text(
                'Cancelar',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _stopActiveRepetition();
                Navigator.of(context).pop(true); // Confirmar
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Sí, Abandonar',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _mostrarMensajeCancelacion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
        ),
        title: Row(
          children: [
            Icon(
              Icons.pause_circle,
              color: const Color(0xFFFF6B6B),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Repetición Cancelada',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Has cancelado la sesión de repetición.',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6B6B).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '⚠️ Sesión interrumpida',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFF6B6B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Para obtener mejores resultados, se recomienda completar la sesión completa de 2 minutos.',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          CustomButton(
            text: 'Entendido',
            onPressed: () {
              Navigator.of(context).pop();
              // Después de cerrar este mensaje, mostrar el segundo mensaje
              if (context.mounted) {
                _mostrarMensajePuedeSalir();
              }
            },
            color: const Color(0xFFFF6B6B),
          ),
        ],
      ),
    );
  }

  void _mostrarMensajePuedeSalir() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFFD700), width: 2),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: Color(0xFFFFD700),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Listo para Salir',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Ahora puedes salir de la sesión dando clic en el botón "Volver".',
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          CustomButton(
            text: 'Entendido',
            onPressed: () {
              Navigator.of(context).pop();
            },
            color: const Color(0xFFFFD700),
          ),
        ],
      ),
    );
  }

  @override
  Widget _buildSequentialStepCard() {
    final steps = [
      {
        'title': 'Preparación de la Conciencia',
        'description': 'Cierra los ojos, respira... conecta con la Norma.',
        'icon': Icons.self_improvement,
        'color': Colors.green,
      },
      {
        'title': 'Visualización Activa',
        'description': 'Visualiza la secuencia dentro de una esfera luminosa.',
        'icon': Icons.visibility,
        'color': Colors.blue,
      },
      {
        'title': 'Emisión del Pensamiento Dirigido',
        'description': 'Enfoca tu intención y emítela al campo cuántico.',
        'icon': Icons.psychology,
        'color': Colors.purple,
      },
      {
        'title': 'Repetición Consciente',
        'description': 'Repite la secuencia 3 veces sintiendo la vibración. Recuerda que 2 minutos continuos con intención son de gran ayuda para el pilotaje cuántico.',
        'icon': Icons.repeat,
        'color': Colors.orange,
      },
      {
        'title': 'Cierre Energético',
        'description': 'Agradece y sella la intención en el campo cuántico.',
        'icon': Icons.check_circle,
        'color': Colors.teal,
      },
      {
        'title': 'Intención Personal',
        'description': '¿Qué deseas armonizar con esta secuencia?',
        'icon': Icons.edit,
        'color': Colors.amber,
        'hasTextField': true,
      },
    ];

    final currentStepData = steps[_currentStepIndex];
    final isCompleted = _stepCompleted[_currentStepIndex];

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5), // Fondo semi-transparente
        child: Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: -1.0, end: 0.0),
            curve: Curves.easeOutCubic,
            builder: (context, slideValue, child) {
              return Transform.translate(
                offset: Offset(slideValue * MediaQuery.of(context).size.width, 0),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: slideValue > -0.8 ? 1.0 : 0.0,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          currentStepData['color'] as Color,
                          (currentStepData['color'] as Color).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (currentStepData['color'] as Color).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icono del paso
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            currentStepData['icon'] as IconData,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Título del paso
                        Text(
                          currentStepData['title'] as String,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Descripción del paso
                        Text(
                          currentStepData['description'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Campo de texto para el paso de intención
                        if (currentStepData['hasTextField'] == true) ...[
                          TextField(
                            controller: _intencionPersonalController,
                            style: GoogleFonts.inter(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Escribe tu intención aquí...',
                              hintStyle: GoogleFonts.inter(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.white, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            maxLines: 3,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                        ],
                        
                        // Botón de acción
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Indicador de progreso
                            Row(
                              children: List.generate(6, (index) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: index <= _currentStepIndex
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }),
                            ),
                            
                            // Botón de siguiente paso
                            GestureDetector(
                              onTap: _nextStep,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  _currentStepIndex < 5 ? Icons.play_arrow : Icons.check,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        // Si está en modo concentración, salir de él primero
        if (_isConcentrationMode) {
          setState(() {
            _isConcentrationMode = false;
          });
          return;
        }
        
        await _handleBackNavigation();
      },
      child: Stack(
        children: [
          // Capa Base: Pantalla Normal (siempre renderizada para preservar estado)
          Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: GlowBackground(
                    child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: _handleBackNavigation,
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          Expanded(
                            child: Text(
                              'Sesión de Repetición',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFD700),
                              ),
                            ),
                          ),
                          // Botón compartir/descargar
                          IconButton(
                            onPressed: _shareImage,
                            icon: const Icon(Icons.share, color: Color(0xFFFFD700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Esfera normal en pantalla (solo esfera + números; controles van abajo)
                      Center(
                        child: _buildIntegratedSphere(widget.codigo),
                      ),

                      // Bloque unificado reutilizable (SessionToolsBlock)
                      const SizedBox(height: 28),
                      SessionToolsBlock(
                        colorSelectorChild: _buildColorSelectorContent(),
                        descriptionChild: FutureBuilder<Map<String, dynamic>>(
                          future: _codigoInfoFuture,
                          builder: (context, snapshot) {
                            final titulo = snapshot.data?['titulo'] ?? 'Campo Energético';
                            final descripcion = snapshot.data?['descripcion'] ?? 'Secuencia cuántica para la manifestación y transformación energética.';
                            final titulosRelacionados = snapshot.data?['titulosRelacionados'] as List<Map<String, dynamic>>? ?? [];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      titulo,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFFFD700),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: _mostrarNotaImportante,
                                      child: const Icon(Icons.info_outline, color: Color(0xFFFFD700), size: 20),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  descripcion,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                    height: 1.4,
                                  ),
                                ),
                                if (_showSequentialSteps && _currentStepIndex == 5) ...[
                                  const SizedBox(height: 20),
                                  Text(
                                    '¿Qué deseas armonizar con esta secuencia?',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFFFD700),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _intencionPersonalController,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Escribe tu intención aquí...',
                                      hintStyle: GoogleFonts.inter(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 14,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.1),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: const Color(0xFFFFD700).withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: const Color(0xFFFFD700).withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFFFD700),
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    maxLines: 3,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                if (_intencionPersonal.isNotEmpty && (!_showSequentialSteps || _currentStepIndex != 5)) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD700).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFFFD700).withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Intención Personal',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFFFD700),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _intencionPersonal,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: Colors.white.withOpacity(0.9),
                                            height: 1.4,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (titulosRelacionados.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD700).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFFFD700).withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.info_outline,
                                              color: Color(0xFFFFD700),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'También relacionado con:',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFFFFD700),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ...titulosRelacionados.map((tituloRel) {
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '• ${tituloRel['titulo']?.toString() ?? ''}',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                if (tituloRel['descripcion'] != null &&
                                                    (tituloRel['descripcion'] as String).isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 12),
                                                    child: Text(
                                                      tituloRel['descripcion']?.toString() ?? '',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        color: Colors.white.withOpacity(0.7),
                                                        height: 1.3,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                        hasGuidedRepetition: _hasGuidedRepetition,
                        voiceToggleChild: _buildVoiceNumbersToggleContent(),
                        onVoiceToggle: _toggleVoiceNumbers,
                        musicControllerKey: ValueKey(_musicControllerKeySeed),
                        musicAutoPlay: _isRepetitionActive,
                        musicIsActive: true,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                ),
              ),
              ),
            // Widget para capturar (completamente fuera de la vista pero renderizado)
            Positioned(
              left: -1000,
              top: -1000,
              child: IgnorePointer(
                ignoring: true,
                child: SizedBox(
                  width: 800,
                  height: 800,
                  child: Screenshot(
                    controller: _screenshotController,
                    child: Builder(
                      builder: (context) {
                        // Obtener datos del código de forma síncrona para evitar problemas de async
                        return FutureBuilder<Map<String, String>>(
                          future: _shareableDataFuture,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Container(
                                width: 800,
                                height: 800,
                                color: Colors.black,
                                child: const Center(child: CircularProgressIndicator()),
                              );
                            }
                            final titulo = snapshot.data!['titulo'] ?? 'Campo Energético';
                            final descripcion = snapshot.data!['descripcion'] ?? 'Secuencia cuántica para la manifestación y transformación energética.';
                            return _buildShareableImage(widget.codigo, titulo, descripcion);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            // Sistema de Steps Secuenciales como Overlay Flotante
            if (_showSequentialSteps) _buildSequentialStepCard(),
        ],
      ),
      bottomNavigationBar: null, // Ocultar menú inferior en sesión de repetición
      ),
          // Capa Superior: Modo Concentración (Overlay)
          if (_isConcentrationMode)
            Positioned.fill(
              child: _buildConcentrationMode(),
            ),
        ],
      ),
    );
  }
  
  // Métodos para controlar la animación de la barra de colores
  void _hideColorBarAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (_isRepetitionActive && mounted) {
        setState(() {
          _isColorBarExpanded = false;
        });
        _colorBarController.forward();
      }
    });
  }
  
  void _showColorBar() {
    setState(() {
      _isColorBarExpanded = true;
    });
    
    // Ocultar la barra después de 3 segundos si la repetición está activa
    if (_isRepetitionActive) {
      _hideColorBarAfterDelay();
    }
  }
  
  void _onColorChanged() {
    // Cuando se cambia el color, reiniciar el timer de ocultación
    if (_isRepetitionActive) {
      _hideColorBarAfterDelay();
    }
  }

  void _incrementRepetition() {
    if (_isRepetitionActive) {
      setState(() {
        // Aquí puedes agregar lógica para contar repeticiones si es necesario
      });
    }
  }
  
  Color _getColorSeleccionado() {
    return _coloresDisponibles[_colorSeleccionado]!;
  }
  

  // ---- WIDGET PARA COMPARTIR (con app name, esfera, título y descripción) ----
  Widget _buildShareableImage(String codigoCrudo, String titulo, String descripcion) {
    return Container(
      width: 800,
      height: 800,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage('assets/images/ManiGrab-esfera.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          // Gradiente eliminado para que la imagen base se vea sin sombra
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Espacio superior
            const SizedBox(height: 140),
            
            // ⚡ CÓDIGO ENORME
            Expanded(
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.80,
                  child: Text(
                    codigoCrudo,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: GoogleFonts.spaceMono(
                      fontSize: 72,     // <<--- TAMAÑO REAL GRANDE
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 6,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.8),
                          blurRadius: 6,
                          offset: const Offset(2, 2),
                        ),
                        Shadow(
                          color: Colors.white.withOpacity(0.8),
                          blurRadius: 30,
                          offset: Offset.zero,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // ⚡ TÍTULO + DESCRIPCIÓN GRANDES
            Transform.translate(
              offset: const Offset(0, -12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titulo,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 32,            // <<-- ANTES 20
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFD700),
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.7),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      descripcion,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 20,          // <<-- ANTES 14
                        height: 1.35,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.7),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ---- MÉTODO DE ESFERA INTEGRADA (igual que en Cuántico) ----
  Widget _buildIntegratedSphere(String codigoCrudo) {
    final String codigoFormateado = CodeFormatter.formatCodeForDisplay(codigoCrudo);
    final double fontSize = CodeFormatter.calculateFontSize(codigoCrudo);

    return GestureDetector(
      onTap: _copyCodeInfo,
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // 1) ESFERA DORADA — solo visual, sin 'code'
            Transform.scale(
              scale: _isRepetitionActive ? _pulseAnimation.value : 1.0,
              child: GoldenSphere(
                size: 260,
                color: _getColorSeleccionado(),
                glowIntensity: _isRepetitionActive ? 0.8 : 0.6,
                isAnimated: true,
              ),
            ),

            // 2) CÓDIGO ILUMINADO SUPERPUESTO
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isRepetitionActive ? _pulseAnimation.value : 1.0,
                  child: IlluminatedCodeText(
                    code: codigoFormateado,
                    fontSize: fontSize,
                    color: _getColorSeleccionado(),
                    letterSpacing: 4,
                    isAnimated: false,
                  ),
                );
              },
            ),
          ],
        ),
      ],
      ),
    );
  }

  // Modo de concentración - pantalla completa con solo la esfera
  Widget _buildConcentrationMode() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Esfera centrada con animaciones
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final pulseScale = _isRepetitionActive ? _pulseAnimation.value : 1.0;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Esfera con animaciones
                    Transform.scale(
                      scale: _isRepetitionActive ? pulseScale : 1.0,
                      child: GoldenSphere(
                        color: _getColorSeleccionado(),
                        size: 300,
                        isAnimated: _isRepetitionActive,
                      ),
                    ),
                    // Código Grabovoi dentro de la esfera
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isRepetitionActive ? _pulseAnimation.value : 1.0,
                          child: GestureDetector(
                            onTap: _incrementRepetition,
                            child: Text(
                              CodeFormatter.formatCodeForDisplay(widget.codigo),
                              style: GoogleFonts.inter(
                                fontSize: CodeFormatter.calculateFontSize(widget.codigo),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(2.0, 2.0),
                                    blurRadius: 4.0,
                                    color: Colors.black.withOpacity(0.8),
                                  ),
                                  Shadow(
                                    offset: const Offset(-1.0, -1.0),
                                    blurRadius: 2.0,
                                    color: Colors.black.withOpacity(0.6),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          // Botón para salir del modo de concentración
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isConcentrationMode = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fullscreen, color: Colors.white, size: 24),
              ),
            ),
          ),
          // Icono ManiGrab abajo al centro
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Center(
              child: Image.asset(
                'assets/icons/ManiGrab_transparente.png',
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
      // Ocultar menú inferior en modo de concentración
      bottomNavigationBar: null,
    );
  }

  // Toggle del modo de concentración
  void _toggleConcentrationMode() {
    setState(() {
      _isConcentrationMode = !_isConcentrationMode;
    });
  }

  // Método para construir la barra de navegación inferior
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B132B),
            Color(0xFF1C2541),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                icon: Icons.home_filled,
                label: 'Inicio',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.menu_book,
                label: 'Biblioteca',
                index: 1,
              ),
              // _buildNavItem(
              //   icon: Icons.auto_awesome,
              //   label: 'Cuántico',
              //   index: 2,
              //   isCenter: true,
              // ), // Eliminado - se integró en biblioteca
              _buildNavItem(
                icon: Icons.emoji_events,
                label: 'Desafíos',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.show_chart,
                label: 'Evolución',
                index: 3,
              ),
              _buildNavItem(
                icon: Icons.person,
                label: 'Perfil',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Método para construir los elementos de navegación (igual que en main.dart)
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    bool isCenter = false,
  }) {
    return GestureDetector(
      onTap: () {
        // Navegar a la pantalla correspondiente
        switch (index) {
          case 0: // Inicio
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            break;
          case 1: // Biblioteca
            Navigator.of(context).pushNamed('/biblioteca');
            break;
          // case 2: // Cuántico - Eliminado
          //   Navigator.of(context).pushNamed('/pilotage');
          //   break;
          case 2: // Desafíos
            Navigator.of(context).pushNamed('/desafios');
            break;
          case 3: // Evolución
            Navigator.of(context).pushNamed('/evolucion');
            break;
          case 4: // Perfil
            Navigator.of(context).pushNamed('/profile');
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white.withOpacity(0.5),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Solo el contenido del selector (Row) para usar dentro del bloque unificado.
  Widget _buildColorSelectorContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Color:',
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        ..._coloresDisponibles.entries.map((entry) {
          final isSelected = _colorSeleccionado == entry.key;
          return GestureDetector(
            onTap: () {
              setState(() {
                _colorSeleccionado = entry.key;
              });
            },
            child: Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: entry.value,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: entry.value.withOpacity(0.8),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ] : null,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          );
        }).toList(),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: _toggleConcentrationMode,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getColorSeleccionado().withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getColorSeleccionado().withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.fullscreen,
              color: _getColorSeleccionado(),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _getColorSeleccionado().withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _buildColorSelectorContent(),
      ),
    );
  }

  // Método para mostrar la nota importante
  void _mostrarNotaImportante() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final mediaQuery = MediaQuery.of(context);
        final constrainedScale =
            mediaQuery.textScaleFactor.clamp(1.0, 1.25);

        return MediaQuery(
          data: mediaQuery.copyWith(textScaleFactor: constrainedScale),
          child: AlertDialog(
            backgroundColor: const Color(0xFF363636),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFF5A623), width: 2),
            ),
            title: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFF5A623), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Nota Importante',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFF5A623),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: mediaQuery.size.width * 0.9,
                maxHeight: mediaQuery.size.height * 0.6,
              ),
              child: SingleChildScrollView(
                child: Text(
                  'Las secuencias numéricas gravitacionales NO sustituyen la atención médica profesional. '
                  'Siempre consulta con profesionales de la salud para cualquier condición médica. '
                  'Estas secuencias son herramientas complementarias de bienestar.',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFCCCCCC),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            actions: [
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Entendido',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Método para registrar repetición y mostrar recompensas
  Future<void> _registrarRepeticionYMostrarRecompensas() async {
    try {
      // Registrar repetición
      await BibliotecaSupabaseService.registrarRepeticion(
        codeId: widget.codigo,
        codeName: widget.nombre ?? widget.codigo,
        durationMinutes: 2,
      );
      
      // Obtener recompensas
      final rewardsService = RewardsService();
      final recompensasInfo = await rewardsService.recompensarPorRepeticion(
        codigoId: widget.codigo,
      );
      
      // Mostrar notificación si ya se otorgaron recompensas
      if (recompensasInfo['yaOtorgadas'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              recompensasInfo['mensaje'] as String? ?? 
              'Ya recibiste cristales por esta secuencia hoy. Puedes seguir usándola, pero no recibirás más recompensas.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
      
      // Mostrar modal con recompensas
      if (mounted) {
        _mostrarMensajeFinalizacion(
          cristalesGanados: recompensasInfo['cristalesGanados'] as int,
          luzCuanticaAnterior: recompensasInfo['luzCuanticaAnterior'] as double,
          luzCuanticaActual: recompensasInfo['luzCuanticaActual'] as double,
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error registrando repetición y obteniendo recompensas: $e');
      // Mostrar modal sin recompensas si hay error
      if (mounted) {
        _mostrarMensajeFinalizacion();
      }
    }
  }

  // Método para mostrar modal de seguimiento del diario
  void _mostrarModalSeguimientoDiario() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TrackCodeModal(
        codigo: widget.codigo,
        nombre: widget.nombre,
        onAccept: () {
          Navigator.of(context).pop();
          // Navegar a la pantalla del diario para crear entrada
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => NuevaEntradaDiarioScreen(
                  codigo: widget.codigo,
                  nombre: widget.nombre,
                ),
              ),
            );
          }
        },
        onSkip: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // Método para mostrar el mensaje de finalización con códigos sincrónicos
  void _mostrarMensajeFinalizacion({
    int? cristalesGanados,
    double? luzCuanticaAnterior,
    double? luzCuanticaActual,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => SequenciaActivadaModal(
        onContinue: () {
          Navigator.of(context).pop();
          // Mostrar modal de seguimiento del diario
          if (context.mounted) {
            _mostrarModalSeguimientoDiario();
          }
        },
        buildSincronicosSection: ({void Function(String)? onCodeCopied}) => _buildSincronicosSection(onCodeCopied: onCodeCopied),
        mensajeCompletado: '¡Excelente trabajo! Has completado tu sesión de repeticiones.',
        cristalesGanados: cristalesGanados,
        luzCuanticaAnterior: luzCuanticaAnterior,
        luzCuanticaActual: luzCuanticaActual,
        tipoAccion: 'repeticion',
      ),
    );
  }

  // Cache para el Future de códigos sincrónicos
  Future<List<Map<String, dynamic>>>? _sincronicosFuture;

  // Método para construir la sección de códigos sincrónicos
  Widget _buildSincronicosSection({void Function(String)? onCodeCopied}) {
    // Cachear el Future para evitar múltiples ejecuciones
    _sincronicosFuture ??= _getSincronicosForCurrentCode();
    
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _sincronicosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFD700),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final codigosSincronicos = snapshot.data!;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFFD700).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.of(context).textScaleFactor;
              final screenWidth = constraints.maxWidth;
              final bool forceColumn = screenWidth < 360 || textScale >= 1.15;
              
              // Calcular ancho de cards para que quepan 2 sin scroll horizontal
              // Considerando padding del container (16*2 = 32) y spacing entre cards (8)
              final availableWidth = screenWidth - 32 - 8; // padding + spacing
              final double cardWidth = forceColumn
                  ? screenWidth - 32 // Ancho completo menos padding
                  : (availableWidth / 2).floorToDouble(); // Mitad del espacio disponible

              // Limitar a máximo 2 códigos sincrónicos
              final codigosLimitados = codigosSincronicos.take(2).toList();

              final cards = codigosLimitados.map((codigo) {
                return SizedBox(
                  width: cardWidth,
                  child: _buildSincronicoCard(context, codigo, onCodeCopied: onCodeCopied),
                );
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Combínalo con las siguientes secuencias para amplificar la resonancia',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFD700),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Mostrar secuencias una arriba de la otra (centradas)
                  ...cards.map((card) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: card,
                      )),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // Método para obtener códigos sincrónicos del código actual
  Future<List<Map<String, dynamic>>> _getSincronicosForCurrentCode() async {
    try {
      // Obtener la categoría del código actual
      final categoria = await _getCodeCategory(widget.codigo);
      if (categoria.isEmpty) return [];
      
      // Obtener códigos sincrónicos
      return await CodigosRepository().getSincronicosByCategoria(categoria);
    } catch (e) {
      debugPrint('⚠️ Error al obtener códigos sincrónicos: $e');
      return [];
    }
  }

  // Método helper para obtener la categoría del código
  Future<String> _getCodeCategory(String codigo) async {
    try {
      final codigoData = await SupabaseService.client
          .from('codigos_grabovoi')
          .select('categoria')
          .eq('codigo', codigo)
          .single();
      return codigoData['categoria'] ?? 'General';
    } catch (e) {
      debugPrint('⚠️ Error al obtener categoría del código: $e');
      return 'General';
    }
  }

  Future<void> _verificarFavorito() async {
    try {
      final customCodesService = UserCustomCodesService();
      final esPersonalizado = await customCodesService.isCustomCode(widget.codigo);
      
      bool esFavorito = false;
      if (esPersonalizado) {
        // Los códigos personalizados siempre son favoritos
        esFavorito = true;
      } else {
        // Verificar si está en favoritos oficiales
        esFavorito = await BibliotecaSupabaseService.esFavorito(widget.codigo);
      }
      
      if (mounted) {
        setState(() {
          _esFavorito = esFavorito;
          _esCodigoPersonalizado = esPersonalizado;
        });
      }
    } catch (e) {
      debugPrint('Error verificando favorito: $e');
    }
  }

  Future<void> _toggleFavorito() async {
    try {
      final customCodesService = UserCustomCodesService();
      
      if (_esCodigoPersonalizado) {
        // Si es código personalizado, mostrar advertencia antes de eliminar
        final confirmar = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C2541),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFFFD700), width: 2),
            ),
            title: Text(
              'Eliminar secuencia personalizada',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Esta secuencia fue insertada manualmente; si la eliminas de favoritos no podrás volver a verla hasta que la insertes nuevamente de forma manual.',
              style: GoogleFonts.inter(
                color: Colors.white70,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.inter(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text(
                  'Eliminar',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ),
            ],
          ),
        );
        
        if (confirmar == true) {
          // Eliminar código personalizado
          await customCodesService.deleteCustomCode(widget.codigo);
          if (mounted) {
            setState(() {
              _esFavorito = false;
              _esCodigoPersonalizado = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Secuencia eliminada de favoritos'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else if (_esFavorito) {
        // Remover de favoritos oficiales
        final favoritesService = UserFavoritesService();
        await favoritesService.removeFromFavorites(widget.codigo);
        if (mounted) {
          setState(() {
            _esFavorito = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removido de favoritos'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Agregar a favoritos
        final favoritesService = UserFavoritesService();
        await favoritesService.addToFavorites(widget.codigo);
        if (mounted) {
          setState(() {
            _esFavorito = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Agregado a favoritos'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error al cambiar favorito: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _loadCodigoInfo() async {
    final titulo = await _getCodigoTitulo();
    final descripcion = await _getCodigoDescription();
    final titulosRelacionados = await SupabaseService.getTitulosRelacionados(widget.codigo);
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'titulosRelacionados': titulosRelacionados,
    };
  }

  Future<Map<String, String>> _loadShareableData() async {
    final titulo = await _getCodigoTitulo();
    final descripcion = await _getCodigoDescription();
    return {
      'titulo': titulo,
      'descripcion': descripcion,
    };
  }

  Widget _buildSincronicoCard(BuildContext context, Map<String, dynamic> codigo, {void Function(String)? onCodeCopied}) {
    final codigoTexto = codigo['codigo'] ?? '';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Secuencia con icono de copiar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  codigoTexto,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: codigoTexto));
                  
                  // Usar el callback del modal si está disponible, de lo contrario usar SnackBar
                  if (onCodeCopied != null) {
                    onCodeCopied(codigoTexto);
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✅ Secuencia copiada: $codigoTexto',
                          style: GoogleFonts.inter(color: Colors.white),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        backgroundColor: const Color(0xFFFFD700),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Icon(
                  Icons.content_copy,
                  size: 16,
                  color: const Color(0xFFFFD700).withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            codigo['nombre'] ?? '',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              codigo['categoria'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 9,
                color: const Color(0xFFFFD700),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
