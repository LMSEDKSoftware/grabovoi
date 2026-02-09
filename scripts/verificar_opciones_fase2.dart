// ignore_for_file: avoid_print
/// Script para verificar que las opciones de respuesta Fase 2 se dan según lo establecido.
/// Consulta Supabase vía REST (sin Flutter). Comprueba búsqueda "futbol" y candidatos.
///
/// Uso (desde raíz del proyecto):
///   dart run scripts/verificar_opciones_fase2.dart
///
/// Requiere: .env con SUPABASE_URL y SUPABASE_ANON_KEY.

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

const _query = 'futbol';
const _maxCandidatos = 20;
const _minRecomendaciones = 3;

/// Carga .env desde el archivo en la raíz del proyecto.
Map<String, String> loadEnv() {
  final file = File('.env');
  if (!file.existsSync()) return {};
  final lines = file.readAsStringSync().split('\n');
  final env = <String, String>{};
  for (final line in lines) {
    final idx = line.indexOf('=');
    if (idx <= 0) continue;
    final key = line.substring(0, idx).trim();
    final value = line.substring(idx + 1).trim();
    if (value.startsWith('"') && value.endsWith('"')) {
      env[key] = value.substring(1, value.length - 1).trim();
    } else {
      env[key] = value;
    }
  }
  return env;
}

/// GET Supabase REST.
Future<List<dynamic>> supabaseGet(
  String baseUrl,
  String anonKey,
  String table, {
  String? orFilter,
  String? categoryEq,
  List<String>? codigosIn,
  int limit = 100,
}) async {
  final uri = Uri.parse('$baseUrl/rest/v1/$table');
  var query = <String, String>{
    'select': '*',
    'order': 'nombre.asc',
    if (limit > 0) 'limit': limit.toString(),
  };
  if (orFilter != null) query['or'] = orFilter;
  if (categoryEq != null) query['categoria'] = 'eq.$categoryEq';
  if (codigosIn != null && codigosIn.isNotEmpty) {
    query['codigo'] = 'in.(${codigosIn.join(',')})';
  }
  final url = uri.replace(queryParameters: query);
  final res = await http.get(
    url,
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $anonKey',
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
    },
  );
  if (res.statusCode != 200) {
    print('⚠️ HTTP ${res.statusCode} $table: ${res.body}');
    return [];
  }
  final decoded = jsonDecode(res.body);
  return decoded is List ? decoded : [];
}

void main(List<String> args) async {
  print('═══════════════════════════════════════════════════════════════');
  print('  Verificación: opciones de respuesta para búsqueda "$_query"');
  print('═══════════════════════════════════════════════════════════════\n');

  final env = loadEnv();
  final baseUrl = (env['SUPABASE_URL'] ?? '').replaceAll(RegExp(r'/$'), '');
  final anonKey = env['SUPABASE_ANON_KEY'] ?? '';

  if (baseUrl.isEmpty || anonKey.isEmpty) {
    print('❌ Falta SUPABASE_URL o SUPABASE_ANON_KEY en .env');
    exit(1);
  }

  try {
    // 1) Búsqueda local por título (ILIKE en codigos_grabovoi y codigos_titulos_relacionados)
    print('1️⃣ Búsqueda local por título/descripción: "$_query"');
    final pattern = '%$_query%';
    final orFilter = '(nombre.ilike.$pattern,descripcion.ilike.$pattern)';

    final codigosDirect = await supabaseGet(
      baseUrl,
      anonKey,
      'codigos_grabovoi',
      orFilter: orFilter,
      limit: 100,
    );

    // Tabla de relacionados usa titulo/descripcion (no nombre)
    final orFilterRel = '(titulo.ilike.$pattern,descripcion.ilike.$pattern)';
    final titulosRel = await supabaseGet(
      baseUrl,
      anonKey,
      'codigos_titulos_relacionados',
      orFilter: orFilterRel,
      limit: 100,
    );

    final codigosUnicos = <String>{};
    for (final c in codigosDirect) {
      codigosUnicos.add((c['codigo'] ?? '').toString());
    }
    for (final t in titulosRel) {
      codigosUnicos.add((t['codigo_existente'] ?? '').toString());
    }

    List<dynamic> porTitulo = [];
    if (codigosUnicos.isNotEmpty) {
      porTitulo = await supabaseGet(
        baseUrl,
        anonKey,
        'codigos_grabovoi',
        codigosIn: codigosUnicos.toList(),
        limit: 100,
      );
    }

    print('   Resultados ILIKE: ${porTitulo.length}');
    if (porTitulo.isEmpty) {
      print('   → No hay coincidencias locales (esperado para "$_query").');
    } else {
      print('   → Códigos: ${porTitulo.take(5).map((c) => c['codigo']).join(", ")}${porTitulo.length > 5 ? "..." : ""}');
    }
    print('');

    // 2) Candidatos Fase 2: mismos que la app (relleno con generales si < maxCandidatos)
    print('2️⃣ Candidatos para Fase 2 (fallback + generales si < $_maxCandidatos)');
    List<Map<String, dynamic>> todos = [];
    for (final c in porTitulo) {
      todos.add(Map<String, dynamic>.from(c as Map));
    }
    todos = todos.take(_maxCandidatos).toList();

    final categorias = ['Crecimiento personal', 'Salud', 'Energía y vitalidad', 'Otros'];
    if (todos.length < _maxCandidatos) {
      for (final cat in categorias) {
        if (todos.length >= _maxCandidatos) break;
        final list = await supabaseGet(
          baseUrl,
          anonKey,
          'codigos_grabovoi',
          categoryEq: cat,
          limit: 100,
        );
        for (final c in list) {
          if (todos.length >= _maxCandidatos) break;
          final cod = (c['codigo'] ?? '').toString();
          if (!todos.any((e) => (e['codigo'] ?? '').toString() == cod)) {
            todos.add(Map<String, dynamic>.from(c as Map));
          }
        }
      }
    }
    if (todos.length < _maxCandidatos) {
      final rest = await supabaseGet(
        baseUrl,
        anonKey,
        'codigos_grabovoi',
        limit: 500,
      );
      for (final c in rest) {
        if (todos.length >= _maxCandidatos) break;
        final cod = (c['codigo'] ?? '').toString();
        if (!todos.any((e) => (e['codigo'] ?? '').toString() == cod)) {
          todos.add(Map<String, dynamic>.from(c as Map));
        }
      }
    }
    final candidatos = todos.take(_maxCandidatos).toList();

    print('   Candidatos totales: ${candidatos.length}');
    if (candidatos.length >= _minRecomendaciones) {
      print('   ✅ Hay al menos $_minRecomendaciones candidatos → la app PUEDE mostrar $_minRecomendaciones recomendaciones.');
      print('   Primeros $_minRecomendaciones:');
      for (var i = 0; i < candidatos.length && i < _minRecomendaciones; i++) {
        final c = candidatos[i];
        print('      ${i + 1}. ${c['codigo']} - ${c['nombre']} (${c['categoria']})');
      }
    } else {
      print('   ❌ Menos de $_minRecomendaciones candidatos (${candidatos.length}) → la app NO mostraría $_minRecomendaciones recomendaciones.');
    }
    print('');

    // 3) Conclusión
    print('3️⃣ Conclusión (según lo establecido):');
    if (candidatos.length >= _minRecomendaciones) {
      print('   ✅ SÍ se deben dar opciones de respuesta: $_minRecomendaciones códigos relacionados (o generales).');
      print('   La lógica de relleno con generales cuando ILIKE devuelve 0 lo permite.');
    } else {
      print('   ❌ NO se están dando las opciones: se requieren al menos $_minRecomendaciones candidatos en BD.');
    }
    print('\n═══════════════════════════════════════════════════════════════\n');

    exit(candidatos.length >= _minRecomendaciones ? 0 : 1);
  } catch (e, st) {
    print('❌ Error: $e');
    print(st);
    exit(1);
  }
}
