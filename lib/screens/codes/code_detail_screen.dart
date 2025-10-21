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
  
  // Variables para la animación de la barra de colores
  bool _isColorBarExpanded = true;
  late AnimationController _colorBarController;
  late Animation<Offset> _colorBarAnimation;

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
    
    // Inicializar controlador de animación de la barra de colores
    _colorBarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _colorBarAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.3, 0), // Se desliza hacia la derecha
    ).animate(CurvedAnimation(
      parent: _colorBarController,
      curve: Curves.easeInOut,
    ));
    
    // Ocultar la barra de colores después de 3 segundos
    _hideColorBarAfterDelay();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _colorBarController.dispose();
    // Evitar setState tras dispose en countdown
    _secondsRemaining = 0;
    super.dispose();
  }

  Future<void> _startPiloting() async {
    setState(() {
      _isPreloading = true;
    });
    // Ocultar la barra de colores después de 3 segundos
    _hideColorBarAfterDelay();
    
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
      final codigos = await SupabaseService.getCodigos();
      final codigoEncontrado = codigos.firstWhere(
        (c) => c.codigo == codigo,
        orElse: () => CodigoGrabovoi(
          id: '',
          codigo: codigo,
          nombre: 'Campo Energético',
          descripcion: 'Código sagrado para la manifestación y transformación energética.',
          categoria: 'General',
          color: '#FFD700',
        ),
      );
      return codigoEncontrado.descripcion;
    } catch (e) {
      return 'Código sagrado para la manifestación y transformación energética.';
    }
  }

  // Función helper para obtener el título del código desde la base de datos
  Future<String> _getCodeTitulo(String codigo) async {
    try {
      final codigos = await SupabaseService.getCodigos();
      final codigoEncontrado = codigos.firstWhere(
        (c) => c.codigo == codigo,
        orElse: () => CodigoGrabovoi(
          id: '',
          codigo: codigo,
          nombre: 'Campo Energético',
          descripcion: 'Código sagrado para la manifestación y transformación energética.',
          categoria: 'General',
          color: '#FFD700',
        ),
      );
      return codigoEncontrado.nombre;
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
  
  // Métodos para controlar la animación de la barra de colores
  void _hideColorBarAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (_isPiloting && mounted) {
        setState(() {
          _isColorBarExpanded = false;
        });
        _colorBarController.forward();
      }
    });
  }
  
  void _toggleColorBar() {
    setState(() {
      _isColorBarExpanded = !_isColorBarExpanded;
    });
    
    if (_isColorBarExpanded) {
      _colorBarController.reverse();
    } else {
      _colorBarController.forward();
    }
  }
  
  void _selectColor(String color) {
    setState(() {
      _colorSeleccionado = color;
    });
    
    // Ocultar la barra después de 3 segundos
    _hideColorBarAfterDelay();
  }
  
  Color _getColorSeleccionado() {
    if (_colorSeleccionado == 'categoria') {
      return _coloresDisponibles['categoria']!;
    }
    return _coloresDisponibles[_colorSeleccionado]!;
  }
  
  // Método para construir el selector de colores
  Widget _buildColorSelector() {
    return SlideTransition(
      position: _colorBarAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: _getColorSeleccionado().withOpacity(0.5),
            width: 1,
          ),
        ),
        child: _isColorBarExpanded
            ? Row(
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
                        behavior: HitTestBehavior.translucent,
                        onTap: () => _selectColor(entry.key),
                        child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: entry.value,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: entry.value.withOpacity(0.8),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ],
              )
            : GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _toggleColorBar,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getColorSeleccionado(),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getColorSeleccionado().withOpacity(0.8),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Toca para cambiar',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
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
