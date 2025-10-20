import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔍 Verificando códigos existentes en la base de datos...');
  
  try {
    final supabaseUrl = 'https://whtiazgcxdnemrrgjjqf.supabase.co';
    final serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDUyMzYzOCwiZXhwIjoyMDc2MDk5NjM4fQ.LIVQ2FpXRpJD7ie4GVkrwU7lLPRm4S5NekNG2Cqme8o';
    
    final client = HttpClient();
    
    // 1. Obtener algunos códigos de la tabla codigos_grabovoi
    print('\n📋 Obteniendo códigos de la tabla codigos_grabovoi...');
    final request = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/codigos_grabovoi?select=id,codigo,nombre&limit=10'));
    request.headers.set('apikey', serviceKey);
    request.headers.set('Authorization', 'Bearer $serviceKey');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('✅ Respuesta: ${response.statusCode}');
    if (response.statusCode == 200) {
      final List<dynamic> codigos = jsonDecode(responseBody);
      print('📄 Códigos encontrados: ${codigos.length}');
      
      for (final codigo in codigos.take(5)) {
        print('   - ID: ${codigo['id']}, Código: ${codigo['codigo']}, Nombre: ${codigo['nombre']}');
      }
      
      if (codigos.isNotEmpty) {
        // 2. Probar agregar el primer código a favoritos
        final primerCodigo = codigos.first;
        final codigoId = primerCodigo['id'];
        
        print('\n💾 Probando agregar código $codigoId a favoritos...');
        final insertRequest = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/usuario_favoritos'));
        insertRequest.headers.set('apikey', serviceKey);
        insertRequest.headers.set('Authorization', 'Bearer $serviceKey');
        insertRequest.headers.set('Content-Type', 'application/json');
        insertRequest.headers.set('Prefer', 'return=representation');
        
        final insertBody = jsonEncode({
          'user_id': 'test-user-verificacion',
          'codigo_id': codigoId,
          'etiqueta': 'verificacion'
        });
        
        insertRequest.write(insertBody);
        final insertResponse = await insertRequest.close();
        final insertResponseBody = await insertResponse.transform(utf8.decoder).join();
        
        print('✅ Inserción: ${insertResponse.statusCode}');
        print('📄 Respuesta: $insertResponseBody');
        
        if (insertResponse.statusCode == 201) {
          print('\n🎉 ¡Los códigos existen y se pueden agregar a favoritos correctamente!');
        } else {
          print('\n❌ Error al agregar a favoritos');
        }
      }
    } else {
      print('❌ Error obteniendo códigos: $responseBody');
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
