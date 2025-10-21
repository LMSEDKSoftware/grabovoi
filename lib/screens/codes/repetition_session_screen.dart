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
import '../../widgets/golden_sphere.dart';
import '../../widgets/streamed_music_controller.dart';
import '../../widgets/illuminated_code_text.dart';
import '../../utils/code_formatter.dart';
import '../../services/challenge_tracking_service.dart';
import '../../services/supabase_service.dart';
import '../../models/supabase_models.dart';


class RepetitionSessionScreen extends StatefulWidget {
  final String codigo;
  final String? nombre;

  const RepetitionSessionScreen({super.key, required this.codigo, this.nombre});

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
    _recordMeditationSession();
    
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
    
    // Iniciar automáticamente la repetición
    _startRepetition();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _colorBarController.dispose();
    super.dispose();
  }

  void _startRepetition() {
    setState(() {
      _isRepetitionActive = true;
    });
    // Ocultar la barra de colores después de 3 segundos
    _hideColorBarAfterDelay();
  }

  // Removed _formatCodeForDisplay method - now using CodeFormatter

  Future<void> _recordMeditationSession() async {
    // Registrar sesión de meditación para desafíos
    final trackingService = ChallengeTrackingService();
    await trackingService.recordMeditationSession(
      const Duration(minutes: 15), // Duración estimada de la sesión
    );
  }

  Future<void> _shareImage() async {
    try {
      final Uint8List? pngBytes = await _screenshotController.capture(pixelRatio: 2.0);
      if (pngBytes == null) return;

      // Solo para móvil, web no soporta compartir imágenes
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/grabovoi_${widget.codigo}.png');
        await file.writeAsBytes(pngBytes);

        await Share.shareXFiles([XFile(file.path)], text: '${widget.nombre}\n\n${widget.codigo}\n\nManifestación Numérica Grabovoi');
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al compartir: $e')),
      );
    }
  }

  // Función helper para obtener la descripción del código desde la base de datos
  Future<String> _getCodigoDescription() async {
    try {
      final codigos = await SupabaseService.getCodigos();
      final codigoEncontrado = codigos.firstWhere(
        (c) => c.codigo == widget.codigo,
        orElse: () => CodigoGrabovoi(
          id: '',
          codigo: widget.codigo,
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
  Future<String> _getCodigoTitulo() async {
    try {
      final codigos = await SupabaseService.getCodigos();
      final codigoEncontrado = codigos.firstWhere(
        (c) => c.codigo == widget.codigo,
        orElse: () => CodigoGrabovoi(
          id: '',
          codigo: widget.codigo,
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
      body: GlowBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Spacer(),
                    // Botón copiar en la parte superior derecha
                    IconButton(
                      onPressed: () async {
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
                              behavior: SnackBarBehavior.floating,
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
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy, color: Color(0xFFFFD700)),
                    ),
                    // Botón ver detalle
                    IconButton(
                      onPressed: () {
                        // Aquí puedes agregar la navegación a una pantalla de detalles
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Función en desarrollo'),
                            backgroundColor: Colors.blue,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline, color: Color(0xFFFFD700)),
                    ),
                    // Botón compartir/descargar
                    IconButton(
                      onPressed: _shareImage,
                      icon: const Icon(Icons.share, color: Color(0xFFFFD700)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Sesión de Repetición',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(height: 20),

                // Vista a capturar - Solo esfera como en pilotaje
                Center(
                  child: Screenshot(
                    controller: _screenshotController,
                    child: _buildIntegratedSphere(widget.codigo),
                  ),
                ),

                const SizedBox(height: 20),
                
                // Descripción del código
                Center(
                  child: FutureBuilder<Map<String, String>>(
                    future: Future.wait([
                      _getCodigoTitulo(),
                      _getCodigoDescription(),
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
                
                // Control de Música para sesión de repetición
                const StreamedMusicController(autoPlay: true, isActive: true),
                
                const SizedBox(height: 20),
                
                // Notas de la versión 1
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.medical_services, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Nota Importante',
                            style: GoogleFonts.inter(
                              color: Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Los códigos numéricos de Grabovoi NO sustituyen la atención médica profesional. '
                        'Siempre consulta con profesionales de la salud para cualquier condición médica. '
                        'Estos códigos son herramientas complementarias de bienestar.',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
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
      child: GestureDetector(
        onTap: _toggleColorBar,
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
              : Row(
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

  // ---- MÉTODO DE ESFERA INTEGRADA (igual que en Cuántico) ----
  Widget _buildIntegratedSphere(String codigoCrudo) {
    final String codigoFormateado = CodeFormatter.formatCodeForDisplay(codigoCrudo);
    final double fontSize = CodeFormatter.calculateFontSize(codigoCrudo);

    return Stack(
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

        // 3) SELECTOR DE COLORES
        _buildColorSelector(),
      ],
    );
  }
}


