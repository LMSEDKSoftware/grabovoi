import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔍 Verificando si la columna etiqueta existe...');
  
  try {
    final supabaseUrl = 'https://whtiazgcxdnemrrgjjqf.supabase.co';
    final serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDUyMzYzOCwiZXhwIjoyMDc2MDk5NjM4fQ.LIVQ2FpXRpJD7ie4GVkrwU7lLPRm4S5NekNG2Cqme8o';
    
    final client = HttpClient();
    
    // Verificar estructura de la tabla
    print('\n📋 Verificando estructura de la tabla...');
    final request = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/usuario_favoritos?select=*&limit=1'));
    request.headers.set('apikey', serviceKey);
    request.headers.set('Authorization', 'Bearer $serviceKey');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('✅ Respuesta: ${response.statusCode}');
    print('📄 Estructura: $responseBody');
    
    // Intentar insertar un favorito con etiqueta
    print('\n🧪 Probando insertar favorito con etiqueta...');
    final insertRequest = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/usuario_favoritos'));
    insertRequest.headers.set('apikey', serviceKey);
    insertRequest.headers.set('Authorization', 'Bearer $serviceKey');
    insertRequest.headers.set('Content-Type', 'application/json');
    insertRequest.headers.set('Prefer', 'return=representation');
    
    final insertBody = jsonEncode({
      'user_id': 'test-user-123',
      'codigo_id': '111',
      'etiqueta': 'prueba'
    });
    
    insertRequest.write(insertBody);
    final insertResponse = await insertRequest.close();
    final insertResponseBody = await insertResponse.transform(utf8.decoder).join();
    
    print('✅ Inserción: ${insertResponse.statusCode}');
    print('📄 Respuesta: $insertResponseBody');
    
    client.close();
    
    if (insertResponse.statusCode == 201) {
      print('\n🎉 ¡Columna etiqueta existe y funciona correctamente!');
    } else if (insertResponse.statusCode == 400 && insertResponseBody.contains('etiqueta')) {
      print('\n❌ La columna etiqueta NO existe aún');
      print('💡 Ejecuta el SQL en el SQL Editor de Supabase');
    } else {
      print('\n❓ Estado incierto, verifica manualmente');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
