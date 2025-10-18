import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/golden_sphere.dart';
import '../../widgets/streamed_music_controller.dart';
import '../../widgets/music_info_card.dart';
import '../codes/code_detail_screen.dart';

class PilotajeScreen extends StatefulWidget {
  const PilotajeScreen({super.key});

  @override
  State<PilotajeScreen> createState() => _PilotajeScreenState();
}

class _PilotajeScreenState extends State<PilotajeScreen> with TickerProviderStateMixin {
  final List<String> _codigosRecomendados = [
    '5197148', // Todo es Posible
    '1884321', // Norma Absoluta
    '88888588888', // Código Universal
    '318798', // Prosperidad
    '71931', // Protección
    '741', // Limpieza
  ];

  String _codigoSeleccionado = '5197148';
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;

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
    super.dispose();
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
              // Botón de regreso
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 10),
              // Título - Movido más arriba
              Text(
                'Pilotaje Consciente',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700),
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
              const SizedBox(height: 40),
                
                // Esfera Dorada con Código
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Esfera dorada de fondo
                      Transform.scale(
                        scale: _pulseAnimation.value,
                        child: GoldenSphere(
                          size: 200,
                          color: const Color(0xFFFFD700),
                          glowIntensity: 0.8,
                          isAnimated: true,
                        ),
                      ),
                      // Código superpuesto
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Text(
                              _codigoSeleccionado,
                              style: GoogleFonts.spaceMono(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 4,
                                shadows: [
                                  // Múltiples sombras para efecto 3D pronunciado
                                  Shadow(
                                    color: Colors.black.withOpacity(0.9),
                                    blurRadius: 12,
                                    offset: const Offset(2, 2),
                                  ),
                                  Shadow(
                                    color: Colors.black.withOpacity(0.7),
                                    blurRadius: 6,
                                    offset: const Offset(1, 1),
                                  ),
                                  Shadow(
                                    color: Colors.white.withOpacity(0.5),
                                    blurRadius: 2,
                                    offset: const Offset(-1, -1),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
                // Control de Música Energizante con reproducción automática
                const StreamedMusicController(autoPlay: true),
                const SizedBox(height: 20),
                
                // Información sobre Frecuencias
                Text(
                  'Frecuencias Energizantes',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFrequencyInfo(),
                const SizedBox(height: 30),
                
                // Código Seleccionado
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFD700).withOpacity(0.2),
                        const Color(0xFFFFD700).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD700), width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Código Seleccionado',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _codigoSeleccionado,
                        style: GoogleFonts.spaceMono(
                          color: const Color(0xFFFFD700),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
                // Selección de Códigos
                Text(
                  'Selecciona un Código',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                
                // Grid de Códigos
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _codigosRecomendados.length,
                  itemBuilder: (context, index) {
                    final codigo = _codigosRecomendados[index];
                    final isSelected = codigo == _codigoSeleccionado;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _codigoSeleccionado = codigo;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? const Color(0xFFFFD700).withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? const Color(0xFFFFD700) 
                                : Colors.white.withOpacity(0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            codigo,
                            style: GoogleFonts.spaceMono(
                              color: isSelected 
                                  ? const Color(0xFFFFD700) 
                                  : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                
                // Botones de Acción
                CustomButton(
                  text: 'Iniciar Pilotaje',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CodeDetailScreen(
                          codigo: _codigoSeleccionado,
                        ),
                      ),
                    );
                  },
                  icon: Icons.play_arrow,
                ),
                const SizedBox(height: 15),
                CustomButton(
                  text: 'Pilotaje Aleatorio',
                  onPressed: () {
                    final randomCodigo = _codigosRecomendados[
                      (DateTime.now().millisecondsSinceEpoch % _codigosRecomendados.length)
                    ];
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CodeDetailScreen(
                          codigo: randomCodigo,
                        ),
                      ),
                    );
                  },
                  isOutlined: true,
                  icon: Icons.shuffle,
                ),
                const SizedBox(height: 40),
              ],
            ),
        ),
      ),
    );
  }

  Widget _buildFrequencyInfo() {
    return Column(
      children: [
        MusicInfoCard(
          title: '432Hz - Armonía Universal',
          description: 'Frecuencia de sanación natural, reduce estrés y promueve la armonía.',
          frequency: '432Hz',
          icon: Icons.healing,
          color: const Color(0xFF4CAF50),
        ),
        const SizedBox(height: 8),
        MusicInfoCard(
          title: '528Hz - Frecuencia del Amor',
          description: 'Transformación y reparación del ADN, amor incondicional y sanación.',
          frequency: '528Hz',
          icon: Icons.favorite,
          color: const Color(0xFFE91E63),
        ),
        const SizedBox(height: 8),
        MusicInfoCard(
          title: 'Binaural Beats',
          description: 'Ondas cerebrales para estados de meditación profunda y manifestación.',
          frequency: 'Theta 4-8Hz',
          icon: Icons.psychology,
          color: const Color(0xFF9C27B0),
        ),
      ],
    );
  }
}
