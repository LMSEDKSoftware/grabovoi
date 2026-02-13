import '../config/supabase_config.dart';
import '../models/store_config_model.dart';
import '../models/rewards_model.dart';

/// Servicio para cargar configuración dinámica de la tienda desde Supabase.
/// Permite administrar precios, cantidades y visibilidad sin actualizar la app.
class StoreConfigService {
  static final StoreConfigService _instance = StoreConfigService._internal();
  factory StoreConfigService() => _instance;
  StoreConfigService._internal();

  List<PaqueteCristales>? _paquetesCache;
  List<ElementoTienda>? _elementosCache;
  List<CodigoPremium>? _codigosCache;
  List<MeditacionEspecial>? _meditacionesCache;
  DateTime? _lastFetch;

  static const Duration _cacheDuration = Duration(minutes: 5);

  bool get _cacheExpired =>
      _lastFetch == null || DateTime.now().difference(_lastFetch!) > _cacheDuration;

  /// Paquetes de cristales (cantidad, precio MXN) - solo activos
  Future<List<PaqueteCristales>> getPaquetesCristales({bool forceRefresh = false}) async {
    if (!forceRefresh && _paquetesCache != null && !_cacheExpired) {
      return _paquetesCache!;
    }
    try {
      final response = await SupabaseConfig.client
          .from('paquetes_cristales')
          .select()
          .eq('activo', true)
          .order('orden', ascending: true);

      _paquetesCache = (response as List)
          .map((json) => PaqueteCristales.fromJson(json as Map<String, dynamic>))
          .toList();
      _lastFetch = DateTime.now();
      return _paquetesCache!;
    } catch (e) {
      print('Error cargando paquetes cristales: $e');
      return _paquetesCache ?? [];
    }
  }

  /// Elementos de tienda (Voz numérica, Ancla, etc.) - solo activos
  Future<List<ElementoTienda>> getElementosTienda({bool forceRefresh = false}) async {
    if (!forceRefresh && _elementosCache != null && !_cacheExpired) {
      return _elementosCache!;
    }
    try {
      final response = await SupabaseConfig.client
          .from('elementos_tienda')
          .select()
          .eq('activo', true)
          .order('orden', ascending: true);

      _elementosCache = (response as List)
          .map((json) => ElementoTienda.fromJson(json as Map<String, dynamic>))
          .toList();
      _lastFetch = DateTime.now();
      return _elementosCache!;
    } catch (e) {
      print('Error cargando elementos tienda: $e');
      return _elementosCache ?? [];
    }
  }

  /// Costo de voz numérica (desde DB o fallback)
  Future<int> getCostoVozNumerica() async {
    final elementos = await getElementosTienda();
    final elem = elementos.where((e) => e.tipo == 'voz_numerica').firstOrNull;
    return elem?.costoCristales ?? 50;
  }

  /// Costo y max anclas de Ancla de Continuidad (desde DB o fallback)
  Future<({int costo, int maxAnclas})> getConfigAnclaContinuidad() async {
    final elementos = await getElementosTienda();
    final elem = elementos.where((e) => e.tipo == 'ancla_continuidad').firstOrNull;
    return (
      costo: elem?.costoCristales ?? 200,
      maxAnclas: elem?.maxAnclas ?? 2,
    );
  }

  /// Códigos premium - solo activos (activo=true o sin columna)
  Future<List<CodigoPremium>> getCodigosPremium({bool forceRefresh = false}) async {
    if (!forceRefresh && _codigosCache != null && !_cacheExpired) {
      return _codigosCache!;
    }
    try {
      final response = await SupabaseConfig.client
          .from('codigos_premium')
          .select()
          .order('costo_cristales', ascending: true);

      _codigosCache = (response as List)
          .map((json) {
            final m = json as Map<String, dynamic>;
            if (m['activo'] == false) return null;
            return CodigoPremium(
              id: m['id'],
              codigo: m['codigo'],
              nombre: m['nombre'],
              descripcion: m['descripcion'],
              costoCristales: m['costo_cristales'],
              categoria: m['categoria'] ?? 'Premium',
              esRaro: m['es_raro'] ?? false,
              wallpaperUrl: m['wallpaper_url'] as String?,
            );
          })
          .whereType<CodigoPremium>()
          .toList();
      _lastFetch = DateTime.now();
      return _codigosCache!;
    } catch (e) {
      print('Error cargando códigos premium: $e');
      return _codigosCache ?? [];
    }
  }

  /// Meditaciones especiales - solo activas
  Future<List<MeditacionEspecial>> getMeditacionesEspeciales({bool forceRefresh = false}) async {
    if (!forceRefresh && _meditacionesCache != null && !_cacheExpired) {
      return _meditacionesCache!;
    }
    try {
      final response = await SupabaseConfig.client
          .from('meditaciones_especiales')
          .select()
          .order('duracion_minutos', ascending: true);

      _meditacionesCache = (response as List)
          .map((json) {
            final m = json as Map<String, dynamic>;
            if (m['activo'] == false) return null;
            return MeditacionEspecial(
              id: m['id'],
              nombre: m['nombre'],
              descripcion: m['descripcion'],
              audioUrl: m['audio_url'] ?? '',
              luzCuanticaRequerida: (m['luz_cuantica_requerida'] ?? 100.0).toDouble(),
              duracionMinutos: m['duracion_minutos'] ?? 15,
            );
          })
          .whereType<MeditacionEspecial>()
          .toList();
      _lastFetch = DateTime.now();
      return _meditacionesCache!;
    } catch (e) {
      print('Error cargando meditaciones especiales: $e');
      return _meditacionesCache ?? [];
    }
  }

  void invalidateCache() {
    _paquetesCache = null;
    _elementosCache = null;
    _codigosCache = null;
    _meditacionesCache = null;
    _lastFetch = null;
  }
}
