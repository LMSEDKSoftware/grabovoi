import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio centralizado de caché para reducir requests a Supabase
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Caché en memoria (TTL: 5 minutos para datos del usuario)
  final Map<String, _CacheEntry> _memoryCache = {};
  static const Duration _userDataTTL = Duration(minutes: 5);
  static const Duration _staticDataTTL = Duration(hours: 24);
  
  // Caché de códigos relacionados (batch)
  final Map<String, List<Map<String, dynamic>>> _titulosRelacionadosCache = {};
  bool _titulosRelacionadosLoaded = false;
  
  /// Obtener datos del usuario con caché
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    final cacheKey = 'user_data_$userId';
    
    // Verificar caché en memoria
    if (_memoryCache.containsKey(cacheKey)) {
      final entry = _memoryCache[cacheKey]!;
      if (entry.isValid) {
        return entry.data;
      } else {
        _memoryCache.remove(cacheKey);
      }
    }
    
    // Cargar desde Supabase
    try {
      final userData = await _supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .maybeSingle();
      
      if (userData != null) {
        _memoryCache[cacheKey] = _CacheEntry(
          data: userData,
          expiresAt: DateTime.now().add(_userDataTTL),
        );
        return userData;
      }
    } catch (e) {
      print('⚠️ Error cargando datos del usuario: $e');
    }
    
    return null;
  }
  
  /// Obtener múltiples títulos relacionados en batch (optimización crítica)
  Future<Map<String, List<Map<String, dynamic>>>> getTitulosRelacionadosBatch(
    List<String> codigos,
  ) async {
    if (codigos.isEmpty) return {};
    
    // Separar códigos que ya están en caché
    final codigosNoCacheados = <String>[];
    final resultado = <String, List<Map<String, dynamic>>>{};
    
    for (final codigo in codigos) {
      if (_titulosRelacionadosCache.containsKey(codigo)) {
        resultado[codigo] = _titulosRelacionadosCache[codigo]!;
      } else {
        codigosNoCacheados.add(codigo);
      }
    }
    
    // Si todos están en caché, retornar
    if (codigosNoCacheados.isEmpty) {
      return resultado;
    }
    
    // Consulta batch: obtener todos los títulos relacionados de una vez
    try {
      final response = await _supabase
          .from('codigos_titulos_relacionados')
          .select('*')
          .inFilter('codigo_existente', codigosNoCacheados)
          .order('created_at', ascending: true);
      
      // Agrupar por código
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final item in response as List) {
        final codigo = item['codigo_existente'] as String;
        if (!grouped.containsKey(codigo)) {
          grouped[codigo] = [];
        }
        grouped[codigo]!.add(item as Map<String, dynamic>);
      }
      
      // Actualizar caché y resultado
      for (final codigo in codigosNoCacheados) {
        final titulos = grouped[codigo] ?? [];
        _titulosRelacionadosCache[codigo] = titulos;
        resultado[codigo] = titulos;
      }
      
      _titulosRelacionadosLoaded = true;
      print('✅ Batch query: ${codigosNoCacheados.length} códigos en 1 request');
      
    } catch (e) {
      print('❌ Error en batch query de títulos relacionados: $e');
      // Retornar listas vacías para códigos no encontrados
      for (final codigo in codigosNoCacheados) {
        resultado[codigo] = [];
      }
    }
    
    return resultado;
  }
  
  /// Obtener datos del usuario en batch (users, subscriptions, challenges, progress)
  Future<Map<String, dynamic>> getUserDataBatch(String userId) async {
    final cacheKey = 'user_data_batch_$userId';
    
    // Verificar caché
    if (_memoryCache.containsKey(cacheKey)) {
      final entry = _memoryCache[cacheKey]!;
      if (entry.isValid) {
        return entry.data as Map<String, dynamic>;
      }
    }
    
    try {
      // Cargar todos los datos en paralelo
      final futures = await Future.wait([
        _supabase.from('users').select('*').eq('id', userId).maybeSingle(),
        _supabase.from('user_subscriptions').select('*').eq('user_id', userId).eq('is_active', true),
        _supabase.from('user_challenges').select('*').eq('user_id', userId),
        _supabase.from('usuario_progreso').select('*').eq('user_id', userId).maybeSingle(),
        _supabase.from('user_rewards').select('*').eq('user_id', userId).maybeSingle(),
        _supabase.from('user_assessments').select('*').eq('user_id', userId).order('created_at', ascending: false).limit(1),
      ] as Iterable<Future<dynamic>>);
      
      final batchData = {
        'user': futures[0],
        'subscriptions': futures[1],
        'challenges': futures[2],
        'progress': futures[3],
        'rewards': futures[4],
        'assessment': (futures[5] as List).isNotEmpty ? (futures[5] as List)[0] : null,
      };
      
      // Guardar en caché
      _memoryCache[cacheKey] = _CacheEntry(
        data: batchData,
        expiresAt: DateTime.now().add(_userDataTTL),
      );
      
      print('✅ Batch query: Datos del usuario cargados en 1 request');
      return batchData;
      
    } catch (e) {
      print('❌ Error en batch query de datos del usuario: $e');
      return {};
    }
  }
  
  /// Limpiar caché de un usuario específico
  void invalidateUserCache(String userId) {
    _memoryCache.removeWhere((key, _) => key.contains(userId));
  }
  
  /// Limpiar todo el caché
  void clearCache() {
    _memoryCache.clear();
    _titulosRelacionadosCache.clear();
    _titulosRelacionadosLoaded = false;
  }
  
  /// Limpiar entradas expiradas
  void cleanExpiredEntries() {
    final now = DateTime.now();
    _memoryCache.removeWhere((_, entry) => !entry.isValid);
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;
  
  _CacheEntry({required this.data, required this.expiresAt});
  
  bool get isValid => DateTime.now().isBefore(expiresAt);
}

