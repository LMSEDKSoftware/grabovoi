import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/supabase_models.dart';
import '../services/supabase_service.dart';

class CodigosRepository {
  static final CodigosRepository _instance = CodigosRepository._internal();
  List<CodigoGrabovoi>? _codigos;
  static const String _cacheKey = 'codigos_cache';
  // Los sincrónicos ya no se cachean (ver getSincronicosByCategoria); esta
  // clave solo se conserva para poder borrar de los teléfonos el caché
  // viejo, que dejaba las sugerencias congeladas hasta reinstalar.
  static const String _sincronicosCacheKeyObsoleta = 'sincronicos_cache';

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
    
    await _borrarCacheSincronicosObsoleto();
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

  /// Borra el caché viejo de sincrónicos que quedó en los teléfonos.
  ///
  /// Ya no se usa: guardaba las 2 sugerencias por categoría en
  /// SharedPreferences, así que además de ser siempre las mismas (la
  /// consulta no ordenaba), quedaban congeladas hasta reinstalar la app.
  /// Sin esto el blob se queda ahí ocupando espacio para siempre.
  Future<void> _borrarCacheSincronicosObsoleto() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_sincronicosCacheKeyObsoleta)) {
      await prefs.remove(_sincronicosCacheKeyObsoleta);
      print('🧹 Caché viejo de sincrónicos eliminado');
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

  /// Obtiene las secuencias sincrónicas que se sugieren al terminar una
  /// sesión ("Combínalo con las siguientes secuencias para amplificar la
  /// resonancia").
  ///
  /// La selección la hace la función roku_sincronicas en Supabase, en
  /// tres niveles: pareja curada a mano, categoría afín por peso, y misma
  /// categoría como respaldo. El nombre lleva el prefijo roku_ porque
  /// nació para ese canal, pero la lógica es la misma para app y TV y no
  /// tiene sentido duplicarla.
  ///
  /// Antes esto se resolvía aquí con
  ///   .inFilter('categoria', categorias).limit(2)
  /// sin ningún orden, así que Postgres devolvía siempre las mismas dos
  /// filas. Y encima el resultado se guardaba en SharedPreferences: las
  /// sugerencias no solo eran fijas, quedaban congeladas en el teléfono
  /// hasta reinstalar. Por eso ya no se cachea: el punto de la función es
  /// justamente que cambien en cada sesión.
  ///
  /// [codigo] es opcional por compatibilidad, pero conviene pasarlo: sin
  /// él se pierde el nivel de parejas curadas y todo cae en el automático.
  Future<List<Map<String, dynamic>>> getSincronicosByCategoria(
    String categoria, {
    String? codigo,
  }) async {
    try {
      print('🔍 [SINCRÓNICOS] Buscando sincrónicos para: $categoria (código: ${codigo ?? "sin código"})');

      final result = await SupabaseService.client.rpc(
        'roku_sincronicas',
        params: {
          'p_categoria': categoria,
          'p_limite': 2,
          'p_codigo': codigo,
        },
      );

      final lista = List<Map<String, dynamic>>.from(result as List);
      print('✅ [SINCRÓNICOS] Encontrados ${lista.length} códigos sincrónicos');
      return lista;
    } catch (e) {
      print('❌ [SINCRÓNICOS] Error al obtener códigos sincrónicos: $e');
      return [];
    }
  }
}