import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/golden_sphere.dart';
import '../../widgets/illuminated_code_text.dart';
import '../../widgets/welcome_modal.dart';
import '../../services/biblioteca_supabase_service.dart';
import '../../services/supabase_service.dart';
import '../../models/supabase_models.dart';
import '../../utils/code_formatter.dart';
import '../pilotaje/pilotaje_screen.dart';
import '../desafios/desafios_screen.dart';
import '../codes/code_detail_screen.dart';
import '../../main.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  Map<String, dynamic> _datosHome = {
    'nivel': 1,
    'codigoRecomendado': '5197148',
    'fraseMotivacional': '🌙 El viaje de mil millas comienza con un solo paso.',
    'proximoPaso': 'Realiza tu primer pilotaje consciente hoy',
  };
  
  // La esfera de inicio es solo decorativa, sin funcionalidades interactivas

  @override
  void initState() {
    super.initState();
    _cargarDatosHome();
    _checkWelcomeModal();
  }

  Future<void> _cargarDatosHome() async {
    try {
      final datos = await BibliotecaSupabaseService.getDatosParaHome();
      if (mounted) {
        setState(() {
          _datosHome = datos;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar datos de home: $e');
    }
  }

  Future<void> _checkWelcomeModal() async {
    final prefs = await SharedPreferences.getInstance();
    final welcomeModalShown = prefs.getBool('welcome_modal_shown') ?? false;

    // Verifica que no se haya mostrado antes y que el widget esté montado
    if (!welcomeModalShown && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const WelcomeModal(),
        );
      });
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
                Text(
                  'Portal Energético',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
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
                  _datosHome['fraseMotivacional'],
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),
                // Esfera decorativa simple - solo visual, sin funcionalidades
                Center(
                  child: GoldenSphere(
                    size: 180,
                    color: const Color(0xFFFFD700), // Color dorado fijo
                    glowIntensity: 0.7,
                    isAnimated: true,
                  ),
                ),
                const SizedBox(height: 30),
                _buildEnergyCard('Nivel Energético', '${_datosHome['nivel']}/10', Icons.bolt),
                const SizedBox(height: 20),
                _buildCodeOfDay(context, _datosHome['codigoRecomendado']),
                const SizedBox(height: 20),
                _buildNextStep(_datosHome['proximoPaso']),
                const SizedBox(height: 30),
                Center(
                  child: CustomButton(
                    text: 'Ver Desafíos', 
                    onPressed: () {
                      if (widget.onNavigateToTab != null) {
                        widget.onNavigateToTab!(3); // Índice de DesafiosScreen
                      }
                    }, 
                    isOutlined: true,
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: Text(
                    'Tu energía se eleva con cada pilotaje consciente',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white30,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnergyCard(String title, String value, IconData icon) {
    return Center(
      child: GestureDetector(
        onTap: () => _mostrarModalNivelEnergetico(),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFFFFD700), size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeOfDay(BuildContext context, String codigo) {
    // En la pantalla de inicio, mostrar el código original con _ sin formateo multilínea
    final fontSize = CodeFormatter.calculateFontSize(codigo);
    
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CodeDetailScreen(codigo: codigo),
            ),
          );
        },
        child: Container(
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
              Text('Código Recomendado', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 12),
              IlluminatedCodeText(
                code: codigo,
                fontSize: fontSize,
                color: const Color(0xFFFFD700),
                letterSpacing: 4,
                isAnimated: false,
              ),
              const SizedBox(height: 16),
              // Descripción del código
              FutureBuilder<Map<String, String>>(
                future: Future.wait([
                  _getCodigoTitulo(codigo),
                  _getCodigoDescription(codigo),
                ]).then((results) => {
                  'titulo': results[0],
                  'descripcion': results[1],
                }),
                builder: (context, snapshot) {
                  final titulo = snapshot.data?['titulo'] ?? 'Campo Energético';
                  final descripcion = snapshot.data?['descripcion'] ?? 'Código sagrado para la manifestación y transformación energética.';
                  
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
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
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFD700),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          descripcion,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text('Toca para pilotar', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextStep(String step) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 20),
            const SizedBox(width: 12),
            Flexible(
              child: Text(step, style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarModalNivelEnergetico() {
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
                // Icono y título
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bolt, color: Color(0xFFFFD700), size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Nivel Energético',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Explicación
                Text(
                  'Es un sistema de puntuación que representa el estado energético/vibracional del usuario, basado en su evaluación inicial y actividades en la app.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Información adicional
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '¿Cómo funciona?',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoItem('• Es parte de la escala de niveles en el formulario que se llenó al inicio'),
                      const SizedBox(height: 8),
                      _buildInfoItem('• Se actualiza con el uso de la app'),
                      const SizedBox(height: 8),
                      _buildInfoItem('• Completar desafíos aumenta el nivel'),
                      const SizedBox(height: 8),
                      _buildInfoItem('• Practicar códigos regularmente mejora el nivel'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Mensaje final
                Text(
                  '"El sistema está diseñado para crecer contigo mientras usas la app y practicas los códigos de Grabovoi."',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Botón de cerrar
                CustomButton(
                  text: 'Entendido',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icons.check,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // Función helper para obtener la descripción del código desde la base de datos
  Future<String> _getCodigoDescription(String codigo) async {
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
  Future<String> _getCodigoTitulo(String codigo) async {
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
  
}
