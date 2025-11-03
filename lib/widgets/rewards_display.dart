import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/rewards_model.dart';
import '../services/rewards_service.dart';

/// Widget para mostrar las recompensas del usuario (cristales, luz cuántica, etc.)
class RewardsDisplay extends StatefulWidget {
  final bool compact; // Versión compacta para encabezados

  const RewardsDisplay({super.key, this.compact = false});

  @override
  State<RewardsDisplay> createState() => _RewardsDisplayState();
}

class _RewardsDisplayState extends State<RewardsDisplay> {
  final RewardsService _rewardsService = RewardsService();
  UserRewards? _rewards;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    try {
      final rewards = await _rewardsService.getUserRewards();
      if (mounted) {
        setState(() {
          _rewards = rewards;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando recompensas: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _rewards == null) {
      return widget.compact
          ? const SizedBox.shrink()
          : const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
    }

    if (widget.compact) {
      return _buildCompactView();
    }

    return _buildFullView();
  }

  Widget _buildCompactView() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cristales de energía
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2C3E50).withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.diamond, color: Color(0xFFFFD700), size: 16),
              const SizedBox(width: 4),
              Text(
                '${_rewards!.cristalesEnergia}',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Barra de luz cuántica (versión mini)
        Container(
          width: 60,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: const Color(0xFF2C3E50),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: _rewards!.luzCuantica / RewardsService.luzCuanticaMaxima,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFFF00)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFullView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1C2541),
            const Color(0xFF2C3E50).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recompensas Cuánticas',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFD700),
            ),
          ),
          const SizedBox(height: 16),
          // Cristales de energía
          _buildCristalesCard(),
          const SizedBox(height: 12),
          // Luz cuántica
          _buildLuzCuanticaCard(),
          const SizedBox(height: 12),
          // Restauradores
          if (_rewards!.restauradoresArmonia > 0) ...[
            _buildRestauradoresCard(),
            const SizedBox(height: 12),
          ],
          // Mantras desbloqueados
          if (_rewards!.mantrasDesbloqueados.isNotEmpty) ...[
            _buildMantrasCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildCristalesCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.diamond, color: Color(0xFFFFD700), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cristales de Energía',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  '${_rewards!.cristalesEnergia}',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_rewards!.cristalesEnergia ~/ RewardsService.cristalesParaCodigoPremium} disponibles para códigos premium',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white54,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildLuzCuanticaCard() {
    final porcentaje = (_rewards!.luzCuantica / RewardsService.luzCuanticaMaxima * 100).toInt();
    final isCompleta = _rewards!.luzCuantica >= RewardsService.luzCuanticaMaxima;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleta
              ? Colors.green.withOpacity(0.5)
              : const Color(0xFFFFD700).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCompleta ? Icons.check_circle : Icons.auto_awesome,
                color: isCompleta ? Colors.green : const Color(0xFFFFD700),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Luz Cuántica',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '$porcentaje%',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCompleta ? Colors.green : const Color(0xFFFFD700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: const Color(0xFF2C3E50),
                ),
              ),
              FractionallySizedBox(
                widthFactor: _rewards!.luzCuantica / RewardsService.luzCuanticaMaxima,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: isCompleta
                          ? [Colors.green, Colors.greenAccent]
                          : [const Color(0xFFFFD700), const Color(0xFFFFFF00)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isCompleta ? Colors.green : const Color(0xFFFFD700)).withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isCompleta) ...[
            const SizedBox(height: 8),
            Text(
              '✨ ¡Luz cuántica completa! Accede a meditaciones especiales',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.greenAccent,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRestauradoresCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.healing, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restauradores de Armonía',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  '${_rewards!.restauradoresArmonia} disponible${_rewards!.restauradoresArmonia != 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMantrasCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.purple, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mantras Desbloqueados',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  '${_rewards!.mantrasDesbloqueados.length} mantra${_rewards!.mantrasDesbloqueados.length != 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purpleAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

