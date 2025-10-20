import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔍 Probando foreign key corregida...');
  
  try {
    final supabaseUrl = 'https://whtiazgcxdnemrrgjjqf.supabase.co';
    final serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDUyMzYzOCwiZXhwIjoyMDc2MDk5NjM4fQ.LIVQ2FpXRpJD7ie4GVkrwU7lLPRm4S5NekNG2Cqme8o';
    
    final client = HttpClient();
    
    // 1. Obtener un código existente
    print('\n📋 Obteniendo código existente...');
    final codigosRequest = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/codigos_grabovoi?select=codigo&limit=1'));
    codigosRequest.headers.set('apikey', serviceKey);
    codigosRequest.headers.set('Authorization', 'Bearer $serviceKey');
    
    final codigosResponse = await codigosRequest.close();
    final codigosBody = await codigosResponse.transform(utf8.decoder).join();
    
    if (codigosResponse.statusCode == 200) {
      final List<dynamic> codigos = jsonDecode(codigosBody);
      if (codigos.isNotEmpty) {
        final codigo = codigos.first['codigo'];
        print('✅ Código encontrado: $codigo');
        
        // 2. Probar insertar con el código (no el ID)
        print('\n💾 Probando insertar con código: $codigo');
        final insertRequest = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/usuario_favoritos'));
        insertRequest.headers.set('apikey', serviceKey);
        insertRequest.headers.set('Authorization', 'Bearer $serviceKey');
        insertRequest.headers.set('Content-Type', 'application/json');
        insertRequest.headers.set('Prefer', 'return=representation');
        
        final insertBody = jsonEncode({
          'user_id': 'test-user-foreign-key',
          'codigo_id': codigo, // Usar el código, no el ID
          'etiqueta': 'foreign-key-test'
        });
        
        insertRequest.write(insertBody);
        final insertResponse = await insertRequest.close();
        final insertResponseBody = await insertResponse.transform(utf8.decoder).join();
        
        print('✅ Inserción: ${insertResponse.statusCode}');
        print('📄 Respuesta: $insertResponseBody');
        
        if (insertResponse.statusCode == 201) {
          print('\n🎉 ¡Foreign key corregida! Ahora funciona con códigos');
        } else {
          print('\n❌ Aún hay problemas con la foreign key');
          print('💡 Necesitas ejecutar el SQL en Supabase:');
          print('''
            ALTER TABLE usuario_favoritos 
            DROP CONSTRAINT IF EXISTS usuario_favoritos_codigo_id_fkey;
            
            ALTER TABLE usuario_favoritos 
            ADD CONSTRAINT usuario_favoritos_codigo_id_fkey 
            FOREIGN KEY (codigo_id) REFERENCES codigos_grabovoi(codigo);
          ''');
        }
      }
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
