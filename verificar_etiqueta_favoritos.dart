import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔍 Verificando columna etiqueta en usuario_favoritos...');
  
  try {
    // Configuración de Supabase
    final supabaseUrl = 'https://whtiazgcxdnemrrgjjqf.supabase.co';
    final supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ1NzQ4NzMsImV4cCI6MjA1MDE1MDg3M30.5QqJ8QqJ8QqJ8QqJ8QqJ8QqJ8QqJ8QqJ8QqJ8QqJ8Q';
    
    // 1. Verificar estructura actual de la tabla
    print('\n📋 Verificando estructura actual...');
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/usuario_favoritos?select=*&limit=1'));
    request.headers.set('apikey', supabaseKey);
    request.headers.set('Authorization', 'Bearer $supabaseKey');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('✅ Respuesta de Supabase: ${response.statusCode}');
    if (response.statusCode == 200) {
      print('📄 Estructura actual: $responseBody');
    } else {
      print('❌ Error: $responseBody');
    }
    
    // 2. Intentar agregar la columna etiqueta
    print('\n🔧 Agregando columna etiqueta...');
    final alterRequest = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/rpc/exec_sql'));
    alterRequest.headers.set('apikey', supabaseKey);
    alterRequest.headers.set('Authorization', 'Bearer $supabaseKey');
    alterRequest.headers.set('Content-Type', 'application/json');
    
    final alterBody = jsonEncode({
      'sql': '''
        ALTER TABLE usuario_favoritos 
        ADD COLUMN IF NOT EXISTS etiqueta TEXT DEFAULT 'Favorito';
        
        CREATE INDEX IF NOT EXISTS idx_favoritos_etiqueta ON usuario_favoritos(etiqueta);
        
        UPDATE usuario_favoritos 
        SET etiqueta = 'Favorito' 
        WHERE etiqueta IS NULL;
      '''
    });
    
    alterRequest.write(alterBody);
    final alterResponse = await alterRequest.close();
    final alterResponseBody = await alterResponse.transform(utf8.decoder).join();
    
    print('✅ Alteración: ${alterResponse.statusCode}');
    print('📄 Respuesta: $alterResponseBody');
    
    // 3. Verificar que la columna se agregó
    print('\n🔍 Verificando nueva estructura...');
    final verifyRequest = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/usuario_favoritos?select=*&limit=1'));
    verifyRequest.headers.set('apikey', supabaseKey);
    verifyRequest.headers.set('Authorization', 'Bearer $supabaseKey');
    
    final verifyResponse = await verifyRequest.close();
    final verifyResponseBody = await verifyResponse.transform(utf8.decoder).join();
    
    print('✅ Verificación: ${verifyResponse.statusCode}');
    print('📄 Nueva estructura: $verifyResponseBody');
    
    client.close();
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
