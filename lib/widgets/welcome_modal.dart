import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeModal extends StatefulWidget {
  const WelcomeModal({super.key});

  @override
  State<WelcomeModal> createState() => _WelcomeModalState();
}

class _WelcomeModalState extends State<WelcomeModal> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C2541),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFFFD700), width: 2),
      ),
      contentPadding: const EdgeInsets.all(24),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Center(
              child: Text(
                '🌀 Bienvenido a la Frecuencia Grabovoi',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFFFD700),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            
            // Texto principal
            Text(
              'Los Códigos Numéricos de Grigori Grabovoi son secuencias que vibran en frecuencias específicas, capaces de armonizar tu cuerpo, tu mente y tu realidad.\n\nCada número actúa como una llave energética que abre caminos hacia la Norma: ese estado perfecto en el que todo vuelve al equilibrio natural del Creador.',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            
            // Separador
            Container(
              height: 1,
              color: const Color(0xFFFFD700).withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            
            // Cómo utilizarlos
            Text(
              '✨ Cómo utilizarlos',
              style: GoogleFonts.inter(
                color: const Color(0xFFFFD700),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildInstruction('1.', 'Conéctate con tu intención.\nAntes de repetir el código, ten claro qué deseas armonizar o manifestar.'),
            const SizedBox(height: 8),
            _buildInstruction('2.', 'Pronuncia número por número.\nEjemplo: "uno… cuatro… siete" en lugar de "ciento cuarenta y siete".\nSi el código tiene espacios, haz una pequeña pausa consciente entre ellos.'),
            const SizedBox(height: 8),
            _buildInstruction('3.', 'Visualiza una esfera de luz.\nImagina la secuencia flotando dentro de una esfera blanca o dorada, irradiando energía sobre ti o sobre aquello que deseas transformar.'),
            const SizedBox(height: 8),
            _buildInstruction('4.', 'Siente, no cuentes.\nUna sola repetición con total presencia puede ser más poderosa que cien hechas sin atención.\nLa activación ocurre por resonancia, no por cantidad.'),
            const SizedBox(height: 8),
            _buildInstruction('5.', 'Agradece.\nCierra el proceso sintiendo gratitud, como si la armonía ya se hubiera manifestado.'),
            
            const SizedBox(height: 20),
            
            // Separador
            Container(
              height: 1,
              color: const Color(0xFFFFD700).withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            
            // Recuerda
            Text(
              '🕊️ Recuerda:',
              style: GoogleFonts.inter(
                color: const Color(0xFFFFD700),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los números son vibraciones vivas.\nTu enfoque, intención y conciencia son los que activan su poder creador.',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Separador
            Container(
              height: 1,
              color: const Color(0xFFFFD700).withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            
            // Checkbox para no mostrar de nuevo
            Row(
              children: [
                Checkbox(
                  value: _dontShowAgain,
                  onChanged: (value) {
                    setState(() {
                      _dontShowAgain = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFFFFD700),
                  checkColor: Colors.black,
                ),
                Expanded(
                  child: Text(
                    'No volver a mostrar este mensaje',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              if (_dontShowAgain) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('welcome_modal_shown', true);
              }
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
            ),
            child: const Text(
              'Comenzar',
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

  Widget _buildInstruction(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: GoogleFonts.inter(
            color: const Color(0xFFFFD700),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
