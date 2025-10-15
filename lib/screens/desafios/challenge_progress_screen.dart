import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../services/challenge_service.dart';

class ChallengeProgressScreen extends StatefulWidget {
  final Map<String, dynamic> challenge;

  const ChallengeProgressScreen({super.key, required this.challenge});

  @override
  State<ChallengeProgressScreen> createState() => _ChallengeProgressScreenState();
}

class _ChallengeProgressScreenState extends State<ChallengeProgressScreen> {
  Map<String, dynamic>? activeChallenge;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChallenge();
  }

  Future<void> _loadChallenge() async {
    final challenge = await ChallengeService.getActiveChallenge();
    setState(() {
      activeChallenge = challenge;
      isLoading = false;
    });
  }

  Future<void> _updateProgress() async {
    if (activeChallenge != null) {
      final currentDay = (activeChallenge!['currentDay'] ?? 1) + 1;
      await ChallengeService.updateProgress(currentDay);
      await _loadChallenge();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Día $currentDay completado ✨'),
          backgroundColor: const Color(0xFFFFD700),
        ),
      );
    }
  }

  Future<void> _completeChallenge() async {
    await ChallengeService.completeChallenge();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('¡Desafío completado! 🎉'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (activeChallenge == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Desafío No Encontrado'),
          backgroundColor: Colors.transparent,
        ),
        body: const Center(
          child: Text('No hay desafío activo'),
        ),
      );
    }

    final totalDays = widget.challenge['duracionDias'] ?? 7;
    final currentDay = activeChallenge!['currentDay'] ?? 1;
    final progress = ChallengeService.calculateProgress(activeChallenge!, totalDays);
    final progressMessage = ChallengeService.getProgressMessage(activeChallenge!, totalDays);

    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: SingleChildScrollView(
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

                // Título del Desafío
                Text(
                  activeChallenge!['title'] ?? 'Desafío',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.challenge['descripcion'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 30),

                // Progreso Circular
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFFFFD700),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            '$currentDay/$totalDays',
                            style: GoogleFonts.spaceMono(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFD700),
                            ),
                          ),
                          Text(
                            'días',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Mensaje de Progreso
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getProgressIcon(progress),
                        color: const Color(0xFFFFD700),
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        progressMessage,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Información del Desafío
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información del Desafío',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Iniciado:', _formatDate(activeChallenge!['startDate'])),
                      _buildInfoRow('Duración:', '$totalDays días'),
                      _buildInfoRow('Progreso:', '${(progress * 100).toInt()}%'),
                      _buildInfoRow('Dificultad:', widget.challenge['dificultad'] ?? 'Intermedio'),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Botones de Acción
                if (currentDay < totalDays)
                  CustomButton(
                    text: 'Marcar Día Completado',
                    onPressed: _updateProgress,
                    icon: Icons.check_circle,
                  )
                else
                  CustomButton(
                    text: 'Completar Desafío',
                    onPressed: _completeChallenge,
                    icon: Icons.emoji_events,
                  ),
                const SizedBox(height: 15),
                CustomButton(
                  text: 'Ver Detalles',
                  onPressed: () {
                    // TODO: Mostrar detalles específicos del desafío
                  },
                  isOutlined: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getProgressIcon(double progress) {
    if (progress >= 1.0) return Icons.emoji_events;
    if (progress >= 0.75) return Icons.star;
    if (progress >= 0.5) return Icons.trending_up;
    if (progress >= 0.25) return Icons.play_circle;
    return Icons.play_arrow;
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}
