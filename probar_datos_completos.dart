import 'dart:convert';
import 'dart:io';

/// Script para probar inserción de datos completos
Future<void> main() async {
  print('🚀 Probando inserción de datos completos...');
  
  // Configuración de Supabase
  const String supabaseUrl = 'https://whtiazgcxdnemrrgjjqf.supabase.co';
  const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDUyMzYzOCwiZXhwIjoyMDc2MDk5NjM4fQ.LIVQ2FpXRpJD7ie4GVkrwU7lLPRm4S5NekNG2Cqme8o';
  
  try {
    // Crear datos completos de ejemplo
    final busquedaCompleta = {
      'codigo_buscado': '52183',
      'usuario_id': 'test-user-123',
      'prompt_system': 'Eres un experto en códigos numéricos de Grigori Grabovoi. Tu tarea es analizar códigos numéricos y proporcionar información útil. Responde SIEMPRE con un JSON válido que contenga: {"nombre": "Nombre del código", "descripcion": "Descripción detallada", "categoria": "Salud/Abundancia/Amor/Reprogramacion/Manifestacion"}. Si conoces el código específico, proporciona información detallada. Si no lo conoces específicamente, analiza el patrón numérico y proporciona una interpretación basada en la numerología de Grabovoi. NUNCA respondas con "null" o texto plano, siempre proporciona un JSON válido con información útil.',
      'prompt_user': 'Analiza el código numérico de Grabovoi: 52183. Si conoces este código específico, proporciona información detallada. Si no lo conoces, analiza el patrón numérico y proporciona una interpretación basada en los principios de Grabovoi sobre manifestación, sanación, transformación y reprogramación mental. Responde con un JSON válido que contenga nombre, descripción y categoría apropiada.',
      'respuesta_ia': '{"nombre": "Transformación Personal Profunda", "descripcion": "Código numérico para la transformación personal y el desarrollo del potencial interno. El patrón 52183 activa la capacidad de manifestación consciente y facilita el cambio de patrones mentales limitantes. Promueve la reprogramación mental y la conexión con el propósito superior.", "categoria": "Reprogramacion"}',
      'codigo_encontrado': true,
      'codigo_guardado': true,
      'fecha_busqueda': DateTime.now().toIso8601String(),
      'duracion_ms': 2500,
      'modelo_ia': 'gpt-3.5-turbo',
      'tokens_usados': 150,
      'costo_estimado': 0.000225,
    };
    
    print('📝 Datos completos:');
    print('   Código: ${busquedaCompleta['codigo_buscado']}');
    print('   Usuario: ${busquedaCompleta['usuario_id']}');
    print('   Encontrado: ${busquedaCompleta['codigo_encontrado']}');
    print('   Guardado: ${busquedaCompleta['codigo_guardado']}');
    print('   Duración: ${busquedaCompleta['duracion_ms']} ms');
    print('   Tokens: ${busquedaCompleta['tokens_usados']}');
    print('   Costo: \$${busquedaCompleta['costo_estimado']}');
    
    // Insertar datos
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/busquedas_profundas'));
    
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('apikey', supabaseKey);
    request.headers.set('Authorization', 'Bearer $supabaseKey');
    request.headers.set('Prefer', 'return=representation');
    
    final jsonData = jsonEncode(busquedaCompleta);
    request.write(jsonData);
    
    print('\n🌐 Enviando datos completos...');
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('📊 Respuesta:');
    print('   Status: ${response.statusCode}');
    print('   Body: $responseBody');
    
    if (response.statusCode == 201) {
      print('\n✅ ¡Datos insertados exitosamente!');
      
      // Consultar todos los datos
      print('\n🔍 Consultando todos los registros...');
      await _consultarTodos(supabaseUrl, supabaseKey);
      
    } else {
      print('\n❌ Error al insertar datos');
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Error: $e');
  }
}

Future<void> _consultarTodos(String supabaseUrl, String supabaseKey) async {
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/busquedas_profundas?select=*&order=fecha_busqueda.desc'));
    
    request.headers.set('apikey', supabaseKey);
    request.headers.set('Authorization', 'Bearer $supabaseKey');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody) as List;
      print('📊 Total de registros: ${data.length}');
      
      for (var item in data) {
        print('\n📋 Registro ${item['id']}:');
        print('   Código: ${item['codigo_buscado']}');
        print('   Usuario: ${item['usuario_id'] ?? 'N/A'}');
        print('   Fecha: ${item['fecha_busqueda']}');
        print('   Encontrado: ${item['codigo_encontrado'] ? "✅" : "❌"}');
        print('   Guardado: ${item['codigo_guardado'] ? "✅" : "❌"}');
        print('   Duración: ${item['duracion_ms'] ?? 'N/A'} ms');
        print('   Tokens: ${item['tokens_usados'] ?? 'N/A'}');
        print('   Costo: \$${item['costo_estimado'] ?? 'N/A'}');
        if (item['respuesta_ia'] != null) {
          print('   Respuesta IA: ${item['respuesta_ia'].toString().substring(0, 100)}...');
        }
      }
    } else {
      print('❌ Error en consulta: ${response.statusCode}');
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Error consultando: $e');
  }
}
