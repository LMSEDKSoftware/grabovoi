import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  print('🔍 DEBUG: Verificando secciones de la aplicación...\n');
  
  // Verificar archivos de las secciones
  final sections = [
    'lib/screens/biblioteca/static_biblioteca_screen.dart',
    'lib/screens/desafios/desafios_screen.dart',
    'lib/screens/pilotaje/pilotaje_screen.dart',
    'lib/screens/evolucion/evolucion_screen.dart',
  ];
  
  for (final section in sections) {
    final file = File(section);
    if (await file.exists()) {
      print('✅ $section - EXISTE');
      
      // Leer contenido y verificar estructura
      final content = await file.readAsString();
      
      // Verificar si tiene Scaffold
      if (content.contains('Scaffold(')) {
        print('   📱 Tiene Scaffold');
      } else {
        print('   ❌ NO tiene Scaffold');
      }
      
      // Verificar si tiene GlowBackground
      if (content.contains('GlowBackground(')) {
        print('   ✨ Tiene GlowBackground');
      } else {
        print('   ❌ NO tiene GlowBackground');
      }
      
      // Verificar si tiene AppHeader
      if (content.contains('AppHeader(')) {
        print('   📋 Tiene AppHeader (PROBLEMA)');
      } else {
        print('   ✅ NO tiene AppHeader');
      }
      
      // Verificar si tiene Column principal
      if (content.contains('Column(')) {
        print('   📊 Tiene Column principal');
      } else {
        print('   ❌ NO tiene Column principal');
      }
      
    } else {
      print('❌ $section - NO EXISTE');
    }
    print('');
  }
  
  // Verificar main.dart
  print('🔍 Verificando main.dart...');
  final mainFile = File('lib/main.dart');
  if (await mainFile.exists()) {
    final content = await mainFile.readAsString();
    
    if (content.contains('GlowBackground(')) {
      print('✅ main.dart tiene GlowBackground');
    } else {
      print('❌ main.dart NO tiene GlowBackground');
    }
    
    if (content.contains('IndexedStack(')) {
      print('✅ main.dart tiene IndexedStack');
    } else {
      print('❌ main.dart NO tiene IndexedStack');
    }
    
    if (content.contains('Scaffold(')) {
      print('✅ main.dart tiene Scaffold');
    } else {
      print('❌ main.dart NO tiene Scaffold');
    }
  }
  
  print('\n🔍 Verificando errores de renderizado...');
  print('Los errores "Cannot hit test a render box with no size" indican:');
  print('- Widgets sin tamaño definido');
  print('- Problemas de layout en Column/Row');
  print('- Widgets anidados incorrectamente');
  print('- Falta de Expanded/Flexible en widgets flexibles');
  
  print('\n📋 DIAGNÓSTICO:');
  print('1. Las secciones existen pero pueden tener problemas de layout');
  print('2. Los errores de renderizado sugieren widgets mal estructurados');
  print('3. Necesitamos verificar la estructura de widgets en cada pantalla');
  print('4. Posible conflicto entre Scaffold anidados');
}
