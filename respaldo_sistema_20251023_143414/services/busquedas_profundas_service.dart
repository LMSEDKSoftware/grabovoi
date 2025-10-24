import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/busqueda_profunda_model.dart';
import '../config/supabase_config.dart';

class BusquedasProfundasService {
  static final SupabaseClient _client = SupabaseConfig.client;
  static final SupabaseClient _serviceClient = SupabaseConfig.serviceClient;

  // Guardar una nueva búsqueda profunda
  static Future<int> guardarBusquedaProfunda(BusquedaProfunda busqueda) async {
    try {
      print('💾 Guardando búsqueda profunda: ${busqueda.codigoBuscado}');
      
      final response = await _serviceClient
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

  // Actualizar una búsqueda existente
  static Future<void> actualizarBusquedaProfunda(int id, BusquedaProfunda busqueda) async {
    try {
      print('🔄 Actualizando búsqueda profunda ID: $id');
      
      await _serviceClient
          .from('busquedas_profundas')
          .update(busqueda.toJson())
          .eq('id', id);
      
      print('✅ Búsqueda profunda actualizada');
    } catch (e) {
      print('❌ Error al actualizar búsqueda profunda: $e');
      rethrow;
    }
  }

  // Obtener búsquedas de un usuario específico
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

  // Obtener todas las búsquedas (solo para administradores)
  static Future<List<BusquedaProfunda>> getAllBusquedas() async {
    try {
      print('🔍 Obteniendo todas las búsquedas profundas');
      
      final response = await _serviceClient
          .from('busquedas_profundas')
          .select('*')
          .order('fecha_busqueda', ascending: false);
      
      final busquedas = response.map((json) => BusquedaProfunda.fromJson(json)).toList();
      print('✅ Se encontraron ${busquedas.length} búsquedas totales');
      return busquedas;
    } catch (e) {
      print('❌ Error al obtener todas las búsquedas: $e');
      return [];
    }
  }

  // Obtener estadísticas de búsquedas
  static Future<Map<String, dynamic>> getEstadisticas() async {
    try {
      print('📊 Obteniendo estadísticas de búsquedas');
      
      final response = await _serviceClient
          .from('busquedas_profundas')
          .select('codigo_encontrado, codigo_guardado, duracion_ms, tokens_usados, costo_estimado');
      
      int totalBusquedas = response.length;
      int codigosEncontrados = response.where((r) => r['codigo_encontrado'] == true).length;
      int codigosGuardados = response.where((r) => r['codigo_guardado'] == true).length;
      
      double duracionPromedio = 0;
      int tokensTotales = 0;
      double costoTotal = 0;
      
      if (totalBusquedas > 0) {
        duracionPromedio = response
            .where((r) => r['duracion_ms'] != null)
            .map((r) => r['duracion_ms'] as int)
            .reduce((a, b) => a + b) / totalBusquedas;
        
        tokensTotales = response
            .where((r) => r['tokens_usados'] != null)
            .map((r) => r['tokens_usados'] as int)
            .fold(0, (a, b) => a + b);
        
        costoTotal = response
            .where((r) => r['costo_estimado'] != null)
            .map((r) => (r['costo_estimado'] as num).toDouble())
            .fold(0.0, (a, b) => a + b);
      }
      
      final estadisticas = {
        'total_busquedas': totalBusquedas,
        'codigos_encontrados': codigosEncontrados,
        'codigos_guardados': codigosGuardados,
        'tasa_exito': totalBusquedas > 0 ? (codigosEncontrados / totalBusquedas) * 100 : 0,
        'tasa_guardado': totalBusquedas > 0 ? (codigosGuardados / totalBusquedas) * 100 : 0,
        'duracion_promedio_ms': duracionPromedio,
        'tokens_totales': tokensTotales,
        'costo_total': costoTotal,
      };
      
      print('✅ Estadísticas obtenidas: $estadisticas');
      return estadisticas;
    } catch (e) {
      print('❌ Error al obtener estadísticas: $e');
      return {};
    }
  }

  // Obtener códigos más buscados
  static Future<List<Map<String, dynamic>>> getCodigosMasBuscados({int limit = 10}) async {
    try {
      print('🔍 Obteniendo códigos más buscados');
      
      final response = await _serviceClient
          .from('busquedas_profundas')
          .select('codigo_buscado')
          .order('fecha_busqueda', ascending: false)
          .limit(1000); // Obtener más datos para hacer el conteo
      
      // Contar frecuencias
      Map<String, int> frecuencias = {};
      for (var busqueda in response) {
        final codigo = busqueda['codigo_buscado'] as String;
        frecuencias[codigo] = (frecuencias[codigo] ?? 0) + 1;
      }
      
      // Ordenar por frecuencia
      final codigosMasBuscados = frecuencias.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value))
          ..take(limit);
      
      final resultado = codigosMasBuscados.map((entry) => {
        'codigo': entry.key,
        'frecuencia': entry.value,
      }).toList();
      
      print('✅ Códigos más buscados obtenidos: ${resultado.length}');
      return resultado;
    } catch (e) {
      print('❌ Error al obtener códigos más buscados: $e');
      return [];
    }
  }
}
