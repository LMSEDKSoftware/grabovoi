import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../models/challenge_model.dart';
import '../../services/challenge_service.dart';

class ChallengeProgressScreen extends StatefulWidget {
  final Challenge challenge;

  const ChallengeProgressScreen({super.key, required this.challenge});

  @override
  State<ChallengeProgressScreen> createState() => _ChallengeProgressScreenState();
}

class _ChallengeProgressScreenState extends State<ChallengeProgressScreen> {
  late Challenge _challenge;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _challenge = widget.challenge;
    _loadChallengeProgress();
  }

  Future<void> _loadChallengeProgress() async {
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Título del desafío
                      Text(
                        _challenge.title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _challenge.description,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Progreso del desafío
                      _buildProgressCard(),
                      
                      const SizedBox(height: 30),
                      
                      // Acciones del día
                      _buildDailyActions(),
                      
                      const SizedBox(height: 30),
                      
                      // Botones de acción
                      _buildActionButtons(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final color = Color(int.parse(_challenge.color.replaceAll('#', '0xFF')));
    final progress = _challenge.currentDay / _challenge.durationDays;
    
    return Container(
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
              Text(
                _challenge.icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progreso del Desafío',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Día ${_challenge.currentDay} de ${_challenge.durationDays}',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acciones de Hoy',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._getRequiredActionsForToday().map((action) => _buildActionItem(action)).toList(),
        ],
      ),
    );
  }

  List<String> _getRequiredActionsForToday() {
    // Obtener las acciones requeridas basadas en la dificultad del desafío
    switch (_challenge.difficulty) {
      case ChallengeDifficulty.principiante:
        return [
          '🔄 Repetir al menos 1 código',
          '🧘 Meditar 10 minutos',
          '⏱️ Usar la app 15 minutos'
        ];
      case ChallengeDifficulty.intermedio:
        return [
          '🔄 Repetir 2 códigos diferentes',
          '🚀 Pilotar 1 código',
          '🧘 Meditar 15 minutos',
          '⏱️ Usar la app 20 minutos'
        ];
      case ChallengeDifficulty.avanzado:
        return [
          '🔄 Repetir 3 códigos diferentes',
          '🚀 Pilotar 2 códigos',
          '🧘 Meditar 20 minutos',
          '⏱️ Usar la app 30 minutos'
        ];
      case ChallengeDifficulty.maestro:
        return [
          '🔄 Repetir 5 códigos diferentes',
          '🚀 Pilotar 3 códigos',
          '🧘 Meditar 30 minutos',
          '⏱️ Usar la app 45 minutos'
        ];
    }
  }

  IconData _getActionIcon(String action) {
    if (action.contains('🔄')) return Icons.repeat;
    if (action.contains('🚀')) return Icons.rocket_launch;
    if (action.contains('🧘')) return Icons.self_improvement;
    if (action.contains('⏱️')) return Icons.timer;
    return Icons.check_circle_outline;
  }

  Widget _buildActionItem(String action) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(
            _getActionIcon(action),
            color: const Color(0xFFFFD700),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              action,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          Icon(
            Icons.check_circle,
            color: Colors.green.withOpacity(0.7),
            size: 20,
          ),
        ],
      ),
    );
  }


  Widget _buildActionButtons() {
    return Column(
      children: [
        CustomButton(
          text: 'Continuar Desafío',
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icons.play_arrow,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'Ver Estadísticas',
          onPressed: () {
            // TODO: Implementar pantalla de estadísticas
          },
          isOutlined: true,
          icon: Icons.analytics,
        ),
      ],
    );
  }
}