import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/golden_sphere.dart';
import '../../widgets/streamed_music_controller.dart';


class RepetitionSessionScreen extends StatefulWidget {
  final String codigo;
  final String? nombre;

  const RepetitionSessionScreen({super.key, required this.codigo, this.nombre});

  @override
  State<RepetitionSessionScreen> createState() => _RepetitionSessionScreenState();
}

class _RepetitionSessionScreenState extends State<RepetitionSessionScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _shareImage() async {
    try {
      final Uint8List? pngBytes = await _screenshotController.capture(pixelRatio: 2.0);
      if (pngBytes == null) return;

      // Solo para móvil, web no soporta compartir imágenes
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/grabovoi_${widget.codigo}.png');
        await file.writeAsBytes(pngBytes);

        await Share.shareXFiles([XFile(file.path)], text: 'Manifestación Numérica Grabovoi');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Función de compartir no disponible en web'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al compartir: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Spacer(),
                    // Botón copiar en la parte superior derecha
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.codigo));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Código ${widget.codigo} copiado'),
                            backgroundColor: const Color(0xFFFFD700),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, color: Color(0xFFFFD700)),
                    ),
                    // Botón ver detalle
                    IconButton(
                      onPressed: () {
                        // Aquí puedes agregar la navegación a una pantalla de detalles
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Función en desarrollo'),
                            backgroundColor: Colors.blue,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline, color: Color(0xFFFFD700)),
                    ),
                    // Botón compartir/descargar
                    IconButton(
                      onPressed: _shareImage,
                      icon: const Icon(Icons.share, color: Color(0xFFFFD700)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Sesión de Repetición',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Vista a capturar - Solo esfera como en pilotaje
                Center(
                  child: Screenshot(
                    controller: _screenshotController,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Esfera dorada sin contenedor rectangular
                        GoldenSphere(
                          size: 300,
                          color: const Color(0xFFFFD700),
                          glowIntensity: 0.8,
                          isAnimated: true,
                        ),
                        // Números blancos que siempre quepan en una línea - 90% del ancho
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Calcular el tamaño de fuente para que use el 90% del ancho disponible
                            final availableWidth = constraints.maxWidth * 0.9;
                            final codeLength = widget.codigo.length;
                            
                            // Calcular fontSize para que quepa en una línea usando el 90% del ancho
                            double fontSize = (availableWidth / codeLength) * 0.85; // 0.85 para dar margen
                            fontSize = fontSize.clamp(16.0, 60.0); // Limitar entre 16 y 60
                            
                            return Container(
                              width: availableWidth,
                              child: Text(
                                widget.codigo,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                                style: GoogleFonts.spaceMono(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: fontSize > 30 ? 3 : 1, // Ajustar espaciado según tamaño
                                  color: Colors.white,
                                  shadows: [
                                    // Múltiples sombras para efecto 3D pronunciado
                                    Shadow(
                                      color: Colors.black.withOpacity(0.9),
                                      blurRadius: 15,
                                      offset: const Offset(3, 3),
                                    ),
                                    Shadow(
                                      color: Colors.black.withOpacity(0.7),
                                      blurRadius: 8,
                                      offset: const Offset(1, 1),
                                    ),
                                    Shadow(
                                      color: Colors.white.withOpacity(0.5),
                                      blurRadius: 2,
                                      offset: const Offset(-1, -1),
                                    ),
                                    Shadow(
                                      color: Colors.yellow.withOpacity(0.4),
                                      blurRadius: 4,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                
                // Control de Música para sesión de repetición
                const StreamedMusicController(autoPlay: true),
                
                const SizedBox(height: 20),
                
                // Mensaje sobre Grabovoi y repetición
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Importante sobre Grabovoi',
                            style: GoogleFonts.inter(
                              color: Colors.blue,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Grabovoi no menciona que se deba repetir el código, pero si es tu deseo, puedes hacerlo.',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Notas de la versión 1
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.medical_services, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Nota Importante',
                            style: GoogleFonts.inter(
                              color: Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Los códigos numéricos de Grabovoi NO sustituyen la atención médica profesional. '
                        'Siempre consulta con profesionales de la salud para cualquier condición médica. '
                        'Estos códigos son herramientas complementarias de bienestar.',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


