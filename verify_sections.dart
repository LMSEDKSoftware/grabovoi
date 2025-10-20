import 'dart:io';

void main() async {
  print('🔍 VERIFICACIÓN DE SECCIONES CORREGIDAS\n');
  
  // Verificar que los Scaffold fueron removidos
  final sections = [
    'lib/screens/biblioteca/static_biblioteca_screen.dart',
    'lib/screens/desafios/desafios_screen.dart', 
    'lib/screens/pilotaje/pilotaje_screen.dart',
    'lib/screens/evolucion/evolucion_screen.dart',
  ];
  
  print('✅ VERIFICANDO CORRECCIONES:');
  for (final section in sections) {
    final file = File(section);
    if (await file.exists()) {
      final content = await file.readAsString();
      
      // Verificar que NO tiene Scaffold
      if (!content.contains('return Scaffold(')) {
        print('   ✅ $section - Scaffold removido correctamente');
      } else {
        print('   ❌ $section - AÚN tiene Scaffold');
      }
      
      // Verificar que tiene la estructura correcta
      if (content.contains('SingleChildScrollView(') || content.contains('SafeArea(')) {
        print('   ✅ $section - Estructura correcta');
      } else {
        print('   ❌ $section - Estructura incorrecta');
      }
    }
  }
  
  print('\n🌐 NAVEGANDO CHROME...');
  print('URL: http://localhost:8107');
  print('\n📋 INSTRUCCIONES PARA VERIFICAR:');
  print('1. Navega a "Biblioteca" - Debe mostrar 365 códigos');
  print('2. Navega a "Desafíos" - Debe mostrar desafíos disponibles');
  print('3. Navega a "Pilotaje" - Debe mostrar la esfera dorada');
  print('4. Navega a "Evolución" - Debe mostrar el nivel energético');
  print('5. Verifica que NO hay errores de renderizado en la consola');
  
  print('\n🎯 RESULTADO ESPERADO:');
  print('- ✅ Sin errores "Cannot hit test a render box with no size"');
  print('- ✅ Todas las secciones se muestran correctamente');
  print('- ✅ Navegación fluida entre secciones');
  print('- ✅ Contenido visible en cada pantalla');
  
  // Abrir Chrome
  await Process.run('open', ['-a', 'Google Chrome', 'http://localhost:8107']);
}
