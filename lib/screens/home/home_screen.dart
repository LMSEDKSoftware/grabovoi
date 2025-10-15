import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/sacred_circle.dart';
import '../../services/ai_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analisis = AIService.analizarPatrones(
      categoriasUsadas: ['Abundancia', 'Salud', 'Armonía'],
      diasConsecutivos: 5,
      totalPilotajes: 12,
    );

    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Portal Energético',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                    shadows: [
                      Shadow(
                        color: const Color(0xFFFFD700).withOpacity(0.5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  analisis['fraseMotivacional'],
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),
                const Center(child: SacredCircle(size: 180)),
                const SizedBox(height: 30),
                _buildEnergyCard('Nivel Energético', '${analisis['nivel']}/10', Icons.bolt),
                const SizedBox(height: 20),
                _buildCodeOfDay(context, analisis['codigoRecomendado']),
                const SizedBox(height: 20),
                _buildNextStep(analisis['proximoPaso']),
                const SizedBox(height: 30),
                CustomButton(text: 'Comenzar Pilotaje', onPressed: () {}),
                const SizedBox(height: 15),
                CustomButton(text: 'Ver Desafíos', onPressed: () {}, isOutlined: true),
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    '5197148',
                    style: GoogleFonts.spaceMono(
                      fontSize: 12,
                      color: Colors.white30,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnergyCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1),
      ),
      child: Row(
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
                Text(title, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeOfDay(BuildContext context, String codigo) {
    return Container(
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
          Text('Código Recomendado', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 12),
          Text(
            codigo,
            style: GoogleFonts.spaceMono(
              color: const Color(0xFFFFD700),
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text('Toca para pilotar', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildNextStep(String step) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(step, style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
