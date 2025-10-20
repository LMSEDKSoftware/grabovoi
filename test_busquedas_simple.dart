import 'dart:convert';
import 'dart:io';

/// Script simple para probar la conexión a Supabase sin Flutter
Future<void> main() async {
  print('🚀 Probando conexión a Supabase...');
  
  // Configuración de Supabase
  const String supabaseUrl = 'https://whtiazgcxdnemrrgjjqf.supabase.co';
  const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDUyMzYzOCwiZXhwIjoyMDc2MDk5NjM4fQ.LIVQ2FpXRpJD7ie4GVkrwU7lLPRm4S5NekNG2Cqme8o';
  
  try {
    // Crear datos de prueba
    final busquedaEjemplo = {
      'codigo_buscado': '52183',
      'usuario_id': 'test-user-123',
      'prompt_system': 'Eres un experto en códigos numéricos de Grigori Grabovoi...',
      'prompt_user': 'Analiza el código numérico de Grabovoi: 52183...',
      'respuesta_ia': '{"nombre": "Transformación Personal", "descripcion": "Código para transformación personal profunda", "categoria": "Reprogramacion"}',
      'codigo_encontrado': true,
      'codigo_guardado': true,
      'fecha_busqueda': DateTime.now().toIso8601String(),
      'duracion_ms': 2500,
      'modelo_ia': 'gpt-3.5-turbo',
      'tokens_usados': 150,
      'costo_estimado': 0.000225,
    };
    
    print('📝 Datos de prueba:');
    print('   Código: ${busquedaEjemplo['codigo_buscado']}');
    print('   Usuario: ${busquedaEjemplo['usuario_id']}');
    print('   Fecha: ${busquedaEjemplo['fecha_busqueda']}');
    
    // Hacer petición HTTP a Supabase
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/busquedas_profundas'));
    
    // Configurar headers
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('apikey', supabaseKey);
    request.headers.set('Authorization', 'Bearer $supabaseKey');
    request.headers.set('Prefer', 'return=representation');
    
    // Enviar datos
    final jsonData = jsonEncode(busquedaEjemplo);
    print('📤 JSON enviado: $jsonData');
    request.write(jsonData);
    
    print('\n🌐 Enviando petición a Supabase...');
    final response = await request.close();
    
    print('📊 Respuesta del servidor:');
    print('   Status Code: ${response.statusCode}');
    print('   Headers: ${response.headers}');
    
    // Leer respuesta
    final responseBody = await response.transform(utf8.decoder).join();
    print('   Body: $responseBody');
    
    if (response.statusCode == 201) {
      print('\n✅ ¡Búsqueda insertada exitosamente!');
      
      // Probar consulta
      print('\n🔍 Probando consulta...');
      await _probarConsulta(supabaseUrl, supabaseKey);
      
    } else {
      print('\n❌ Error al insertar búsqueda');
      print('   Código de error: ${response.statusCode}');
      print('   Mensaje: $responseBody');
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Error en la prueba: $e');
    print('🔍 Verifica que:');
    print('   1. La tabla busquedas_profundas existe en Supabase');
    print('   2. Las credenciales de Supabase son correctas');
    print('   3. El servicio role key tiene permisos para insertar');
  }
}

Future<void> _probarConsulta(String supabaseUrl, String supabaseKey) async {
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/busquedas_profundas?select=*&order=fecha_busqueda.desc&limit=5'));
    
    // Configurar headers
    request.headers.set('apikey', supabaseKey);
    request.headers.set('Authorization', 'Bearer $supabaseKey');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('📊 Consulta exitosa:');
    print('   Status Code: ${response.statusCode}');
    print('   Datos: $responseBody');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody) as List;
      print('   Total registros: ${data.length}');
      
      for (var item in data) {
        print('   - ${item['codigo_buscado']} (${item['fecha_busqueda']}) - ${item['codigo_encontrado'] ? "✅" : "❌"}');
      }
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Error en la consulta: $e');
  }
}
