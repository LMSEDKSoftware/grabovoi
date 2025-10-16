import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Script para exportar todos los códigos desde Supabase
/// Ejecutar: dart lib/scripts/export_codes_from_supabase.dart
void main() async {
  print('🚀 Exportando códigos desde Supabase...');
  
  const String supabaseUrl = 'https://whtiazgcxdnemrrgjjqf.supabase.co/functions/v1';
  const String apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1MjM2MzgsImV4cCI6MjA3NjA5OTYzOH0.1CFkusMrMKcvSU_-5RyGYPoKDM_yizuQMVGo7W3mXHU';
  
  try {
    // 1. Obtener todos los códigos
    print('📡 Obteniendo códigos...');
    final response = await http.get(
      Uri.parse('$supabaseUrl/get-codigos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
    }

    final data = json.decode(response.body);
    if (data['success'] != true) {
      throw Exception('Error API: ${data['error']}');
    }

    final codigos = data['data'] as List;
    print('✅ Códigos obtenidos: ${codigos.length}');

    // 2. Limpiar y formatear datos
    final codigosLimpios = codigos.map((codigo) {
      return {
        'id': codigo['id']?.toString() ?? '',
        'codigo': codigo['codigo']?.toString() ?? '',
        'nombre': codigo['nombre']?.toString() ?? '',
        'descripcion': codigo['descripcion']?.toString() ?? '',
        'categoria': codigo['categoria']?.toString() ?? 'General',
        'color': codigo['color']?.toString() ?? '#FFD700',
        'created_at': codigo['created_at']?.toString() ?? DateTime.now().toIso8601String(),
        'updated_at': codigo['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
      };
    }).toList();

    // 3. Guardar en archivo
    final jsonString = const JsonEncoder.withIndent('  ').convert(codigosLimpios);
    final file = File('codigos_completos.json');
    await file.writeAsString(jsonString);

    print('✅ Archivo guardado: ${file.path}');
    print('📊 Total códigos exportados: ${codigosLimpios.length}');
    
    // 4. Mostrar estadísticas
    final categorias = codigosLimpios.map((c) => c['categoria']).toSet().toList();
    print('📋 Categorías encontradas: ${categorias.length}');
    for (final categoria in categorias) {
      final count = codigosLimpios.where((c) => c['categoria'] == categoria).length;
      print('   • $categoria: $count códigos');
    }

    print('🎉 Exportación completada exitosamente!');
    print('📁 Archivo: ${file.absolute.path}');
    
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}
