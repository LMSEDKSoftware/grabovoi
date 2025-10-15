import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/sphere_3d.dart';

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

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/grabovoi_${widget.codigo}.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Manifestación Numérica Grabovoi');
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
          child: Padding(
            padding: const EdgeInsets.all(20),
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

                // Vista a capturar
                Expanded(
                  child: Center(
                    child: Screenshot(
                      controller: _screenshotController,
                      child: Container(
                        width: 320,
                        height: 420,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0B132B), Color(0xFF1C2541)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFD700), width: 2),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Positioned(
                              top: 28,
                              child: Text(
                                'Manifestación Numérica Grabovoi',
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            Sphere3D(
                              size: 260,
                              color: const Color(0xFFFFD700),
                              glowIntensity: 0.45,
                              isAnimated: false,
                            ),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFFFF4C2), Color(0xFFFFD700)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Text(
                                widget.codigo,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.spaceMono(
                                  fontSize: 46,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 6,
                                  shadows: const [
                                    Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 2)),
                                    Shadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 6)),
                                  ],
                                ),
                              ),
                            ),
                            if (widget.nombre != null && widget.nombre!.isNotEmpty)
                              Positioned(
                                bottom: 20,
                                child: Text(
                                  widget.nombre!,
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _shareImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: const Color(0xFF0B132B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.share),
                        label: Text(
                          'Compartir / Descargar',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Toca el botón para compartir o guardar tu imagen con la esfera dorada y el código al centro.',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


