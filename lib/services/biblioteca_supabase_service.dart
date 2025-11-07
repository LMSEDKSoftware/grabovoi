import '../models/supabase_models.dart';
import '../config/supabase_config.dart';
import 'supabase_service.dart';
import 'auth_service_simple.dart';
import 'user_favorites_service.dart';
import 'user_progress_service.dart';
import 'daily_code_service.dart';
import 'notification_scheduler.dart';
import 'rewards_service.dart';

class BibliotecaSupabaseService {
  static final AuthServiceSimple _authService = AuthServiceSimple();
  static final UserFavoritesService _favoritesService = UserFavoritesService();
  static final UserProgressService _progressService = UserProgressService();

  static String? _getUserId() {
    if (!_authService.isLoggedIn) return null;
    return _authService.currentUser!.id;
  }

  // ===== CÓDIGOS =====
  
  static Future<List<CodigoGrabovoi>> getTodosLosCodigos() async {
    try {
      print('🔄 Iniciando conexión con Supabase...');
      print('📍 URL: ${SupabaseConfig.url}');
      print('🔑 Usando anon key seguro desde variables de entorno...');
      
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
    if (!_authService.isLoggedIn) return [];
    
    try {
      final favoritesWithDetails = await _favoritesService.getFavoritesWithDetails();
      return favoritesWithDetails.map((item) {
        final codigoData = item['codigos_grabovoi'];
        return CodigoGrabovoi(
          id: codigoData['id'],
          codigo: codigoData['codigo'],
          nombre: codigoData['nombre'],
          descripcion: codigoData['descripcion'],
          categoria: codigoData['categoria'],
          color: codigoData['color'],
        );
      }).toList();
    } catch (e) {
      print('Error obteniendo favoritos: $e');
      return [];
    }
  }

  static Future<void> toggleFavorito(String codigoId) async {
    if (!_authService.isLoggedIn) {
      print('⚠️ Usuario no autenticado, no se puede gestionar favoritos');
      return;
    }
    
    await _favoritesService.toggleFavorite(codigoId);
  }

  static Future<void> agregarFavoritoConEtiqueta(String codigoId, String etiqueta) async {
    if (!_authService.isLoggedIn) {
      print('⚠️ Usuario no autenticado, no se puede agregar favoritos');
      return;
    }
    
    try {
      await SupabaseService.agregarFavorito(
        _authService.currentUser!.id,
        codigoId,
        etiqueta: etiqueta,
      );
      print('✅ Favorito agregado con etiqueta: $etiqueta');
    } catch (e) {
      print('Error agregando favorito con etiqueta: $e');
      rethrow;
    }
  }

  static Future<bool> esFavorito(String codigoId) async {
    if (!_authService.isLoggedIn) return false;
    return await _favoritesService.isFavorite(codigoId);
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
    if (!_authService.isLoggedIn) return null;
    
    try {
      // Progreso desde la tabla usuario_progreso (fuente de verdad)
      final progress = await _progressService.getUserProgress();
      if (progress != null) {
        return UsuarioProgreso(
          id: progress['id'] ?? progress['user_id'],
          userId: progress['user_id'],
          diasConsecutivos: (progress['dias_consecutivos'] ?? 0) as int,
          totalPilotajes: (progress['total_pilotajes'] ?? 0) as int,
          nivelEnergetico: (progress['nivel_energetico'] ?? 1) as int,
          ultimoPilotaje: progress['ultimo_pilotaje'] != null
              ? DateTime.parse(progress['ultimo_pilotaje'])
              : DateTime.now(),
          createdAt: progress['created_at'] != null
              ? DateTime.parse(progress['created_at'])
              : DateTime.now(),
          updatedAt: progress['updated_at'] != null
              ? DateTime.parse(progress['updated_at'])
              : DateTime.now(),
        );
      }

      // Fallback: datos mínimos desde users si aún no hay fila en user_progress
      final user = await SupabaseService.getCurrentUser();
      if (user == null) return null;

      return UsuarioProgreso(
        id: user['id'],
        userId: user['id'],
        diasConsecutivos: 0,
        totalPilotajes: 0,
        nivelEnergetico: user['level'] ?? 1,
        ultimoPilotaje: DateTime.now(),
        createdAt: DateTime.parse(user['created_at']),
        updatedAt: DateTime.parse(user['updated_at']),
      );
    } catch (e) {
      print('Error obteniendo progreso del usuario: $e');
      return null;
    }
  }

  static Future<void> registrarPilotaje({
    String? codeId,
    String? codeName,
    int durationMinutes = 0,
    String? category,
  }) async {
    if (!_authService.isLoggedIn) {
      print('⚠️ Usuario no autenticado, sesión no registrada');
      return;
    }
    
    await _progressService.recordSession(
      sessionType: 'pilotage',
      codeId: codeId,
      codeName: codeName,
      durationMinutes: durationMinutes,
      category: category,
    );
    
    // Notificar al scheduler de notificaciones
    await NotificationScheduler().onPilotageCompleted();
  }

  static Future<void> registrarRepeticion({
    String? codeId,
    String? codeName,
    int durationMinutes = 0,
    String? category,
  }) async {
    if (!_authService.isLoggedIn) {
      print('⚠️ Usuario no autenticado, sesión no registrada');
      return;
    }

    await _progressService.recordSession(
      sessionType: 'repetition',
      codeId: codeId,
      codeName: codeName,
      durationMinutes: durationMinutes,
      category: category,
    );
    
    // Notificar al scheduler de notificaciones
    await NotificationScheduler().onRepetitionCompleted();
    
    // Recompensar por completar repetición (misma lógica que pilotaje)
    try {
      final rewardsService = RewardsService();
      await rewardsService.recompensarPorPilotaje();
      await rewardsService.addToHistory(
        'cristales',
        'Cristales de energía ganados por completar repetición',
        cantidad: RewardsService.cristalesPorDia,
      );
      await rewardsService.addToHistory(
        'luz_cuantica',
        'Luz cuántica ganada por completar repetición',
        cantidad: RewardsService.luzCuanticaPorPilotaje.toInt(),
      );
    } catch (e) {
      print('⚠️ Error otorgando recompensas: $e');
    }
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
      
      // Obtener el código del día actual desde daily_code_assignments
      // Todos los usuarios verán el mismo código cada día
      final codigoRecomendado = await DailyCodeService.getTodayCode();

      // Si el usuario no está autenticado, usar datos por defecto
      if (!_authService.isLoggedIn) {
        return {
          'nivel': 1,
          'codigoRecomendado': codigoRecomendado,
          'fraseMotivacional': '🌙 Inicia sesión para personalizar tu experiencia',
          'proximoPaso': 'Regístrate para comenzar tu viaje energético',
        };
      }

      return {
        'nivel': progreso?.nivelEnergetico ?? 1,
        'codigoRecomendado': codigoRecomendado,
        'fraseMotivacional': _generarFraseMotivacional(progreso?.nivelEnergetico ?? 1, progreso?.diasConsecutivos ?? 0),
        'proximoPaso': _determinarProximoPaso(progreso?.diasConsecutivos ?? 0, progreso?.totalPilotajes ?? 0),
      };
    } catch (e) {
      print('❌ Error en getDatosParaHome: $e');
      // Fallback en caso de error
      return {
        'nivel': 1,
        'codigoRecomendado': '812_719_819_14', // Vitalidad como fallback
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

  // ===== FAVORITOS CON ETIQUETAS =====
  
  static Future<List<String>> getEtiquetasFavoritos() async {
    try {
      return await SupabaseService.getEtiquetasFavoritos(_getUserId() ?? '');
    } catch (e) {
      print('Error obteniendo etiquetas de favoritos: $e');
      return [];
    }
  }

  static Future<List<CodigoGrabovoi>> getFavoritosPorEtiqueta(String etiqueta) async {
    try {
      return await SupabaseService.getFavoritosPorEtiqueta(_getUserId() ?? '', etiqueta);
    } catch (e) {
      print('Error obteniendo favoritos por etiqueta: $e');
      return [];
    }
  }

  static Future<String?> getEtiquetaFavorito(String codigoId) async {
    if (!_authService.isLoggedIn) return null;
    
    try {
      // Usar el servicio de favoritos para obtener la etiqueta
      final favoritesWithDetails = await _favoritesService.getFavoritesWithDetails();
      final favorite = favoritesWithDetails.firstWhere(
        (item) => item['codigo_id'] == codigoId,
        orElse: () => <String, dynamic>{},
      );
      
      return favorite['etiqueta'] as String?;
    } catch (e) {
      print('Error obteniendo etiqueta del favorito: $e');
      return null;
    }
  }
}
