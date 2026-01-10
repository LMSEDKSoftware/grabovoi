import '../models/resource_model.dart';
import '../config/supabase_config.dart';

class ResourcesService {
  /// Obtener todos los recursos activos ordenados
  Future<List<Resource>> getResources({String? category}) async {
    try {
      var query = SupabaseConfig.client
          .from('resources')
          .select()
          .eq('is_active', true);

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      final response = await query
          .order('order', ascending: true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Resource.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo recursos: $e');
      return [];
    }
  }

  /// Obtener un recurso por ID
  Future<Resource?> getResourceById(String id) async {
    try {
      final response = await SupabaseConfig.client
          .from('resources')
          .select()
          .eq('id', id)
          .eq('is_active', true)
          .single();

      return Resource.fromJson(response);
    } catch (e) {
      print('❌ Error obteniendo recurso: $e');
      return null;
    }
  }

  /// Obtener todas las categorías disponibles
  Future<List<String>> getCategories() async {
    try {
      final response = await SupabaseConfig.client
          .from('resources')
          .select('category')
          .eq('is_active', true);

      final categories = (response as List<dynamic>)
          .map((item) => (item as Map<String, dynamic>)['category'] as String)
          .toSet()
          .toList();

      categories.sort();
      return categories;
    } catch (e) {
      print('❌ Error obteniendo categorías: $e');
      return [];
    }
  }
}

