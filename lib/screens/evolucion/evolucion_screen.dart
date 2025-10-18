import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../services/ai_service.dart';
import '../../services/challenge_service.dart';
import '../../services/user_progress_service.dart';
import '../../services/auth_service_simple.dart';
import '../../models/challenge_model.dart';

class EvolucionScreen extends StatefulWidget {
  const EvolucionScreen({super.key});

  @override
  State<EvolucionScreen> createState() => _EvolucionScreenState();
}

class _EvolucionScreenState extends State<EvolucionScreen> {
  final UserProgressService _progressService = UserProgressService();
  final AuthServiceSimple _authService = AuthServiceSimple();
  final ChallengeService _challengeService = ChallengeService();
  
  Map<String, dynamic>? userProgress;
  Map<String, dynamic>? activeChallenge;
  List<Map<String, dynamic>> completedChallenges = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
      // Cargar progreso del usuario
      final progress = await _progressService.getUserProgress();
      final statistics = await _progressService.getUserStatistics();
      
      // Cargar desafíos
      await _challengeService.initializeChallenges();
      final userChallenges = _challengeService.getUserChallenges();
      final activeChallenges = userChallenges.where((c) => c.status == ChallengeStatus.enProgreso).toList();
      final completedChallenges = userChallenges.where((c) => c.status == ChallengeStatus.completado).toList();

      setState(() {
        userProgress = progress;
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Evolución Energética',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
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
                const SizedBox(height: 20),

                // Acciones
                CustomButton(
                  text: 'Ver Reporte Detallado',
                  onPressed: () {
                    _showDetailedReport();
                  },
                  icon: Icons.analytics,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnergyLevelCard() {
    final nivel = userProgress?['nivel'] ?? 1;
    final frase = userProgress?['fraseMotivacional'] ?? '';

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
          const SizedBox(height: 12),
          Text(
            frase,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
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
          _buildProgressRow('Días Consecutivos', '12', Icons.calendar_today),
          _buildProgressRow('Total Pilotajes', '45', Icons.play_circle),
          _buildProgressRow('Desafíos Completados', '${completedChallenges.length}', Icons.emoji_events),
          _buildProgressRow('Códigos Explorados', '8', Icons.explore),
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
              _buildStatItem('Tiempo Total', '2h 30m', Icons.timer),
              _buildStatItem('Sesiones', '45', Icons.play_arrow),
              _buildStatItem('Racha', '12 días', Icons.local_fire_department),
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

