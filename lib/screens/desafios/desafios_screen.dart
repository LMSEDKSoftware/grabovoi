import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../services/challenge_service.dart';
import '../../models/challenge_model.dart';
import 'challenge_progress_screen.dart';

class DesafiosScreen extends StatefulWidget {
  const DesafiosScreen({super.key});

  @override
  State<DesafiosScreen> createState() => _DesafiosScreenState();
}

class _DesafiosScreenState extends State<DesafiosScreen> {
  final ChallengeService _challengeService = ChallengeService();
  List<Challenge> _availableChallenges = [];
  List<Challenge> _userChallenges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeChallenges();
  }

  Future<void> _initializeChallenges() async {
    await _challengeService.initializeChallenges();
    setState(() {
      _availableChallenges = _challengeService.getAvailableChallenges();
      _userChallenges = _challengeService.getUserChallenges();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
            : SingleChildScrollView(
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
                      'Desafíos Vibracionales',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFD700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rutas de transformación personal',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 30),

                      // Desafíos Activos
                      if (_userChallenges.isNotEmpty) ...[
                        Text(
                          'Desafíos Activos',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._userChallenges.map((challenge) => _buildActiveChallengeCard(challenge)).toList(),
                        const SizedBox(height: 30),
                      ],
                      
                      // Desafíos Disponibles
                      Text(
                        'Desafíos Disponibles',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._availableChallenges.map((challenge) => _buildChallengeCard(challenge)).toList(),
                      
                      const SizedBox(height: 30),
                      
                      // Botón de Desafío Aleatorio
                      CustomButton(
                        text: 'Desafío Aleatorio',
                        onPressed: () {
                          if (_availableChallenges.isNotEmpty) {
                            final randomChallenge = _availableChallenges[
                              (DateTime.now().millisecondsSinceEpoch % _availableChallenges.length)
                            ];
                            _showChallengeDialog(randomChallenge);
                          }
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

  Widget _buildChallengeCard(Challenge challenge) {
    final color = Color(int.parse(challenge.color.replaceAll('#', '0xFF')));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showChallengeDialog(challenge),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        challenge.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge.title,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${challenge.durationDays} días',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getDifficultyText(challenge.difficulty),
                                  style: GoogleFonts.inter(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white54,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  challenge.description,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChallengeDialog(Challenge challenge) {
    final color = Color(int.parse(challenge.color.replaceAll('#', '0xFF')));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Text(
                challenge.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                challenge.title,
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFFFD700),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              challenge.description,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Duración: ${challenge.durationDays} días',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Nivel: ${_getDifficultyText(challenge.difficulty)}',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.card_giftcard, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Recompensas: ${challenge.rewards.join(', ')}',
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cerrar',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startChallenge(challenge);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Comenzar',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChallengeCard(Challenge challenge) {
    final color = Color(int.parse(challenge.color.replaceAll('#', '0xFF')));
    final progress = challenge.currentDay / challenge.durationDays;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  challenge.icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Día ${challenge.currentDay} de ${challenge.durationDays}',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Ver Progreso',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChallengeProgressScreen(challenge: challenge),
                      ),
                    );
                  },
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  text: 'Continuar',
                  onPressed: () {
                    // Lógica para continuar el desafío
                    _continueChallenge(challenge);
                  },
                  isOutlined: true,
                  icon: Icons.play_arrow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDifficultyText(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.principiante:
        return 'Principiante';
      case ChallengeDifficulty.intermedio:
        return 'Intermedio';
      case ChallengeDifficulty.avanzado:
        return 'Avanzado';
      case ChallengeDifficulty.maestro:
        return 'Maestro';
    }
  }

  Future<void> _startChallenge(Challenge challenge) async {
    try {
      await _challengeService.startChallenge(challenge.id);
      
      setState(() {
        _availableChallenges = _challengeService.getAvailableChallenges();
        _userChallenges = _challengeService.getUserChallenges();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Has comenzado el ${challenge.title}!'),
          backgroundColor: Color(int.parse(challenge.color.replaceAll('#', '0xFF'))),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Ver Progreso',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChallengeProgressScreen(challenge: challenge),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      // Mostrar diálogo de confirmación si ya hay un desafío activo
      if (e.toString().contains('Ya tienes un desafío activo')) {
        _showActiveChallengeDialog(challenge);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar el desafío: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _continueChallenge(Challenge challenge) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChallengeProgressScreen(challenge: challenge),
      ),
    );
  }

  void _showActiveChallengeDialog(Challenge newChallenge) {
    final userChallenges = _challengeService.getUserChallenges();
    Challenge? activeChallenge;
    
    try {
      activeChallenge = userChallenges.firstWhere(
        (challenge) => challenge.status == ChallengeStatus.enProgreso,
      );
    } catch (e) {
      return; // No hay desafío activo
    }
    
    if (activeChallenge == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C2541),
          title: Text(
            'Desafío Activo',
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFFFD700),
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ya tienes un desafío en progreso:',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  activeChallenge?.title ?? 'Desafío Activo',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFFD700),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Debes completar tu desafío actual antes de iniciar uno nuevo.',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Entendido',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (activeChallenge != null) {
                  _continueChallenge(activeChallenge);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
              ),
              child: Text(
                'Ver Mi Desafío',
                style: GoogleFonts.inter(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

}

