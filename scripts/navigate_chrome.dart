import 'dart:io';

void main() async {
  print('🌐 Navegando Chrome para verificar secciones...\n');
  
  // Abrir Chrome en la URL
  final result = await Process.run('open', ['-a', 'Google Chrome', 'http://localhost:8106']);
  
  if (result.exitCode == 0) {
    print('✅ Chrome abierto en http://localhost:8106');
    print('\n📋 INSTRUCCIONES PARA VERIFICAR:');
    print('1. Navega a la sección "Biblioteca" (segunda pestaña)');
    print('2. Verifica si se muestran los códigos o está vacía');
    print('3. Navega a la sección "Desafíos" (cuarta pestaña)');
    print('4. Verifica si se muestran los desafíos o está vacía');
    print('5. Navega a la sección "Pilotaje" (tercera pestaña)');
    print('6. Verifica si se muestra el contenido o está vacía');
    print('7. Navega a la sección "Evolución" (quinta pestaña)');
    print('8. Verifica si se muestra el contenido o está vacía');
    
    print('\n🔍 PROBLEMAS IDENTIFICADOS:');
    print('- Las secciones tienen Scaffold anidados (PROBLEMA)');
    print('- Esto causa errores de renderizado "Cannot hit test a render box with no size"');
    print('- Las secciones no se muestran correctamente');
    
    print('\n🔧 SOLUCIÓN NECESARIA:');
    print('- Remover Scaffold de las pantallas individuales');
    print('- Dejar solo el Scaffold principal en main.dart');
    print('- Asegurar que GlowBackground envuelva todo correctamente');
  } else {
    print('❌ Error abriendo Chrome: ${result.stderr}');
  }
}
