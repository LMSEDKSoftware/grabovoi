import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/config/supabase_config.dart';

void main() async {
  print('🔍 Debugging favoritos...');
  
  try {
    // Inicializar Supabase
    await Supabase.initialize(
      url: 'https://your-project.supabase.co',
      anonKey: 'your-anon-key',
    );
    
    final client = Supabase.instance.client;
    
    // 1. Verificar si el código "812_719_819_14" existe
    print('\n1. Verificando si el código "812_719_819_14" existe...');
    final codigoResponse = await client
        .from('codigos_grabovoi')
        .select('codigo, nombre')
        .eq('codigo', '812_719_819_14')
        .maybeSingle();
    
    if (codigoResponse != null) {
      print('✅ Código encontrado: ${codigoResponse['codigo']} - ${codigoResponse['nombre']}');
    } else {
      print('❌ Código NO encontrado en la base de datos');
    }
    
    // 2. Intentar agregar a favoritos
    print('\n2. Intentando agregar a favoritos...');
    try {
      await client.from('usuario_favoritos').insert({
        'user_id': 'test-user-debug',
        'codigo_id': '812_719_819_14',
        'etiqueta': 'debug',
      });
      print('✅ Favorito agregado exitosamente');
    } catch (e) {
      print('❌ Error agregando favorito: $e');
    }
    
    // 3. Verificar favoritos del usuario
    print('\n3. Verificando favoritos del usuario...');
    final favoritosResponse = await client
        .from('usuario_favoritos')
        .select('*')
        .eq('user_id', 'test-user-debug');
    
    print('📄 Favoritos encontrados: ${favoritosResponse.length}');
    for (final fav in favoritosResponse) {
      print('  - ${fav['codigo_id']} (${fav['etiqueta']})');
    }
    
  } catch (e) {
    print('❌ Error general: $e');
  }
}
