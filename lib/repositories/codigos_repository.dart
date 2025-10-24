import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/supabase_models.dart';
import '../services/supabase_service.dart';

class CodigosRepository {
  static final CodigosRepository _instance = CodigosRepository._internal();
  List<CodigoGrabovoi>? _codigos;
  static const String _cacheKey = 'codigos_cache';

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
    return codigoEncontrado?.descripcion ?? 'Código sagrado para la manifestación y transformación energética.';
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
}