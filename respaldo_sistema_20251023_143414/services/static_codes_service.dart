import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/supabase_models.dart';

class StaticCodesService {
  // URLs de fallback - puedes usar GitHub Pages, Netlify, etc.
  static const List<String> _urls = [
    'https://raw.githubusercontent.com/LMSEDKSoftware/grabovoi/main/codigos.json',
    'https://manifestacionnumerica.app/codigos.json',
    'https://cdn.jsdelivr.net/gh/LMSEDKSoftware/grabovoi@main/codigos.json',
  ];

  static Future<List<CodigoGrabovoi>> getCodigos({
    String? categoria,
    String? search,
  }) async {
    print('[STATIC] Intentando cargar códigos desde CDN...');
    
    for (int i = 0; i < _urls.length; i++) {
      try {
        print('[STATIC] Probando URL ${i + 1}: ${_urls[i]}');
        
        final response = await http.get(
          Uri.parse(_urls[i]),
          headers: {
            'Accept': 'application/json',
            'Cache-Control': 'no-cache',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          List<dynamic> codigosData;
          
          if (data is List) {
            codigosData = data;
          } else if (data is Map && data['data'] is List) {
            codigosData = data['data'];
          } else {
            throw Exception('Formato JSON inválido');
          }

          final codigos = codigosData
              .map((json) => CodigoGrabovoi.fromJson(json))
              .toList();

          print('[STATIC] ✅ Códigos cargados: ${codigos.length} desde ${_urls[i]}');
          
          // Aplicar filtros
          var filtrados = codigos;
          if (categoria != null && categoria != 'Todos') {
            filtrados = filtrados.where((c) => c.categoria == categoria).toList();
          }
          if (search != null && search.isNotEmpty) {
            filtrados = filtrados.where((c) => 
              c.nombre.toLowerCase().contains(search.toLowerCase()) ||
              c.codigo.contains(search) ||
              c.descripcion.toLowerCase().contains(search.toLowerCase())
            ).toList();
          }

          return filtrados;
        }
      } catch (e) {
        print('[STATIC] ❌ Error con URL ${i + 1}: $e');
        if (i == _urls.length - 1) {
          // Si todas fallan, usar datos locales
          return _getCodigosLocales();
        }
      }
    }
    
    return _getCodigosLocales();
  }

  static List<CodigoGrabovoi> _getCodigosLocales() {
    print('[STATIC] 🔄 Usando códigos locales de respaldo...');
    
    // Códigos esenciales embebidos (los más importantes)
    final codigosLocales = [
      CodigoGrabovoi(
        id: 'local-1',
        codigo: '888_412_128_9012',
        nombre: 'Sanación Universal',
        descripcion: 'Para sanación física, mental y espiritual.',
        categoria: 'Sanación',
        color: '#FF6B6B',
      ),
      CodigoGrabovoi(
        id: 'local-2',
        codigo: '520_741_963_8520',
        nombre: 'Abundancia y Prosperidad',
        descripcion: 'Atrae abundancia y prosperidad a tu vida.',
        categoria: 'Abundancia',
        color: '#4ECDC4',
      ),
      CodigoGrabovoi(
        id: 'local-3',
        codigo: '714_825_936_7142',
        nombre: 'Amor y Relaciones',
        descripcion: 'Fortalece relaciones y atrae amor verdadero.',
        categoria: 'Amor',
        color: '#FFE66D',
      ),
      CodigoGrabovoi(
        id: 'local-4',
        codigo: '369_147_258_3691',
        nombre: 'Protección Espiritual',
        descripcion: 'Protección contra energías negativas.',
        categoria: 'Protección',
        color: '#A8E6CF',
      ),
      CodigoGrabovoi(
        id: 'local-5',
        codigo: '123_456_789_0123',
        nombre: 'Paz Interior',
        descripcion: 'Encuentra paz y equilibrio interior.',
        categoria: 'Paz',
        color: '#FFB6C1',
      ),
    ];

    print('[STATIC] ✅ Códigos locales cargados: ${codigosLocales.length}');
    return codigosLocales;
  }

  static Future<List<String>> getCategorias() async {
    try {
      final codigos = await getCodigos();
      return codigos.map((c) => c.categoria).toSet().toList();
    } catch (e) {
      return ['Sanación', 'Abundancia', 'Amor', 'Protección', 'Paz'];
    }
  }

  static Future<List<UsuarioFavorito>> getFavoritos(String userId) async {
    // Para versión estática, usar SharedPreferences
    return [];
  }

  static Future<void> toggleFavorito(String userId, String codigoId) async {
    // Para versión estática, usar SharedPreferences
    print('[STATIC] Toggle favorito: $codigoId');
  }

  static Future<void> incrementarPopularidad(String codigoId) async {
    // Para versión estática, usar SharedPreferences
    print('[STATIC] Incrementar popularidad: $codigoId');
  }
}
