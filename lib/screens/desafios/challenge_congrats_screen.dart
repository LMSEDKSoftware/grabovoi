import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/golden_sphere.dart';
import '../../widgets/illuminated_code_text.dart';
import '../../utils/code_formatter.dart';

class ChallengeCongratsScreen extends StatefulWidget {
  final String title;
  final String imageUrl; // público en Supabase storage
  final String? description; // Descripción del reto

  const ChallengeCongratsScreen({
    super.key,
    required this.title,
    required this.imageUrl,
    this.description,
  });

  @override
  State<ChallengeCongratsScreen> createState() => _ChallengeCongratsScreenState();
}

class _ChallengeCongratsScreenState extends State<ChallengeCongratsScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                  '¡Felicitaciones!',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    color: const Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Has completado el reto: ${widget.title}',
                  style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, _, __) => Container(
                        color: Colors.white10,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported, color: Colors.white54, size: 48),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Widget para capturar (oculto, fuera de la vista)
                Offstage(
                  child: Screenshot(
                    controller: _screenshotController,
                    child: FutureBuilder<String>(
                      future: Future.value(widget.description ?? 
                          'Has completado con éxito este desafío de manifestación cuántica usando los códigos de Grigori Grabovoi.'),
                      builder: (context, snapshot) {
                        final descripcion = snapshot.data ?? 
                            'Has completado con éxito este desafío de manifestación cuántica usando los códigos de Grigori Grabovoi.';
                        return _buildShareableImage(descripcion);
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: const Color(0xFF0B132B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _shareImage,
                    icon: const Icon(Icons.ios_share),
                    label: Text('Compartir o guardar certificado', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareImage() async {
    try {
      // Capturar la imagen del widget que está en el árbol
      final pngBytes = await _screenshotController.capture(pixelRatio: 2.0);
      
      if (pngBytes == null) return;

      // Solo para móvil, web no soporta compartir imágenes
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/reto_${widget.title.replaceAll(' ', '_')}.png');
        await file.writeAsBytes(pngBytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Compartido desde ManiGrab - Manifestaciones Cuánticas Grabovoi',
        );
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
        SnackBar(
          content: Text('Error al compartir: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildShareableImage(String descripcion) {
    // Código genérico para retos de iniciación (usando código de iniciación)
    final codigoReto = '1884321'; // Norma Absoluta - código de iniciación
    final String codigoFormateado = CodeFormatter.formatCodeForDisplay(codigoReto);
    final double fontSize = CodeFormatter.calculateFontSize(codigoReto);

    return Container(
      width: 800, // Ancho fijo para la imagen
      height: 1200, // Alto fijo para la imagen
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1) NOMBRE DE LA APP - Arriba
          Text(
            'ManiGrab - Manifestaciones Cuánticas Grabovoi',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFD700),
              shadows: [
                Shadow(
                  color: const Color(0xFFFFD700).withOpacity(0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
          
          // 2) ESFERA CON CÓDIGO - Centro
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Esfera dorada
              GoldenSphere(
                size: 320,
                color: const Color(0xFFFFD700),
                glowIntensity: 0.8,
                isAnimated: false,
              ),
              // Código iluminado superpuesto
              IlluminatedCodeText(
                code: codigoFormateado,
                fontSize: fontSize,
                color: const Color(0xFFFFD700),
                letterSpacing: 4,
                isAnimated: false,
              ),
            ],
          ),
          const SizedBox(height: 60),
          
          // 3) TÍTULO Y DESCRIPCIÓN DEL RETO - Abajo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  descripcion,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
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


