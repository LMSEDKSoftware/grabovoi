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
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    setState(() {
      _isLoading = true;
    });
    
    // Inicializar desafíos en el servicio
    await _challengeService.initializeChallenges();
    
    setState(() {
      _availableChallenges = _challengeService.getAvailableChallenges();
      _userChallenges = _challengeService.getUserChallenges();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título de la sección
                  Text(
                    'Desafíos Vibracionales',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
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

                  // Lista de desafíos con scroll
                  Expanded(
                    child: ListView(
                      children: [
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
                        ..._availableChallenges.map((challenge) => _buildChallengeCard(challenge)).toList(),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            );
  }

  Widget _buildChallengeCard(Challenge challenge) {
    final color = Color(int.parse(challenge.color.replaceAll('#', '0xFF')));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
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
                                Icons.timer,
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
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getDifficultyColor(challenge.difficulty).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getDifficultyText(challenge.difficulty),
                                  style: GoogleFonts.inter(
                                    color: _getDifficultyColor(challenge.difficulty),
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

  Widget _buildActiveChallengeCard(Challenge challenge) {
    final color = Color(int.parse(challenge.color.replaceAll('#', '0xFF')));
    final progress = challenge.currentDay / challenge.durationDays;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.3),
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
                              Icon(Icons.trending_up, color: Colors.white70, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Día ${challenge.currentDay} de ${challenge.durationDays}',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(progress * 100).toInt()}%',
                        style: GoogleFonts.inter(
                          color: Colors.white,
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
                Text(
                  challenge.description,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Continuar Desafío',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChallengeProgressScreen(challenge: challenge),
                      ),
                    );
                  },
                  icon: Icons.play_arrow,
                ),
              ],
            ),
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

  Color _getDifficultyColor(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.principiante:
        return Colors.green;
      case ChallengeDifficulty.intermedio:
        return Colors.orange;
      case ChallengeDifficulty.avanzado:
        return Colors.red;
      case ChallengeDifficulty.maestro:
        return Colors.purple;
    }
  }

  void _showChallengeDialog(Challenge challenge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        title: Text(
          challenge.title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              challenge.description,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.timer, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Duración: ${challenge.durationDays} días',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Dificultad: ${_getDifficultyText(challenge.difficulty)}',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
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
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _challengeService.startChallenge(challenge.id);
              setState(() {
                _userChallenges = _challengeService.getUserChallenges();
                _availableChallenges = _challengeService.getAvailableChallenges();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: const Color(0xFF0B132B),
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
}