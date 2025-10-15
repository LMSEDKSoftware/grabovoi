import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/sphere_3d.dart';
import '../../widgets/music_controller.dart';

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

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _startPiloting() {
    setState(() {
      _isPiloting = true;
      _secondsRemaining = 300; // 5 minutos
    });
    
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
        _startCountdown();
      } else {
        setState(() {
          _isPiloting = false;
        });
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
      body: GlowBackground(
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
                    // Esfera 3D de fondo
                    Transform.scale(
                      scale: _isPiloting ? _pulseAnimation.value : 1.0,
                      child: Sphere3D(
                        size: 280,
                        color: const Color(0xFFFFD700),
                        glowIntensity: _isPiloting ? 0.5 : 0.3,
                        isAnimated: true,
                      ),
                    ),
                    // Código superpuesto
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isPiloting ? _pulseAnimation.value : 1.0,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFFD700).withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              widget.codigo,
                              style: GoogleFonts.spaceMono(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFD700),
                                letterSpacing: 6,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.8),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
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
                
                // Control de Música Energizante
                const MusicController(showMusicList: false),
                const SizedBox(height: 30),
                
                // Timer si está pilotando
                if (_isPiloting) ...[
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
                if (!_isPiloting)
                  CustomButton(
                    text: 'Pilotar Ahora',
                    onPressed: _startPiloting,
                    icon: Icons.play_arrow,
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
    );
  }
}
