import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/glow_background.dart';
import '../../../widgets/golden_sphere.dart';
import '../../../widgets/illuminated_code_text.dart';

class StaticHomeScreen extends StatelessWidget {
  const StaticHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portal Energético',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
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
                      'Bienvenido, Usuario',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Esfera decorativa
                    const Center(
                      child: SizedBox(
                        height: 200,
                        width: 200,
                        child: GoldenSphere(),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Tarjeta de Código del Día
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Secuencia del Día',
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              color: const Color(0xFFFFD700),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 15),
                          const IlluminatedCodeText(
                            code: '519 7148',
                            fontSize: 32,
                            color: Color(0xFFFFD700),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Todo es Posible',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              color: Colors.white,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Frase motivacional
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'El viaje de mil millas comienza con un solo paso.',
                              style: GoogleFonts.lato(
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
