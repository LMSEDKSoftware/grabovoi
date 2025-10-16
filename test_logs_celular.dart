import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  print('🔍 [TEST CELULAR] ===========================================');
  print('🔍 [TEST CELULAR] INICIANDO TEST EN CELULAR');
  print('🔍 [TEST CELULAR] ===========================================');
  print('🔍 [TEST CELULAR] Timestamp: ${DateTime.now()}');
  print('🔍 [TEST CELULAR] Platform: ${Platform.operatingSystem}');
  print('🔍 [TEST CELULAR] ===========================================');
  
  // Test 1: Conectividad básica
  print('\n🌐 [TEST 1] VERIFICANDO CONECTIVIDAD BÁSICA...');
  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      print('✅ [TEST 1] Conectividad básica: OK');
      print('   IP Google: ${result[0].address}');
    } else {
      print('❌ [TEST 1] Conectividad básica: FALLO');
    }
  } catch (e) {
    print('❌ [TEST 1] Conectividad básica: ERROR - $e');
  }
  
  // Test 2: DNS Supabase
  print('\n🌐 [TEST 2] VERIFICANDO DNS SUPABASE...');
  try {
    final result = await InternetAddress.lookup('whtiazgcxdnemrrgjjqf.supabase.co');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      print('✅ [TEST 2] DNS Supabase: OK');
      print('   IP Supabase: ${result[0].address}');
    } else {
      print('❌ [TEST 2] DNS Supabase: FALLO');
    }
  } catch (e) {
    print('❌ [TEST 2] DNS Supabase: ERROR - $e');
  }
  
  // Test 3: HTTP directo a Supabase
  print('\n🌐 [TEST 3] VERIFICANDO HTTP DIRECTO A SUPABASE...');
  try {
    final uri = Uri.parse('https://whtiazgcxdnemrrgjjqf.supabase.co/functions/v1/get-codigos');
    print('   URL: $uri');
    
    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1MjM2MzgsImV4cCI6MjA3NjA5OTYzOH0.1CFkusMrMKcvSU_-5RyGYPoKDM_yizuQMVGo7W3mXHU',
      'User-Agent': 'ManifestacionApp/1.0',
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 30));
    
    print('   Status: ${response.statusCode}');
    print('   Body length: ${response.body.length}');
    print('   Headers: ${response.headers}');
    
    if (response.statusCode == 200) {
      print('✅ [TEST 3] HTTP Supabase: OK');
      try {
        final data = json.decode(response.body);
        print('   JSON Keys: ${data.keys.toList()}');
        if (data['success'] == true) {
          final codigos = data['data'] as List;
          print('   Códigos obtenidos: ${codigos.length}');
          print('✅ [TEST 3] API funcionando correctamente');
          print('   Primer código: ${codigos.isNotEmpty ? codigos.first['nombre'] : 'N/A'}');
        } else {
          print('❌ [TEST 3] API Error: ${data['error']}');
        }
      } catch (e) {
        print('❌ [TEST 3] JSON Error: $e');
        print('   Body preview: ${response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body}');
      }
    } else {
      print('❌ [TEST 3] HTTP Error: ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('❌ [TEST 3] HTTP Supabase: ERROR - $e');
    print('   Tipo de error: ${e.runtimeType}');
  }
  
  print('\n🔍 [TEST CELULAR] ===========================================');
  print('🔍 [TEST CELULAR] Test completado');
  print('🔍 [TEST CELULAR] ===========================================');
}
