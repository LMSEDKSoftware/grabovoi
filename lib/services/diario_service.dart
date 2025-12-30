import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service_simple.dart';

class DiarioService {
  static final DiarioService _instance = DiarioService._internal();
  factory DiarioService() => _instance;
  DiarioService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthServiceSimple _authService = AuthServiceSimple();

  /// Guardar una nueva entrada del diario
  Future<Map<String, dynamic>> guardarEntrada({
    String? codigo,
    required String intencion,
    String? estadoAnimo,
    String? sensaciones,
    int? horasSueno,
    bool? hizoEjercicio,
    String? gratitud,
    DateTime? fecha,
  }) async {
    if (!_authService.isLoggedIn) {
      throw Exception('Usuario no autenticado');
    }

    final userId = _authService.currentUser!.id;
    final fechaEntrada = fecha ?? DateTime.now();
    final fechaDate = DateTime(fechaEntrada.year, fechaEntrada.month, fechaEntrada.day);

    try {
      // Siempre crear una nueva entrada (permitir múltiples entradas por día)
      final data = <String, dynamic>{
        'user_id': userId,
        'intencion': intencion,
        'fecha': fechaDate.toIso8601String().split('T')[0], // Solo la fecha (YYYY-MM-DD)
      };

      if (codigo != null && codigo.isNotEmpty && codigo != 'Ninguno') {
        data['codigo'] = codigo;
      }
      if (estadoAnimo != null && estadoAnimo.isNotEmpty) {
        data['estado_animo'] = estadoAnimo;
      }
      if (sensaciones != null && sensaciones.isNotEmpty) {
        data['sensaciones'] = sensaciones;
      }
      if (horasSueno != null) {
        data['horas_sueno'] = horasSueno;
      }
      if (hizoEjercicio != null) {
        data['hizo_ejercicio'] = hizoEjercicio;
      }
      if (gratitud != null && gratitud.isNotEmpty) {
        data['gratitud'] = gratitud;
      }

      // Siempre insertar una nueva entrada (no actualizar existentes)
      final inserted = await _supabase
          .from('diario_entradas')
          .insert(data)
          .select()
          .single();
      
      print('✅ Nueva entrada del diario guardada (ID: ${inserted['id']})');
      return inserted;
    } catch (e) {
      print('❌ Error guardando entrada del diario: $e');
      rethrow;
    }
  }

  /// Obtener todas las entradas del usuario con filtros opcionales
  Future<List<Map<String, dynamic>>> getEntradas({
    String? codigo,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int? limit,
    int? offset,
  }) async {
    if (!_authService.isLoggedIn) {
      return [];
    }

    final userId = _authService.currentUser!.id;

    try {
      // Construir query base con filtros
      dynamic queryBuilder = _supabase
          .from('diario_entradas')
          .select()
          .eq('user_id', userId);

      if (codigo != null && codigo.isNotEmpty) {
        queryBuilder = queryBuilder.eq('codigo', codigo);
      }

      if (fechaDesde != null) {
        queryBuilder = queryBuilder.gte('fecha', fechaDesde.toIso8601String().split('T')[0]);
      }

      if (fechaHasta != null) {
        queryBuilder = queryBuilder.lte('fecha', fechaHasta.toIso8601String().split('T')[0]);
      }

      // Aplicar ordenamiento y paginación según corresponda
      dynamic response;
      if (limit != null && offset != null) {
        response = await queryBuilder
            .order('fecha', ascending: false)
            .range(offset, offset + limit - 1);
      } else if (limit != null) {
        response = await queryBuilder
            .order('fecha', ascending: false)
            .limit(limit);
      } else {
        response = await queryBuilder.order('fecha', ascending: false);
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error obteniendo entradas del diario: $e');
      return [];
    }
  }

  /// Obtener una entrada específica por fecha
  Future<Map<String, dynamic>?> getEntradaPorFecha(DateTime fecha) async {
    if (!_authService.isLoggedIn) {
      return null;
    }

    final userId = _authService.currentUser!.id;
    final fechaDate = DateTime(fecha.year, fecha.month, fecha.day);

    try {
      final response = await _supabase
          .from('diario_entradas')
          .select()
          .eq('user_id', userId)
          .eq('fecha', fechaDate.toIso8601String().split('T')[0])
          .maybeSingle();

      return response;
    } catch (e) {
      print('❌ Error obteniendo entrada por fecha: $e');
      return null;
    }
  }

  /// Obtener días consecutivos de registro
  Future<int> getDiasConsecutivos() async {
    if (!_authService.isLoggedIn) {
      return 0;
    }

    final userId = _authService.currentUser!.id;

    try {
      // Obtener todas las entradas para extraer fechas únicas
      final response = await _supabase
          .from('diario_entradas')
          .select('fecha')
          .eq('user_id', userId);
      
      // Extraer fechas únicas
      final fechasUnicas = <String>{};
      for (final entrada in response) {
        fechasUnicas.add(entrada['fecha'].toString());
      }
      
      if (fechasUnicas.isEmpty) return 0;

      // Ordenar fechas descendente (más reciente primero)
      final fechasOrdenadas = fechasUnicas.map((f) => DateTime.parse(f)).toList()
        ..sort((a, b) => b.compareTo(a));

      final hoy = DateTime.now();
      final hoyDate = DateTime(hoy.year, hoy.month, hoy.day);
      
      int diasConsecutivos = 0;
      DateTime fechaEsperada = hoyDate;

      for (final fechaEntradaDate in fechasOrdenadas) {
        final fechaNormalizada = DateTime(
          fechaEntradaDate.year,
          fechaEntradaDate.month,
          fechaEntradaDate.day,
        );
        
        if (fechaNormalizada.isAtSameMomentAs(fechaEsperada)) {
          diasConsecutivos++;
          fechaEsperada = fechaEsperada.subtract(const Duration(days: 1));
        } else if (fechaNormalizada.isBefore(fechaEsperada)) {
          // Si la fecha es anterior a la esperada, romper la cadena
          break;
        }
        // Si la fecha es posterior a la esperada, simplemente continuar
      }

      return diasConsecutivos;
    } catch (e) {
      print('❌ Error calculando días consecutivos: $e');
      return 0;
    }
  }

  /// Obtener códigos más usados en el diario
  Future<Map<String, int>> getCodigosMasUsados({int limit = 10}) async {
    if (!_authService.isLoggedIn) {
      return {};
    }

    final userId = _authService.currentUser!.id;

    try {
      final entradas = await _supabase
          .from('diario_entradas')
          .select('codigo')
          .eq('user_id', userId)
          .not('codigo', 'is', null);

      final contador = <String, int>{};
      for (final entrada in entradas) {
        final codigo = entrada['codigo'] as String?;
        if (codigo != null && codigo.isNotEmpty) {
          contador[codigo] = (contador[codigo] ?? 0) + 1;
        }
      }

      // Ordenar y limitar
      final sorted = Map.fromEntries(
        contador.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)),
      );

      return Map.fromEntries(sorted.entries.take(limit));
    } catch (e) {
      print('❌ Error obteniendo códigos más usados: $e');
      return {};
    }
  }

  /// Obtener secuencias en seguimiento agrupadas por código
  /// Retorna un mapa donde la clave es el código y el valor es la lista de entradas
  Future<Map<String, List<Map<String, dynamic>>>> getSecuenciasEnSeguimiento() async {
    if (!_authService.isLoggedIn) {
      return {};
    }

    final userId = _authService.currentUser!.id;

    try {
      final entradas = await _supabase
          .from('diario_entradas')
          .select()
          .eq('user_id', userId)
          .not('codigo', 'is', null)
          .order('fecha', ascending: false);

      // Agrupar por código
      final agrupadas = <String, List<Map<String, dynamic>>>{};
      for (final entrada in entradas) {
        final codigo = entrada['codigo'] as String?;
        if (codigo != null && codigo.isNotEmpty) {
          if (!agrupadas.containsKey(codigo)) {
            agrupadas[codigo] = [];
          }
          agrupadas[codigo]!.add(entrada);
        }
      }

      return agrupadas;
    } catch (e) {
      print('❌ Error obteniendo secuencias en seguimiento: $e');
      return {};
    }
  }

  /// Eliminar una entrada del diario
  Future<void> eliminarEntrada(String id) async {
    if (!_authService.isLoggedIn) {
      throw Exception('Usuario no autenticado');
    }

    final userId = _authService.currentUser!.id;

    try {
      await _supabase
          .from('diario_entradas')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);

      print('✅ Entrada del diario eliminada');
    } catch (e) {
      print('❌ Error eliminando entrada del diario: $e');
      rethrow;
    }
  }

  /// Método de prueba para verificar que la tabla funciona
  Future<Map<String, dynamic>?> testInsercion() async {
    if (!_authService.isLoggedIn) {
      print('⚠️ Usuario no autenticado para prueba');
      return null;
    }

    final userId = _authService.currentUser!.id;
    final fechaHoy = DateTime.now();
    final fechaStr = '${fechaHoy.year}-${fechaHoy.month.toString().padLeft(2, '0')}-${fechaHoy.day.toString().padLeft(2, '0')}';

    try {
      print('🧪 Test: Intentando insertar entrada de prueba...');
      print('   User ID: $userId');
      print('   Fecha: $fechaStr');

      final resultado = await guardarEntrada(
        intencion: 'Test de inserción - Verificación de tabla',
        estadoAnimo: 'tranquilo',
        sensaciones: 'Este es un registro de prueba para verificar que la tabla funciona correctamente',
        horasSueno: 8,
        hizoEjercicio: false,
        gratitud: 'Agradecido por poder probar el sistema',
        fecha: fechaHoy,
      );

      print('✅ Test exitoso - Entrada insertada/actualizada correctamente');
      print('   ID: ${resultado['id']}');
      return resultado;
    } catch (e) {
      print('❌ Error en test de inserción: $e');
      if (e.toString().contains('relation "diario_entradas" does not exist')) {
        print('⚠️ La tabla diario_entradas no existe. Por favor, ejecuta el SQL schema primero.');
      }
      rethrow;
    }
  }

  /// Actualizar una entrada existente
  Future<Map<String, dynamic>> actualizarEntrada({
    required String id,
    String? codigo,
    String? intencion,
    String? estadoAnimo,
    String? sensaciones,
    int? horasSueno,
    bool? hizoEjercicio,
    String? gratitud,
  }) async {
    if (!_authService.isLoggedIn) {
      throw Exception('Usuario no autenticado');
    }

    final userId = _authService.currentUser!.id;

    try {
      final data = <String, dynamic>{};

      if (codigo != null) {
        if (codigo.isEmpty || codigo == 'Ninguno') {
          data['codigo'] = null;
        } else {
          data['codigo'] = codigo;
        }
      }
      if (intencion != null) {
        data['intencion'] = intencion;
      }
      if (estadoAnimo != null) {
        data['estado_animo'] = estadoAnimo;
      }
      if (sensaciones != null) {
        data['sensaciones'] = sensaciones;
      }
      if (horasSueno != null) {
        data['horas_sueno'] = horasSueno;
      }
      if (hizoEjercicio != null) {
        data['hizo_ejercicio'] = hizoEjercicio;
      }
      if (gratitud != null) {
        data['gratitud'] = gratitud;
      }

      final updated = await _supabase
          .from('diario_entradas')
          .update(data)
          .eq('id', id)
          .eq('user_id', userId)
          .select()
          .single();

      print('✅ Entrada del diario actualizada');
      return updated;
    } catch (e) {
      print('❌ Error actualizando entrada del diario: $e');
      rethrow;
    }
  }
}

