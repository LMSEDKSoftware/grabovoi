import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Servicio para gestionar el código diario que todos los usuarios ven
class DailyCodeService {
  static final SupabaseClient _client = SupabaseConfig.client;

  /// Obtiene el código del día actual
  /// Si no existe un código asignado para hoy, crea uno automáticamente
  static Future<String> getTodayCode() async {
    try {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      // Buscar si ya existe un código asignado para hoy
      final assignmentResponse = await _client
          .from('daily_code_assignments')
          .select('''
            codigo_id,
            daily_codes!inner(codigo, nombre, descripcion)
          ''')
          .eq('fecha_asignacion', todayDate.toIso8601String().split('T')[0])
          .eq('es_activo', true)
          .maybeSingle();

      if (assignmentResponse != null) {
        final dailyCode = assignmentResponse['daily_codes'] as Map<String, dynamic>;
        final codigo = dailyCode['codigo'] as String;
        print('✅ Código del día encontrado: $codigo');
        return codigo;
      }

      // No existe un código asignado para hoy, crear uno automáticamente
      print('📅 No existe código asignado para hoy, creando uno automáticamente...');
      return await _assignCodeForToday(todayDate);
    } catch (e) {
      print('❌ Error obteniendo código del día: $e');
      // Fallback a código por defecto
      return '812_719_819_14'; // Vitalidad como fallback
    }
  }

  /// Asigna un código para el día actual
  /// Usa rotación basada en el día del año para distribuir códigos
  static Future<String> _assignCodeForToday(DateTime date) async {
    try {
      // Primero, desactivar cualquier otro código activo para hoy (por si acaso)
      await _client
          .from('daily_code_assignments')
          .update({'es_activo': false})
          .eq('fecha_asignacion', date.toIso8601String().split('T')[0]);

      // Obtener todos los códigos disponibles en daily_codes
      final codesResponse = await _client
          .from('daily_codes')
          .select('id, codigo, nombre')
          .order('id');

      if (codesResponse.isEmpty) {
        print('⚠️ No hay códigos en daily_codes, usando codigos_grabovoi directamente');
        // Si no hay códigos en daily_codes, usar codigos_grabovoi directamente
        // No podemos crear un assignment porque requiere codigo_id de daily_codes,
        // pero todos los usuarios verán el mismo código basado en el día del año
        final allCodigos = await _client
            .from('codigos_grabovoi')
            .select('codigo, nombre')
            .order('nombre');

        if (allCodigos.isEmpty) {
          print('❌ No hay códigos disponibles en ninguna tabla');
          return '812_719_819_14'; // Último fallback
        }

        // Usar el día del año como índice para rotar códigos
        final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
        final codigoIndex = dayOfYear % allCodigos.length;
        final selectedCode = allCodigos[codigoIndex] as Map<String, dynamic>;
        final codigo = selectedCode['codigo'] as String;
        final nombre = selectedCode['nombre'] as String;

        print('📌 Usando código de codigos_grabovoi: $codigo - $nombre (índice: $codigoIndex de ${allCodigos.length})');
        return codigo;
      }

      // Usar el día del año como índice para rotar códigos de daily_codes
      // Esto asegura que el mismo código no se repita hasta el próximo año
      final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
      final codigoIndex = dayOfYear % codesResponse.length;
      final selectedCode = codesResponse[codigoIndex] as Map<String, dynamic>;
      final codigoId = selectedCode['id'] as int;
      final codigo = selectedCode['codigo'] as String;
      final nombre = selectedCode['nombre'] as String;

      print('📌 Asignando código de daily_codes: $codigo - $nombre (índice: $codigoIndex de ${codesResponse.length})');

      try {
        // Crear el assignment para hoy
        await _client.from('daily_code_assignments').insert({
          'codigo_id': codigoId,
          'fecha_asignacion': date.toIso8601String().split('T')[0],
          'es_activo': true,
        });

        print('✅ Código asignado exitosamente para ${date.toIso8601String().split('T')[0]}');
        return codigo;
      } catch (insertError) {
        // Si hay un error de clave duplicada, significa que otro proceso ya creó el assignment
        // Intentar obtener el código ya asignado
        if (insertError.toString().contains('duplicate key') || insertError.toString().contains('23505')) {
          print('⚠️ Código ya existe para hoy, obteniendo el código asignado...');
          final existingAssignment = await _client
              .from('daily_code_assignments')
              .select('''
                codigo_id,
                daily_codes!inner(codigo, nombre)
              ''')
              .eq('fecha_asignacion', date.toIso8601String().split('T')[0])
              .eq('es_activo', true)
              .maybeSingle();

          if (existingAssignment != null) {
            final dailyCode = existingAssignment['daily_codes'] as Map<String, dynamic>;
            final existingCodigo = dailyCode['codigo'] as String;
            print('✅ Código obtenido de assignment existente: $existingCodigo');
            return existingCodigo;
          }
        }
        // Si no es error de clave duplicada o no se pudo obtener, re-lanzar el error
        rethrow;
      }
    } catch (e) {
      print('❌ Error asignando código para hoy: $e');
      // Fallback
      return '812_719_819_14';
    }
  }

  /// Obtiene información completa del código del día (incluyendo nombre y descripción)
  static Future<Map<String, String>?> getTodayCodeInfo() async {
    try {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      final assignmentResponse = await _client
          .from('daily_code_assignments')
          .select('''
            codigo_id,
            daily_codes!inner(codigo, nombre, descripcion)
          ''')
          .eq('fecha_asignacion', todayDate.toIso8601String().split('T')[0])
          .eq('es_activo', true)
          .maybeSingle();

      if (assignmentResponse != null) {
        final dailyCode = assignmentResponse['daily_codes'] as Map<String, dynamic>;
        final codigo = dailyCode['codigo'] as String;
        final nombre = dailyCode['nombre'] as String?;
        final descripcion = dailyCode['descripcion'] as String?;
        
        // Si hay nombre y descripción en daily_codes, usarlos
        if (nombre != null && nombre.isNotEmpty && descripcion != null && descripcion.isNotEmpty) {
          return {
            'codigo': codigo,
            'nombre': nombre,
            'descripcion': descripcion,
          };
        }
        
        // Si no hay descripción completa en daily_codes, buscar en codigos_grabovoi
        if (codigo.isNotEmpty) {
          final codigoInfo = await _client
              .from('codigos_grabovoi')
              .select('nombre, descripcion')
              .eq('codigo', codigo)
              .maybeSingle();
          
          if (codigoInfo != null) {
            return {
              'codigo': codigo,
              'nombre': (codigoInfo['nombre'] as String?) ?? nombre ?? 'Código Diario',
              'descripcion': (codigoInfo['descripcion'] as String?) ?? descripcion ?? 'Código cuántico para la manifestación y transformación energética.',
            };
          }
        }
      }

      // Si no existe assignment, obtener el código y buscar su info en codigos_grabovoi
      final codigo = await getTodayCode();
      
      // Buscar información del código en codigos_grabovoi
      final codigoInfo = await _client
          .from('codigos_grabovoi')
          .select('nombre, descripcion')
          .eq('codigo', codigo)
          .maybeSingle();
      
      if (codigoInfo != null) {
        return {
          'codigo': codigo,
          'nombre': (codigoInfo['nombre'] as String?) ?? 'Código Diario',
          'descripcion': (codigoInfo['descripcion'] as String?) ?? 'Código sagrado para la manifestación y transformación energética.',
        };
      }
      
      // Último fallback
      return {
        'codigo': codigo,
        'nombre': 'Código Diario',
        'descripcion': 'Código cuántico para la manifestación y transformación energética.',
      };
    } catch (e) {
      print('❌ Error obteniendo información del código del día: $e');
      // Si hay error, al menos intentar obtener el código y buscar su info
      try {
        final codigo = await getTodayCode();
        final codigoInfo = await _client
            .from('codigos_grabovoi')
            .select('nombre, descripcion')
            .eq('codigo', codigo)
            .maybeSingle();
        
        if (codigoInfo != null) {
          return {
            'codigo': codigo,
            'nombre': (codigoInfo['nombre'] as String?) ?? 'Código Diario',
            'descripcion': (codigoInfo['descripcion'] as String?) ?? 'Código cuántico para la manifestación y transformación energética.',
          };
        }
      } catch (_) {}
      return null;
    }
  }
}

