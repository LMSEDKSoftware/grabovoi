import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔍 Creando columna etiqueta en usuario_favoritos...');
  
  try {
    // Configuración de Supabase con credenciales correctas
    final supabaseUrl = 'https://whtiazgcxdnemrrgjjqf.supabase.co';
    final serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDUyMzYzOCwiZXhwIjoyMDc2MDk5NjM4fQ.LIVQ2FpXRpJD7ie4GVkrwU7lLPRm4S5NekNG2Cqme8o';
    
    final client = HttpClient();
    
    // 1. Verificar estructura actual
    print('\n📋 Verificando estructura actual...');
    final request = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/usuario_favoritos?select=*&limit=1'));
    request.headers.set('apikey', serviceKey);
    request.headers.set('Authorization', 'Bearer $serviceKey');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('✅ Respuesta: ${response.statusCode}');
    if (response.statusCode == 200) {
      print('📄 Estructura actual: $responseBody');
    } else {
      print('❌ Error: $responseBody');
    }
    
    // 2. Ejecutar SQL para agregar columna
    print('\n🔧 Ejecutando SQL para agregar columna etiqueta...');
    
    // Usar el endpoint de SQL directo
    final sqlRequest = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/rpc/exec'));
    sqlRequest.headers.set('apikey', serviceKey);
    sqlRequest.headers.set('Authorization', 'Bearer $serviceKey');
    sqlRequest.headers.set('Content-Type', 'application/json');
    sqlRequest.headers.set('Prefer', 'return=minimal');
    
    final sqlBody = jsonEncode({
      'query': '''
        ALTER TABLE usuario_favoritos 
        ADD COLUMN IF NOT EXISTS etiqueta TEXT DEFAULT 'Favorito';
        
        CREATE INDEX IF NOT EXISTS idx_favoritos_etiqueta ON usuario_favoritos(etiqueta);
        
        UPDATE usuario_favoritos 
        SET etiqueta = 'Favorito' 
        WHERE etiqueta IS NULL;
      '''
    });
    
    sqlRequest.write(sqlBody);
    final sqlResponse = await sqlRequest.close();
    final sqlResponseBody = await sqlResponse.transform(utf8.decoder).join();
    
    print('✅ SQL ejecutado: ${sqlResponse.statusCode}');
    print('📄 Respuesta: $sqlResponseBody');
    
    // 3. Verificar que la columna se agregó
    print('\n🔍 Verificando nueva estructura...');
    final verifyRequest = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/usuario_favoritos?select=*&limit=1'));
    verifyRequest.headers.set('apikey', serviceKey);
    verifyRequest.headers.set('Authorization', 'Bearer $serviceKey');
    
    final verifyResponse = await verifyRequest.close();
    final verifyResponseBody = await verifyResponse.transform(utf8.decoder).join();
    
    print('✅ Verificación: ${verifyResponse.statusCode}');
    print('📄 Nueva estructura: $verifyResponseBody');
    
    // 4. Probar insertar un favorito con etiqueta
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
    
    if (sqlResponse.statusCode == 200 || sqlResponse.statusCode == 204) {
      print('\n🎉 ¡Columna etiqueta creada exitosamente!');
    } else {
      print('\n❌ Error al crear la columna etiqueta');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
