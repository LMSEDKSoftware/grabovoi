import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 PRUEBA DE CONECTIVIDAD DNS');
  print('============================');
  
  // 1. Probar resolución DNS básica
  print('\n1. Probando resolución DNS...');
  try {
    final addresses = await InternetAddress.lookup('whtiazgcxdnemrrgjjqf.supabase.co');
    print('✅ DNS resuelto correctamente:');
    for (final addr in addresses) {
      print('   ${addr.address} (${addr.type.name})');
    }
  } catch (e) {
    print('❌ Error de DNS: $e');
  }
  
  // 2. Probar ping (si está disponible)
  print('\n2. Probando conectividad...');
  try {
    final result = await Process.run('ping', ['-c', '3', 'whtiazgcxdnemrrgjjqf.supabase.co']);
    if (result.exitCode == 0) {
      print('✅ Ping exitoso');
      print(result.stdout);
    } else {
      print('❌ Ping falló: ${result.stderr}');
    }
  } catch (e) {
    print('⚠️ Ping no disponible: $e');
  }
  
  // 3. Probar HTTP request
  print('\n3. Probando HTTP request...');
  try {
    final uri = Uri.https(
      'whtiazgcxdnemrrgjjqf.supabase.co',
      '/functions/v1/get-categorias',
    );
    
    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1MjM2MzgsImV4cCI6MjA3NjA5OTYzOH0.1CFkusMrMKcvSU_-5RyGYPoKDM_yizuQMVGo7W3mXHU',
    });
    
    print('✅ HTTP request exitoso: ${response.statusCode}');
    print('📄 Respuesta: ${response.body}');
  } catch (e) {
    print('❌ Error HTTP: $e');
  }
  
  print('\n🏁 Prueba completada');
}
