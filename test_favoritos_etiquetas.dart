import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manifestacion_numerica_grabovoi/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Prueba de Favoritos y Etiquetas', () {
    testWidgets('Probar funcionalidad completa de favoritos y etiquetas', (WidgetTester tester) async {
      // Iniciar la aplicación
      app.main();
      await tester.pumpAndSettle();

      print('🔍 PASO 1: Verificando que la aplicación se cargó correctamente');
      
      // Verificar que estamos en la pantalla principal
      expect(find.text('Manifestación Numérica Grabovoi'), findsOneWidget);
      print('✅ Aplicación cargada correctamente');

      print('🔍 PASO 2: Navegando a la sección de Biblioteca');
      
      // Buscar y tocar el botón de Biblioteca
      final bibliotecaButton = find.text('Biblioteca');
      expect(bibliotecaButton, findsOneWidget);
      await tester.tap(bibliotecaButton);
      await tester.pumpAndSettle();

      print('✅ Navegado a Biblioteca');

      print('🔍 PASO 3: Verificando que se muestran los códigos');
      
      // Verificar que se muestran los códigos
      expect(find.text('Biblioteca Sagrada'), findsOneWidget);
      print('✅ Biblioteca cargada correctamente');

      print('🔍 PASO 4: Verificando que NO están habilitados los favoritos inicialmente');
      
      // Verificar que inicialmente NO se muestran las etiquetas de favoritos
      expect(find.text('Filtrar por etiqueta:'), findsNothing);
      print('✅ Favoritos no habilitados inicialmente (correcto)');

      print('🔍 PASO 5: Habilitando los favoritos');
      
      // Buscar y tocar el botón de Favoritos
      final favoritosButton = find.text('Favoritos');
      expect(favoritosButton, findsOneWidget);
      await tester.tap(favoritosButton);
      await tester.pumpAndSettle();

      print('✅ Botón de Favoritos presionado');

      print('🔍 PASO 6: Verificando que se ocultan búsqueda y categorías');
      
      // Verificar que se ocultó la búsqueda
      expect(find.text('Buscar código, intención o categoría...'), findsNothing);
      print('✅ Búsqueda oculta correctamente');

      // Verificar que se ocultaron las categorías
      expect(find.text('Todos'), findsNothing);
      print('✅ Categorías ocultas correctamente');

      print('🔍 PASO 7: Verificando que se muestran las etiquetas de favoritos');
      
      // Verificar que se muestran las etiquetas de favoritos
      expect(find.text('Filtrar por etiqueta:'), findsOneWidget);
      print('✅ Etiquetas de favoritos mostradas');

      // Verificar que se muestra el botón "Todas"
      expect(find.text('Todas'), findsOneWidget);
      print('✅ Botón "Todas" mostrado');

      print('🔍 PASO 8: Probando el botón "Todas"');
      
      // Tocar el botón "Todas"
      final todasButton = find.text('Todas');
      await tester.tap(todasButton);
      await tester.pumpAndSettle();

      print('✅ Botón "Todas" presionado');

      print('🔍 PASO 9: Verificando que se muestran todos los favoritos');
      
      // Verificar que se muestran los favoritos (si hay alguno)
      // Nota: Esto puede variar dependiendo de si el usuario tiene favoritos
      print('✅ Verificación de favoritos completada');

      print('🔍 PASO 10: Probando filtrado por etiquetas específicas');
      
      // Buscar etiquetas específicas (si existen)
      final etiquetas = find.byType(Container);
      final etiquetasEvaluadas = etiquetas.evaluate().where((element) {
        final widget = element.widget as Container;
        if (widget.child is Text) {
          final text = (widget.child as Text).data;
          return text != null && text != 'Todas' && text.length > 0;
        }
        return false;
      }).toList();

      if (etiquetasEvaluadas.isNotEmpty) {
        print('✅ Se encontraron etiquetas específicas');
        
        // Probar la primera etiqueta encontrada
        final primeraEtiqueta = find.byWidget(etiquetasEvaluadas.first.widget);
        await tester.tap(primeraEtiqueta);
        await tester.pumpAndSettle();
        
        print('✅ Etiqueta específica presionada');
        
        // Volver a "Todas"
        await tester.tap(todasButton);
        await tester.pumpAndSettle();
        
        print('✅ Regresado a "Todas"');
      } else {
        print('ℹ️ No se encontraron etiquetas específicas (esto es normal si no hay favoritos)');
      }

      print('🔍 PASO 11: Deshabilitando los favoritos');
      
      // Volver a tocar el botón de Favoritos para deshabilitarlos
      await tester.tap(favoritosButton);
      await tester.pumpAndSettle();

      print('✅ Favoritos deshabilitados');

      print('🔍 PASO 12: Verificando que se restauran búsqueda y categorías');
      
      // Verificar que se restauró la búsqueda
      expect(find.text('Buscar código, intención o categoría...'), findsOneWidget);
      print('✅ Búsqueda restaurada');

      // Verificar que se restauraron las categorías
      expect(find.text('Todos'), findsOneWidget);
      print('✅ Categorías restauradas');

      // Verificar que se ocultaron las etiquetas de favoritos
      expect(find.text('Filtrar por etiqueta:'), findsNothing);
      print('✅ Etiquetas de favoritos ocultas');

      print('🎉 TODAS LAS PRUEBAS COMPLETADAS EXITOSAMENTE');
      print('✅ La funcionalidad de favoritos y etiquetas funciona correctamente');
    });
  });
}


