import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/golden_sphere.dart';
import '../../widgets/streamed_music_controller.dart';
import '../../widgets/audio_preload_indicator.dart';
import '../../widgets/illuminated_code_text.dart';
import '../../services/audio_preload_service.dart';
import '../../services/challenge_tracking_service.dart';
import '../../services/supabase_service.dart';
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
    'azul_celestial': const Color(0xFF87CEEB),
    'categoria': const Color(0xFFFFD700), // Se actualizará dinámicamente
  };
  
  // Variables para el modo concentración
  bool _isConcentrationMode = false;
  

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
Obtuve esta información en la app: Manifestación Numérica Grabovoi''';
      
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
                
                // Esfera integrada (sin contenedor rectangular oscuro)
                _buildQuantumDetailSphere(widget.codigo),
                const SizedBox(height: 80), // Más espacio para el selector de colores
                
                // Descripción
                Center(
                  child: FutureBuilder<Map<String, String>>(
                    future: Future.wait([
                      _getCodeTitulo(widget.codigo),
                      _getCodeDescription(widget.codigo),
                    ]).then((results) => {
                      'titulo': results[0],
                      'descripcion': results[1],
                    }),
                    builder: (context, snapshot) {
                      final titulo = snapshot.data?['titulo'] ?? 'Campo Energético';
                      final descripcion = snapshot.data?['descripcion'] ?? 'Código sagrado para la manifestación y transformación energética.';
                      
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
                          children: [
                            Text(
                              titulo,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFD700),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              descripcion,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                height: 1.4,
                              ),
                            ),
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
                
                // Control de Timer si está pilotando
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
                
                // Botón de Acción eliminado - el pilotaje se inicia automáticamente
                
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
  
  
  Color _getColorSeleccionado() {
    if (_colorSeleccionado == 'categoria') {
      return _coloresDisponibles['categoria']!;
    }
    return _coloresDisponibles[_colorSeleccionado]!;
  }
  
  // Método para alternar el modo concentración
  void _toggleConcentrationMode() {
    setState(() {
      _isConcentrationMode = !_isConcentrationMode;
    });
  }
  
  // Método para construir el selector de colores (igual que en Sesión de Repetición)
  Widget _buildColorSelector() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              onTap: _toggleConcentrationMode,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fullscreen,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
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

        // 3️⃣ Selector de colores en la parte inferior
        Positioned(
          bottom: -40, // Ajustado para evitar superposición
          child: _buildColorSelector(),
        ),
      ],
    );
  }
}
