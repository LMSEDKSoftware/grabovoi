import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sugerencia_codigo_model.dart';
import '../config/supabase_config.dart';

class SugerenciasCodigosService {
  static final SupabaseClient _client = SupabaseConfig.client;
  static final SupabaseClient _serviceClient = SupabaseConfig.serviceClient;

  // Crear una nueva sugerencia
  static Future<int> crearSugerencia(SugerenciaCodigo sugerencia) async {
    try {
      print('💾 Creando sugerencia para código: ${sugerencia.codigoExistente}');
      
      final response = await _serviceClient
          .from('sugerencias_codigos')
          .insert(sugerencia.toJson())
          .select('id')
          .single();
      
      final id = response['id'] as int;
      print('✅ Sugerencia creada con ID: $id');
      return id;
    } catch (e) {
      print('❌ Error al crear sugerencia: $e');
      rethrow;
    }
  }

  // Actualizar estado de una sugerencia
  static Future<void> actualizarEstadoSugerencia(int id, String nuevoEstado, {String? comentario}) async {
    try {
      print('🔄 Actualizando sugerencia ID: $id a estado: $nuevoEstado');
      
      final updateData = {
        'estado': nuevoEstado,
        'fecha_resolucion': DateTime.now().toIso8601String(),
      };
      
      if (comentario != null) {
        updateData['comentario_admin'] = comentario;
      }
      
      await _serviceClient
          .from('sugerencias_codigos')
          .update(updateData)
          .eq('id', id);
      
      print('✅ Sugerencia actualizada');
    } catch (e) {
      print('❌ Error al actualizar sugerencia: $e');
      rethrow;
    }
  }

  // Obtener sugerencias de un usuario
  static Future<List<SugerenciaCodigo>> getSugerenciasPorUsuario(String usuarioId) async {
    try {
      print('🔍 Obteniendo sugerencias del usuario: $usuarioId');
      
      final response = await _client
          .from('sugerencias_codigos')
          .select('*')
          .eq('usuario_id', usuarioId)
          .order('fecha_sugerencia', ascending: false);
      
      final sugerencias = response.map((json) => SugerenciaCodigo.fromJson(json)).toList();
      print('✅ Se encontraron ${sugerencias.length} sugerencias del usuario');
      return sugerencias;
    } catch (e) {
      print('❌ Error al obtener sugerencias del usuario: $e');
      return [];
    }
  }

  // Obtener sugerencias pendientes (para administradores)
  static Future<List<SugerenciaCodigo>> getSugerenciasPendientes() async {
    try {
      print('🔍 Obteniendo sugerencias pendientes');
      
      final response = await _serviceClient
          .from('sugerencias_codigos')
          .select('*')
          .eq('estado', 'pendiente')
          .order('fecha_sugerencia', ascending: false);
      
      final sugerencias = response.map((json) => SugerenciaCodigo.fromJson(json)).toList();
      print('✅ Se encontraron ${sugerencias.length} sugerencias pendientes');
      return sugerencias;
    } catch (e) {
      print('❌ Error al obtener sugerencias pendientes: $e');
      return [];
    }
  }

  // Obtener sugerencias por código
  static Future<List<SugerenciaCodigo>> getSugerenciasPorCodigo(String codigo) async {
    try {
      print('🔍 Obteniendo sugerencias para código: $codigo');
      
      final response = await _client
          .from('sugerencias_codigos')
          .select('*')
          .eq('codigo_existente', codigo)
          .order('fecha_sugerencia', ascending: false);
      
      final sugerencias = response.map((json) => SugerenciaCodigo.fromJson(json)).toList();
      print('✅ Se encontraron ${sugerencias.length} sugerencias para el código');
      return sugerencias;
    } catch (e) {
      print('❌ Error al obtener sugerencias por código: $e');
      return [];
    }
  }

  // Verificar si ya existe una sugerencia similar (mejorado con control de duplicados)
  static Future<bool> existeSugerenciaSimilar(int busquedaId, String codigo, String temaSugerido, String? usuarioId) async {
    try {
      print('🔍 Verificando si existe sugerencia similar para usuario: $usuarioId');
      
      // Buscar sugerencias pendientes del mismo usuario con el mismo código
      final query = _client
          .from('sugerencias_codigos')
          .select('id')
          .eq('codigo_existente', codigo)
          .eq('estado', 'pendiente');
      
      if (usuarioId != null) {
        query.eq('usuario_id', usuarioId);
      }
      
      final response = await query.limit(1);
      
      final existe = response.isNotEmpty;
      
      if (existe) {
        print('⚠️ Ya existe una sugerencia pendiente para este código');
      } else {
        print('✅ No se encontró sugerencia pendiente similar');
      }
      
      return existe;
    } catch (e) {
      print('❌ Error al verificar sugerencia similar: $e');
      return false;
    }
  }

  // Obtener estadísticas de sugerencias
  static Future<Map<String, dynamic>> getEstadisticasSugerencias() async {
    try {
      print('📊 Obteniendo estadísticas de sugerencias');
      
      final response = await _serviceClient
          .from('sugerencias_codigos')
          .select('estado, fecha_sugerencia');
      
      int totalSugerencias = response.length;
      int pendientes = response.where((r) => r['estado'] == 'pendiente').length;
      int aprobadas = response.where((r) => r['estado'] == 'aprobada').length;
      int rechazadas = response.where((r) => r['estado'] == 'rechazada').length;
      
      final estadisticas = {
        'total_sugerencias': totalSugerencias,
        'pendientes': pendientes,
        'aprobadas': aprobadas,
        'rechazadas': rechazadas,
        'tasa_aprobacion': totalSugerencias > 0 ? (aprobadas / totalSugerencias) * 100 : 0,
      };
      
      print('✅ Estadísticas de sugerencias obtenidas: $estadisticas');
      return estadisticas;
    } catch (e) {
      print('❌ Error al obtener estadísticas de sugerencias: $e');
      return {};
    }
  }
}
