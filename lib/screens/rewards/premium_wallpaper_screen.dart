import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../config/supabase_config.dart';
import '../../models/rewards_model.dart';
import '../../utils/share_helper.dart';
import '../../widgets/glow_background.dart';

// Importación condicional para web
import 'premium_wallpaper_screen_web.dart' if (dart.library.html) 'premium_wallpaper_screen_web.dart' if (dart.library.io) 'premium_wallpaper_screen_web_stub.dart';

/// Pantalla que muestra la imagen/recompensa asociada a un código premium
/// y permite descargarla/compartirla para usarla como fondo de pantalla.
class PremiumWallpaperScreen extends StatefulWidget {
  final CodigoPremium codigo;

  /// URL de la imagen. Si es nula o vacía, la pantalla mostrará un mensaje de error.
  final String? imageUrl;

  const PremiumWallpaperScreen({
    super.key,
    required this.codigo,
    required this.imageUrl,
  });

  @override
  State<PremiumWallpaperScreen> createState() => _PremiumWallpaperScreenState();
}

class _PremiumWallpaperScreenState extends State<PremiumWallpaperScreen> {
  bool _isDownloading = false;
  String? _resolvedImageUrl;

  /// Resuelve la URL de la imagen, convirtiendo rutas relativas de Supabase Storage a URLs públicas
  /// 
  /// IMPORTANTE: Las URLs de Supabase Storage tienen CORS configurado automáticamente y funcionan
  /// perfectamente en Flutter Web. Las URLs externas pueden tener problemas de CORS.
  String? _resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    
    // Si ya es una URL completa (http/https)
    if (url.startsWith('http://') || url.startsWith('https://')) {
      // Verificar si es una URL de Supabase Storage (tiene CORS configurado)
      if (url.contains('.supabase.co/storage/')) {
        print('✅ URL de Supabase Storage detectada (CORS configurado): $url');
        return url;
      } else {
        // Es una URL externa - puede tener problemas de CORS en web
        if (kIsWeb) {
          print('⚠️ URL externa detectada (puede tener problemas de CORS): $url');
          print('💡 RECOMENDACIÓN: Migrar esta imagen a Supabase Storage para evitar problemas de CORS');
        } else {
          print('✅ URL externa detectada: $url');
        }
        return url;
      }
    }
    
    // Si es una ruta relativa (ej: "wallpapers/888_888_888.png"), convertirla a URL pública de Supabase Storage
    // Las imágenes en Supabase Storage tienen CORS configurado automáticamente
    try {
      // Intentar primero con bucket 'wallpapers'
      final publicUrl = SupabaseConfig.client.storage
          .from('wallpapers')
          .getPublicUrl(url);
      print('✅ URL resuelta desde Supabase Storage (wallpapers) - CORS configurado: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('⚠️ Error resolviendo URL desde bucket wallpapers: $e');
      try {
        // Intentar con bucket 'images' como fallback
        final publicUrl = SupabaseConfig.client.storage
            .from('images')
            .getPublicUrl(url);
        print('✅ URL resuelta desde Supabase Storage (images) - CORS configurado: $publicUrl');
        return publicUrl;
      } catch (e2) {
        print('❌ Error resolviendo URL desde bucket images: $e2');
        // Si falla, retornar la URL original (puede ser una URL externa mal formada)
        return url;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _resolvedImageUrl = _resolveImageUrl(widget.imageUrl);
    if (_resolvedImageUrl != null) {
      print('🖼️ URL de imagen resuelta: $_resolvedImageUrl');
      // Registrar el view factory para web si es necesario
      if (kIsWeb && _resolvedImageUrl != null) {
        _registerWebImage(_resolvedImageUrl!);
      }
    } else {
      print('⚠️ No se pudo resolver la URL de la imagen');
    }
  }

  /// Registra un elemento HTML <img> para evitar problemas de CORS en web
  void _registerWebImage(String url) {
    if (!kIsWeb) return;
    
    try {
      // Crear un identificador único basado en la URL (hash simple)
      final urlHash = url.hashCode.toString();
      final viewType = 'image-view-$urlHash';
      
      WebImageHelper.registerWebImage(url, viewType);
    } catch (e) {
      print('⚠️ Error registrando imagen HTML: $e');
    }
  }

  /// Construye el widget de imagen apropiado según la plataforma
  Widget _buildImageWidget(String imageUrl) {
    if (kIsWeb) {
      // En web, usar HtmlElementView con un elemento <img> para evitar CORS
      try {
        final urlHash = imageUrl.hashCode.toString();
        final viewType = 'image-view-$urlHash';
        _registerWebImage(imageUrl);
        
        return SizedBox.expand(
          child: HtmlElementView(
            viewType: viewType,
          ),
        );
      } catch (e) {
        print('⚠️ Error creando HtmlElementView, usando Image.network como fallback: $e');
        // Fallback a Image.network si HtmlElementView falla
        return _buildNetworkImage(imageUrl);
      }
    } else {
      // En otras plataformas, usar Image.network normalmente
      // HtmlElementView no está disponible en móvil, así que siempre usamos Image.network
      return _buildNetworkImage(imageUrl);
    }
  }

  /// Construye un widget Image.network con manejo de errores
  Widget _buildNetworkImage(String imageUrl) {
    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: const Color(0xFFFFD700),
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        (loadingProgress.expectedTotalBytes ?? 1)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Cargando imagen...',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
                                errorBuilder: (context, error, stackTrace) {
                                  print('❌ Error cargando imagen: $error');
                                  print('❌ Stack trace: $stackTrace');
                                  print('❌ URL intentada: $imageUrl');
                                  
                                  // Detectar si es un error de CORS
                                  final isCorsError = error.toString().toLowerCase().contains('cors') ||
                                                     error.toString().toLowerCase().contains('cross-origin');
                                  final isSupabaseUrl = imageUrl.contains('.supabase.co/storage/');
                                  
                                  return Container(
                                    color: Colors.black26,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 48,
                                          color: Colors.red[300],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          isCorsError ? 'Error de CORS al cargar la imagen' : 'No se pudo cargar la imagen',
                                          style: GoogleFonts.inter(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'URL: ${imageUrl.length > 50 ? "${imageUrl.substring(0, 50)}..." : imageUrl}',
                                          style: GoogleFonts.inter(
                                            color: Colors.white38,
                                            fontSize: 10,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          isCorsError && !isSupabaseUrl
                                              ? 'SOLUCIÓN:\n• Migra esta imagen a Supabase Storage\n• Los buckets públicos de Supabase tienen CORS configurado automáticamente\n• Usa el bucket "wallpapers" o "images"'
                                              : 'Verifica que:\n• La URL sea válida\n• El archivo exista\n• Los permisos de Storage estén configurados',
                                          style: GoogleFonts.inter(
                                            color: Colors.white38,
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  );
                                },
    );
  }

  Future<void> _downloadImage() async {
    final url = _resolvedImageUrl ?? widget.imageUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ No se encontró la imagen de esta recompensa'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (kIsWeb) {
      // En web, de momento solo mostramos la imagen; la descarga nativa se maneja por el navegador.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Descarga disponible solo en la app móvil'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isDownloading = true;
      });

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Error HTTP ${response.statusCode}');
      }

      final Uint8List bytes = response.bodyBytes;

      await ShareHelper.shareImage(
        pngBytes: bytes,
        fileName: 'wallpaper_${widget.codigo.codigo}',
        text:
            'Fondo cuántico de la secuencia premium ${widget.codigo.codigo} - ${widget.codigo.nombre}',
        context: context,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Imagen lista para guardar/usar como fondo'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ No se pudo descargar la imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolvedImageUrl ?? widget.imageUrl;

    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFFFFD700)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.codigo.codigo,
                            style: GoogleFonts.spaceMono(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFD700),
                            ),
                          ),
                          Text(
                            widget.codigo.nombre,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Imagen centrada
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: imageUrl == null || imageUrl.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.image_not_supported,
                                  size: 64,
                                  color: Colors.white38,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'La imagen de esta recompensa aún no está disponible.\n\nPide al equipo que configure el campo `wallpaper_url` en la tabla de `codigos_premium`.',
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: kIsWeb
                                ? InteractiveViewer(
                                    minScale: 1.0,
                                    maxScale: 3.0,
                                    child: _buildImageWidget(imageUrl),
                                  )
                                : InteractiveViewer(
                                    minScale: 1.0,
                                    maxScale: 3.0,
                                    child: _buildNetworkImage(imageUrl),
                                  ),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Texto de ayuda y botón de descarga
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Descarga esta imagen para usarla como fondo de pantalla en tu celular y mantener activa la vibración de esta secuencia.',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed:
                            ((_resolvedImageUrl ?? imageUrl) == null || (_resolvedImageUrl ?? imageUrl)!.isEmpty || _isDownloading)
                                ? null
                                : _downloadImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        icon: _isDownloading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              )
                            : const Icon(Icons.download),
                        label: Text(
                          _isDownloading ? 'Preparando imagen...' : 'Descargar fondo',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

