import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
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

  // Método para mostrar la nota importante (clonado de sesión de repeticiones)
  void _mostrarNotaImportante() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF363636),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFF5A623), width: 2),
          ),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFF5A623), size: 28),
              const SizedBox(width: 10),
              Text(
                'Nota Importante',
                style: GoogleFonts.inter(
                  color: const Color(0xFFF5A623),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Los códigos numéricos de Grabovoi NO sustituyen la atención médica profesional. '
            'Siempre consulta con profesionales de la salud para cualquier condición médica. '
            'Estos códigos son herramientas complementarias de bienestar.',
            style: GoogleFonts.inter(
              color: const Color(0xFFCCCCCC),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A623),
                  borderRadius: BorderRadius.circular(10),
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
        );
      },
    );
  }

  void _shareCode() async {
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
      
      final textToShare = '''${codigoEncontrado.codigo} : ${codigoEncontrado.nombre}
${codigoEncontrado.descripcion}
Obtuve esta información en la app: Manifestación Numérica Grabovoi''';
      
      await Share.share(textToShare);
    } catch (e) {
      // Fallback si hay error
      final textToShare = '''${widget.codigo} : Código Sagrado
Código sagrado para la manifestación y transformación energética.
Obtuve esta información en la app: Manifestación Numérica Grabovoi''';
      
      await Share.share(textToShare);
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
    // Modo de concentración (pantalla completa)
    if (_isConcentrationMode) {
      return _buildConcentrationMode();
    }

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
                
                
                // Botón de Acción eliminado - el pilotaje se inicia automáticamente
                
                
                const SizedBox(height: 40),
                
                  ],
                ),
              ),
            ),
          ),
          
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
}
