// ignore_for_file: avoid_print
/// Script para verificar que la búsqueda "futbol" y Fase 2 devuelven opciones de respuesta.
///
/// Comprueba:
/// 1) Búsqueda local por "futbol" (ILIKE) → N resultados.
/// 2) Candidatos para fallback Fase 2 (con relleno de generales si N < 20) → M >= 3.
/// 3) ¿Se deben dar 3 recomendaciones? Sí si M >= 3.
///
/// Uso (desde raíz del proyecto):
///   dart run scripts/verificar_fase2_futbol.dart
///
/// Requiere: .env con SUPABASE_URL y SUPABASE_ANON_KEY.
library;


import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dotenv/dotenv.dart';
import 'package:manifestacion_numerica_grabovoi/services/supabase_service.dart';

Future<void> main(List<String> args) async {
  print('═══════════════════════════════════════════════════════════════');
  print('  Verificación: opciones de respuesta para búsqueda "futbol"');
  print('═══════════════════════════════════════════════════════════════\n');

  final env = DotEnv(includePlatformEnvironment: true)..load(['.env']);
  final url = env['SUPABASE_URL']?.trim() ?? '';
  final anonKey = env['SUPABASE_ANON_KEY']?.trim() ?? '';

  if (url.isEmpty || anonKey.isEmpty) {
    print('❌ Falta SUPABASE_URL o SUPABASE_ANON_KEY en .env');
    exit(1);
  }

  await Supabase.initialize(url: url, anonKey: anonKey);

  const query = 'futbol';

  try {
    // 1) Búsqueda local (equivalente a buscarCodigosPorTitulo)
    print('1️⃣ Búsqueda local por título/descripción: "$query"');
    final porTitulo = await SupabaseService.buscarCodigosPorTitulo(query);
    print('   Resultados ILIKE: ${porTitulo.length}');
    if (porTitulo.isEmpty) {
      print('   → No hay coincidencias locales (esperado para "futbol").');
    } else {
      print('   → Códigos: ${porTitulo.map((c) => c.codigo).take(5).join(", ")}${porTitulo.length > 5 ? "..." : ""}');
    }
    print('');

    // 2) Candidatos para Fase 2 (con relleno de generales si hace falta)
    print('2️⃣ Candidatos para Fase 2 (fallback relacionados + generales si < 20)');
    final candidatos = await SupabaseService.getCandidatosParaFallbackRelacionados(
      userQueryText: query,
      isNumericQuery: false,
      exactCode: null,
      maxCandidatos: 20,
    );
    print('   Candidatos totales: ${candidatos.length}');
    if (candidatos.length >= 3) {
      print('   ✅ Hay al menos 3 candidatos → la app PUEDE mostrar 3 recomendaciones.');
      print('   Primeros 3:');
      for (var i = 0; i < candidatos.length && i < 3; i++) {
        final c = candidatos[i];
        print('      ${i + 1}. ${c.codigo} - ${c.nombre} (${c.categoria})');
      }
    } else {
      print('   ❌ Menos de 3 candidatos (${candidatos.length}) → la app NO mostraría 3 recomendaciones.');
    }
    print('');

    // 3) Conclusión
    print('3️⃣ Conclusión (según lo establecido):');
    if (candidatos.length >= 3) {
      print('   ✅ SÍ se deben dar opciones de respuesta: 3 códigos relacionados (o generales).');
      print('   La corrección aplicada (rellenar con generales cuando ILIKE devuelve 0) lo permite.');
    } else {
      print('   ❌ NO se están dando las opciones: se requieren al menos 3 candidatos en BD.');
    }
    print('\n═══════════════════════════════════════════════════════════════\n');
  } catch (e, st) {
    print('❌ Error: $e');
    print(st);
    exit(1);
  }

  exit(0);
}
