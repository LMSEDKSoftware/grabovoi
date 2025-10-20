import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔍 Verificando estructura de las tablas...');
  
  try {
    final supabaseUrl = 'https://whtiazgcxdnemrrgjjqf.supabase.co';
    final serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDUyMzYzOCwiZXhwIjoyMDc2MDk5NjM4fQ.LIVQ2FpXRpJD7ie4GVkrwU7lLPRm4S5NekNG2Cqme8o';
    
    final client = HttpClient();
    
    // 1. Verificar estructura de codigos_grabovoi
    print('\n📋 Estructura de codigos_grabovoi...');
    final codigosRequest = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/codigos_grabovoi?select=id,codigo,nombre&limit=3'));
    codigosRequest.headers.set('apikey', serviceKey);
    codigosRequest.headers.set('Authorization', 'Bearer $serviceKey');
    
    final codigosResponse = await codigosRequest.close();
    final codigosBody = await codigosResponse.transform(utf8.decoder).join();
    
    print('✅ Códigos: ${codigosResponse.statusCode}');
    print('📄 Estructura: $codigosBody');
    
    // 2. Verificar estructura de usuario_favoritos
    print('\n📋 Estructura de usuario_favoritos...');
    final favoritosRequest = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/usuario_favoritos?select=*&limit=3'));
    favoritosRequest.headers.set('apikey', serviceKey);
    favoritosRequest.headers.set('Authorization', 'Bearer $serviceKey');
    
    final favoritosResponse = await favoritosRequest.close();
    final favoritosBody = await favoritosResponse.transform(utf8.decoder).join();
    
    print('✅ Favoritos: ${favoritosResponse.statusCode}');
    print('📄 Estructura: $favoritosBody');
    
    // 3. Probar insertar con el ID correcto
    if (codigosResponse.statusCode == 200) {
      final List<dynamic> codigos = jsonDecode(codigosBody);
      if (codigos.isNotEmpty) {
        final primerCodigo = codigos.first;
        final codigoId = primerCodigo['id']; // Este es el UUID correcto
        
        print('\n💾 Probando insertar con ID correcto: $codigoId');
        final insertRequest = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/usuario_favoritos'));
        insertRequest.headers.set('apikey', serviceKey);
        insertRequest.headers.set('Authorization', 'Bearer $serviceKey');
        insertRequest.headers.set('Content-Type', 'application/json');
        insertRequest.headers.set('Prefer', 'return=representation');
        
        final insertBody = jsonEncode({
          'user_id': 'test-user-estructura',
          'codigo_id': codigoId, // Usar el UUID, no el código
          'etiqueta': 'estructura'
        });
        
        insertRequest.write(insertBody);
        final insertResponse = await insertRequest.close();
        final insertResponseBody = await insertResponse.transform(utf8.decoder).join();
        
        print('✅ Inserción: ${insertResponse.statusCode}');
        print('📄 Respuesta: $insertResponseBody');
        
        if (insertResponse.statusCode == 201) {
          print('\n🎉 ¡La estructura es correcta! El problema es que la app usa el código en lugar del ID');
        }
      }
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
