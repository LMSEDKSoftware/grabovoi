import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/challenge_service.dart';
import '../../services/user_progress_service.dart';
import '../../services/auth_service_simple.dart';
import '../../services/app_time_tracker.dart';
import '../../models/challenge_model.dart';
import '../../services/subscription_service.dart';
import '../../widgets/subscription_required_modal.dart';

class EvolucionScreen extends StatefulWidget {
  const EvolucionScreen({super.key});

  @override
  State<EvolucionScreen> createState() => _EvolucionScreenState();
}

class _EvolucionScreenState extends State<EvolucionScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  final UserProgressService _progressService = UserProgressService();
  final AuthServiceSimple _authService = AuthServiceSimple();
  final ChallengeService _challengeService = ChallengeService();
  final AppTimeTracker _appTimeTracker = AppTimeTracker();
  
  Map<String, dynamic>? userProgress;
  Map<String, dynamic>? activeChallenge;
  List<Map<String, dynamic>> completedChallenges = [];
  bool isLoading = true;
  Timer? _sessionTimeUpdateTimer;
  
  // Caché para códigos explorados
  int? _cachedExploredCodesCount;
  DateTime? _cacheTimestamp;
  static const _cacheDuration = Duration(minutes: 5);
  
  // Animación de flama
  late AnimationController _flameController;
  late Animation<double> _flameAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appTimeTracker.addListener(_updateSessionTime);
    _startSessionTimeTimer();
    
    // Inicializar animación de flama (movimiento de fuego más realista)
    _flameController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat();
    
    _flameAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: -0.12, end: 0.08).chain(
        CurveTween(curve: Curves.easeInOut),
      ), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 0.08, end: -0.1).chain(
        CurveTween(curve: Curves.easeInOut),
      ), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -0.1, end: 0.12).chain(
        CurveTween(curve: Curves.easeInOut),
      ), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 0.12, end: -0.12).chain(
        CurveTween(curve: Curves.easeInOut),
      ), weight: 1),
    ]).animate(_flameController);
    
    // Verificar si el usuario es gratuito después de los 7 días
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subscriptionService = SubscriptionService();
      if (subscriptionService.isFreeUser && mounted) {
        SubscriptionRequiredModal.show(
          context,
          message: 'La sección de Evolución está disponible solo para usuarios Premium. Suscríbete para acceder a esta función.',
          onDismiss: () {
            // Redirigir a Inicio después de cerrar el modal
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        );
      }
    });
    
    _loadUserData();
    _loadExploredCodesCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appTimeTracker.removeListener(_updateSessionTime);
    _sessionTimeUpdateTimer?.cancel();
    _flameController.dispose();
    super.dispose();
  }

  void _startSessionTimeTimer() {
    // Actualizar el tiempo de sesión cada segundo para mostrar el tiempo en tiempo real
    _sessionTimeUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Solo actualizar para forzar rebuild y mostrar el tiempo actualizado
        });
      }
    });
  }

  void _updateSessionTime() {
    if (mounted) {
      setState(() {
        // Forzar rebuild para actualizar el tiempo de sesión
      });
    }
  }

  // Hook: refrescar cuando la app vuelve al primer plano o cuando se reentra a la sección
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadUserData();
      // Refrescar códigos explorados forzando actualización
      _loadExploredCodesCount(forceRefresh: true);
    }
  }

  // Obtener conteo de códigos explorados desde user_actions (fuente única de verdad)
  // Consulta directamente desde user_actions para evitar duplicación de datos
  Future<int> _getExploredCodesCount({bool forceRefresh = false}) async {
    if (!_authService.isLoggedIn) {
      return 0;
    }

    // Usar caché si está disponible y no ha expirado
    if (!forceRefresh && 
        _cachedExploredCodesCount != null && 
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      return _cachedExploredCodesCount!;
    }

    try {
      final supabase = Supabase.instance.client;
      final userId = _authService.currentUser!.id;
      
      // Consultar directamente desde user_actions (fuente única de verdad)
      // Filtrar solo acciones que involucran códigos
      final response = await supabase
          .from('user_actions')
          .select('action_data')
          .eq('user_id', userId)
          .inFilter('action_type', ['sesionPilotaje', 'codigoRepetido', 'pilotajeCompartido']);
      
      // Obtener códigos únicos desde action_data
      final uniqueCodes = <String>{};
      for (final row in response) {
        final actionData = row['action_data'] as Map<String, dynamic>?;
        if (actionData != null) {
          final codeId = actionData['codeId'] as String?;
          if (codeId != null && codeId.isNotEmpty) {
            uniqueCodes.add(codeId);
          }
        }
      }
      
      final count = uniqueCodes.length;
      
      // Guardar en caché
      _cachedExploredCodesCount = count;
      _cacheTimestamp = DateTime.now();
      
      print('✅ Códigos explorados encontrados: $count (desde user_actions)');
      return count;
    } catch (e) {
      print('❌ Error obteniendo códigos explorados: $e');
      // Si hay error pero tenemos caché, usar el valor en caché
      if (_cachedExploredCodesCount != null) {
        return _cachedExploredCodesCount!;
      }
      return 0;
    }
  }
  
  // Cargar códigos explorados una vez al iniciar
  Future<void> _loadExploredCodesCount({bool forceRefresh = false}) async {
    final count = await _getExploredCodesCount(forceRefresh: forceRefresh);
    if (mounted) {
      setState(() {
        _cachedExploredCodesCount = count;
      });
    }
  }

  Future<void> _loadUserData() async {
    if (!_authService.isLoggedIn) {
      setState(() {
        userProgress = {
          'nivel': 1,
          'dias_consecutivos': 0,
          'total_sesiones': 0,
          'mensaje': 'Inicia sesión para ver tu progreso personalizado',
        };
        isLoading = false;
      });
      return;
    }

    try {
      // Cargar progreso del usuario y sesiones
      final progress = await _progressService.getUserProgress();
      final sessionHistory = await _progressService.getSessionHistory(limit: 500);
      final totalMinutes = sessionHistory.fold<int>(0, (acc, s) => acc + ((s['duration_minutes'] as int?) ?? 0));
      
      // Cargar desafíos
      await _challengeService.initializeChallenges();
      final userChallenges = _challengeService.getUserChallenges();
      final activeChallenges = userChallenges.where((c) => c.status == ChallengeStatus.enProgreso).toList();
      final completedChallenges = userChallenges.where((c) => c.status == ChallengeStatus.completado).toList();

      setState(() {
        userProgress = {
          ...?progress,
          // Mapear claves esperadas por la UI
          'nivel': progress?['nivel_energetico'] ?? 1,
          'dias_consecutivos': progress?['dias_consecutivos'] ?? 0,
          'total_pilotajes': progress?['total_pilotajes'] ?? 0,
          'total_minutes': totalMinutes,
          // last_session_minutes ya no se usa, se obtiene directamente de AppTimeTracker
        };
        activeChallenge = activeChallenges.isNotEmpty ? {
          'id': activeChallenges.first.id,
          'title': activeChallenges.first.title,
          'status': activeChallenges.first.status.toString(),
        } : null;
        this.completedChallenges = completedChallenges.map((c) => {
          'id': c.id,
          'title': c.title,
          'status': c.status.toString(),
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error cargando datos de evolución: $e');
      setState(() {
        userProgress = {
          'nivel': 1,
          'dias_consecutivos': 0,
          'total_sesiones': 0,
          'mensaje': 'Error cargando datos',
        };
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título de la sección
                  Text(
                    'Evolución Energética',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFD700),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tu progreso vibracional',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 30),

              // Contenido con scroll
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Racha Actual - Círculo con flama
                      const SizedBox(height: 20), // Espacio superior para evitar corte
                      _buildStreakCircle(),
                      const SizedBox(height: 30),

                      // Estadísticas en grid de 6 cuadros
                      _buildStatsGrid(),
                      const SizedBox(height: 20),

                      // Desafío Activo
                      if (activeChallenge != null) ...[
                        _buildActiveChallengeCard(),
                        const SizedBox(height: 20),
                      ],

                      // Desafíos Completados
                      if (completedChallenges.isNotEmpty) ...[
                        _buildCompletedChallengesCard(),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildActiveChallengeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle_fill, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Text(
                'Desafío Activo',
                style: GoogleFonts.inter(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showHelpDialog(
                  'Desafío Activo',
                  'Muestra el desafío que estás realizando actualmente y en qué día te encuentras.\n\nLos desafíos son retos de práctica constante que te ayudan a establecer hábitos energéticos y alcanzar objetivos específicos.',
                ),
                child: Icon(
                  Icons.help_outline,
                  size: 18,
                  color: Colors.green.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            activeChallenge?['title'] ?? '',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Día ${activeChallenge?['currentDay'] ?? 1} en progreso',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedChallengesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Desafíos Completados',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFFD700),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showHelpDialog(
                  'Desafíos Completados',
                  'Lista de desafíos que has terminado exitosamente.\n\nCompletar desafíos demuestra tu compromiso y constancia en la práctica de los códigos Grabovoi, elevando tu vibración energética.',
                ),
                child: Icon(
                  Icons.help_outline,
                  size: 18,
                  color: const Color(0xFFFFD700).withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (completedChallenges.isEmpty)
            // Estado vacío: mostrar copa centrada
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Icon(
                    Icons.emoji_events,
                    color: const Color(0xFFFFD700).withOpacity(0.5),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes desafíos completados',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            )
          else
            // Listado de desafíos completados
            ...completedChallenges.take(3).map((challenge) => 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        challenge['title'] ?? '',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStreakCircle() {
    final racha = (userProgress?['dias_consecutivos'] ?? 0).toString();
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Contenedor con padding asimétrico: más arriba para la flama que sale
          Padding(
            padding: const EdgeInsets.only(
              top: 35, // Más espacio arriba para la flama que sale del círculo
              bottom: 25, // Espacio abajo para evitar overflow
              left: 20,
              right: 20,
            ),
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                // Círculo principal
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFD700).withOpacity(0.15),
                      border: Border.all(color: const Color(0xFFFFD700), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0, left: 8.0, right: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 20), // Espacio para la flama que está fuera
                          SizedBox(
                            height: 24,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                racha,
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Flama grande posicionada arriba (media dentro, media fuera)
                Positioned(
                  top: -20, // Media flama fuera del círculo
                  child: AnimatedBuilder(
                    animation: _flameAnimation,
                    builder: (context, child) {
                      // Movimiento de fuego: rotación + ligera escala
                      final rotation = _flameAnimation.value;
                      final scale = 1.0 + (0.08 * (rotation.abs() / 0.12));
                      return Transform(
                        transform: Matrix4.identity()
                          ..rotateZ(rotation)
                          ..scale(scale),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.local_fire_department,
                          color: Color(0xFFFFD700),
                          size: 48, // Casi el doble del tamaño del número (22px * 2 = 44px, usamos 48px)
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Días en Racha',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final totalMinutes = (userProgress?['total_minutes'] ?? 0) as int;
    final horas = (totalMinutes ~/ 60);
    final mins = (totalMinutes % 60);
    
    // Formatear tiempo total
    String tiempoStr;
    if (horas > 0) {
      tiempoStr = mins > 0 ? '${horas}h ${mins}m' : '${horas}h';
    } else {
      tiempoStr = '${mins}m';
    }
    
    // Tiempo de sesión actual
    final currentSessionDuration = _appTimeTracker.getCurrentSessionTime();
    final currentSessionMinutes = currentSessionDuration.inMinutes;
    final currentSessionHours = currentSessionDuration.inHours;
    
    String tiempoSesionStr;
    if (currentSessionHours > 0) {
      final sessionMinsRestantes = currentSessionMinutes % 60;
      tiempoSesionStr = sessionMinsRestantes > 0
          ? '${currentSessionHours}h ${sessionMinsRestantes}m'
          : '${currentSessionHours}h';
    } else {
      tiempoSesionStr = '${currentSessionMinutes}m';
    }
    
    final nivel = userProgress?['nivel'] ?? userProgress?['nivel_energetico'] ?? 1;
    final totalPilotajes = (userProgress?['total_pilotajes'] ?? 0).toString();
    final totalSesiones = (userProgress?['total_sesiones'] ?? 0).toString();
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Tiempo Total', tiempoStr, Icons.timer),
        _buildStatCard('Códigos Explorados', '${_cachedExploredCodesCount ?? 0}', Icons.numbers),
        _buildStatCard('Total Pilotajes', totalPilotajes, Icons.psychology),
        _buildStatCard('Tiempo Sesión', tiempoSesionStr, Icons.timelapse),
        _buildStatCard('Sesiones', totalSesiones, Icons.play_circle),
        _buildStatCard('Nivel', '$nivel', Icons.star),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFFFD700), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFFD700), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showHelpDialog(String title, String explanation) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1C2541),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: Color(0xFFFFD700),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFFFFD700),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                explanation,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700).withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Entendido',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFFD700),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailedReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reporte Detallado',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu evolución energética muestra un progreso constante hacia frecuencias más elevadas.',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              'Próximo objetivo: Completar 21 días consecutivos para desbloquear el siguiente nivel.',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cerrar',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

