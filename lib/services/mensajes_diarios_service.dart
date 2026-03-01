import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para obtener mensajes diarios desde la tabla mensajes_diarios
class MensajesDiariosService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene el día del año (1-365)
  static int _obtenerDiaDelAnio() {
    final ahora = DateTime.now();
    final inicioAnio = DateTime(ahora.year, 1, 1);
    final diferencia = ahora.difference(inicioAnio);
    // +1 para que el primer día del año sea día 1, no día 0
    final diaDelAnio = diferencia.inDays + 1;
    // Asegurar que esté entre 1 y 365
    return diaDelAnio.clamp(1, 365);
  }

  /// Obtiene el mensaje diario correspondiente al día actual del año (1-365)
  /// Si no hay mensaje para ese día, retorna null
  static Future<String?> obtenerMensajeDiario() async {
    try {
      final dia = _obtenerDiaDelAnio();
      
      final response = await _supabase
          .from('mensajes_diarios')
          .select('mensaje')
          .eq('dia', dia)
          .maybeSingle();

      if (response != null && response['mensaje'] != null) {
        return response['mensaje'] as String;
      }

      // Si no hay mensaje para ese día, retornar null
      return null;
    } catch (e) {
      print('❌ Error obteniendo mensaje diario: $e');
      return null;
    }
  }

  /// Obtiene el mensaje diario con un fallback por defecto
  /// Si no hay mensaje en la BD, retorna el mensaje por defecto
  static Future<String> obtenerMensajeDiarioConFallback() async {
    final mensaje = await obtenerMensajeDiario();
    
    if (mensaje != null && mensaje.isNotEmpty) {
      return mensaje;
    }

    // Mensaje por defecto si no hay mensaje en la BD
    return '🔮 La energía fluye contigo. Cada día es más poderoso.';
  }
}

