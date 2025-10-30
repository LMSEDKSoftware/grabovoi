import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/golden_sphere.dart';
import '../../widgets/streamed_music_controller.dart';
import '../../widgets/illuminated_code_text.dart';
import '../../utils/code_formatter.dart';
import '../../services/supabase_service.dart';
import '../../models/supabase_models.dart';
import '../../repositories/codigos_repository.dart';
import '../codes/code_detail_screen.dart';

class PilotajeScreen extends StatefulWidget {
  final String? codigoInicial;
  
  const PilotajeScreen({super.key, this.codigoInicial});

  @override
  State<PilotajeScreen> createState() => _PilotajeScreenState();
}

class _PilotajeScreenState extends State<PilotajeScreen> with TickerProviderStateMixin {
  String _codigoPersonalizado = '';
  bool _isMusicActive = false;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  
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
    
    // Usar código inicial si está disponible
    if (widget.codigoInicial != null) {
      _codigoPersonalizado = widget.codigoInicial!;
    }
    
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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _colorBarController.dispose();
    super.dispose();
  }

  void _showCodigoPersonalizadoDialog() {
    final TextEditingController controller = TextEditingController(text: _codigoPersonalizado);
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2541),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título
                Text(
                  'Código Personalizado',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Campo de texto
                TextField(
                  controller: controller,
                  style: GoogleFonts.spaceMono(
                    fontSize: 18,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ingresa tu código...',
                    hintStyle: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: const Color(0xFFFFD700)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Botones
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Usar Código',
                        onPressed: () {
                          setState(() {
                            _codigoPersonalizado = controller.text.trim();
                          });
                          Navigator.of(context).pop();
                        },
                        icon: Icons.check,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Cancelar',
                        onPressed: () => Navigator.of(context).pop(),
                        isOutlined: true,
                        icon: Icons.close,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPilotajeInstructions() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2541),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título
                Text(
                  'Instrucciones de Pilotaje',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Instrucciones numeradas
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInstructionItem('1', 'Enfoca tu atención en el código'),
                    const SizedBox(height: 16),
                    _buildInstructionItem('2', 'Visualiza el código brillando en dorado'),
                    const SizedBox(height: 16),
                    _buildInstructionItem('3', 'Siente la energía fluyendo a través de ti'),
                    const SizedBox(height: 16),
                    _buildInstructionItem('4', 'Mantén la intención durante 5 minutos'),
                  ],
                ),
                const SizedBox(height: 32),
                
                  // Botón de continuar
                  CustomButton(
                    text: 'Comenzar Pilotaje',
                    onPressed: () {
                      Navigator.of(context).pop(); // Cerrar modal
                      setState(() {
                        _isMusicActive = true; // Activar música
                      });
                      // Ocultar la barra de colores después de 3 segundos
                      _hideColorBarAfterDelay();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CodeDetailScreen(
                            codigo: _codigoPersonalizado.isNotEmpty ? _codigoPersonalizado : '5197148',
                          ),
                        ),
                      );
                    },
                    icon: Icons.play_arrow,
                  ),
                const SizedBox(height: 12),
                
                // Botón de cancelar
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1C2541),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // Función helper para obtener la descripción del código desde la base de datos
  Future<String> _getCodigoDescription() async {
    final codigoMostrar = _codigoPersonalizado.isNotEmpty ? _codigoPersonalizado : '88888588888';
    
    try {
      return CodigosRepository().getDescripcionByCode(codigoMostrar);
    } catch (e) {
      return 'Código sagrado para la manifestación y transformación energética.';
    }
  }

  // Función helper para obtener el título del código desde la base de datos
  Future<String> _getCodigoTitulo() async {
    final codigoMostrar = _codigoPersonalizado.isNotEmpty ? _codigoPersonalizado : '88888588888';
    
    try {
      return CodigosRepository().getTituloByCode(codigoMostrar);
    } catch (e) {
      return 'Campo Energético';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título de la sección
              Text(
                'Pilotaje Consciente',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700),
                  shadows: [
                    Shadow(
                      color: const Color(0xFFFFD700).withOpacity(0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dirige tu realidad con intención',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 20),
              
              // Esfera Dorada con Código (como en repeticiones)
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Esfera dorada con animaciones
                    Transform.scale(
                      scale: _pulseAnimation.value,
                      child: GoldenSphere(
                        size: 280,
                        color: _getColorSeleccionado(),
                        glowIntensity: 0.8,
                        isAnimated: true,
                      ),
                    ),
                    // Números blancos con animaciones
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        final codigoMostrar = _codigoPersonalizado.isNotEmpty ? _codigoPersonalizado : '88888588888';
                        final codigoFormateado = CodeFormatter.formatCodeForDisplay(codigoMostrar);
                        final necesitaMultilinea = CodeFormatter.needsMultilineFormat(codigoMostrar);
                        final fontSize = CodeFormatter.calculateFontSize(codigoMostrar);
                        
                        return Transform.scale(
                          scale: _pulseAnimation.value,
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
                    // Selector de colores en la parte inferior
                    Positioned(
                      bottom: -60,
                      child: _buildColorSelector(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
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
              const SizedBox(height: 30),
              
              // Control de Música Energizante con reproducción automática
              StreamedMusicController(autoPlay: true, isActive: _isMusicActive),
              const SizedBox(height: 40),
              
              // Botones de Acción
              CustomButton(
                text: 'Ingresar Código Personalizado',
                onPressed: () {
                  _showCodigoPersonalizadoDialog();
                },
                icon: Icons.edit,
              ),
              const SizedBox(height: 15),
              CustomButton(
                text: 'Iniciar Pilotaje',
                onPressed: () {
                  if (_codigoPersonalizado.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Por favor ingresa un código personalizado primero'),
                        backgroundColor: const Color(0xFFFFD700),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  _showPilotajeInstructions();
                },
                icon: Icons.play_arrow,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  
  // Métodos para controlar la animación de la barra de colores
  void _hideColorBarAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (_isMusicActive && mounted) {
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

}
