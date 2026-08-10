import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sugerencia_codigo_model.dart';
import '../config/supabase_config.dart';

class SugerenciasCodigosService {
  static final SupabaseClient _client = SupabaseConfig.client;

  // Crear una nueva sugerencia (RLS: auth.uid() = usuario_id)
  static Future<int> crearSugerencia(SugerenciaCodigo sugerencia) async {
    try {
      print('💾 Creando sugerencia para código: ${sugerencia.codigoExistente}');

      final response = await _client
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

  // Actualizar estado de una sugerencia (solo admins, ver migration_admin_rls_sugerencias_codigos.sql)
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

      await _client
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

  // Obtener sugerencias pendientes (solo admins, ver migration_admin_rls_sugerencias_codigos.sql)
  static Future<List<SugerenciaCodigo>> getSugerenciasPendientes() async {
    try {
      print('🔍 Obteniendo sugerencias pendientes');

      final response = await _client
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

  // Verificar si ya existe una sugerencia similar (control de duplicados)
  static Future<bool> existeSugerenciaSimilar(int busquedaId, String codigo, String temaSugerido, String? usuarioId) async {
    try {
      print('🔍 Verificando si existe sugerencia similar para usuario: $usuarioId');

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
}
