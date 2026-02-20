import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuantumPilotageModal extends StatefulWidget {
  const QuantumPilotageModal({super.key});

  @override
  State<QuantumPilotageModal> createState() => _QuantumPilotageModalState();
}

class _QuantumPilotageModalState extends State<QuantumPilotageModal> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollIndicator = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScrollPosition);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollPosition();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScrollPosition() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final canScroll = maxScroll > 0;
      final shouldShow = canScroll && currentScroll < maxScroll - 50;
      if (_showScrollIndicator != shouldShow) {
        setState(() {
          _showScrollIndicator = shouldShow;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C2541),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF9C27B0), width: 2),
      ),
      title: Text(
        'Pilotaje Cuántico Gravitacional',
        style: GoogleFonts.playfairDisplay(
          color: const Color(0xFF9C27B0),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      content: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El Pilotaje Cuántico es una técnica avanzada que combina la Numerología Gravitacional con principios de física cuántica para manifestar cambios profundos en tu realidad.',
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
              '• Las secuencias numéricas actúan como frecuencias vibratorias específicas\n• Al repetirlas conscientemente, sincronizas tu campo energético\n• Esto crea resonancia con las frecuencias deseadas en el campo cuántico\n• El resultado es la manifestación de cambios en tu realidad física',
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
            const SizedBox(height: 20),
          ],
        ),
      ),
          // Mensaje "Desliza hacia arriba" cuando hay contenido scrolleable
          if (_showScrollIndicator)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF1C2541).withOpacity(0.95),
                        const Color(0xFF1C2541),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_up,
                        color: const Color(0xFFFFD700),
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Desliza hacia arriba',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFFD700),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
