import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Overlay de 6 pasos guiados ("Preparación de la Conciencia" -> "Intención
/// Personal") que se muestra antes de iniciar una sesión de 2 minutos.
/// Extraído de repetition_session_screen.dart (donde vivía duplicado en
/// código) para poder reutilizarlo también en code_detail_screen.dart
/// (pilotaje de la secuencia diaria en Inicio) sin mantener dos copias.
///
/// Se coloca como último hijo de un Stack, ej:
///   Stack(children: [
///     Scaffold(...),
///     if (_showSequentialSteps)
///       SequentialStepsOverlay(onCompleted: (intencion) { ... }),
///   ])
class SequentialStepsOverlay extends StatefulWidget {
  final void Function(String intencionPersonal) onCompleted;

  const SequentialStepsOverlay({super.key, required this.onCompleted});

  @override
  State<SequentialStepsOverlay> createState() => _SequentialStepsOverlayState();
}

class _SequentialStepsOverlayState extends State<SequentialStepsOverlay> {
  static final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Preparación de la Conciencia',
      'description': 'Cierra los ojos, respira... conecta con la Norma.',
      'icon': Icons.self_improvement,
      'color': Colors.green,
    },
    {
      'title': 'Visualización Activa',
      'description': 'Visualiza la secuencia dentro de una esfera luminosa.',
      'icon': Icons.visibility,
      'color': Colors.blue,
    },
    {
      'title': 'Emisión del Pensamiento Dirigido',
      'description': 'Enfoca tu intención y emítela al campo cuántico.',
      'icon': Icons.psychology,
      'color': Colors.purple,
    },
    {
      'title': 'Repetición Consciente',
      'description': 'Repite la secuencia 3 veces sintiendo la vibración. Recuerda que 2 minutos continuos con intención son de gran ayuda para el pilotaje cuántico.',
      'icon': Icons.repeat,
      'color': Colors.orange,
    },
    {
      'title': 'Cierre Energético',
      'description': 'Agradece y sella la intención en el campo cuántico.',
      'icon': Icons.check_circle,
      'color': Colors.teal,
    },
    {
      'title': 'Intención Personal',
      'description': '¿Qué deseas armonizar con esta secuencia?',
      'icon': Icons.edit,
      'color': Colors.amber,
      'hasTextField': true,
    },
  ];

  int _currentStepIndex = 0;
  final TextEditingController _intencionController = TextEditingController();

  @override
  void dispose() {
    _intencionController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStepIndex < _steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
    } else {
      widget.onCompleted(_intencionController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStepData = _steps[_currentStepIndex];

    return Positioned.fill(
      // Este overlay se coloca como hermano del Scaffold dentro de un Stack
      // (no como hijo), así que no hereda el Material del Scaffold. Sin este
      // Material propio, el TextField del último paso truena con "No
      // Material widget found" y el resto del texto se ve subrayado (aviso
      // de depuración de Flutter por falta de ancestro Material).
      child: Material(
        type: MaterialType.transparency,
        child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: -1.0, end: 0.0),
            curve: Curves.easeOutCubic,
            builder: (context, slideValue, child) {
              return Transform.translate(
                offset: Offset(slideValue * MediaQuery.of(context).size.width, 0),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: slideValue > -0.8 ? 1.0 : 0.0,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          currentStepData['color'] as Color,
                          (currentStepData['color'] as Color).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (currentStepData['color'] as Color).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            currentStepData['icon'] as IconData,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentStepData['title'] as String,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentStepData['description'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (currentStepData['hasTextField'] == true) ...[
                          TextField(
                            controller: _intencionController,
                            style: GoogleFonts.inter(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Escribe tu intención aquí...',
                              hintStyle: GoogleFonts.inter(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.white, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            maxLines: 3,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: List.generate(_steps.length, (index) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: index <= _currentStepIndex
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }),
                            ),
                            GestureDetector(
                              onTap: _nextStep,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  _currentStepIndex < _steps.length - 1 ? Icons.play_arrow : Icons.check,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        ),
      ),
    );
  }
}
