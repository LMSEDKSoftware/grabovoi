import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/permissions_service.dart';

class WelcomeModal extends StatefulWidget {
  final VoidCallback? onContinue;

  const WelcomeModal({super.key, this.onContinue});

  @override
  State<WelcomeModal> createState() => _WelcomeModalState();
}

class _WelcomeModalState extends State<WelcomeModal> {
  bool _dontShowAgain = false;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollIndicator = false;
  bool _isProcessing = false; // Flag para evitar múltiples ejecuciones

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
        side: const BorderSide(color: Color(0xFFFFD700), width: 2),
      ),
      contentPadding: const EdgeInsets.all(24),
      content: _ScrollableContent(),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessing
                ? null
                : () async {
                    // Evitar múltiples ejecuciones
                    if (_isProcessing) return;
                    setState(() {
                      _isProcessing = true;
                    });

                    if (_dontShowAgain) {
                      // Persistir preferencia en DB para no volver a mostrar el modal
                      final user = Supabase.instance.client.auth.currentUser;
                      if (user != null) {
                        try {
                          await Supabase.instance.client.from('users').update({
                            'welcome_dont_show_again': true,
                            'welcome_dont_show_again_set_at':
                                DateTime.now().toIso8601String(),
                          }).eq('id', user.id);
                        } catch (e) {
                          debugPrint(
                              '⚠️ Error guardando preferencia WelcomeModal: $e');
                        }
                      }
                    }

                    // Cerrar modal primero
                    if (mounted) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }

                    // Solicitar permisos después de cerrar el modal
                    // (pequeño delay para que el modal se cierre completamente)
                    await Future.delayed(const Duration(milliseconds: 300));
                    await PermissionsService().requestInitialPermissions();

                    // Llamar al callback si existe (para mostrar tablero después)
                    // Solo una vez
                    if (widget.onContinue != null && mounted) {
                      widget.onContinue!();
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

  Widget _buildInstruction(String number, String title, String description) {
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
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$title.\n',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFFD700),
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: description,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _ScrollableContent() {
    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Center(
                child: Text(
                  '🌀 Bienvenido a las Secuencias Numéricas Gravitacionales',
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
                'Las Secuencias Numéricas Gravitacionales son secuencias que vibran en frecuencias específicas, capaces de armonizar tu cuerpo, tu mente y tu realidad.\n\nCada número actúa como una llave energética que abre caminos hacia la Norma: ese estado perfecto en el que todo vuelve al equilibrio natural del Creador.',
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

              _buildInstruction('1.', 'Conéctate con tu intención',
                  'Antes de repetir la secuencia, ten claro qué deseas armonizar o manifestar.'),
              const SizedBox(height: 8),
              _buildInstruction('2.', 'Pronuncia número por número',
                  'Ejemplo: "uno… cuatro… siete" en lugar de "ciento cuarenta y siete".\nSi la secuencia tiene espacios, haz una pequeña pausa consciente entre ellos.'),
              const SizedBox(height: 8),
              _buildInstruction('3.', 'Visualiza una esfera de luz',
                  'Imagina la secuencia flotando dentro de una esfera blanca o dorada. Con esta app puedes materializar esos números y esa esfera de manera más fácil, usando la visualización interactiva que te ofrece la pantalla.'),
              const SizedBox(height: 8),
              _buildInstruction('4.', 'Siente, no cuentes',
                  'Una sola repetición con total presencia puede ser más poderosa que cien hechas sin atención.\nLa activación ocurre por resonancia, no por cantidad.'),
              const SizedBox(height: 8),
              _buildInstruction('5.', 'Agradece',
                  'Cierra el proceso sintiendo gratitud, como si la armonía ya se hubiera manifestado.'),

              const SizedBox(height: 20),

              // Separador
              Container(
                height: 1,
                color: const Color(0xFFFFD700).withOpacity(0.3),
              ),
              const SizedBox(height: 20),

              // Recuerda
              Text(
                '🕊 Recuerda:',
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

              // Advertencia
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF6B6B).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFFFF6B6B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Las secuencias numéricas gravitacionales NO sustituyen la atención médica profesional. Siempre consulta con profesionales de la salud para cualquier condición médica. Estas secuencias son herramientas complementarias de bienestar.',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
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
        // Mensaje "Desliza hacia arriba" cuando hay contenido scrolleable
        if (_showScrollIndicator)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: true,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                    const Icon(
                      Icons.keyboard_arrow_up,
                      color: Color(0xFFFFD700),
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
    );
  }
}
