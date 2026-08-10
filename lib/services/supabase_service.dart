import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/supabase_models.dart';
import '../config/supabase_config.dart';
import 'cache_service.dart';

// Función helper para obtener el usuario actual
String? _getCurrentUserId() {
  try {
    return Supabase.instance.client.auth.currentUser?.id;
  } catch (e) {
    print('⚠️ No se pudo obtener el ID del usuario actual: $e');
    return null;
  }
}

class SupabaseService {
  static final SupabaseClient _client = SupabaseConfig.client;

  // Getter público para acceder al cliente
  static SupabaseClient get client => _client;

  // ===== CÓDIGOS GRABOVOI =====

  // Verificar si un código ya existe en la base de datos
  static Future<bool> codigoExiste(String codigo) async {
    try {
      final response = await _client
          .from('codigos_grabovoi')
          .select('codigo')
          .eq('codigo', codigo)
          .limit(1);
      
      return response.isNotEmpty;
    } catch (e) {
      print('❌ Error verificando existencia del código: $e');
      return false;
    }
  }

  static String _getCategoryColor(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'salud':
        return '#32CD32'; // Verde
      case 'abundancia':
        return '#FFD700'; // Dorado
      case 'amor':
        return '#FF69B4'; // Rosa
      case 'reprogramacion':
        return '#9370DB'; // Violeta
      case 'manifestacion':
        return '#FF8C00'; // Naranja
      default:
        return '#FFD700'; // Dorado por defecto
    }
  }
  
  /// Tamaño de página para paginación (Supabase/PostgREST devuelve máx 1000 por defecto)
  static const int _getCodigosPageSize = 1000;

  static Future<List<CodigoGrabovoi>> getCodigos() async {
    try {
      print('🔗 Ejecutando query en Supabase (paginado para >1000 registros)...');
      final List<CodigoGrabovoi> codigos = [];
      int offset = 0;
      bool hasMore = true;

      while (hasMore) {
        final end = offset + _getCodigosPageSize - 1;
        final response = await _client
            .from('codigos_grabovoi')
            .select()
            .order('nombre', ascending: true)
            .range(offset, end);

        final list = response as List;
        if (list.isEmpty) break;

        for (final json in list) {
          try {
            codigos.add(CodigoGrabovoi.fromJson(json));
          } catch (e) {
            print('❌ Error parseando registro: $e');
            rethrow;
          }
        }
        print('📊 Página: ${offset + 1}-${offset + list.length} (total acumulado: ${codigos.length})');
        if (list.length < _getCodigosPageSize) {
          hasMore = false;
        } else {
          offset += _getCodigosPageSize;
        }
      }

      print('✅ getCodigos completado: ${codigos.length} secuencias');
      return codigos;
    } catch (e) {
      print('💥 ERROR CRÍTICO en SupabaseService.getCodigos():');
      print('   Exception type: ${e.runtimeType}');
      print('   Exception message: $e');
      print('   Exception toString: ${e.toString()}');
      
      // Información adicional sobre el tipo de error
      if (e.toString().contains('PostgrestException')) {
        print('🗄️ DIAGNÓSTICO: Error de PostgreSQL/Supabase');
      } else if (e.toString().contains('SocketException')) {
        print('🌐 DIAGNÓSTICO: Error de red/conectividad');
      } else if (e.toString().contains('TimeoutException')) {
        print('⏰ DIAGNÓSTICO: Timeout en la conexión');
      } else if (e.toString().contains('FormatException')) {
        print('📝 DIAGNÓSTICO: Error de formato en los datos');
      }
      
      throw Exception('Error al obtener códigos: $e');
    }
  }

  static Future<List<CodigoGrabovoi>> getCodigosPorCategoria(String categoria) async {
    try {
      final response = await _client
          .from('codigos_grabovoi')
          .select()
          .eq('categoria', categoria)
          .order('nombre', ascending: true);

      return (response as List)
          .map((json) => CodigoGrabovoi.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener códigos por categoría: $e');
    }
  }

  static Future<List<CodigoGrabovoi>> buscarCodigos(String query) async {
    try {
      final response = await _client
          .from('codigos_grabovoi')
          .select()
          .or('nombre.ilike.%$query%,descripcion.ilike.%$query%,codigo.ilike.%$query%')
          .order('nombre', ascending: true);

      return (response as List)
          .map((json) => CodigoGrabovoi.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar códigos: $e');
    }
  }

  static Future<CodigoGrabovoi?> getCodigoPorId(String codigoId) async {
    try {
      final response = await _client
          .from('codigos_grabovoi')
          .select()
          .eq('codigo', codigoId)
          .single();

      return CodigoGrabovoi.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Obtener información completa de un código existente
  static Future<CodigoGrabovoi?> getCodigoExistente(String codigo) async {
    try {
      // Obtener el primer registro con este código (para compatibilidad)
      final response = await _client
          .from('codigos_grabovoi')
          .select()
          .eq('codigo', codigo)
          .limit(1);

      if (response.isEmpty) {
        return null;
      }

      return CodigoGrabovoi.fromJson(response[0]);
    } catch (e) {
      print('❌ Error obteniendo código existente $codigo: $e');
      return null;
    }
  }

  // Obtener todos los registros con el mismo código (múltiples títulos)
  // NOTA: Este método ya no se usa, ahora usamos getTitulosRelacionados()
  // Se mantiene por compatibilidad pero devuelve solo el código principal
  static Future<List<CodigoGrabovoi>> getTodosLosTitulosCodigo(String codigo) async {
    try {
      final response = await _client
          .from('codigos_grabovoi')
          .select()
          .eq('codigo', codigo)
          .limit(1); // Solo el primero porque el código es UNIQUE

      return (response as List)
          .map((json) => CodigoGrabovoi.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo código $codigo: $e');
      return [];
    }
  }
  
  // Obtener código principal y todos sus títulos relacionados
  static Future<Map<String, dynamic>> getCodigoConTitulosRelacionados(String codigo) async {
    try {
      // Obtener código principal
      final codigoPrincipal = await getCodigoExistente(codigo);
      
      // Obtener títulos relacionados
      final titulosRelacionados = await getTitulosRelacionados(codigo);
      
      return {
        'codigoPrincipal': codigoPrincipal,
        'titulosRelacionados': titulosRelacionados,
      };
    } catch (e) {
      print('❌ Error obteniendo código con títulos relacionados: $e');
      return {
        'codigoPrincipal': null,
        'titulosRelacionados': <Map<String, dynamic>>[],
      };
    }
  }

  // Verificar si un código existe (puede tener múltiples registros)
  static Future<bool> codigoExisteConTitulo(String codigo, String titulo) async {
    try {
      final response = await _client
          .from('codigos_grabovoi')
          .select('codigo')
          .eq('codigo', codigo)
          .eq('nombre', titulo)
          .limit(1);
      
      return response.isNotEmpty;
    } catch (e) {
      print('❌ Error verificando existencia del código con título: $e');
      return false;
    }
  }

  // ===== TÍTULOS RELACIONADOS =====
  
  // Agregar un título relacionado a un código
  static Future<String> agregarTituloRelacionado({
    required String codigoExistente,
    required String titulo,
    String? descripcion,
    String? categoria,
    String fuente = 'sugerencia_aprobada',
    int? sugerenciaId,
    String? usuarioId,
  }) async {
    try {
      print('💾 Agregando título relacionado: $titulo para código $codigoExistente');

      // Operación admin: se ejecuta server-side en la edge function admin-users
      // (valida es_admin() antes de insertar con el service role).
      final response = await _client.functions.invoke('admin-users', body: {
        'action': 'add_titulo_relacionado',
        'codigoExistente': codigoExistente,
        'titulo': titulo,
        'descripcion': descripcion,
        'categoria': categoria,
        'fuente': fuente,
        'sugerenciaId': sugerenciaId,
        'usuarioId': usuarioId,
      });
      if (response.status != 200) {
        final error = (response.data is Map) ? response.data['error'] : response.data;
        throw Exception(error?.toString() ?? 'Error agregando título relacionado');
      }

      final id = response.data['id'] as String;
      print('✅ Título relacionado agregado con ID: $id');
      return id;
    } catch (e) {
      print('❌ Error al agregar título relacionado: $e');
      rethrow;
    }
  }

  // Obtener todos los títulos relacionados de un código
  // NOTA: Para múltiples códigos, usar CacheService.getTitulosRelacionadosBatch()
  static Future<List<Map<String, dynamic>>> getTitulosRelacionados(String codigo) async {
    try {
      // Usar caché si está disponible
      final cacheService = CacheService();
      final batchResult = await cacheService.getTitulosRelacionadosBatch([codigo]);
      return batchResult[codigo] ?? [];
    } catch (e) {
      print('❌ Error obteniendo títulos relacionados: $e');
      return [];
    }
  }
  
  // Obtener títulos relacionados para múltiples códigos en batch (optimizado)
  static Future<Map<String, List<Map<String, dynamic>>>> getTitulosRelacionadosBatch(
    List<String> codigos,
  ) async {
    final cacheService = CacheService();
    return await cacheService.getTitulosRelacionadosBatch(codigos);
  }

  // Buscar códigos por título (incluyendo títulos relacionados)
  static Future<List<CodigoGrabovoi>> buscarCodigosPorTitulo(String terminoBusqueda) async {
    try {
      print('🔍 [BUSCAR_CODIGOS_POR_TITULO] Buscando: "$terminoBusqueda"');
      final terminoLower = terminoBusqueda.toLowerCase();
      final terminoPattern = '%$terminoLower%';
      
      // Buscar en codigos_grabovoi
      final responseCodigos = await _client
          .from('codigos_grabovoi')
          .select()
          .or('nombre.ilike.$terminoPattern,descripcion.ilike.$terminoPattern')
          .limit(100);

      print('🔍 [BUSCAR_CODIGOS_POR_TITULO] Códigos encontrados en tabla principal: ${responseCodigos.length}');

      // Buscar en títulos relacionados
      final responseTitulos = await _client
          .from('codigos_titulos_relacionados')
          .select('codigo_existente, titulo, descripcion')
          .or('titulo.ilike.$terminoPattern,descripcion.ilike.$terminoPattern')
          .limit(100);

      print('🔍 [BUSCAR_CODIGOS_POR_TITULO] Títulos relacionados encontrados: ${responseTitulos.length}');
      if (responseTitulos.isNotEmpty) {
        print('🔍 [BUSCAR_CODIGOS_POR_TITULO] Títulos relacionados: ${responseTitulos.map((t) => t['titulo']).toList()}');
      }

      // Obtener códigos únicos de ambos resultados
      final codigosEncontrados = <String>{};
      
      // Agregar códigos de la búsqueda principal
      for (var codigo in responseCodigos) {
        codigosEncontrados.add(codigo['codigo'] as String);
      }
      
      // Agregar códigos de títulos relacionados
      for (var titulo in responseTitulos) {
        codigosEncontrados.add(titulo['codigo_existente'] as String);
      }

      print('🔍 [BUSCAR_CODIGOS_POR_TITULO] Códigos únicos encontrados: ${codigosEncontrados.length}');
      print('🔍 [BUSCAR_CODIGOS_POR_TITULO] Códigos: ${codigosEncontrados.toList()}');

      // Obtener los códigos completos
      if (codigosEncontrados.isEmpty) {
        print('⚠️ [BUSCAR_CODIGOS_POR_TITULO] No se encontraron códigos');
        return [];
      }

      final codigosList = codigosEncontrados.toList();
      final response = await _client
          .from('codigos_grabovoi')
          .select()
          .inFilter('codigo', codigosList)
          .order('nombre', ascending: true);

      final resultado = (response as List)
          .map((json) => CodigoGrabovoi.fromJson(json))
          .toList();

      print('✅ [BUSCAR_CODIGOS_POR_TITULO] Resultado final: ${resultado.length} códigos');
      return resultado;
    } catch (e) {
      print('❌ Error buscando códigos por título: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Indica si la consulta sugiere deporte/actividad física (para enriquecer candidatos Fase 2).
  static bool _querySugiereDeporteActividad(String q) {
    if (q.isEmpty) return false;
    final lower = q.toLowerCase().trim();
    const terminos = [
      'futbol', 'fútbol', 'deporte', 'deportes', 'sport', 'soccer', 'correr', 'running',
      'ejercicio', 'gimnasio', 'actividad fisica', 'actividad física', 'aire libre',
      'atletismo', 'natacion', 'natación', 'bici', 'ciclismo', 'fitness', 'entrenar',
    ];
    return terminos.any((t) => lower.contains(t));
  }

  /// Candidatos para fallback Fase 2 (relacionados desde catálogo local).
  /// - Query texto: top N por ILIKE; si sugiere deporte/actividad, también busca por rendimiento/vitalidad/recuperación; si faltan, generales.
  /// - Query numérica con texto: ILIKE por parte textual; si faltan, generales.
  /// - Query numérica sin texto: generales desde BD.
  static Future<List<CodigoGrabovoi>> getCandidatosParaFallbackRelacionados({
    required String userQueryText,
    required bool isNumericQuery,
    String? exactCode,
    int maxCandidatos = 20,
  }) async {
    try {
      List<CodigoGrabovoi> todos = [];
      if (!isNumericQuery) {
        final list = await buscarCodigosPorTitulo(userQueryText);
        todos = list.take(maxCandidatos).toList();
        // Si la búsqueda sugiere deporte/actividad y hay pocos resultados, enriquecer con términos relacionados
        if (todos.length < maxCandidatos && _querySugiereDeporteActividad(userQueryText)) {
          for (final keyword in ['rendimiento', 'vitalidad', 'recuperación', 'lesión', 'energía', 'físico', 'muscular']) {
            if (todos.length >= maxCandidatos) break;
            final extra = await buscarCodigosPorTitulo(keyword);
            for (final c in extra) {
              if (todos.length >= maxCandidatos) break;
              if (!todos.any((e) => e.codigo == c.codigo)) todos.add(c);
            }
          }
        }
      } else {
        final textPart = userQueryText
            .replaceAll(RegExp(r'[0-9_\s]+'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (textPart.isNotEmpty) {
          final list = await buscarCodigosPorTitulo(textPart);
          todos = list.take(maxCandidatos).toList();
          if (todos.length < maxCandidatos && _querySugiereDeporteActividad(textPart)) {
            for (final keyword in ['rendimiento', 'vitalidad', 'recuperación', 'lesión', 'energía']) {
              if (todos.length >= maxCandidatos) break;
              final extra = await buscarCodigosPorTitulo(keyword);
              for (final c in extra) {
                if (todos.length >= maxCandidatos) break;
                if (!todos.any((e) => e.codigo == c.codigo)) todos.add(c);
              }
            }
          }
        }
      }
      // Si no hay suficientes candidatos (ej. "futbol" devuelve 0), rellenar con generales
      // de forma DIVERSIFICADA: tomar por igual de cada categoría para que el LLM tenga
      // opciones temáticamente variadas (vitalidad, rendimiento, recuperación, etc.).
      if (todos.length < maxCandidatos) {
        final categorias = ['Crecimiento personal', 'Salud', 'Energía y vitalidad', 'Otros'];
        final porCategoria = (maxCandidatos / 4).ceil();
        for (final cat in categorias) {
          if (todos.length >= maxCandidatos) break;
          final list = await getCodigosPorCategoria(cat);
          for (final c in list.take(porCategoria)) {
            if (todos.length >= maxCandidatos) break;
            if (!todos.any((e) => e.codigo == c.codigo)) todos.add(c);
          }
        }
        if (todos.length < maxCandidatos) {
          final rest = await getCodigos();
          for (final c in rest) {
            if (todos.length >= maxCandidatos) break;
            if (!todos.any((e) => e.codigo == c.codigo)) todos.add(c);
          }
        }
      }
      return todos.take(maxCandidatos).toList();
    } catch (e) {
      print('❌ Error getCandidatosParaFallbackRelacionados: $e');
      return [];
    }
  }

  // ===== FAVORITOS =====
  
  static Future<List<CodigoGrabovoi>> getFavoritos(String userId) async {
    try {
      final response = await _client
          .from('usuario_favoritos')
          .select('''
            codigo_id,
            codigos_grabovoi (
              id, codigo, nombre, descripcion, categoria, created_at, updated_at
            )
          ''')
          .eq('user_id', userId);

      return (response as List)
          .map((json) => CodigoGrabovoi.fromJson(json['codigos_grabovoi']))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener favoritos: $e');
    }
  }

  static Future<void> agregarFavorito(String userId, String codigoId, {String etiqueta = 'Favorito'}) async {
    try {
      await _client.from('usuario_favoritos').insert({
        'user_id': userId,
        'codigo_id': codigoId,
        'etiqueta': etiqueta,
      });
    } catch (e) {
      throw Exception('Error al agregar favorito: $e');
    }
  }

  static Future<void> quitarFavorito(String userId, String codigoId) async {
    try {
      await _client
          .from('usuario_favoritos')
          .delete()
          .eq('user_id', userId)
          .eq('codigo_id', codigoId);
    } catch (e) {
      throw Exception('Error al quitar favorito: $e');
    }
  }

  static Future<bool> esFavorito(String userId, String codigoId) async {
    try {
      final response = await _client
          .from('usuario_favoritos')
          .select()
          .eq('user_id', userId)
          .eq('codigo_id', codigoId);

      return (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<List<UsuarioFavorito>> getFavoritosConEtiquetas(String userId) async {
    try {
      final response = await _client
          .from('usuario_favoritos')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.map((json) => UsuarioFavorito.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener favoritos con etiquetas: $e');
    }
  }

  static Future<List<String>> getEtiquetasFavoritos(String userId) async {
    try {
      final response = await _client
          .from('usuario_favoritos')
          .select('etiqueta')
          .eq('user_id', userId);

      return response
          .map((json) => json['etiqueta'] as String)
          .toSet()
          .toList()
          ..sort();
    } catch (e) {
      throw Exception('Error al obtener etiquetas de favoritos: $e');
    }
  }

  static Future<List<CodigoGrabovoi>> getFavoritosPorEtiqueta(String userId, String etiqueta) async {
    try {
      final response = await _client
          .from('usuario_favoritos')
          .select('''
            codigos_grabovoi (
              codigo,
              nombre,
              descripcion,
              categoria,
              color
            )
          ''')
          .eq('user_id', userId)
          .eq('etiqueta', etiqueta);

      return (response as List)
          .map((json) => CodigoGrabovoi.fromJson(json['codigos_grabovoi']))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener favoritos por etiqueta: $e');
    }
  }

  // ===== POPULARIDAD =====
  
  static Future<List<CodigoPopularidad>> getPopularidad() async {
    try {
      final response = await _client
          .from('codigo_popularidad')
          .select('''
            *,
            codigos_grabovoi (
              id, codigo, nombre, descripcion, categoria
            )
          ''')
          .order('contador', ascending: false)
          .limit(10);

      return (response as List)
          .map((json) => CodigoPopularidad.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener popularidad: $e');
    }
  }

  static Future<void> incrementarPopularidad(String codigoId) async {
    try {
      // Verificar si existe el registro
      final existing = await _client
          .from('codigo_popularidad')
          .select()
          .eq('codigo_id', codigoId)
          .maybeSingle();

      if (existing != null) {
        // Actualizar registro existente (incremento numérico; el cliente no acepta expresiones SQL)
        final contadorActual = (existing['contador'] as num?)?.toInt() ?? 0;
        await _client
            .from('codigo_popularidad')
            .update({
              'contador': contadorActual + 1,
              'ultimo_uso': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('codigo_id', codigoId);
      } else {
        // RLS: "Authenticated users can insert popularidad" (database/migration_client_write_policies.sql)
        await _client.from('codigo_popularidad').insert({
          'codigo_id': codigoId,
          'contador': 1,
          'ultimo_uso': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      // Si falla, simplemente no incrementamos la popularidad
      print('Warning: No se pudo incrementar popularidad: $e');
      // No lanzamos excepción para no interrumpir la funcionalidad
    }
  }

  // ===== AUDIOS =====
  
  static Future<List<AudioFile>> getAudios() async {
    try {
      final response = await _client
          .from('audio_files')
          .select()
          .order('nombre');

      return (response as List)
          .map((json) => AudioFile.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener audios: $e');
    }
  }

  static Future<String> getAudioUrl(String archivo) async {
    try {
      final response = _client.storage
          .from('audios')
          .getPublicUrl(archivo);
      
      return response;
    } catch (e) {
      throw Exception('Error al obtener URL del audio: $e');
    }
  }

  // ===== AVATARES =====
  
  /// Sube un avatar al bucket 'images' y retorna la URL pública
  static Future<String> uploadAvatar(String userId, XFile imageFile) async {
    try {
      // Usar una ruta específica del usuario para evitar problemas de RLS
      // La estructura avatars/{userId}/avatar.jpg permite políticas RLS más específicas
      final filePath = 'avatars/$userId/avatar.jpg';
      
      // Crear un archivo temporal y convertir XFile a File
      final file = File(imageFile.path);
      
      // Subir al bucket 'images' con la ruta específica del usuario
      await _client.storage
          .from('images')
          .upload(filePath, file, fileOptions: const FileOptions(
            upsert: true, // Sobrescribir si existe
            contentType: 'image/jpeg',
          ));
      
      // Obtener URL pública
      final url = _client.storage
          .from('images')
          .getPublicUrl(filePath);
      
      print('✅ Avatar subido exitosamente: $url');
      return url;
    } catch (e) {
      print('❌ Error subiendo avatar: $e');
      throw Exception('Error al subir avatar: $e');
    }
  }
  
  /// Obtiene la URL pública del avatar de un usuario
  static String? getAvatarUrl(String? avatarFileName) {
    if (avatarFileName == null || avatarFileName.isEmpty) return null;
    
    try {
      // Si ya es una URL completa, retornarla
      if (avatarFileName.startsWith('http')) {
        return avatarFileName;
      }
      
      // Si es solo el nombre del archivo (formato antiguo: avatar_userId.jpg),
      // intentar construir la URL con el formato antiguo primero
      // Si no funciona, intentar con el nuevo formato (avatars/userId/avatar.jpg)
      if (avatarFileName.startsWith('avatar_')) {
        // Formato antiguo: avatar_userId.jpg
        return _client.storage
            .from('images')
            .getPublicUrl(avatarFileName);
      } else if (avatarFileName.contains('/')) {
        // Ya es una ruta completa (avatars/userId/avatar.jpg)
        return _client.storage
            .from('images')
            .getPublicUrl(avatarFileName);
      } else {
        // Intentar extraer userId del nombre del archivo si es formato antiguo
        // o construir con el nuevo formato si tenemos el userId
        return _client.storage
            .from('images')
            .getPublicUrl(avatarFileName);
      }
    } catch (e) {
      print('⚠️ Error obteniendo URL del avatar: $e');
      return null;
    }
  }

  // ===== PROGRESO DE USUARIO =====
  
  static Future<UsuarioProgreso?> getProgresoUsuario(String userId) async {
    try {
      final response = await _client
          .from('usuario_progreso')
          .select()
          .eq('user_id', userId)
          .single();

      return UsuarioProgreso.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  static Future<void> actualizarProgresoUsuario(
    String userId, {
    int? diasConsecutivos,
    int? totalPilotajes,
    int? nivelEnergetico,
  }) async {
    try {
      final data = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (diasConsecutivos != null) data['dias_consecutivos'] = diasConsecutivos;
      if (totalPilotajes != null) data['total_pilotajes'] = totalPilotajes;
      if (nivelEnergetico != null) data['nivel_energetico'] = nivelEnergetico;

      await _client
          .from('usuario_progreso')
          .update(data)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Error al actualizar progreso: $e');
    }
  }

  static Future<void> registrarPilotaje(String userId) async {
    try {
      final ahora = DateTime.now();
      
      // Obtener progreso actual
      final progreso = await getProgresoUsuario(userId);
      
      if (progreso != null) {
        // Calcular días consecutivos
        final ultimoPilotaje = progreso.ultimoPilotaje;
        final diasDiferencia = ahora.difference(ultimoPilotaje).inDays;
        
        int nuevosDiasConsecutivos = diasDiferencia == 1 
            ? progreso.diasConsecutivos + 1 
            : 1;
        
        // Actualizar progreso
        await actualizarProgresoUsuario(
          userId,
          diasConsecutivos: nuevosDiasConsecutivos,
          totalPilotajes: progreso.totalPilotajes + 1,
          nivelEnergetico: _calcularNivelEnergetico(nuevosDiasConsecutivos, progreso.totalPilotajes + 1),
        );
      } else {
        // Crear nuevo progreso
        await _client.from('usuario_progreso').insert({
          'user_id': userId,
          'dias_consecutivos': 1,
          'total_pilotajes': 1,
          'nivel_energetico': 1,
          'ultimo_pilotaje': ahora.toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception('Error al registrar pilotaje: $e');
    }
  }

  static int _calcularNivelEnergetico(int diasConsecutivos, int totalPilotajes) {
    int nivel = 1;
    
    // Por días consecutivos
    if (diasConsecutivos >= 21) {
      nivel += 4;
    } else if (diasConsecutivos >= 14) nivel += 3;
    else if (diasConsecutivos >= 7) nivel += 2;
    else if (diasConsecutivos >= 3) nivel += 1;
    
    // Por total de pilotajes
    if (totalPilotajes >= 100) {
      nivel += 3;
    } else if (totalPilotajes >= 50) nivel += 2;
    else if (totalPilotajes >= 20) nivel += 1;
    else if (totalPilotajes >= 5) nivel += 1;
    
    // Nivel mínimo de 3 para usuarios activos
    if (diasConsecutivos > 0 || totalPilotajes > 0) {
      nivel = nivel.clamp(3, 10);
    }
    
    return nivel.clamp(1, 10);
  }

  // RLS: "Authenticated users can insert codigos" (database/migration_client_write_policies.sql)
  static Future<CodigoGrabovoi> crearCodigo(CodigoGrabovoi codigo) async {
    try {
      print('💾 Creando código: ${codigo.codigo}');
      final response = await _client
          .from('codigos_grabovoi')
          .insert({
            'codigo': codigo.codigo,
            'nombre': codigo.nombre,
            'descripcion': codigo.descripcion,
            'categoria': codigo.categoria,
            'color': codigo.color,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      print('✅ Código creado exitosamente: ${codigo.codigo}');
      return CodigoGrabovoi.fromJson(response);
    } catch (e) {
      print('❌ Error al crear código: $e');
      throw Exception('Error al crear código: $e');
    }
  }

  // ===== USUARIO ACTUAL =====
  
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      
      // Obtener datos completos del usuario desde la tabla users
      final response = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();
      
      return response;
    } catch (e) {
      print('Error obteniendo usuario actual: $e');
      return null;
    }
  }

  // ===== REPORTES DE CÓDIGOS =====
  
  /// Guarda un reporte de código en la base de datos
  /// Requiere: usuario_id, email, codigo_id, tipo_reporte
  static Future<void> guardarReporteCodigo({
    required String usuarioId,
    required String email,
    required String codigoId,
    required String tipoReporte,
  }) async {
    try {
      print('📝 Guardando reporte de código:');
      print('  Usuario: $usuarioId');
      print('  Email: $email');
      print('  Código: $codigoId');
      print('  Tipo: $tipoReporte');
      
      await _client.from('reportes_codigos').insert({
        'usuario_id': usuarioId,
        'email': email,
        'codigo_id': codigoId,
        'tipo_reporte': tipoReporte,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      print('✅ Reporte guardado exitosamente');
    } catch (e) {
      print('❌ Error guardando reporte: $e');
      throw Exception('Error al guardar el reporte: $e');
    }
  }

  /// Obtiene todos los reportes de códigos (solo para administradores)
  /// Opcionalmente filtra por tipo de reporte
  static Future<List<Map<String, dynamic>>> getReportesCodigos({String? tipoReporte}) async {
    try {
      print('📊 Obteniendo reportes de códigos...');
      print('🔍 Filtro: ${tipoReporte ?? "todos"}');
      
      // RLS: "Los administradores pueden ver todos los reportes" (es_admin(), sin recursión)
      if (tipoReporte != null && tipoReporte != 'todos') {
        final response = await _client
            .from('reportes_codigos')
            .select()
            .eq('tipo_reporte', tipoReporte)
            .order('created_at', ascending: false);
        final reportes = (response as List).map((e) => Map<String, dynamic>.from(e)).toList();
        print('✅ Reportes obtenidos: ${reportes.length}');
        return reportes;
      } else {
        final response = await _client
            .from('reportes_codigos')
            .select()
            .order('created_at', ascending: false);
        final reportes = (response as List).map((e) => Map<String, dynamic>.from(e)).toList();
        print('✅ Reportes obtenidos: ${reportes.length}');
        return reportes;
      }
    } catch (e) {
      print('❌ Error obteniendo reportes: $e');
      throw Exception('Error al obtener reportes: $e');
    }
  }

  /// Actualiza el estatus de un reporte de código
  /// Requiere: reporteId, nuevoEstatus
  /// Los estatus válidos son: pendiente, revisado, aceptado, rechazado, resuelto
  static Future<void> actualizarEstatusReporte({
    required String reporteId,
    required String nuevoEstatus,
  }) async {
    try {
      print('📝 Actualizando estatus del reporte:');
      print('  Reporte ID: $reporteId');
      print('  Nuevo estatus: $nuevoEstatus');

      // Validar estatus
      final estatusValidos = ['pendiente', 'revisado', 'aceptado', 'rechazado', 'resuelto'];
      if (!estatusValidos.contains(nuevoEstatus)) {
        throw Exception('Estatus inválido: $nuevoEstatus');
      }

      // RLS: "Los administradores pueden actualizar todos los reportes" (es_admin())
      await _client
          .from('reportes_codigos')
          .update({'estatus': nuevoEstatus})
          .eq('id', reporteId);

      print('✅ Estatus del reporte actualizado exitosamente');
    } catch (e) {
      print('❌ Error actualizando estatus del reporte: $e');
      throw Exception('Error al actualizar el estatus del reporte: $e');
    }
  }

}
