import '../models/supabase_models.dart';
import 'supabase_service.dart';

class BibliotecaSupabaseService {
  static String _getUserId() {
    // Por ahora usar un ID fijo, después implementar autenticación
    return 'user_demo';
  }

  // ===== CÓDIGOS =====
  
  static Future<List<CodigoGrabovoi>> getTodosLosCodigos() async {
    try {
      print('🔄 Iniciando conexión con Supabase...');
      print('📍 URL: https://whtiazgcxdnemrrgjjqf.supabase.co');
      print('🔑 Usando anon key...');
      
      final codigos = await SupabaseService.getCodigos();
      print('📚 Respuesta de Supabase: ${codigos.length} códigos');
      
      if (codigos.isEmpty) {
        print('⚠️ PROBLEMA: Supabase devolvió lista vacía');
        print('🔍 Esto puede indicar:');
        print('   - Problema de conectividad');
        print('   - Tabla vacía en Supabase');
        print('   - Error en RLS (Row Level Security)');
        print('   - Credenciales incorrectas');
      } else {
        print('✅ Éxito: Códigos cargados correctamente');
        if (codigos.length > 0) {
          print('📄 Primer código: ${codigos.first.codigo} - ${codigos.first.nombre}');
        }
      }
      
      return codigos;
    } catch (e) {
      print('❌ ERROR CRÍTICO en conexión Supabase:');
      print('   Tipo de error: ${e.runtimeType}');
      print('   Mensaje: $e');
      print('   Stack trace: ${StackTrace.current}');
      
      if (e.toString().contains('Connection')) {
        print('🌐 DIAGNÓSTICO: Problema de conectividad');
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        print('🔐 DIAGNÓSTICO: Problema de autenticación/autorización');
      } else if (e.toString().contains('404')) {
        print('📋 DIAGNÓSTICO: Tabla no encontrada');
      } else if (e.toString().contains('RLS') || e.toString().contains('row level')) {
        print('🛡️ DIAGNÓSTICO: Problema con Row Level Security');
      } else {
        print('❓ DIAGNÓSTICO: Error desconocido');
      }
      
      rethrow; // Re-lanzar el error para que se maneje arriba
    }
  }

  static List<CodigoGrabovoi> _getCodigosLocales() {
    return [
      CodigoGrabovoi(
        id: '1',
        codigo: '5197148',
        nombre: 'Todo es posible',
        descripcion: 'Para manifestar cualquier deseo o intención',
        categoria: 'Manifestación',
        color: '#FFD700',
      ),
      CodigoGrabovoi(
        id: '2',
        codigo: '1884321',
        nombre: 'Condición física desconocida',
        descripcion: 'Para sanar cualquier condición física',
        categoria: 'Salud',
        color: '#00FF7F',
      ),
      CodigoGrabovoi(
        id: '3',
        codigo: '318798',
        nombre: 'Activar la abundancia',
        descripcion: 'Para atraer abundancia y prosperidad',
        categoria: 'Abundancia',
        color: '#FFD700',
      ),
      CodigoGrabovoi(
        id: '4',
        codigo: '71931',
        nombre: 'Protección general',
        descripcion: 'Para protección energética y espiritual',
        categoria: 'Protección',
        color: '#1E90FF',
      ),
      CodigoGrabovoi(
        id: '5',
        codigo: '741',
        nombre: 'Solución inmediata',
        descripcion: 'Para resolver problemas urgentes',
        categoria: 'Soluciones',
        color: '#C0C0C0',
      ),
    ];
  }

  static Future<List<CodigoGrabovoi>> getCodigosPorCategoria(String categoria) async {
    return await SupabaseService.getCodigosPorCategoria(categoria);
  }

  static Future<List<CodigoGrabovoi>> buscarCodigos(String query) async {
    if (query.isEmpty) return await getTodosLosCodigos();
    return await SupabaseService.buscarCodigos(query);
  }

  // ===== FAVORITOS =====
  
  static Future<List<CodigoGrabovoi>> getFavoritos() async {
    return await SupabaseService.getFavoritos(_getUserId());
  }

  static Future<void> toggleFavorito(String codigoId) async {
    final userId = _getUserId();
    final esFavorito = await SupabaseService.esFavorito(userId, codigoId);
    
    if (esFavorito) {
      await SupabaseService.quitarFavorito(userId, codigoId);
    } else {
      await SupabaseService.agregarFavorito(userId, codigoId);
    }
  }

  static Future<bool> esFavorito(String codigoId) async {
    return await SupabaseService.esFavorito(_getUserId(), codigoId);
  }

  // ===== POPULARIDAD =====
  
  static Future<List<CodigoPopularidad>> getPopularidad() async {
    return await SupabaseService.getPopularidad();
  }

  static Future<void> incrementarPopularidad(String codigoId) async {
    await SupabaseService.incrementarPopularidad(codigoId);
  }

  // ===== CATEGORÍAS =====
  
  static Future<List<String>> getCategorias() async {
    try {
      final codigos = await getTodosLosCodigos();
      final categorias = codigos.map((c) => c.categoria).toSet().toList();
      categorias.sort();
      return categorias;
    } catch (e) {
      return ['Manifestación', 'Salud', 'Abundancia', 'Protección', 'Soluciones', 'Espiritual'];
    }
  }

  // ===== PROGRESO DE USUARIO =====
  
  static Future<UsuarioProgreso?> getProgresoUsuario() async {
    return await SupabaseService.getProgresoUsuario(_getUserId());
  }

  static Future<void> registrarPilotaje() async {
    await SupabaseService.registrarPilotaje(_getUserId());
  }

  // ===== AUDIOS =====
  
  static Future<List<AudioFile>> getAudios() async {
    return await SupabaseService.getAudios();
  }

  static Future<String> getAudioUrl(String archivo) async {
    return await SupabaseService.getAudioUrl(archivo);
  }

  // ===== MÉTODOS DE CONVENIENCIA =====
  
  static Future<Map<String, dynamic>> getDatosParaHome() async {
    try {
      final progreso = await getProgresoUsuario();
      final codigos = await getTodosLosCodigos();
      
      // Código recomendado (primero de la lista o aleatorio)
      final codigoRecomendado = codigos.isNotEmpty 
          ? codigos.first.codigo 
          : '5197148';

      return {
        'nivel': progreso?.nivelEnergetico ?? 1,
        'codigoRecomendado': codigoRecomendado,
        'fraseMotivacional': _generarFraseMotivacional(progreso?.nivelEnergetico ?? 1, progreso?.diasConsecutivos ?? 0),
        'proximoPaso': _determinarProximoPaso(progreso?.diasConsecutivos ?? 0, progreso?.totalPilotajes ?? 0),
      };
    } catch (e) {
      // Fallback en caso de error
      return {
        'nivel': 1,
        'codigoRecomendado': '5197148',
        'fraseMotivacional': '🌙 El viaje de mil millas comienza con un solo paso.',
        'proximoPaso': 'Realiza tu primer pilotaje consciente hoy',
      };
    }
  }

  static String _generarFraseMotivacional(int nivel, int diasConsecutivos) {
    if (diasConsecutivos >= 21) {
      return '✨ Tu energía vibra en frecuencias elevadas. ¡Eres imparable!';
    } else if (diasConsecutivos >= 14) {
      return '🌟 Tu constancia está manifestando resultados poderosos.';
    } else if (diasConsecutivos >= 7) {
      return '💫 Una semana de conexión consciente. ¡Continúa el camino!';
    } else if (diasConsecutivos >= 3) {
      return '🔮 La energía fluye contigo. Cada día es más poderoso.';
    } else {
      return '🌙 El viaje de mil millas comienza con un solo paso.';
    }
  }

  static String _determinarProximoPaso(int diasConsecutivos, int totalPilotajes) {
    if (diasConsecutivos == 0) {
      return 'Realiza tu primer pilotaje consciente hoy';
    } else if (diasConsecutivos < 7) {
      return 'Completa 7 días consecutivos para desbloquear el primer nivel';
    } else if (diasConsecutivos < 21) {
      return 'Continúa hasta 21 días para una transformación profunda';
    } else {
      return 'Comparte tu luz con la comunidad';
    }
  }
}
