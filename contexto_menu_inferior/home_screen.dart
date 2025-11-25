import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/golden_sphere.dart';
import '../../widgets/illuminated_code_text.dart';
import '../../widgets/welcome_modal.dart';
import '../../services/biblioteca_supabase_service.dart';
import '../../services/daily_code_service.dart';
import '../../services/auth_service_simple.dart';
import '../../utils/code_formatter.dart';
import '../codes/code_detail_screen.dart';
import '../../repositories/codigos_repository.dart';
import '../../services/subscription_service.dart';
import '../../widgets/subscription_required_modal.dart';
import '../../widgets/energy_stats_tab.dart';
import '../../widgets/mural_modal.dart';
import '../../services/mural_service.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  Map<String, dynamic> _datosHome = {
    'nivel': 1,
    'codigoRecomendado': '5197148',
    'fraseMotivacional': '🌙 El viaje de mil millas comienza con un solo paso.',
    'proximoPaso': 'Realiza tu primer pilotaje consciente hoy',
  };
  
  String _userName = '';
  final AuthServiceSimple _authService = AuthServiceSimple();
  final MuralService _muralService = MuralService();
  
  // La esfera de inicio es solo decorativa, sin funcionalidades interactivas

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarDatosHome();
    _cargarNombreUsuario();
    _checkMuralMessages();
    _checkOnboarding();
    // Verificar si debe mostrar el modal de bienvenida
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await _checkWelcomeModal();
      }
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refrescar cuando la app vuelve a estar activa
    if (state == AppLifecycleState.resumed && mounted) {
      _cargarDatosHome();
      _checkMuralMessages();
      // El EnergyStatsTab se refrescará automáticamente
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // El EnergyStatsTab se refrescará automáticamente mediante su propio mecanismo
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

  Future<void> _checkMuralMessages() async {
    try {
      final count = await _muralService.getUnreadCount();
      if (count > 0 && mounted) {
        // Si hay mensajes no leídos, mostrar el modal automáticamente
        // Usamos addPostFrameCallback para asegurar que el contexto esté listo si se llama desde initState
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showMuralModal();
        });
      }
    } catch (e) {
      debugPrint('Error verificando mensajes del mural: $e');
    }
  }

  void _showMuralModal() {
    // Evitar abrir múltiples modales si ya hay uno abierto (opcional, pero buena práctica)
    // Por simplicidad, confiamos en que _checkMuralMessages se llama controladamente
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const MuralModal(),
    ).then((_) {
      // Al cerrar el modal, podríamos actualizar estado si fuera necesario
      // pero como ya no hay botón con badge, no es crítico actualizar _unreadMuralMessages
    });
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

  // ... resto del código de HomeScreen (métodos _buildEnergyCard, _buildCodeOfDay, etc.)
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
    final fontSize = CodeFormatter.calculateFontSize(codigo);
    final subscriptionService = SubscriptionService();
    
    return Center(
      child: GestureDetector(
        onTap: () async {
          if (subscriptionService.isFreeUser) {
            SubscriptionRequiredModal.show(
              context,
              message: 'El pilotaje cuántico está disponible solo para usuarios Premium. Suscríbete para acceder a esta función.',
            );
            return;
          }
          
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CodeDetailScreen(codigo: codigo),
            ),
          );
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
        return const Dialog(
          child: Text('Modal de nivel energético'),
        );
      },
    );
  }
}

