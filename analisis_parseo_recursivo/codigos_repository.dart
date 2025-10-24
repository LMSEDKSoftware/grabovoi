import '../models/supabase_models.dart';
import '../services/supabase_service.dart';

class CodigosRepository {
  static final CodigosRepository _instance = CodigosRepository._internal();
  factory CodigosRepository() => _instance;
  CodigosRepository._internal();

  List<CodigoGrabovoi>? _codigos;
  Future<List<CodigoGrabovoi>>? _fetchFuture;

  Future<List<CodigoGrabovoi>> getCodigos() {
    if (_codigos != null) {
      return Future.value(_codigos!);
    }
    
    if (_fetchFuture != null) {
      return _fetchFuture!;
    }
    
    _fetchFuture = SupabaseService.getCodigos().then((codigos) {
      _codigos = codigos;
      return codigos;
    });
    
    return _fetchFuture!;
  }

  void clearCache() {
    _codigos = null;
    _fetchFuture = null;
  }

  // Método para obtener un código específico por su código
  CodigoGrabovoi? getCodigoByCode(String codigo) {
    if (_codigos == null) return null;
    try {
      return _codigos!.firstWhere((c) => c.codigo == codigo);
    } catch (e) {
      return null;
    }
  }

  // Método para obtener el título de un código
  String getTituloByCode(String codigo) {
    final codigoEncontrado = getCodigoByCode(codigo);
    return codigoEncontrado?.nombre ?? 'Campo Energético';
  }

  // Método para obtener la descripción de un código
  String getDescripcionByCode(String codigo) {
    final codigoEncontrado = getCodigoByCode(codigo);
    return codigoEncontrado?.descripcion ?? 'Código sagrado para la manifestación y transformación energética.';
  }
}
