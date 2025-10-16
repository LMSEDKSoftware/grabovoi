import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  print('🔍 [TEST SIMPLE] ===========================================');
  print('🔍 [TEST SIMPLE] Iniciando test simple de conectividad');
  print('🔍 [TEST SIMPLE] Timestamp: ${DateTime.now()}');
  print('🔍 [TEST SIMPLE] ===========================================');
  
  // Test directo a Supabase
  try {
    print('\n🌐 [TEST] Probando conexión directa a Supabase...');
    final uri = Uri.parse('https://whtiazgcxdnemrrgjjqf.supabase.co/functions/v1/get-codigos');
    
    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1MjM2MzgsImV4cCI6MjA3NjA5OTYzOH0.1CFkusMrMKcvSU_-5RyGYPoKDM_yizuQMVGo7W3mXHU',
      'User-Agent': 'ManifestacionApp/1.0',
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 30));
    
    print('   Status: ${response.statusCode}');
    print('   Body length: ${response.body.length}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final codigos = data['data'] as List;
        print('✅ [TEST] ÉXITO: ${codigos.length} códigos obtenidos');
        print('✅ [TEST] Primer código: ${codigos.isNotEmpty ? codigos.first['nombre'] : 'N/A'}');
        print('✅ [TEST] La API funciona correctamente');
      } else {
        print('❌ [TEST] API Error: ${data['error']}');
      }
    } else {
      print('❌ [TEST] HTTP Error: ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('❌ [TEST] Error: $e');
    print('   Tipo: ${e.runtimeType}');
  }
  
  print('\n🔍 [TEST SIMPLE] ===========================================');
  print('🔍 [TEST SIMPLE] Test completado');
  print('🔍 [TEST SIMPLE] ===========================================');
}
