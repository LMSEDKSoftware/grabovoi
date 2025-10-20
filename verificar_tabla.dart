import 'dart:convert';
import 'dart:io';

/// Script para verificar si la tabla existe y probar la conexión
Future<void> main() async {
  print('🔍 Verificando tabla busquedas_profundas...');
  
  // Configuración de Supabase
  const String supabaseUrl = 'https://whtiazgcxdnemrrgjjqf.supabase.co';
  const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDUyMzYzOCwiZXhwIjoyMDc2MDk5NjM4fQ.LIVQ2FpXRpJD7ie4GVkrwU7lLPRm4S5NekNG2Cqme8o';
  
  try {
    // 1. Verificar si la tabla existe consultando el schema
    print('\n1️⃣ Verificando schema de la tabla...');
    await _verificarSchema(supabaseUrl, supabaseKey);
    
    // 2. Intentar hacer una consulta simple
    print('\n2️⃣ Probando consulta simple...');
    await _probarConsulta(supabaseUrl, supabaseKey);
    
    // 3. Intentar insertar un dato simple
    print('\n3️⃣ Probando inserción simple...');
    await _probarInsercion(supabaseUrl, supabaseKey);
    
  } catch (e) {
    print('❌ Error: $e');
  }
}

Future<void> _verificarSchema(String supabaseUrl, String supabaseKey) async {
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/information_schema.tables?table_name=eq.busquedas_profundas'));
    
    request.headers.set('apikey', supabaseKey);
    request.headers.set('Authorization', 'Bearer $supabaseKey');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('📊 Respuesta schema:');
    print('   Status: ${response.statusCode}');
    print('   Body: $responseBody');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody) as List;
      if (data.isNotEmpty) {
        print('✅ Tabla busquedas_profundas existe');
      } else {
        print('❌ Tabla busquedas_profundas NO existe');
      }
    }
    
  } catch (e) {
    print('❌ Error verificando schema: $e');
  }
}

Future<void> _probarConsulta(String supabaseUrl, String supabaseKey) async {
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/busquedas_profundas?select=count'));
    
    request.headers.set('apikey', supabaseKey);
    request.headers.set('Authorization', 'Bearer $supabaseKey');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('📊 Respuesta consulta:');
    print('   Status: ${response.statusCode}');
    print('   Body: $responseBody');
    
    if (response.statusCode == 200) {
      print('✅ Consulta exitosa - tabla accesible');
    } else {
      print('❌ Error en consulta');
    }
    
  } catch (e) {
    print('❌ Error en consulta: $e');
  }
}

Future<void> _probarInsercion(String supabaseUrl, String supabaseKey) async {
  try {
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/busquedas_profundas'));
    
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('apikey', supabaseKey);
    request.headers.set('Authorization', 'Bearer $supabaseKey');
    request.headers.set('Prefer', 'return=representation');
    
    // Datos mínimos para la inserción
    final datosMinimos = {
      'codigo_buscado': 'test-123',
      'prompt_system': 'test system prompt',
      'prompt_user': 'test user prompt',
      'fecha_busqueda': DateTime.now().toIso8601String(),
    };
    
    final jsonData = jsonEncode(datosMinimos);
    print('📤 JSON mínimo: $jsonData');
    request.write(jsonData);
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('📊 Respuesta inserción:');
    print('   Status: ${response.statusCode}');
    print('   Body: $responseBody');
    
    if (response.statusCode == 201) {
      print('✅ Inserción exitosa');
    } else {
      print('❌ Error en inserción');
    }
    
  } catch (e) {
    print('❌ Error en inserción: $e');
  }
}
