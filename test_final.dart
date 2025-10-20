import 'dart:convert';
import 'dart:io';

/// Script final para probar la tabla
Future<void> main() async {
  print('🚀 Prueba final de la tabla busquedas_profundas...');
  
  const String supabaseUrl = 'https://whtiazgcxdnemrrgjjqf.supabase.co';
  const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDUyMzYzOCwiZXhwIjoyMDc2MDk5NjM4fQ.LIVQ2FpXRpJD7ie4GVkrwU7lLPRm4S5NekNG2Cqme8o';
  
  try {
    // 1. Consultar registros existentes
    print('\n1️⃣ Consultando registros existentes...');
    await _consultarRegistros(supabaseUrl, supabaseKey);
    
    // 2. Insertar un registro simple
    print('\n2️⃣ Insertando registro simple...');
    await _insertarSimple(supabaseUrl, supabaseKey);
    
    // 3. Consultar nuevamente
    print('\n3️⃣ Consultando después de inserción...');
    await _consultarRegistros(supabaseUrl, supabaseKey);
    
    print('\n🎉 ¡Prueba completada exitosamente!');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}

Future<void> _consultarRegistros(String supabaseUrl, String supabaseKey) async {
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/busquedas_profundas?select=*&order=id.desc&limit=5'));
    
    request.headers.set('apikey', supabaseKey);
    request.headers.set('Authorization', 'Bearer $supabaseKey');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('📊 Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody) as List;
      print('📋 Total registros: ${data.length}');
      
      for (var item in data) {
        print('   ID: ${item['id']} | Código: ${item['codigo_buscado']} | Encontrado: ${item['codigo_encontrado']} | Fecha: ${item['fecha_busqueda']}');
      }
    } else {
      print('❌ Error en consulta: $responseBody');
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Error consultando: $e');
  }
}

Future<void> _insertarSimple(String supabaseUrl, String supabaseKey) async {
  try {
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/busquedas_profundas'));
    
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('apikey', supabaseKey);
    request.headers.set('Authorization', 'Bearer $supabaseKey');
    request.headers.set('Prefer', 'return=representation');
    
    // Datos muy simples
    final datos = {
      'codigo_buscado': '111',
      'prompt_system': 'Test system prompt',
      'prompt_user': 'Test user prompt',
      'fecha_busqueda': DateTime.now().toIso8601String(),
      'codigo_encontrado': true,
      'codigo_guardado': false,
      'duracion_ms': 1500,
      'modelo_ia': 'gpt-3.5-turbo',
      'tokens_usados': 100,
      'costo_estimado': 0.00015,
    };
    
    final jsonData = jsonEncode(datos);
    print('📤 Enviando: $jsonData');
    request.write(jsonData);
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('📊 Status: ${response.statusCode}');
    print('📊 Response: $responseBody');
    
    if (response.statusCode == 201) {
      print('✅ Inserción exitosa');
    } else {
      print('❌ Error en inserción');
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Error insertando: $e');
  }
}
