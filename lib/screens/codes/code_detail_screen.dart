import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/golden_sphere.dart';
import '../../widgets/streamed_music_controller.dart';
import '../../widgets/audio_preload_indicator.dart';
import '../../widgets/illuminated_code_text.dart';
import '../../widgets/sequencia_activada_modal.dart';
import '../../services/audio_preload_service.dart';
import '../../services/audio_manager_service.dart';
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

class CodeDetailScreen extends StatefulWidget {
  final String codigo;

  const CodeDetailScreen({super.key, required this.codigo});

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
    
    // Iniciar pilotaje automáticamente al entrar a la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPiloting();
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
    } catch (e) {
      print('Error iniciando audio: $e');
    }
    
    // Notificar al servicio global
    PilotageStateService().setPilotageActive(true);
    
    // Registrar acción de pilotaje para desafíos
    final trackingService = ChallengeTrackingService();
    await trackingService.recordPilotageSession(
      widget.codigo,
      widget.codigo,
      const Duration(minutes: 5),
    );
    
    // Registrar en el nuevo sistema de progreso
    final progressTracker = ChallengeProgressTracker();
    progressTracker.trackCodePiloted();

    // Actualizar progreso global (usuario_progreso)
    try {
      await BibliotecaSupabaseService.registrarPilotaje(
        codeId: widget.codigo,
        codeName: widget.codigo,
        durationMinutes: 5,
      );
    } catch (e) {
      print('Error registrando pilotaje en usuario_progreso: $e');
    }
    
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
        
        // Detener el audio
        AudioManagerService().stop();
        
        // Registrar repetición de código completada para desafíos
        final trackingService = ChallengeTrackingService();
        trackingService.recordCodeRepetition(
          widget.codigo,
          widget.codigo,
        );
        
        // Registrar en el nuevo sistema de progreso
        final progressTracker = ChallengeProgressTracker();
        progressTracker.trackCodeRepeated();
        
        // Registrar repetición en el sistema de progreso global
        try {
          await BibliotecaSupabaseService.registrarRepeticion(
            codeId: widget.codigo,
            codeName: widget.codigo,
            durationMinutes: 2,
          );
        } catch (e) {
          print('Error registrando repetición en usuario_progreso: $e');
        }
        
        _showCompletionDialog();
      }
    });
  }

  void _showCompletionDialog() async {
    // Obtener recompensas antes de mostrar el modal
    int? cristalesGanados;
    double? luzCuanticaAnterior;
    double? luzCuanticaActual;
    
    try {
      final rewardsService = RewardsService();
      final recompensasInfo = await rewardsService.recompensarPorRepeticion();
      cristalesGanados = recompensasInfo['cristalesGanados'] as int;
      luzCuanticaAnterior = recompensasInfo['luzCuanticaAnterior'] as double;
      luzCuanticaActual = recompensasInfo['luzCuanticaActual'] as double;
    } catch (e) {
      print('⚠️ Error obteniendo recompensas: $e');
    }
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.9),
        builder: (context) => SequenciaActivadaModal(
          onContinue: () {
            Navigator.of(context).pop();
          },
          buildSincronicosSection: ({void Function(String)? onCodeCopied}) => _buildSincronicosSection(onCodeCopied: onCodeCopied),
          mensajeCompletado: '¡Excelente trabajo! Has completado tu sesión de campo energético.',
          cristalesGanados: cristalesGanados,
          luzCuanticaAnterior: luzCuanticaAnterior,
          luzCuanticaActual: luzCuanticaActual,
          tipoAccion: 'repeticion',
        ),
      );
    }
  }

  void _copyToClipboard() async {
    try {
      // Buscar el código en la base de datos para obtener su información real
      final codigos = await SupabaseService.getCodigos();
      final codigoEncontrado = codigos.firstWhere(
        (c) => c.codigo == widget.codigo,
        orElse: () => CodigoGrabovoi(
          id: '',
          codigo: widget.codigo,
          nombre: 'Código Sagrado',
          descripcion: 'Código sagrado para la manifestación y transformación energética.',
          categoria: 'General',
          color: '#FFD700',
        ),
      );
      
      final textToCopy = '''${codigoEncontrado.codigo} : ${codigoEncontrado.nombre}
${codigoEncontrado.descripcion}
Obtuve esta información en la app: ManiGrab - Manifestaciones Cuánticas Grabovoi''';
      
      Clipboard.setData(ClipboardData(text: textToCopy));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Código ${widget.codigo} copiado con descripción'),
          backgroundColor: const Color(0xFFFFD700),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Fallback si hay error
      final textToCopy = '''${widget.codigo} : Código Sagrado
Código sagrado para la manifestación y transformación energética.
Obtuve esta información en la app: Manifestación Numérica Grabovoi''';
      
      Clipboard.setData(ClipboardData(text: textToCopy));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Código ${widget.codigo} copiado'),
          backgroundColor: const Color(0xFFFFD700),
          duration: const Duration(seconds: 2),
        ),
      );
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
                  'Los códigos numéricos de Grabovoi NO sustituyen la atención médica profesional. '
                  'Siempre consulta con profesionales de la salud para cualquier condición médica. '
                  'Estos códigos son herramientas complementarias de bienestar.',
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

  Future<void> _shareCode() async {
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

      // Solo para móvil, web no soporta compartir imágenes
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/grabovoi_${widget.codigo.replaceAll(RegExp(r'[^\w\s-]'), '_')}.png');
        await file.writeAsBytes(pngBytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Compartido desde ManiGrab - Manifestaciones Cuánticas Grabovoi',
        );

        ChallengeProgressTracker().trackPilotageShared(
          codeId: widget.codigo,
          codeName: widget.codigo,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Función de compartir no disponible en web'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error al compartir imagen: $e');
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
      return 'Código sagrado para la manifestación y transformación energética.';
    }
  }
  
  Widget _buildShareableImage(String codigoCrudo, String titulo, String descripcion) {
    final String codigoFormateado = CodeFormatter.formatCodeForDisplay(codigoCrudo);
    final double fontSize = CodeFormatter.calculateFontSize(codigoCrudo);

    return Container(
      width: 800,
      height: 800,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1) NOMBRE DE LA APP - Arriba
          Text(
            'ManiGrab - Manifestaciones Cuánticas Grabovoi',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFD700),
              shadows: [
                Shadow(
                  color: const Color(0xFFFFD700).withOpacity(0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          
          // 2) ESFERA CON CÓDIGO - Centro
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Esfera dorada (sin animación para captura)
              GoldenSphere(
                size: 280,
                color: _getColorSeleccionado(),
                glowIntensity: 0.8,
                isAnimated: false,
              ),
              // Código iluminado superpuesto (sin animación)
              IlluminatedCodeText(
                code: codigoFormateado,
                fontSize: fontSize,
                color: _getColorSeleccionado(),
                letterSpacing: 4,
                isAnimated: false,
              ),
            ],
          ),
          const SizedBox(height: 25),
          
          // 3) TÍTULO Y DESCRIPCIÓN - Abajo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  descripcion,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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
      return 'Código sagrado para la manifestación y transformación energética.';
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

  void _stopActivePilotage() {
    setState(() {
      _isPiloting = false;
    });
    
    // Notificar al servicio global
    PilotageStateService().setPilotageActive(false);
    
    // Detener el audio
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
            },
            color: const Color(0xFFFF6B6B),
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
                      tooltip: 'Copiar código',
                    ),
                    // Botón de compartir
                    IconButton(
                      onPressed: _shareCode,
                      icon: const Icon(Icons.share, color: Color(0xFFFFD700)),
                      tooltip: 'Compartir código',
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
                
                // Esfera integrada (sin contenedor rectangular oscuro)
                _buildQuantumDetailSphere(widget.codigo),
                const SizedBox(height: 20),
                
                // Selector de colores fuera del Stack
                Center(
                  child: _buildColorSelector(),
                ),
                const SizedBox(height: 20),
                
                // Descripción
                Center(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _codigoInfoFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator(color: Color(0xFFFFD700));
                      }
                      
                      final titulo = snapshot.data?['titulo'] ?? 'Campo Energético';
                      final descripcion = snapshot.data?['descripcion'] ?? 'Código sagrado para la manifestación y transformación energética.';
                      final titulosRelacionados = snapshot.data?['titulosRelacionados'] as List<Map<String, dynamic>>? ?? [];
                      
                      return Container(
                        width: double.infinity,
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
                            // Título principal
                            Text(
                              titulo,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFD700),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Descripción principal
                            Text(
                              descripcion,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                height: 1.4,
                              ),
                            ),
                            // Mostrar otros títulos relacionados si existen
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
                                          'Este código también se relaciona con:',
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
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                
                // Reproductor de Audio (siempre visible)
                StreamedMusicController(
                  autoPlay: _isPiloting,
                  isActive: _isPiloting,
                ),
                const SizedBox(height: 20),
                
                
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
                          final descripcion = snapshot.data!['descripcion'] ?? 'Código sagrado para la manifestación y transformación energética.';
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
  
  // Método para construir el selector de colores (igual que en Sesión de Repetición)
  Widget _buildColorSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Color:',
            style: GoogleFonts.inter(
              color: Colors.white,
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
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: isSelected ? 2 : 1,
                  ),
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
          const SizedBox(width: 8),
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
      ),
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
            'Combínalo con los siguientes códigos para amplificar la resonancia',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFD700),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: codigosSincronicos.length,
              itemBuilder: (context, index) {
                final codigo = codigosSincronicos[index];
                return Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: GestureDetector(
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
                              '✅ Código copiado: $codigoTexto',
                              style: GoogleFonts.inter(color: Colors.white),
                            ),
                            backgroundColor: const Color(0xFFFFD700),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          codigo['codigo'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFD700),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          codigo['nombre'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            codigo['categoria'] ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFFFFD700),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
