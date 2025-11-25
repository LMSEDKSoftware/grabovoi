import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/supabase_models.dart';
import '../services/supabase_service.dart';

class CodigosRepository {
  static final CodigosRepository _instance = CodigosRepository._internal();
  List<CodigoGrabovoi>? _codigos;
  Map<String, List<Map<String, dynamic>>>? _sincronicosCache;
  static const String _cacheKey = 'codigos_cache';
  static const String _sincronicosCacheKey = 'sincronicos_cache';

  factory CodigosRepository() => _instance;

  CodigosRepository._internal();

  /// Inicializa los códigos al abrir la app
  Future<void> initCodigos() async {
    final prefs = await SharedPreferences.getInstance();
    final cache = prefs.getString(_cacheKey);

    if (cache != null) {
      final decoded = jsonDecode(cache) as List;
      _codigos = decoded.map((e) => CodigoGrabovoi.fromJson(e)).toList();
      print('✅ Códigos cargados desde caché (${_codigos!.length})');
    }

    // Intentar refrescar con Supabase si hay conexión
    try {
      final remote = await SupabaseService.getCodigos();
      if (remote.isNotEmpty) {
        _codigos = remote;
        await _saveToLocalStorage(remote);
        print('🔄 Códigos actualizados desde Supabase (${remote.length})');
      }
    } catch (e) {
      print('⚠️ No se pudo actualizar desde Supabase: $e');
    }
    
    // Inicializar caché de sincrónicos
    await _initSincronicosCache();
  }

  /// Actualiza manualmente desde botón
  Future<void> refreshCodigos() async {
    try {
      final remote = await SupabaseService.getCodigos();
      if (remote.isNotEmpty) {
        _codigos = remote;
        await _saveToLocalStorage(remote);
        print('🔄 Códigos refrescados manualmente (${remote.length})');
      }
    } catch (e) {
      print('❌ Error al refrescar manualmente: $e');
    }
  }

  Future<void> _saveToLocalStorage(List<CodigoGrabovoi> codigos) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = codigos.map((c) => c.toJson()).toList();
    await prefs.setString(_cacheKey, jsonEncode(jsonList));
  }

  /// Inicializa el caché de códigos sincrónicos
  Future<void> _initSincronicosCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cache = prefs.getString(_sincronicosCacheKey);

    if (cache != null) {
      final decoded = jsonDecode(cache) as Map<String, dynamic>;
      _sincronicosCache = decoded.map((key, value) => 
        MapEntry(key, List<Map<String, dynamic>>.from(value)));
      print('✅ Caché de sincrónicos cargado (${_sincronicosCache!.length} categorías)');
    } else {
      _sincronicosCache = {};
      print('📝 Caché de sincrónicos inicializado vacío');
    }
  }

  /// Guarda el caché de sincrónicos en local storage
  Future<void> _saveSincronicosCache() async {
    if (_sincronicosCache != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sincronicosCacheKey, jsonEncode(_sincronicosCache));
      print('💾 Caché de sincrónicos guardado');
    }
  }

  List<CodigoGrabovoi> get codigos => _codigos ?? [];

  String getDescripcionByCode(String codigo) {
    final codigoEncontrado = _codigos?.firstWhere(
      (c) => c.codigo == codigo,
      orElse: () => CodigoGrabovoi(
        id: '',
        codigo: codigo,
        nombre: 'Campo Energético',
        descripcion: 'Código sagrado para la manifestación y transformación energética.',
        categoria: 'General',
        color: '#FFD700',
      ),
    );
    return codigoEncontrado?.descripcion ?? 'Código cuántico para la manifestación y transformación energética.';
  }

  String getTituloByCode(String codigo) {
    final codigoEncontrado = _codigos?.firstWhere(
      (c) => c.codigo == codigo,
      orElse: () => CodigoGrabovoi(
        id: '',
        codigo: codigo,
        nombre: 'Campo Energético',
        descripcion: 'Código sagrado para la manifestación y transformación energética.',
        categoria: 'General',
        color: '#FFD700',
      ),
    );
    return codigoEncontrado?.nombre ?? 'Campo Energético';
  }

  void clearCache() {
    _codigos = null;
  }

  /// Obtiene códigos sincrónicos basados en la categoría del código actual
  Future<List<Map<String, dynamic>>> getSincronicosByCategoria(String categoria) async {
    try {
      print('🔍 [SINCRÓNICOS] Buscando códigos sincrónicos para categoría: $categoria');
      
      // Verificar si ya tenemos los datos en caché
      if (_sincronicosCache != null && _sincronicosCache!.containsKey(categoria)) {
        print('✅ [SINCRÓNICOS] Datos encontrados en caché para: $categoria');
        return _sincronicosCache![categoria]!;
      }
      
      print('🔄 [SINCRÓNICOS] Cargando datos desde Supabase para: $categoria');
      
      // Obtener categorías recomendadas desde categorias_sincronicas
      final response = await SupabaseService.client
          .from('categorias_sincronicas')
          .select('categoria_recomendada, rationale')
          .eq('categoria_principal', categoria)
          .order('peso', ascending: false);
      
      final categorias = response.map((item) => item['categoria_recomendada'] as String).toList();
      
      if (categorias.isEmpty) {
        print('⚠️ [SINCRÓNICOS] No se encontraron categorías sincrónicas para: $categoria');
        // Guardar resultado vacío en caché para evitar consultas futuras
        _sincronicosCache ??= {};
        _sincronicosCache![categoria] = [];
        await _saveSincronicosCache();
        return [];
      }
      
      print('📋 [SINCRÓNICOS] Categorías recomendadas: $categorias');
      
      // Obtener códigos de las categorías recomendadas
      final result = await SupabaseService.client
          .from('codigos_grabovoi')
          .select()
          .inFilter('categoria', categorias)
          .limit(2);
      
      print('✅ [SINCRÓNICOS] Encontrados ${result.length} códigos sincrónicos');
      
      // Guardar en caché
      _sincronicosCache ??= {};
      _sincronicosCache![categoria] = result;
      await _saveSincronicosCache();
      
      return result;
    } catch (e) {
      print('❌ [SINCRÓNICOS] Error al obtener códigos sincrónicos: $e');
      return [];
    }
  }
}