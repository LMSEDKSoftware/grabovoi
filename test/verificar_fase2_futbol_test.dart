// ignore_for_file: avoid_print
/// Verificación: opciones de respuesta para búsqueda "futbol" (Fase 2).
///
/// Comprueba:
/// 1) Búsqueda local por "futbol" (ILIKE) → N resultados.
/// 2) Candidatos para fallback Fase 2 (con relleno de generales si N < 20) → M >= 3.
/// 3) Según lo establecido: se deben dar al menos 3 opciones de respuesta.
///
/// Ejecutar desde la raíz del proyecto:
///   flutter test test/verificar_fase2_futbol_test.dart
///
/// Requiere: .env con SUPABASE_URL y SUPABASE_ANON_KEY.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:manifestacion_numerica_grabovoi/config/supabase_config.dart';
import 'package:manifestacion_numerica_grabovoi/services/supabase_service.dart';

void main() {
  group('Verificación opciones de respuesta búsqueda "futbol"', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      try {
        await dotenv.load(fileName: '.env');
      } catch (_) {
        // .env opcional si se usan --dart-define
      }
      await SupabaseConfig.initialize();
    });

    test('Búsqueda "futbol": local devuelve 0; Fase 2 debe dar al menos 3 candidatos', () async {
      const query = 'futbol';

      print('\n═══════════════════════════════════════════════════════════════');
      print('  Verificación: opciones de respuesta para búsqueda "$query"');
      print('═══════════════════════════════════════════════════════════════\n');

      // 1) Búsqueda local (equivalente a buscarCodigosPorTitulo)
      print('1️⃣ Búsqueda local por título/descripción: "$query"');
      final porTitulo = await SupabaseService.buscarCodigosPorTitulo(query);
      print('   Resultados ILIKE: ${porTitulo.length}');
      if (porTitulo.isEmpty) {
        print('   → No hay coincidencias locales (esperado para "$query").');
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

      // 3) Conclusión y aserción
      print('3️⃣ Conclusión (según lo establecido):');
      if (candidatos.length >= 3) {
        print('   ✅ SÍ se están dando las opciones de respuesta: 3 códigos relacionados (o generales).');
      } else {
        print('   ❌ NO se están dando las opciones: se requieren al menos 3 candidatos en BD.');
      }
      print('\n═══════════════════════════════════════════════════════════════\n');

      expect(
        candidatos.length,
        greaterThanOrEqualTo(3),
        reason: 'Fase 2 debe ofrecer al menos 3 opciones de respuesta cuando no hay match exacto (ej. "futbol"). '
            'Candidatos obtenidos: ${candidatos.length}.',
      );
    });
  });
}
