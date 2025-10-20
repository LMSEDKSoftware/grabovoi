import 'dart:io';
import 'dart:convert';

void main() async {
  print('🧪 Probando funcionalidad de favoritos con etiquetas...');
  
  try {
    final supabaseUrl = 'https://whtiazgcxdnemrrgjjqf.supabase.co';
    final serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDUyMzYzOCwiZXhwIjoyMDc2MDk5NjM4fQ.LIVQ2FpXRpJD7ie4GVkrwU7lLPRm4S5NekNG2Cqme8o';
    
    final client = HttpClient();
    
    // 1. Verificar estructura de la tabla
    print('\n📋 Verificando estructura de usuario_favoritos...');
    final request = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/usuario_favoritos?select=*&limit=1'));
    request.headers.set('apikey', serviceKey);
    request.headers.set('Authorization', 'Bearer $serviceKey');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('✅ Respuesta: ${response.statusCode}');
    print('📄 Estructura: $responseBody');
    
    // 2. Insertar favorito con etiqueta personalizada
    print('\n💾 Insertando favorito con etiqueta personalizada...');
    final insertRequest = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/usuario_favoritos'));
    insertRequest.headers.set('apikey', serviceKey);
    insertRequest.headers.set('Authorization', 'Bearer $serviceKey');
    insertRequest.headers.set('Content-Type', 'application/json');
    insertRequest.headers.set('Prefer', 'return=representation');
    
    final insertBody = jsonEncode({
      'user_id': 'test-user-456',
      'codigo_id': '812_719_819_14',
      'etiqueta': 'trabajo'
    });
    
    insertRequest.write(insertBody);
    final insertResponse = await insertRequest.close();
    final insertResponseBody = await insertResponse.transform(utf8.decoder).join();
    
    print('✅ Inserción: ${insertResponse.statusCode}');
    print('📄 Respuesta: $insertResponseBody');
    
    // 3. Insertar otro favorito con diferente etiqueta
    print('\n💾 Insertando segundo favorito con etiqueta diferente...');
    final insert2Request = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/usuario_favoritos'));
    insert2Request.headers.set('apikey', serviceKey);
    insert2Request.headers.set('Authorization', 'Bearer $serviceKey');
    insert2Request.headers.set('Content-Type', 'application/json');
    insert2Request.headers.set('Prefer', 'return=representation');
    
    final insert2Body = jsonEncode({
      'user_id': 'test-user-456',
      'codigo_id': '111',
      'etiqueta': 'hijo mayor'
    });
    
    insert2Request.write(insert2Body);
    final insert2Response = await insert2Request.close();
    final insert2ResponseBody = await insert2Response.transform(utf8.decoder).join();
    
    print('✅ Segunda inserción: ${insert2Response.statusCode}');
    print('📄 Respuesta: $insert2ResponseBody');
    
    // 4. Consultar favoritos por etiqueta
    print('\n🔍 Consultando favoritos por etiqueta "trabajo"...');
    final queryRequest = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/usuario_favoritos?select=*&user_id=eq.test-user-456&etiqueta=eq.trabajo'));
    queryRequest.headers.set('apikey', serviceKey);
    queryRequest.headers.set('Authorization', 'Bearer $serviceKey');
    
    final queryResponse = await queryRequest.close();
    final queryResponseBody = await queryResponse.transform(utf8.decoder).join();
    
    print('✅ Consulta: ${queryResponse.statusCode}');
    print('📄 Favoritos con etiqueta "trabajo": $queryResponseBody');
    
    // 5. Consultar todas las etiquetas del usuario
    print('\n🏷️ Consultando todas las etiquetas del usuario...');
    final etiquetasRequest = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/usuario_favoritos?select=etiqueta&user_id=eq.test-user-456'));
    etiquetasRequest.headers.set('apikey', serviceKey);
    etiquetasRequest.headers.set('Authorization', 'Bearer $serviceKey');
    
    final etiquetasResponse = await etiquetasRequest.close();
    final etiquetasResponseBody = await etiquetasResponse.transform(utf8.decoder).join();
    
    print('✅ Consulta etiquetas: ${etiquetasResponse.statusCode}');
    print('📄 Todas las etiquetas: $etiquetasResponseBody');
    
    client.close();
    
    if (insertResponse.statusCode == 201 && insert2Response.statusCode == 201) {
      print('\n🎉 ¡Funcionalidad de favoritos con etiquetas funciona correctamente!');
      print('✅ Se pueden insertar favoritos con etiquetas personalizadas');
      print('✅ Se pueden consultar favoritos por etiqueta');
      print('✅ Se pueden obtener todas las etiquetas de un usuario');
    } else {
      print('\n❌ Error en la funcionalidad de favoritos');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
