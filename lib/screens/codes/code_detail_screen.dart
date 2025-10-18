import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/golden_sphere.dart';
import '../../widgets/streamed_music_controller.dart';
import '../../widgets/audio_preload_indicator.dart';
import '../../services/audio_preload_service.dart';
import '../../services/challenge_tracking_service.dart';

class CodeDetailScreen extends StatefulWidget {
  final String codigo;

  const CodeDetailScreen({super.key, required this.codigo});

  @override
  State<CodeDetailScreen> createState() => _CodeDetailScreenState();
}

class _CodeDetailScreenState extends State<CodeDetailScreen> 
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  
  bool _isPiloting = false;
  int _secondsRemaining = 0;
  bool _isPreloading = false;
  final AudioPreloadService _preloadService = AudioPreloadService();

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
      _secondsRemaining = 300; // 5 minutos
    });
    
    // Registrar acción de pilotaje para desafíos
    final trackingService = ChallengeTrackingService();
    await trackingService.recordPilotageSession(
      widget.codigo,
      widget.codigo,
      const Duration(minutes: 5),
    );
    
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return; // no llamar setState si ya no está montado
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
        _startCountdown();
      } else {
        setState(() {
          _isPiloting = false;
        });
        
        // Registrar repetición de código completada para desafíos
        final trackingService = ChallengeTrackingService();
        trackingService.recordCodeRepetition(
          widget.codigo,
          widget.codigo,
        );
        
        _showCompletionDialog();
      }
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '¡Pilotaje Completado!',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFFFD700),
            fontSize: 24,
          ),
        ),
        content: Text(
          'Has completado exitosamente el pilotaje del código ${widget.codigo}. Tu energía se ha elevado.',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Continuar',
              style: GoogleFonts.inter(
                color: const Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.codigo));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Código ${widget.codigo} copiado'),
        backgroundColor: const Color(0xFFFFD700),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getCodeDescription(String codigo) {
    switch (codigo) {
      case '1884321':
        return 'Norma Absoluta - Restaurar la armonía del cuerpo y la salud perfecta.';
      case '88888588888':
        return 'Código Universal - Abrir canales de abundancia y prosperidad infinita.';
      case '318798':
        return 'Prosperidad - Atraer riqueza material y espiritual.';
      case '5197148':
        return 'Todo es Posible - Recordar el poder infinito de manifestación.';
      case '71931':
        return 'Protección - Fortalecer el campo energético y la protección áurica.';
      case '741':
        return 'Limpieza - Purificar energías negativas y bloqueos.';
      default:
        return 'Código sagrado para la manifestación y transformación energética.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy, color: Color(0xFFFFD700)),
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
                
                // Esfera 3D con Código
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Esfera dorada de fondo
                    Transform.scale(
                      scale: _isPiloting ? _pulseAnimation.value : 1.0,
                      child: GoldenSphere(
                        size: 280,
                        color: const Color(0xFFFFD700),
                        glowIntensity: _isPiloting ? 0.8 : 0.6,
                        isAnimated: true,
                      ),
                    ),
                    // Código superpuesto sin círculo negro
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isPiloting ? _pulseAnimation.value : 1.0,
                          child: Text(
                            widget.codigo,
                            style: GoogleFonts.spaceMono(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 6,
                              shadows: [
                                // Múltiples sombras para efecto 3D pronunciado
                                Shadow(
                                  color: Colors.black.withOpacity(0.9),
                                  blurRadius: 15,
                                  offset: const Offset(3, 3),
                                ),
                                Shadow(
                                  color: Colors.black.withOpacity(0.7),
                                  blurRadius: 8,
                                  offset: const Offset(1, 1),
                                ),
                                Shadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 2,
                                  offset: const Offset(-1, -1),
                                ),
                                Shadow(
                                  color: Colors.yellow.withOpacity(0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Descripción
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    _getCodeDescription(widget.codigo),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),
                
                // Control de Música y Timer si está pilotando
                if (_isPiloting) ...[
                  // Reproductor con precarga estilo streaming
                  const StreamedMusicController(autoPlay: true),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFFFFD700), width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Tiempo Restante',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                          style: GoogleFonts.spaceMono(
                            color: const Color(0xFFFFD700),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mantén tu atención en el código',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
                
                // Botón de Acción
                if (!_isPiloting && !_isPreloading)
                  CustomButton(
                    text: 'Pilotar Ahora',
                    onPressed: _startPiloting,
                    icon: Icons.play_arrow,
                  ),
                
                // Indicador de precarga
                if (_isPreloading)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFFFFD700), width: 2),
                    ),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Precargando Audio...',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFFD700),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Preparando música energizante',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 40),
                
                // Instrucciones
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Instrucciones de Pilotaje',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFFD700),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '1. Enfoca tu atención en el código\n'
                        '2. Visualiza el código brillando en dorado\n'
                        '3. Siente la energía fluyendo a través de ti\n'
                        '4. Mantén la intención durante 5 minutos',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                  ],
                ),
              ),
            ),
          ),
          
          // Indicador flotante de precarga
          if (_isPreloading) const AudioPreloadIndicator(),
        ],
      ),
    );
  }
}
