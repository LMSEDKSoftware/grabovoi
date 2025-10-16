import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supabase_models.dart';
import 'supabase_config.dart';

class SupabaseService {
  static final SupabaseClient _client = SupabaseConfig.client;
  static final SupabaseClient _serviceClient = SupabaseConfig.serviceClient;

  // ===== CÓDIGOS GRABOVOI =====
  
  static Future<List<CodigoGrabovoi>> getCodigos() async {
    try {
      print('🔗 Ejecutando query en Supabase...');
      print('📋 Tabla: codigos_grabovoi');
      print('🔍 Select: * (todos los campos)');
      print('📊 Order: nombre');
      
      final response = await _client
          .from('codigos_grabovoi')
          .select()
          .order('nombre');

      print('📡 Respuesta recibida de Supabase');
      print('📊 Cantidad de registros: ${response.length}');
      
      if (response.isNotEmpty) {
        print('📄 Primer registro completo: ${response.first}');
        print('🔍 Campos del primer registro: ${(response.first as Map).keys}');
      } else {
        print('⚠️ ADVERTENCIA: La respuesta está vacía');
        print('🔍 Esto puede indicar:');
        print('   - La tabla está vacía');
        print('   - RLS está bloqueando el acceso');
        print('   - Error en la consulta');
      }

      print('🔄 Iniciando parseo de registros...');
      final codigos = (response as List)
          .map((json) {
            try {
              final codigo = CodigoGrabovoi.fromJson(json);
              print('✅ Parseado: ${codigo.codigo} - ${codigo.nombre}');
              return codigo;
            } catch (e) {
              print('❌ Error parseando registro: $json');
              print('❌ Error específico: $e');
              print('❌ Tipo de dato: ${json.runtimeType}');
              rethrow;
            }
          })
          .toList();
      
      print('✅ Parseo completado: ${codigos.length} códigos procesados');
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
          .order('nombre');

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
          .order('nombre');

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

  static Future<void> agregarFavorito(String userId, String codigoId) async {
    try {
      await _client.from('usuario_favoritos').insert({
        'user_id': userId,
        'codigo_id': codigoId,
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
        // Actualizar registro existente
        await _client
            .from('codigo_popularidad')
            .update({
              'contador': 'contador + 1',
              'ultimo_uso': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('codigo_id', codigoId);
      } else {
        // Crear nuevo registro usando service client para evitar RLS
        await _serviceClient.from('codigo_popularidad').insert({
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
      final response = await _client.storage
          .from('audios')
          .getPublicUrl(archivo);
      
      return response;
    } catch (e) {
      throw Exception('Error al obtener URL del audio: $e');
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
    if (diasConsecutivos >= 21) nivel += 4;
    else if (diasConsecutivos >= 14) nivel += 3;
    else if (diasConsecutivos >= 7) nivel += 2;
    else if (diasConsecutivos >= 3) nivel += 1;
    
    // Por total de pilotajes
    if (totalPilotajes >= 100) nivel += 3;
    else if (totalPilotajes >= 50) nivel += 2;
    else if (totalPilotajes >= 20) nivel += 1;
    else if (totalPilotajes >= 5) nivel += 1;
    
    // Nivel mínimo de 3 para usuarios activos
    if (diasConsecutivos > 0 || totalPilotajes > 0) {
      nivel = nivel.clamp(3, 10);
    }
    
    return nivel.clamp(1, 10);
  }

  // ===== MIGRACIÓN DE DATOS =====
  
  static Future<void> migrarCodigosDesdeJson(List<Map<String, dynamic>> codigos) async {
    try {
      for (final codigoData in codigos) {
        final categoria = codigoData['categoria'] ?? 'General';
        final items = codigoData['items'] as List<dynamic>;
        
        for (final item in items) {
          await _serviceClient.from('codigos_grabovoi').upsert({
            'codigo': item['codigo'],
            'nombre': item['descripcion'],
            'descripcion': item['descripcion'],
            'categoria': categoria,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      throw Exception('Error al migrar códigos: $e');
    }
  }

  static Future<CodigoGrabovoi> crearCodigo(CodigoGrabovoi codigo) async {
    try {
      final response = await _serviceClient
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

      return CodigoGrabovoi.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear código: $e');
    }
  }
}
