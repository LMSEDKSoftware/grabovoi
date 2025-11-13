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
import '../../services/daily_code_service.dart';
import '../../services/auth_service_simple.dart';
import '../../models/supabase_models.dart';
import '../../utils/code_formatter.dart';
import '../pilotaje/pilotaje_screen.dart';
import '../desafios/desafios_screen.dart';
import '../codes/code_detail_screen.dart';
import '../../main.dart';
import '../../repositories/codigos_repository.dart';
import '../../services/subscription_service.dart';
import '../../widgets/subscription_required_modal.dart';
import '../subscription/subscription_screen.dart';
import '../../widgets/energy_stats_tab.dart';

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
  
  String _userName = '';
  final AuthServiceSimple _authService = AuthServiceSimple();
  
  // La esfera de inicio es solo decorativa, sin funcionalidades interactivas

  @override
  void initState() {
    super.initState();
    _cargarDatosHome();
    _cargarNombreUsuario();
    _checkOnboarding();
    // Verificar si debe mostrar el modal de bienvenida
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await _checkWelcomeModal();
      }
    });
  }
  
  Future<void> _checkOnboarding() async {
    // El onboarding ya se maneja en AuthWrapper, no es necesario verificar aquí
    // Esta función se mantiene por compatibilidad pero no hace nada
  }

  Future<void> _cargarNombreUsuario() async {
    try {
      await _authService.initialize();
      final user = _authService.currentUser;
      if (user != null && mounted) {
        setState(() {
          _userName = user.name;
        });
      }
    } catch (e) {
      debugPrint('Error cargando nombre de usuario: $e');
    }
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

  bool _hasCheckedModalThisSession = false;
  
  /// Verifica y muestra el modal de bienvenida
  Future<void> _checkWelcomeModal() async {
    if (_hasCheckedModalThisSession) return;

    final prefs = await SharedPreferences.getInstance();
    final welcomeModalShown = prefs.getBool('welcome_modal_shown') ?? false;

    // Mostrar solo si el modal nunca se mostró
    if (!welcomeModalShown && mounted) {
      _hasCheckedModalThisSession = true;

      // Pequeño delay para esperar que la UI esté lista
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const WelcomeModal(),
      );

      // Marcar como mostrado (solo una vez)
      await prefs.setBool('welcome_modal_shown', true);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        body: GlowBackground(
          child: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portal Energético',
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _datosHome['fraseMotivacional'],
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 30),
                // Esfera con nombre del usuario sobre ella
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      GoldenSphere(
                    size: 180,
                    color: const Color(0xFFFFD700), // Color dorado fijo
                    glowIntensity: 0.7,
                    isAnimated: true,
                      ),
                      // Nombre del usuario sobre la esfera con estilo de código
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Bienvenid@',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.8),
                                  blurRadius: 6.0,
                                  offset: const Offset(2.0, 2.0),
                                ),
                                Shadow(
                                  color: Colors.black.withOpacity(0.6),
                                  blurRadius: 3.0,
                                  offset: const Offset(-1.0, -1.0),
                                ),
                                Shadow(
                                  color: const Color(0xFFFFD700).withOpacity(1.0),
                                  blurRadius: 30,
                                  offset: const Offset(0, 0),
                                ),
                                Shadow(
                                  color: Colors.white.withOpacity(0.8),
                                  blurRadius: 20,
                                  offset: const Offset(0, 0),
                                ),
                                Shadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.6),
                                  blurRadius: 40,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_userName.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              _userName,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.8),
                                    blurRadius: 6.0,
                                    offset: const Offset(2.0, 2.0),
                                  ),
                                  Shadow(
                                    color: Colors.black.withOpacity(0.6),
                                    blurRadius: 3.0,
                                    offset: const Offset(-1.0, -1.0),
                                  ),
                                  Shadow(
                                    color: const Color(0xFFFFD700).withOpacity(1.0),
                                    blurRadius: 30,
                                    offset: const Offset(0, 0),
                                  ),
                                  Shadow(
                                    color: Colors.white.withOpacity(0.8),
                                    blurRadius: 20,
                                    offset: const Offset(0, 0),
                                  ),
                                  Shadow(
                                    color: const Color(0xFFFFD700).withOpacity(0.6),
                                    blurRadius: 40,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildEnergyCard('Tu Nivel Energético hoy', '${_datosHome['nivel']}/10', Icons.bolt),
                const SizedBox(height: 20),
                _buildCodeOfDay(context, _datosHome['codigoRecomendado']),
                const SizedBox(height: 20),
                _buildNextStep(_datosHome['proximoPaso']),
                  ],
                ),
              ),
            ),
            // Solapa flotante de estadísticas de energía (esquina superior derecha)
            Positioned(
              top: 0,
              right: 0,
              child: const EnergyStatsTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnergyCard(String title, String value, IconData icon) {
    return Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1),
          ),
        child: Column(
          children: [
            Row(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            value,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFFFD700),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          onPressed: _mostrarModalNivelEnergetico,
                          child: const Text('¿Cómo funciona?'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
            const SizedBox(height: 12),
            Text(
              'Tu energía se eleva con cada pilotaje consciente',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white30,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeOfDay(BuildContext context, String codigo) {
    // En la pantalla de inicio, mostrar el código original con _ sin formateo multilínea
    final fontSize = CodeFormatter.calculateFontSize(codigo);
    final subscriptionService = SubscriptionService();
    
    return Center(
      child: GestureDetector(
        onTap: () async {
          // Verificar si el usuario es gratuito (sin suscripción después de los 7 días)
          if (subscriptionService.isFreeUser) {
            // Usuario gratuito - redirigir a suscripciones
            SubscriptionRequiredModal.show(
              context,
              message: 'El pilotaje cuántico está disponible solo para usuarios Premium. Suscríbete para acceder a esta función.',
            );
            return;
          }
          
          // Usuario premium - permitir acceso normal
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CodeDetailScreen(codigo: codigo),
            ),
          );
          // Al volver de la sesión/código, refrescar nivel y datos
          if (mounted) {
            await _cargarDatosHome();
          }
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
              Text('Tu código diario', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Toca para pilotar', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                  const SizedBox(width: 8),
                  const Icon(Icons.diamond, color: Colors.white54, size: 14),
                  Text(
                    '+3',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
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
        return _NivelEnergeticoModal();
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
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Función helper para obtener la descripción del código desde la base de datos
  Future<String> _getCodigoDescription(String codigo) async {
    try {
      // Obtener información del código del día desde DailyCodeService
      // Esto ya busca en daily_codes y codigos_grabovoi
      final todayInfo = await DailyCodeService.getTodayCodeInfo();
      if (todayInfo != null && todayInfo['codigo'] == codigo) {
        return todayInfo['descripcion'] ?? 'Código sagrado para la manifestación y transformación energética.';
      }
      
      // Si el código del día no coincide, buscar directamente en codigos_grabovoi
      return CodigosRepository().getDescripcionByCode(codigo);
    } catch (e) {
      return 'Código sagrado para la manifestación y transformación energética.';
    }
  }

  // Función helper para obtener el título del código desde la base de datos
  Future<String> _getCodigoTitulo(String codigo) async {
    try {
      // Obtener información del código del día desde DailyCodeService
      // Esto ya busca en daily_codes y codigos_grabovoi
      final todayInfo = await DailyCodeService.getTodayCodeInfo();
      if (todayInfo != null && todayInfo['codigo'] == codigo) {
        return todayInfo['nombre'] ?? 'Código Diario';
      }
      
      // Si el código del día no coincide, buscar directamente en codigos_grabovoi
      return CodigosRepository().getTituloByCode(codigo);
    } catch (e) {
      return 'Código Diario';
    }
  }
}

class _NivelEnergeticoModal extends StatefulWidget {
  @override
  State<_NivelEnergeticoModal> createState() => _NivelEnergeticoModalState();
}

class _NivelEnergeticoModalState extends State<_NivelEnergeticoModal> {
  late ScrollController _scrollController;
  bool _showScrollIndicator = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_checkScrollPosition);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollPosition();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScrollPosition() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final canScroll = maxScroll > 0;
      final shouldShow = canScroll && currentScroll < maxScroll - 50;
      if (_showScrollIndicator != shouldShow) {
        setState(() {
          _showScrollIndicator = shouldShow;
        });
      }
    }
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
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
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
        child: Stack(
          children: [
            SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                
                // Botón de cerrar
                CustomButton(
                  text: 'Entendido',
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                  icon: Icons.check,
                ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      // Indicador de scroll flotante
                      if (_showScrollIndicator)
                        Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                const Color(0xFF1C2541).withOpacity(0.9),
                                const Color(0xFF1C2541),
              ],
            ),
          ),
                          child: Column(
      children: [
                              Icon(
                                Icons.keyboard_arrow_up,
                                color: const Color(0xFFFFD700).withOpacity(0.7),
                                size: 32,
                              ),
                              Text(
                                'Desliza hacia arriba',
            style: GoogleFonts.inter(
                                  color: const Color(0xFFFFD700).withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
            ),
          ),
        ),
      ],
        ),
      ),
    );
  }
}
