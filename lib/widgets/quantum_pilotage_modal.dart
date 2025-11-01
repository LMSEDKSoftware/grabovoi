import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuantumPilotageModal extends StatefulWidget {
  const QuantumPilotageModal({super.key});

  @override
  State<QuantumPilotageModal> createState() => _QuantumPilotageModalState();
}

class _QuantumPilotageModalState extends State<QuantumPilotageModal> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C2541),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF9C27B0), width: 2),
      ),
      title: Text(
        'Pilotaje Cuántico Grabovoi',
        style: GoogleFonts.playfairDisplay(
          color: const Color(0xFF9C27B0),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El Pilotaje Cuántico es una técnica avanzada que combina la numerología cuántica de Grigori Grabovoi con principios de física cuántica para manifestar cambios profundos en tu realidad.',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '¿Cómo funciona?',
              style: GoogleFonts.inter(
                color: const Color(0xFF9C27B0),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Los códigos numéricos actúan como frecuencias vibratorias específicas\n• Al repetirlos conscientemente, sincronizas tu campo energético\n• Esto crea resonancia con las frecuencias deseadas en el campo cuántico\n• El resultado es la manifestación de cambios en tu realidad física',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Beneficios del Pilotaje Cuántico:',
              style: GoogleFonts.inter(
                color: const Color(0xFF9C27B0),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Sanación física y emocional\n• Manifestación de abundancia\n• Mejora de relaciones\n• Protección energética\n• Desarrollo espiritual\n• Transformación de patrones limitantes',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Para obtener mejores resultados, practica con intención clara y fe en el proceso.',
              style: GoogleFonts.inter(
                color: const Color(0xFFFFD700),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
            ),
            child: const Text(
              'Salir',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
