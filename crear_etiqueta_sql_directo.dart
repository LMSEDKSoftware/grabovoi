import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔍 Creando columna etiqueta usando SQL directo...');
  
  try {
    final supabaseUrl = 'https://whtiazgcxdnemrrgjjqf.supabase.co';
    final serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDUyMzYzOCwiZXhwIjoyMDc2MDk5NjM4fQ.LIVQ2FpXRpJD7ie4GVkrwU7lLPRm4S5NekNG2Cqme8o';
    
    final client = HttpClient();
    
    // Usar el endpoint de SQL directo de Supabase
    print('\n🔧 Ejecutando SQL directo...');
    final sqlRequest = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/rpc/exec_sql'));
    sqlRequest.headers.set('apikey', serviceKey);
    sqlRequest.headers.set('Authorization', 'Bearer $serviceKey');
    sqlRequest.headers.set('Content-Type', 'application/json');
    
    final sqlBody = jsonEncode({
      'sql': '''
        -- Agregar campo etiqueta a la tabla usuario_favoritos
        ALTER TABLE usuario_favoritos 
        ADD COLUMN IF NOT EXISTS etiqueta TEXT DEFAULT 'Favorito';
        
        -- Crear índice para búsquedas por etiqueta
        CREATE INDEX IF NOT EXISTS idx_favoritos_etiqueta ON usuario_favoritos(etiqueta);
        
        -- Actualizar etiquetas existentes con valor por defecto
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
    
    // Verificar que la columna se agregó
    print('\n🔍 Verificando nueva estructura...');
    final verifyRequest = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/usuario_favoritos?select=*&limit=1'));
    verifyRequest.headers.set('apikey', serviceKey);
    verifyRequest.headers.set('Authorization', 'Bearer $serviceKey');
    
    final verifyResponse = await verifyRequest.close();
    final verifyResponseBody = await verifyResponse.transform(utf8.decoder).join();
    
    print('✅ Verificación: ${verifyResponse.statusCode}');
    print('📄 Nueva estructura: $verifyResponseBody');
    
    client.close();
    
    if (sqlResponse.statusCode == 200 || sqlResponse.statusCode == 204) {
      print('\n🎉 ¡Columna etiqueta creada exitosamente!');
    } else {
      print('\n❌ Error al crear la columna etiqueta');
      print('💡 Necesitas ejecutar el SQL manualmente en el SQL Editor de Supabase');
      print('📄 SQL a ejecutar:');
      print('''
        ALTER TABLE usuario_favoritos 
        ADD COLUMN IF NOT EXISTS etiqueta TEXT DEFAULT 'Favorito';
        
        CREATE INDEX IF NOT EXISTS idx_favoritos_etiqueta ON usuario_favoritos(etiqueta);
        
        UPDATE usuario_favoritos 
        SET etiqueta = 'Favorito' 
        WHERE etiqueta IS NULL;
      ''');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
