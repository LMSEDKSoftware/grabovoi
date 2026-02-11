import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../utils/share_helper.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/golden_sphere.dart';
import '../../widgets/streamed_music_controller.dart';
import '../../widgets/session_tools_block.dart';
import '../../widgets/audio_preload_indicator.dart';
import '../../widgets/illuminated_code_text.dart';
import '../../widgets/sequencia_activada_modal.dart';
import '../../services/audio_preload_service.dart';
import '../../services/audio_manager_service.dart';
import '../../services/numbers_voice_service.dart';
import '../../services/challenge_tracking_service.dart';
import '../../services/challenge_progress_tracker.dart';
import '../../services/pilotage_state_service.dart';
import '../../services/biblioteca_supabase_service.dart';
import '../../services/supabase_service.dart';
import '../../services/rewards_service.dart';
import '../../models/supabase_models.dart';
import '../../repositories/codigos_repository.dart';
import '../../utils/code_formatter.dart';
import '../pilotaje/pilotaje_screen.dart';
import '../diario/track_code_modal.dart';
import '../diario/nueva_entrada_diario_screen.dart';
import '../../services/subscription_service.dart';
import '../../widgets/subscription_required_modal.dart';

class CodeDetailScreen extends StatefulWidget {
  final String codigo;
  /// Si true, es la secuencia diaria (Portal Energético): acceso permitido sin premium.
  final bool isDailySequence;

  const CodeDetailScreen({super.key, required this.codigo, this.isDailySequence = false});

  @override
  State<CodeDetailScreen> createState() => _CodeDetailScreenState();
}

class _CodeDetailScreenState extends State<CodeDetailScreen> 
    with TickerProviderStateMixin {
  final ScreenshotController _screenshotController = ScreenshotController();
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  
  bool _isPiloting = false;
  int _secondsRemaining = 0;
  bool _isPreloading = false;
  final AudioPreloadService _preloadService = AudioPreloadService();
  
  // Variables para el selector de colores
  String _colorSeleccionado = 'dorado';
  final Map<String, Color> _coloresDisponibles = {
    'dorado': const Color(0xFFFFD700),
    'plateado': const Color(0xFFC0C0C0),
    'azul': const Color(0xFF87CEEB),
    'blanco': const Color(0xFFFFFFFF),
  };
  
  // Variables para el modo concentración
  bool _isConcentrationMode = false;
  late Future<Map<String, dynamic>> _codigoInfoFuture;
  late Future<Map<String, String>> _shareableDataFuture;

  // Repetición guiada (voz numérica), mismo modelo que Sesión de Repetición
  bool _voiceNumbersEnabled = false;
  /// Si el usuario tiene adquirida la repetición guiada en la tienda cuántica (muestra u oculta la card).
  bool _hasGuidedRepetition = false;
  String _voiceGender = 'female';
  int _musicControllerKeySeed = 0;
  

  @override
  void initState() {
    super.initState();
    
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

    _codigoInfoFuture = _loadCodigoInfo();
    _shareableDataFuture = _loadShareableData();
    _loadVoiceSettings();

    // Secuencia diaria (Portal Energético): siempre permitir acceso. Resto: verificar premium.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.isDailySequence) {
        if (mounted) _startPiloting();
        return;
      }
      final subscriptionService = SubscriptionService();
      await subscriptionService.checkSubscriptionStatus();
      
      final hasPremiumAccess = subscriptionService.hasPremiumAccess;
      final remainingTrialDays = await subscriptionService.getRemainingTrialDays();
      
      if (!hasPremiumAccess && (remainingTrialDays == null || remainingTrialDays <= 0)) {
        if (mounted) {
          SubscriptionRequiredModal.show(
            context,
            message: 'El Campo Energético está disponible solo para usuarios Premium o durante el período de prueba. Suscríbete para acceder a esta función.',
            onDismiss: () {
              Navigator.of(context).pop();
            },
          );
        }
        return;
      }
      
      if (mounted) {
        _startPiloting();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    // Evitar setState tras dispose en countdown
    _secondsRemaining = 0;
    super.dispose();
  }

  Future<void> _startPiloting() async {
    // Verificar si ya se otorgaron recompensas antes de iniciar
    final rewardsService = RewardsService();
    final yaOtorgadas = await rewardsService.yaSeOtorgaronRecompensas(
      codigoId: widget.codigo,
      tipoAccion: 'repeticion', // En code_detail_screen se usa como repetición
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

      // Si el usuario cancela, no iniciar el pilotaje
      if (continuar != true) {
        Navigator.of(context).pop(); // Volver atrás
        return;
      }
    }

    setState(() {
      _isPreloading = true;
    });
    
    // Iniciar precarga de audio
    await _preloadService.startPreload();
    
    setState(() {
      _isPreloading = false;
      _isPiloting = true;
      _secondsRemaining = 120; // 2 minutos
    });
    
    // Iniciar audio cuando el pilotaje comience
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
      // Voz numérica (repetición guiada): si está habilitada, iniciar sesión
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
      if (mounted) setState(() {});
    } catch (e) {
      print('Error iniciando audio: $e');
    }
    
    // Notificar al servicio global
    PilotageStateService().setPilotageActive(true);
    
    // NO registrar el pilotaje aquí - solo se registra cuando se COMPLETA
    // Las notificaciones se enviarán solo cuando el timer llegue a 0
    
    _startCountdown();
  }

  void _startCountdown() {
    print('🕐 [CAMPO ENERGÉTICO] Iniciando temporizador: $_secondsRemaining segundos');
    Future.delayed(const Duration(seconds: 1), () async {
      if (!mounted) return; // no llamar setState si ya no está montado
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
        print('🕐 [CAMPO ENERGÉTICO] Tiempo restante: $_secondsRemaining segundos');
        _startCountdown();
      } else {
        print('✅ [CAMPO ENERGÉTICO] Temporizador completado! Mostrando diálogo...');
        setState(() {
          _isPiloting = false;
        });
        
        // Notificar al servicio global
        PilotageStateService().setPilotageActive(false);
        
        // Detener voz numérica y música
        try {
          NumbersVoiceService().stopSession();
        } catch (_) {}
        AudioManagerService().stop();
        
        // AHORA SÍ: Registrar el pilotaje completado (solo cuando se completa)
        try {
          // Registrar acción de pilotaje para desafíos
          final trackingService = ChallengeTrackingService();
          await trackingService.recordPilotageSession(
            widget.codigo,
            widget.codigo,
            const Duration(minutes: 2), // Duración real completada (2 minutos)
          );
          
          // Registrar repetición de código completada para desafíos
          await trackingService.recordCodeRepetition(
            widget.codigo,
            widget.codigo,
          );
          
          // NOTA: NO llamar a progressTracker.trackCodePiloted() ni trackCodeRepeated()
          // porque ya se registran arriba y causaría conteo duplicado/cuádruple

          // Actualizar progreso global (usuario_progreso)
          await BibliotecaSupabaseService.registrarPilotaje(
            codeId: widget.codigo,
            codeName: widget.codigo,
            durationMinutes: 2,
          );
        } catch (e) {
          print('Error registrando pilotaje completado: $e');
        }
        
        // Registrar repetición y mostrar recompensas (igual que en repeticiones)
        _registrarRepeticionYMostrarRecompensas();
      }
    });
  }

  // Método para registrar repetición y mostrar recompensas (igual que en repeticiones)
  Future<void> _registrarRepeticionYMostrarRecompensas() async {
    try {
      // Registrar repetición
      await BibliotecaSupabaseService.registrarRepeticion(
        codeId: widget.codigo,
        codeName: widget.codigo,
        durationMinutes: 2,
      );
      
      // Obtener recompensas
      final rewardsService = RewardsService();
      final recompensasInfo = await rewardsService.recompensarPorRepeticion(
        codigoId: widget.codigo,
      );
      
      // Debug: Verificar valores obtenidos
      print('🔍 [CAMPO ENERGÉTICO] Recompensas obtenidas:');
      print('   cristalesGanados: ${recompensasInfo['cristalesGanados']}');
      print('   luzCuanticaAnterior: ${recompensasInfo['luzCuanticaAnterior']}');
      print('   luzCuanticaActual: ${recompensasInfo['luzCuanticaActual']}');
      print('   yaOtorgadas: ${recompensasInfo['yaOtorgadas']}');
      
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
    } catch (e, stackTrace) {
      print('⚠️ Error registrando repetición y obteniendo recompensas: $e');
      print('⚠️ Stack trace: $stackTrace');
      // Mostrar modal sin recompensas si hay error
      if (mounted) {
        _mostrarMensajeFinalizacion();
      }
    }
  }

  // Método para mostrar modal de seguimiento del diario (solo para usuarios Premium o con trial activo)
  Future<void> _mostrarModalSeguimientoDiario() async {
    // Verificar que el usuario tenga acceso premium o días de trial restantes
    final subscriptionService = SubscriptionService();
    await subscriptionService.checkSubscriptionStatus();
    
    final hasPremiumAccess = subscriptionService.hasPremiumAccess;
    final remainingTrialDays = await subscriptionService.getRemainingTrialDays();
    
    // Solo mostrar el modal si el usuario tiene acceso premium o días de trial restantes
    if (!hasPremiumAccess && (remainingTrialDays == null || remainingTrialDays <= 0)) {
      // Usuario sin acceso - no mostrar modal del diario
      return;
    }
    
    // Obtener el nombre del código para mostrarlo en el modal
    final codigosRepo = CodigosRepository();
    final nombreCodigo = codigosRepo.getTituloByCode(widget.codigo);
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => TrackCodeModal(
          codigo: widget.codigo,
          nombre: nombreCodigo,
          onAccept: () {
            Navigator.of(context).pop();
            // Navegar a la pantalla del diario para crear entrada
            if (context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => NuevaEntradaDiarioScreen(
                    codigo: widget.codigo,
                    nombre: nombreCodigo,
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
  }

  // Método para mostrar el mensaje de finalización con códigos sincrónicos (igual que en repeticiones)
  void _mostrarMensajeFinalizacion({
    int? cristalesGanados,
    double? luzCuanticaAnterior,
    double? luzCuanticaActual,
  }) {
    // Debug: Verificar valores que se pasan al modal
    print('🔍 [CAMPO ENERGÉTICO] Valores pasados al modal:');
    print('   cristalesGanados: $cristalesGanados');
    print('   luzCuanticaAnterior: $luzCuanticaAnterior');
    print('   luzCuanticaActual: $luzCuanticaActual');
    print('   tipoAccion: campo_energetico');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => SequenciaActivadaModal(
        onContinue: () {
          Navigator.of(context).pop();
          // Mostrar modal de seguimiento del diario (solo para usuarios Premium o con trial activo)
          if (context.mounted) {
            _mostrarModalSeguimientoDiario();
          }
        },
        buildSincronicosSection: ({void Function(String)? onCodeCopied}) => _buildSincronicosSection(onCodeCopied: onCodeCopied),
        mensajeCompletado: '¡Excelente trabajo! Has completado tu sesión de campo energético.',
        cristalesGanados: cristalesGanados,
        luzCuanticaAnterior: luzCuanticaAnterior,
        luzCuanticaActual: luzCuanticaActual,
        tipoAccion: 'campo_energetico',
      ),
    );
  }

  void _copyToClipboard() async {
    try {
      // Usar los datos ya cargados en _codigoInfoFuture (sin consultas adicionales)
      final codigoInfo = await _codigoInfoFuture;
      final titulo = codigoInfo['titulo'] as String? ?? 'Campo Energético';
      final descripcion = codigoInfo['descripcion'] as String? ?? 'Secuencia cuántica para la manifestación y transformación energética.';
      
      final textToCopy = '''${widget.codigo} : $titulo
$descripcion
Obtuve esta información en la app: ManiGraB - Manifestaciones Cuánticas Grabovoi''';
      
      await Clipboard.setData(ClipboardData(text: textToCopy));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Secuencia ${widget.codigo} copiada con descripción'),
            backgroundColor: const Color(0xFFFFD700),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Fallback si hay error - usar datos básicos
      final textToCopy = '''${widget.codigo} : Campo Energético
Secuencia cuántica para la manifestación y transformación energética.
Obtuve esta información en la app: ManiGrab - Manifestaciones Cuánticas Grabovoi''';
      
      await Clipboard.setData(ClipboardData(text: textToCopy));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Secuencia ${widget.codigo} copiada'),
            backgroundColor: const Color(0xFFFFD700),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Método para mostrar la nota importante (clonado de sesión de repeticiones)
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

  Future<Uint8List?> _generateImageBytes() async {
    try {
      if (!mounted) return null;
      
      // Verificar que el screenshot controller esté inicializado
      if (_screenshotController == null) {
        return null;
      }

      // Esperar a que el widget se renderice completamente
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Forzar rebuild para asegurar que el widget oculto esté renderizado
      if (mounted) {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      if (!mounted) return null;
      
      // Capturar la imagen del widget oculto
      final Uint8List? pngBytes = await _screenshotController.capture(pixelRatio: 2.0);
      
      return pngBytes;
    } catch (e) {
      print('❌ Error generando imagen: $e');
      return null;
    }
  }

  Future<void> _previewImage() async {
    try {
      if (!mounted) return;
      
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFFD700),
          ),
        ),
      );

      final pngBytes = await _generateImageBytes();
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Cerrar indicador de carga
      
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

      // Mostrar diálogo con la imagen
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2541),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFFD700),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.image,
                          color: Color(0xFFFFD700),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Vista Previa de la Imagen',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Imagen
                  Flexible(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white24,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          pngBytes,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Botones
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Cerrar',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _shareCode();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Compartir',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF1a1a2e),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Error crítico al previsualizar imagen: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        Navigator.of(context).pop(); // Cerrar cualquier diálogo abierto
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar la vista previa. Por favor, intenta nuevamente.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _shareCode() async {
    try {
      if (!mounted) return;
      
      final pngBytes = await _generateImageBytes();
      
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
      try {
        await ShareHelper.shareImage(
          pngBytes: pngBytes,
          fileName: 'grabovoi_${widget.codigo}',
          text: 'Compartido desde ManiGraB - Manifestaciones Cuánticas Grabovoi',
          context: context,
        );

        // Registrar compartido solo si se compartió exitosamente
        try {
          ChallengeProgressTracker().trackPilotageShared(
            codeId: widget.codigo,
            codeName: widget.codigo,
          );
        } catch (e) {
          print('⚠️ Error registrando pilotaje compartido: $e');
          // No mostrar error al usuario, solo log
        }
      } catch (shareError) {
        print('❌ Error al compartir archivo: $shareError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al compartir: ${shareError.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error crítico al compartir imagen: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado al compartir. Por favor, intenta nuevamente.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  Future<String> _getCodigoTitulo() async {
    try {
      return CodigosRepository().getTituloByCode(widget.codigo);
    } catch (e) {
      return 'Campo Energético';
    }
  }

  Future<String> _getCodigoDescription() async {
    try {
      return CodigosRepository().getDescripcionByCode(widget.codigo);
    } catch (e) {
      return 'Secuencia cuántica para la manifestación y transformación energética.';
    }
  }
  
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
                        fontSize: 32,            // <<-- ANTES 18
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
                        fontSize: 20,          // <<-- ANTES 13
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
  
  Color _getColorSeleccionado() {
    return _coloresDisponibles[_colorSeleccionado]!;
  }


  // Función helper para obtener la descripción del código desde la base de datos
  Future<String> _getCodeDescription(String codigo) async {
    try {
      return CodigosRepository().getDescripcionByCode(codigo);
    } catch (e) {
      return 'Secuencia cuántica para la manifestación y transformación energética.';
    }
  }

  // Función helper para obtener el título del código desde la base de datos
  Future<String> _getCodeTitulo(String codigo) async {
    try {
      return CodigosRepository().getTituloByCode(codigo);
    } catch (e) {
      return 'Campo Energético';
    }
  }

  // Obtener todos los títulos relacionados con un código (desde la nueva tabla)
  Future<List<Map<String, dynamic>>> _getTodosLosTitulosRelacionados(String codigo) async {
    try {
      return await SupabaseService.getTitulosRelacionados(codigo);
    } catch (e) {
      print('⚠️ Error obteniendo títulos relacionados: $e');
      return [];
    }
  }

  // Función helper para obtener la categoría del código desde la base de datos
  Future<String> _getCodeCategory(String codigo) async {
    try {
      final codigoData = await SupabaseService.client
          .from('codigos_grabovoi')
          .select('categoria')
          .eq('codigo', codigo)
          .single();
      return codigoData['categoria'] ?? 'General';
    } catch (e) {
      print('⚠️ Error al obtener categoría del código: $e');
      return 'General';
    }
  }

  Future<Map<String, dynamic>> _loadCodigoInfo() async {
    final titulo = await _getCodeTitulo(widget.codigo);
    final descripcion = await _getCodeDescription(widget.codigo);
    final titulosRelacionados = await _getTodosLosTitulosRelacionados(widget.codigo);
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

  Future<void> _loadVoiceSettings() async {
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

  /// Toggle de repetición guiada solo para esta sesión: apaga/enciende la reproducción de voz
  /// para esta secuencia. No modifica la configuración global (esa solo se cambia en Ajustes).
  /// Si en configuración está encendido, la próxima secuencia comenzará de nuevo con voz activa.
  Future<void> _toggleVoiceNumbers() async {
    final newValue = !_voiceNumbersEnabled;
    setState(() => _voiceNumbersEnabled = newValue);
    if (!mounted) return;
    if (_isPiloting) {
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

  void _stopActivePilotage() {
    setState(() {
      _isPiloting = false;
    });
    
    // Notificar al servicio global
    PilotageStateService().setPilotageActive(false);
    
    // Detener voz numérica y música
    try {
      NumbersVoiceService().stopSession();
    } catch (_) {}
    AudioManagerService().stop();
  }

  Future<void> _handleBackNavigation() async {
    // Verificar si hay pilotaje activo
    if (_isPiloting) {
      final result = await _showPilotageActiveDialog();
      if (result == true) {
        // Usuario confirmó, mostrar mensaje de cancelación primero
        if (context.mounted) {
          _mostrarMensajeCancelacion();
        }
      }
    } else {
      // No hay pilotaje activo, permitir pop
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<bool?> _showPilotageActiveDialog() async {
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
                'Pilotaje Activo',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que deseas abandonar el Campo Energético y detener la música?',
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
                _stopActivePilotage();
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
                'Campo Energético Cancelado',
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
              'Has cancelado la sesión de Campo Energético.',
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
              // Mostrar segundo diálogo con indicación de salida
              _mostrarDialogoListoParaSalir();
            },
            color: const Color(0xFFFF6B6B),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoListoParaSalir() {
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
  Widget build(BuildContext context) {
    // Modo de concentración (pantalla completa)
    if (_isConcentrationMode) {
      return _buildConcentrationMode();
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handleBackNavigation();
      },
      child: Scaffold(
        body: Stack(
        children: [
          GlowBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      onPressed: _handleBackNavigation,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Spacer(),
                    // Botón de información
                    IconButton(
                      onPressed: _mostrarNotaImportante,
                      icon: const Icon(Icons.info_outline, color: Color(0xFFFFD700)),
                      tooltip: 'Nota importante',
                    ),
                    // Botón de copiar
                    IconButton(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy, color: Color(0xFFFFD700)),
                      tooltip: 'Copiar secuencia',
                    ),
                    // Botón de previsualizar imagen (solo para web)
                    if (kIsWeb)
                      IconButton(
                        onPressed: _previewImage,
                        icon: const Icon(Icons.preview, color: Color(0xFFFFD700)),
                        tooltip: 'Vista previa de imagen',
                      ),
                    // Botón de compartir
                    IconButton(
                      onPressed: _shareCode,
                      icon: const Icon(Icons.share, color: Color(0xFFFFD700)),
                      tooltip: 'Compartir secuencia',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Título
                Text(
                  'Campo Energético',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Esfera integrada (solo esfera + números; controles en bloque unificado abajo)
                _buildQuantumDetailSphere(widget.codigo),
                const SizedBox(height: 28),
                // Bloque unificado reutilizable (SessionToolsBlock)
                SessionToolsBlock(
                  colorSelectorChild: _buildColorSelectorContent(),
                  descriptionChild: FutureBuilder<Map<String, dynamic>>(
                    future: _codigoInfoFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(color: Color(0xFFFFD700)),
                          ),
                        );
                      }
                      final titulo = snapshot.data?['titulo'] ?? 'Campo Energético';
                      final descripcion = snapshot.data?['descripcion'] ?? 'Secuencia sagrada para la manifestación y transformación energética.';
                      final titulosRelacionados = snapshot.data?['titulosRelacionados'] as List<Map<String, dynamic>>? ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                          const SizedBox(height: 12),
                          Text(
                            descripcion,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.45,
                            ),
                          ),
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
                                      const Icon(Icons.info_outline, color: Color(0xFFFFD700), size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Esta secuencia también se relaciona con:',
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
                                            tituloRel['titulo']?.toString() ?? '',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          if (tituloRel['descripcion'] != null && (tituloRel['descripcion'] as String).isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              tituloRel['descripcion']?.toString() ?? '',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: Colors.white.withOpacity(0.7),
                                                height: 1.3,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
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
                  musicAutoPlay: _isPiloting,
                  musicIsActive: _isPiloting,
                ),
                const SizedBox(height: 24),
                
                
                // Botón de Acción eliminado - el pilotaje se inicia automáticamente
                
                
                const SizedBox(height: 40),
                
                  ],
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
                          final descripcion = snapshot.data!['descripcion'] ?? 'Secuencia sagrada para la manifestación y transformación energética.';
                          return _buildShareableImage(widget.codigo, titulo, descripcion);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
  
  // Método para alternar el modo concentración
  void _toggleConcentrationMode() {
    setState(() {
      _isConcentrationMode = !_isConcentrationMode;
    });
  }
  
  /// Solo el contenido del selector (Row) para el bloque unificado.
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
          final colorName = entry.key;
          final color = entry.value;
          final isSelected = _colorSeleccionado == colorName;
          return GestureDetector(
            onTap: () {
              setState(() {
                _colorSeleccionado = colorName;
              });
            },
            child: Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.8),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          );
        }).toList(),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () {
            setState(() {
              _isConcentrationMode = true;
            });
          },
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

  // ---- MÉTODO DE ESFERA INTEGRADA (igual que en Cuántico y Repetición) ----
  Widget _buildQuantumDetailSphere(String codigoCrudo) {
    final String codigoFormateado = CodeFormatter.formatCodeForDisplay(codigoCrudo);
    final double fontSize = CodeFormatter.calculateFontSize(codigoCrudo, baseSize: 42);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // 1️⃣ Esfera dorada (solo visual, sin contenedor rectangular)
        Transform.scale(
          scale: _isPiloting ? _pulseAnimation.value : 1.0,
          child: GoldenSphere(
            size: 260,
            color: _getColorSeleccionado(),
            glowIntensity: _isPiloting ? 0.85 : 0.7,
            isAnimated: true,
          ),
        ),

        // 2️⃣ Texto iluminado (el código sobre la esfera)
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isPiloting ? _pulseAnimation.value : 1.0,
              child: IlluminatedCodeText(
                code: codigoFormateado,
                fontSize: fontSize,
                color: _getColorSeleccionado(),
                letterSpacing: 6,
                isAnimated: false,
              ),
            );
          },
        ),

      ],
    );
  }

  // Modo de concentración - CLONADO EXACTAMENTE del pilotaje cuántico
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
                final pulseScale = _isPiloting ? 
                  _pulseAnimation.value * 1.3 : 
                  _pulseAnimation.value;
                
                // Modo Esfera - Esfera dorada con código
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Esfera con código centrado
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Esfera con animaciones
                        Transform.scale(
                          scale: _isPiloting ? pulseScale : 1.0,
                          child: GoldenSphere(
                            size: 320, // Más grande para pantalla completa
                            color: _getColorSeleccionado(),
                            glowIntensity: _isPiloting ? 0.9 : 0.7,
                            isAnimated: true,
                          ),
                        ),
                        // Código centrado en la esfera
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _isPiloting ? pulseScale : 1.0,
                              child: IlluminatedCodeText(
                                code: CodeFormatter.formatCodeForDisplay(widget.codigo),
                                fontSize: CodeFormatter.calculateFontSize(widget.codigo, baseSize: 40),
                                color: _getColorSeleccionado(),
                                letterSpacing: 6,
                                isAnimated: false,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Botón para salir del modo concentración
          Positioned(
            top: 50,
            right: 20,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isConcentrationMode = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.fullscreen_exit,
                  color: Colors.white,
                  size: 24,
                ),
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
    );
  }

  // Método para construir la sección de códigos sincrónicos
  Widget _buildSincronicosSection({void Function(String)? onCodeCopied}) {
    return _SincronicosSection(codigo: widget.codigo, onCodeCopied: onCodeCopied);
  }
}

// Widget separado para manejar los códigos sincrónicos con estado local
class _SincronicosSection extends StatefulWidget {
  final String codigo;
  final void Function(String)? onCodeCopied;
  
  const _SincronicosSection({required this.codigo, this.onCodeCopied});
  
  @override
  State<_SincronicosSection> createState() => _SincronicosSectionState();
}

class _SincronicosSectionState extends State<_SincronicosSection> {
  String? _categoria;
  List<Map<String, dynamic>>? _codigosSincronicos;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadSincronicos();
  }
  
  Future<void> _loadSincronicos() async {
    try {
      // Obtener categoría del código
      final categoria = await _getCodeCategory(widget.codigo);
      
      if (mounted) {
        setState(() {
          _categoria = categoria;
        });
        
        // Obtener códigos sincrónicos
        final codigos = await CodigosRepository().getSincronicosByCategoria(categoria);
        
        if (mounted) {
          setState(() {
            _codigosSincronicos = codigos;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error cargando sincrónicos: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<String> _getCodeCategory(String codigo) async {
    try {
      final codigoData = await SupabaseService.client
          .from('codigos_grabovoi')
          .select('categoria')
          .eq('codigo', codigo)
          .single();
      return codigoData['categoria'] ?? 'General';
    } catch (e) {
      print('⚠️ Error al obtener categoría del código: $e');
      return 'General';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
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
    
    if (_codigosSincronicos == null || _codigosSincronicos!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final codigosSincronicos = _codigosSincronicos!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Combínalo con las siguientes secuencias para amplificar la resonancia',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFD700),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Mostrar secuencias una arriba de la otra (centradas)
          ...codigosSincronicos.take(2).map((codigo) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
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
                      // Secuencia con icono de copiar (igual que en repeticiones)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              codigo['codigo'] ?? '',
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
                              // Copiar código al portapapeles
                              final codigoTexto = codigo['codigo'] ?? '';
                              await Clipboard.setData(ClipboardData(text: codigoTexto));
                              
                              // Usar el callback del modal si está disponible, de lo contrario usar SnackBar
                              if (widget.onCodeCopied != null) {
                                widget.onCodeCopied!(codigoTexto);
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
                ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
