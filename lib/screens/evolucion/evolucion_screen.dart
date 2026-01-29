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
  List<Challenge> completedChallenges = [];
  bool isLoading = true;
  Timer? _sessionTimeUpdateTimer;
  
  // Caché para secuencias exploradas
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
      // Refrescar secuencias exploradas forzando actualización
      _loadExploredCodesCount(forceRefresh: true);
    }
  }

  // Obtener conteo de secuencias exploradas desde user_actions (fuente única de verdad)
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
      // Filtrar solo acciones que involucran secuencias
      final response = await supabase
          .from('user_actions')
          .select('action_data')
          .eq('user_id', userId)
          .inFilter('action_type', ['sesionPilotaje', 'codigoRepetido', 'pilotajeCompartido']);
      
      // Obtener secuencias únicas desde action_data
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
      
      print('✅ Secuencias exploradas encontradas: $count (desde user_actions)');
      return count;
    } catch (e) {
      print('❌ Error obteniendo secuencias exploradas: $e');
      // Si hay error pero tenemos caché, usar el valor en caché
      if (_cachedExploredCodesCount != null) {
        return _cachedExploredCodesCount!;
      }
      return 0;
    }
  }
  
  // Cargar secuencias exploradas una vez al iniciar
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
          'total_sesiones': sessionHistory.length, // Calcular desde historial de sesiones
          'total_minutes': totalMinutes,
          // last_session_minutes ya no se usa, se obtiene directamente de AppTimeTracker
        };
        activeChallenge = activeChallenges.isNotEmpty ? {
          'id': activeChallenges.first.id,
          'title': activeChallenges.first.title,
          'status': activeChallenges.first.status.toString(),
        } : null;
        this.completedChallenges = completedChallenges; // Guardar objetos Challenge completos
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1),
          ),
          child: Row(
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
                  'Lista de desafíos que has terminado exitosamente.\n\nCompletar desafíos demuestra tu compromiso y constancia en la práctica de las secuencias de Grabovoi, elevando tu vibración energética.',
                ),
                child: Icon(
                  Icons.help_outline,
                  size: 18,
                  color: const Color(0xFFFFD700).withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (completedChallenges.isEmpty)
          // Estado vacío: mostrar copa centrada
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1),
            ),
            child: Center(
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
            ),
          )
        else
          // Grid de desafíos completados (2 por fila)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: completedChallenges.length,
            itemBuilder: (context, index) {
              return _buildCompletedChallengeCard(completedChallenges[index]);
            },
          ),
      ],
    );
  }

  Widget _buildCompletedChallengeCard(Challenge challenge) {
    final color = Color(int.parse(challenge.color.replaceAll('#', '0xFF')));
    
    // Obtener fecha de finalización
    String fechaCompletado = 'Sin fecha';
    if (challenge.endDate != null) {
      final date = challenge.endDate!;
      fechaCompletado = '${date.day}/${date.month}/${date.year}';
    } else if (challenge.dayProgress.isNotEmpty) {
      // Si no hay endDate, buscar el último día completado
      final lastCompletedDay = challenge.dayProgress.entries
          .where((e) => e.value.isCompleted && e.value.completedAt != null)
          .toList()
        ..sort((a, b) => (b.value.completedAt ?? DateTime.now())
            .compareTo(a.value.completedAt ?? DateTime.now()));
      if (lastCompletedDay.isNotEmpty && lastCompletedDay.first.value.completedAt != null) {
        final date = lastCompletedDay.first.value.completedAt!;
        fechaCompletado = '${date.day}/${date.month}/${date.year}';
      }
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Primera fila: Icono centrado
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Text(
                challenge.icon,
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(height: 12),
            // Segunda fila: "Completado"
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 4),
                Text(
                  'Completado',
                  style: GoogleFonts.inter(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Tercera fila: Título del desafío
            Text(
              challenge.title,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Cuarta fila: Fecha en letra pequeña
            Text(
              fechaCompletado,
              style: GoogleFonts.inter(
                color: Colors.white60,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Días en Racha',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _showHelpDialog(
                  'Días en Racha',
                  'La racha representa los días consecutivos que has usado la aplicación realizando al menos una actividad (repetición, pilotaje o compartido).\n\n'
                  '¿Cómo funciona?\n'
                  '• Se incrementa cada día que realizas al menos una actividad\n'
                  '• Cuenta los días consecutivos desde tu último uso\n'
                  '• Una racha más larga contribuye a tu nivel energético\n\n'
                  '¿Cuándo se reinicia?\n'
                  '• Si no usas la app durante un día completo, la racha se reinicia a 1\n'
                  '• Si pasan más de 24 horas sin actividad, la racha vuelve a comenzar\n\n'
                  '¿Cómo salvar la racha con Ancla de Continuidad?\n'
                  '• Las Anclas de Continuidad te permiten salvar tu racha si olvidaste usar la app un día\n'
                  '• Puedes comprar Anclas en la Tienda Premium con 200 cristales de energía\n'
                  '• Puedes tener máximo 2 anclas a la vez\n'
                  '• Se usan automáticamente cuando detectamos que perdiste un día en un desafío activo\n'
                  '• Una ancla salva un día, permitiéndote mantener tu racha sin interrupciones',
                ),
                child: Icon(
                  Icons.help_outline,
                  size: 18,
                  color: const Color(0xFFFFD700).withOpacity(0.6),
                ),
              ),
            ],
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
        _buildStatCard(
          'Tiempo Total',
          tiempoStr,
          Icons.timer,
          'Tiempo Total',
          'Es la suma acumulada de todos los minutos que has dedicado a practicar secuencias, realizar pilotajes y repeticiones de secuencias de Grabovoi.',
        ),
        _buildStatCard(
          'Secuencias Usadas',
          '${_cachedExploredCodesCount ?? 0}',
          Icons.numbers,
          'Secuencias Usadas',
          'Representa la cantidad única de secuencias de Grabovoi que has utilizado al menos una vez en tus sesiones de repetición, pilotaje o compartido.',
        ),
        _buildStatCard(
          'Total Pilotajes',
          totalPilotajes,
          Icons.psychology,
          'Total Pilotajes',
          'Es el número total de sesiones de pilotaje cuántico que has completado. Cada pilotaje contribuye a tu evolución energética.',
        ),
        _buildStatCard(
          'Tiempo Sesión',
          tiempoSesionStr,
          Icons.timelapse,
          'Tiempo Sesión',
          'Muestra el tiempo acumulado de la sesión actual de la app. Se reinicia cada vez que cierras y abres la aplicación.',
        ),
        _buildStatCard(
          'Sesiones',
          totalSesiones,
          Icons.play_circle,
          'Sesiones',
          'Es el número total de sesiones registradas (repeticiones de secuencias, pilotajes y compartidos) que has completado en la aplicación.',
        ),
        _buildStatCard(
          'Nivel',
          '$nivel',
          Icons.star,
          'Nivel Energético',
          'Es tu nivel de energía vibracional (del 1 al 10), calculado según tu evaluación inicial, días consecutivos de uso, pilotajes completados y práctica constante.',
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, String helpTitle, String helpExplanation) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _showHelpDialog(helpTitle, helpExplanation),
                child: Icon(
                  Icons.help_outline,
                  size: 18,
                  color: const Color(0xFFFFD700).withOpacity(0.6),
                ),
              ),
            ],
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
      builder: (context) => _HelpDialogModal(title: title, explanation: explanation),
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

class _HelpDialogModal extends StatefulWidget {
  final String title;
  final String explanation;

  const _HelpDialogModal({
    required this.title,
    required this.explanation,
  });

  @override
  State<_HelpDialogModal> createState() => _HelpDialogModalState();
}

class _HelpDialogModalState extends State<_HelpDialogModal> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollIndicator = false;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2541),
          borderRadius: BorderRadius.circular(20),
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
              padding: const EdgeInsets.all(20),
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
                          widget.title,
                          style: GoogleFonts.inter(
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
                    widget.explanation,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: const Color(0xFF0B132B),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: Text(
                        'Entendido',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            // Mensaje "Desliza hacia arriba" cuando hay contenido scrolleable
            if (_showScrollIndicator)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF1C2541).withOpacity(0.95),
                          const Color(0xFF1C2541),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.keyboard_arrow_up,
                          color: const Color(0xFFFFD700),
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Desliza hacia arriba',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFFD700),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

