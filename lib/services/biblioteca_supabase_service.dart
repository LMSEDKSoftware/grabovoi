import '../models/supabase_models.dart';
import '../config/supabase_config.dart';
import '../repositories/codigos_repository.dart';
import 'supabase_service.dart';
import 'auth_service_simple.dart';
import 'user_favorites_service.dart';
import 'user_custom_codes_service.dart';
import 'user_progress_service.dart';
import 'daily_code_service.dart';
import 'notification_scheduler.dart';
import 'rewards_service.dart';
import 'mensajes_diarios_service.dart';

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
      // Usar el repositorio que tiene caché para evitar recargas innecesarias
      final repository = CodigosRepository();
      final codigos = repository.codigos;
      
      // Si el repositorio tiene códigos en caché, usarlos directamente (sin llamar a Supabase)
      if (codigos.isNotEmpty) {
        print('✅ Códigos cargados desde caché del repositorio (${codigos.length} códigos)');
        return codigos;
      }
      
      // Si no hay caché, inicializar el repositorio (solo una vez al inicio de la app)
      print('🔄 Inicializando repositorio de códigos (primera carga)...');
      await repository.initCodigos();
      final codigosInicializados = repository.codigos;
      
      if (codigosInicializados.isNotEmpty) {
        print('✅ Códigos cargados desde repositorio (${codigosInicializados.length} códigos)');
        return codigosInicializados;
      }
      
      // Fallback a códigos locales si todo falla
      print('⚠️ No se encontraron códigos, usando fallback local...');
      return _getCodigosLocales();
    } catch (e) {
      print('❌ Error al obtener códigos: $e');
      print('🔄 Usando códigos locales como fallback...');
      return _getCodigosLocales();
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
        final codigoData = item['codigos_grabovoi'] as Map<String, dynamic>;
        return CodigoGrabovoi(
          id: codigoData['id'] as String? ?? '',
          codigo: codigoData['codigo'] as String? ?? '',
          nombre: codigoData['nombre'] as String? ?? '',
          descripcion: codigoData['descripcion'] as String? ?? '',
          categoria: codigoData['categoria'] as String? ?? 'General',
          color: codigoData['color'] as String? ?? '#FFD700',
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
    
    // Verificar si es código personalizado (automáticamente es favorito)
    try {
      final customCodesService = UserCustomCodesService();
      final isCustom = await customCodesService.isCustomCode(codigoId);
      if (isCustom) {
        return true;
      }
    } catch (e) {
      print('⚠️ Error verificando código personalizado: $e');
    }
    
    // Verificar en favoritos oficiales
    return await _favoritesService.isFavorite(codigoId);
  }
  
  static Future<String?> getEtiquetaFavorito(String codigoId) async {
    if (!_authService.isLoggedIn) return null;
    
    // Si es código personalizado, retornar "pilotaje manual"
    try {
      final customCodesService = UserCustomCodesService();
      final isCustom = await customCodesService.isCustomCode(codigoId);
      if (isCustom) {
        return 'pilotaje manual';
      }
    } catch (e) {
      print('⚠️ Error verificando código personalizado: $e');
    }
    
    // Obtener etiqueta de favoritos oficiales
    try {
      final favoritesWithDetails = await _favoritesService.getFavoritesWithDetails();
      final favorite = favoritesWithDetails.firstWhere(
        (item) => (item['codigo_id'] as String? ?? 
                   (item['codigos_grabovoi'] as Map?)?['codigo'] as String?) == codigoId,
        orElse: () => <String, dynamic>{},
      );
      return favorite['etiqueta'] as String?;
    } catch (e) {
      print('Error obteniendo etiqueta de favorito: $e');
      return null;
    }
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
    
    // Notificar al scheduler de notificaciones con el código para evitar duplicados
    await NotificationScheduler().onPilotageCompleted(codeNumber: codeId ?? codeName);
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
    
    // Las recompensas ahora se otorgan en el screen después de completar la repetición
    // para poder mostrar la información en el modal de finalización
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

      // Obtener el mensaje diario desde la tabla mensajes_diarios
      final mensajeDiario = await MensajesDiariosService.obtenerMensajeDiarioConFallback();

      // Si el usuario no está autenticado, usar datos por defecto
      if (!_authService.isLoggedIn) {
        return {
          'nivel': 1,
          'codigoRecomendado': codigoRecomendado,
          'fraseMotivacional': mensajeDiario,
          'proximoPaso': 'Regístrate para comenzar tu viaje energético',
        };
      }

      return {
        'nivel': progreso?.nivelEnergetico ?? 1,
        'codigoRecomendado': codigoRecomendado,
        'fraseMotivacional': mensajeDiario,
        'proximoPaso': _determinarProximoPaso(progreso?.diasConsecutivos ?? 0, progreso?.totalPilotajes ?? 0),
      };
    } catch (e) {
      print('❌ Error en getDatosParaHome: $e');
      // Fallback en caso de error - usar mensaje diario si está disponible
      final mensajeDiario = await MensajesDiariosService.obtenerMensajeDiarioConFallback();
      return {
        'nivel': 1,
        'codigoRecomendado': '812_719_819_14', // Vitalidad como fallback
        'fraseMotivacional': mensajeDiario,
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
      final List<CodigoGrabovoi> allFavorites = [];
      
      // Si la etiqueta es "pilotaje manual", incluir códigos personalizados
      if (etiqueta.toLowerCase() == 'pilotaje manual') {
        try {
          final customCodesService = UserCustomCodesService();
          final customCodes = await customCodesService.getUserCustomCodes();
          allFavorites.addAll(customCodes);
        } catch (e) {
          print('⚠️ Error obteniendo códigos personalizados: $e');
        }
      }
      
      // Obtener favoritos oficiales por etiqueta
      try {
        final officialFavorites = await SupabaseService.getFavoritosPorEtiqueta(_getUserId() ?? '', etiqueta);
        allFavorites.addAll(officialFavorites);
      } catch (e) {
        print('⚠️ Error obteniendo favoritos oficiales: $e');
      }
      
      return allFavorites;
    } catch (e) {
      print('Error obteniendo favoritos por etiqueta: $e');
      return [];
    }
  }

}
