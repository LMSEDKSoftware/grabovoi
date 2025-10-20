import 'dart:io';
import 'dart:convert';

void main() async {
  print('🧪 Probando funcionalidad de favoritos con etiquetas...');
  
  try {
    final supabaseUrl = 'https://whtiazgcxdnemrrgjjqf.supabase.co';
    final serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDUyMzYzOCwiZXhwIjoyMDc2MDk5NjM4fQ.LIVQ2FpXRpJD7ie4GVkrwU7lLPRm4S5NekNG2Cqme8o';
    
    final client = HttpClient();
    
    // 1. Obtener un código existente
    print('\n📋 Obteniendo código existente...');
    final codigosRequest = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/codigos_grabovoi?select=codigo,nombre&limit=1'));
    codigosRequest.headers.set('apikey', serviceKey);
    codigosRequest.headers.set('Authorization', 'Bearer $serviceKey');
    
    final codigosResponse = await codigosRequest.close();
    final codigosBody = await codigosResponse.transform(utf8.decoder).join();
    
    if (codigosResponse.statusCode == 200) {
      final List<dynamic> codigos = jsonDecode(codigosBody);
      if (codigos.isNotEmpty) {
        final codigo = codigos.first;
        final codigoString = codigo['codigo'];
        final nombre = codigo['nombre'];
        
        print('✅ Código encontrado: $codigoString - $nombre');
        
        // 2. Probar insertar con etiqueta personalizada
        print('\n💾 Probando insertar con etiqueta personalizada...');
        final insertRequest = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/usuario_favoritos'));
        insertRequest.headers.set('apikey', serviceKey);
        insertRequest.headers.set('Authorization', 'Bearer $serviceKey');
        insertRequest.headers.set('Content-Type', 'application/json');
        insertRequest.headers.set('Prefer', 'return=representation');
        
        final insertBody = jsonEncode({
          'user_id': 'test-user-dialogo',
          'codigo_id': codigoString,
          'etiqueta': 'trabajo personal'
        });
        
        insertRequest.write(insertBody);
        final insertResponse = await insertRequest.close();
        final insertResponseBody = await insertResponse.transform(utf8.decoder).join();
        
        print('✅ Inserción: ${insertResponse.statusCode}');
        print('📄 Respuesta: $insertResponseBody');
        
        if (insertResponse.statusCode == 201) {
          print('\n🎉 ¡Funcionalidad de favoritos con etiquetas funciona correctamente!');
          print('✅ Se puede agregar códigos a favoritos con etiquetas personalizadas');
          print('✅ El diálogo debería aparecer en la app');
        } else {
          print('\n❌ Error al agregar a favoritos');
        }
        
        // 3. Probar consultar favoritos por etiqueta
        print('\n🔍 Probando consulta por etiqueta...');
        final queryRequest = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/usuario_favoritos?select=*&user_id=eq.test-user-dialogo&etiqueta=eq.trabajo personal'));
        queryRequest.headers.set('apikey', serviceKey);
        queryRequest.headers.set('Authorization', 'Bearer $serviceKey');
        
        final queryResponse = await queryRequest.close();
        final queryResponseBody = await queryResponse.transform(utf8.decoder).join();
        
        print('✅ Consulta: ${queryResponse.statusCode}');
        print('📄 Favoritos con etiqueta "trabajo personal": $queryResponseBody');
      }
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
