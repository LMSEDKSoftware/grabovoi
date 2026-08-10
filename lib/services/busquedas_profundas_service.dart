import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/busqueda_profunda_model.dart';
import '../config/supabase_config.dart';

class BusquedasProfundasService {
  static final SupabaseClient _client = SupabaseConfig.client;

  // Guardar una nueva búsqueda profunda
  static Future<int> guardarBusquedaProfunda(BusquedaProfunda busqueda) async {
    try {
      print('💾 Guardando búsqueda profunda: ${busqueda.codigoBuscado}');

      final response = await _client
          .from('busquedas_profundas')
          .insert(busqueda.toJson())
          .select('id')
          .single();

      final id = response['id'] as int;
      print('✅ Búsqueda profunda guardada con ID: $id');
      return id;
    } catch (e) {
      print('❌ Error al guardar búsqueda profunda: $e');
      rethrow;
    }
  }

  // Actualizar una búsqueda existente (solo la propia, RLS lo garantiza)
  static Future<void> actualizarBusquedaProfunda(int id, BusquedaProfunda busqueda) async {
    try {
      print('🔄 Actualizando búsqueda profunda ID: $id');

      await _client
          .from('busquedas_profundas')
          .update(busqueda.toJson())
          .eq('id', id);

      print('✅ Búsqueda profunda actualizada');
    } catch (e) {
      print('❌ Error al actualizar búsqueda profunda: $e');
      rethrow;
    }
  }

  // Obtener búsquedas de un usuario específico (RLS solo permite ver las propias)
  static Future<List<BusquedaProfunda>> getBusquedasPorUsuario(String usuarioId) async {
    try {
      print('🔍 Obteniendo búsquedas del usuario: $usuarioId');

      final response = await _client
          .from('busquedas_profundas')
          .select('*')
          .eq('usuario_id', usuarioId)
          .order('fecha_busqueda', ascending: false);

      final busquedas = response.map((json) => BusquedaProfunda.fromJson(json)).toList();
      print('✅ Se encontraron ${busquedas.length} búsquedas del usuario');
      return busquedas;
    } catch (e) {
      print('❌ Error al obtener búsquedas del usuario: $e');
      return [];
    }
  }
}
