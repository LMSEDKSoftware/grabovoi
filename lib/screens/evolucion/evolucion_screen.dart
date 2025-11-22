import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../services/ai_service.dart';
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

class _EvolucionScreenState extends State<EvolucionScreen> with WidgetsBindingObserver {
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appTimeTracker.addListener(_updateSessionTime);
    _startSessionTimeTimer();
    
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
      // Refrescar códigos explorados si el caché expiró
      _loadExploredCodesCount();
    }
  }

  // Obtener conteo de códigos explorados desde la BD con caché
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
      
      // Contar códigos únicos en user_code_history
      // Optimizado: solo traer code_id para reducir transferencia de datos
      final response = await supabase
          .from('user_code_history')
          .select('code_id')
          .eq('user_id', userId);
      
      // Obtener códigos únicos
      final uniqueCodes = <String>{};
      for (final row in response) {
        final codeId = row['code_id'] as String?;
        if (codeId != null && codeId.isNotEmpty) {
          uniqueCodes.add(codeId);
        }
      }
      
      final count = uniqueCodes.length;
      
      // Guardar en caché
      _cachedExploredCodesCount = count;
      _cacheTimestamp = DateTime.now();
      
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
  Future<void> _loadExploredCodesCount() async {
    final count = await _getExploredCodesCount();
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
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 30),

              // Contenido con scroll
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nivel Energético
                _buildEnergyLevelCard(),
                const SizedBox(height: 20),

                // Progreso General
                _buildProgressCard(),
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

                // Estadísticas
                _buildStatsCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildEnergyLevelCard() {
    final nivel = userProgress?['nivel'] ?? userProgress?['nivel_energetico'] ?? 1;

    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bolt,
                  color: Color(0xFFFFD700),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nivel Energético',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$nivel/10',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final dias = (userProgress?['dias_consecutivos'] ?? 0).toString();
    final total = (userProgress?['total_pilotajes'] ?? 0).toString();
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
          Text(
            'Progreso General',
            style: GoogleFonts.inter(
              color: const Color(0xFFFFD700),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressRow('Días Consecutivos', dias, Icons.calendar_today),
          _buildProgressRow('Total Pilotajes', total, Icons.play_circle),
          _buildProgressRow('Desafíos Completados', '${completedChallenges.length}', Icons.emoji_events),
          _buildProgressRow('Códigos Explorados', '${_cachedExploredCodesCount ?? 0}', Icons.explore),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFD700), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
          Text(
            'Desafíos Completados',
            style: GoogleFonts.inter(
              color: const Color(0xFFFFD700),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
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
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final totalSesiones = (userProgress?['total_pilotajes'] ?? 0).toString();
    final racha = (userProgress?['dias_consecutivos'] ?? 0).toString();
    final totalMinutes = (userProgress?['total_minutes'] ?? 0) as int;
    
    // Usar el tiempo de la sesión actual desde AppTimeTracker
    final currentSessionDuration = _appTimeTracker.getCurrentSessionTime();
    final currentSessionMinutes = currentSessionDuration.inMinutes;
    final currentSessionHours = currentSessionDuration.inHours;
    
    final horas = (totalMinutes ~/ 60);
    final mins = (totalMinutes % 60);
    final tiempoStr = horas > 0 ? '${horas}h ${mins}m' : '${mins}m';
    
    // Formatear tiempo de sesión actual
    final tiempoSesionStr = currentSessionHours > 0
        ? '${currentSessionHours}h ${currentSessionMinutes % 60}m'
        : '${currentSessionMinutes}m';
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
          Text(
            'Estadísticas',
            style: GoogleFonts.inter(
              color: const Color(0xFFFFD700),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Tiempo sesión', tiempoSesionStr, Icons.timelapse),
              _buildStatItem('Tiempo total', tiempoStr, Icons.timer),
              _buildStatItem('Sesiones', totalSesiones, Icons.play_arrow),
              _buildStatItem('Racha', '$racha días', Icons.local_fire_department),
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

