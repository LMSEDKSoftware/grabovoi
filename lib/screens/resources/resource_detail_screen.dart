import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../widgets/glow_background.dart';
import '../../models/resource_model.dart';

class ResourceDetailScreen extends StatefulWidget {
  final Resource resource;

  const ResourceDetailScreen({
    super.key,
    required this.resource,
  });

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    // Debug: verificar contenido HTML
    print('📄 Contenido del recurso (primeros 300 chars): ${widget.resource.content.length > 300 ? widget.resource.content.substring(0, 300) : widget.resource.content}');
    print('📄 ¿Contiene <p>?: ${widget.resource.content.contains('<p>')}');
    print('📄 ¿Contiene <b>?: ${widget.resource.content.contains('<b>')}');
    if (widget.resource.videoUrl != null &&
        widget.resource.videoUrl!.isNotEmpty) {
      _initializeVideo();
    }
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.resource.videoUrl!),
    );

    _videoController!.initialize().then((_) {
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error cargando video: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );
      setState(() {});
    });
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      body: GlowBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con botón de regreso
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFFFFD700),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          'Recurso',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFD700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Imagen principal si existe
                if (widget.resource.imageUrl != null &&
                    widget.resource.imageUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: widget.resource.imageUrl!,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 250,
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFFD700),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 250,
                      color: Colors.black.withOpacity(0.3),
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
                  ),
                // Video si existe
                if (widget.resource.videoUrl != null &&
                    widget.resource.videoUrl!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _chewieController != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Chewie(controller: _chewieController!),
                          )
                        : const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFFD700),
                            ),
                          ),
                  ),
                // Contenido
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Categoría
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.resource.category,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFFFD700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Título
                      Text(
                        widget.resource.title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Descripción
                      Text(
                        widget.resource.description,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white70,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Contenido principal
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFD700).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: _buildFormattedContent(widget.resource.content),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construir contenido formateado con soporte para HTML básico
  Widget _buildFormattedContent(String content) {
    // Limpiar el contenido: remover etiquetas <p> y convertir <br> a saltos de línea
    String cleanedContent = content
        .replaceAll(RegExp(r'</?p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n'); // Normalizar múltiples saltos de línea

    // Dividir por párrafos (doble salto de línea)
    final paragraphs = cleanedContent
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((paragraph) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _buildParagraph(paragraph.trim()),
        );
      }).toList(),
    );
  }

  /// Construir un párrafo con soporte para texto en negrita
  Widget _buildParagraph(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'<b>(.*?)</b>', caseSensitive: false);
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      // Texto antes de la etiqueta
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.white,
            height: 1.8,
          ),
        ));
      }

      // Texto en negrita
      spans.add(TextSpan(
        text: match.group(1),
        style: GoogleFonts.inter(
          fontSize: 15,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          height: 1.8,
        ),
      ));

      lastIndex = match.end;
    }

    // Texto restante después de la última etiqueta
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: GoogleFonts.inter(
          fontSize: 15,
          color: Colors.white,
          height: 1.8,
        ),
      ));
    }

    // Si no hay etiquetas, mostrar el texto normal (limpiando cualquier HTML restante)
    if (spans.isEmpty) {
      spans.add(TextSpan(
        text: text.replaceAll(RegExp(r'<[^>]*>'), ''),
        style: GoogleFonts.inter(
          fontSize: 15,
          color: Colors.white,
          height: 1.8,
        ),
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
    );
  }
}

