import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/config/supabase_config.dart';

void main() async {
  print('🔍 Verificando código específico en la base de datos...');
  
  try {
    // Inicializar Supabase
    await Supabase.initialize(
      url: 'https://your-project.supabase.co',
      anonKey: 'your-anon-key',
    );
    
    final client = Supabase.instance.client;
    
    // Verificar el código "812_719_819_14" que aparece en el error
    print('\n1. Verificando código "812_719_819_14"...');
    final codigoResponse = await client
        .from('codigos_grabovoi')
        .select('codigo, nombre, categoria')
        .eq('codigo', '812_719_819_14')
        .maybeSingle();
    
    if (codigoResponse != null) {
      print('✅ Código encontrado:');
      print('   - Código: ${codigoResponse['codigo']}');
      print('   - Nombre: ${codigoResponse['nombre']}');
      print('   - Categoría: ${codigoResponse['categoria']}');
    } else {
      print('❌ Código NO encontrado en la base de datos');
      
      // Buscar códigos similares
      print('\n2. Buscando códigos similares...');
      final similarResponse = await client
          .from('codigos_grabovoi')
          .select('codigo, nombre')
          .ilike('codigo', '%812%')
          .limit(5);
      
      if (similarResponse.isNotEmpty) {
        print('📄 Códigos similares encontrados:');
        for (final codigo in similarResponse) {
          print('   - ${codigo['codigo']}: ${codigo['nombre']}');
        }
      } else {
        print('❌ No se encontraron códigos similares');
      }
    }
    
    // Verificar la estructura de la tabla
    print('\n3. Verificando estructura de la tabla...');
    final estructuraResponse = await client
        .from('codigos_grabovoi')
        .select('codigo')
        .limit(1);
    
    if (estructuraResponse.isNotEmpty) {
      print('✅ Tabla accesible');
      print('📄 Primer registro: ${estructuraResponse.first}');
    } else {
      print('❌ Tabla vacía o no accesible');
    }
    
    // Contar total de códigos
    print('\n4. Contando total de códigos...');
    final countResponse = await client
        .from('codigos_grabovoi')
        .select('codigo', const FetchOptions(count: CountOption.exact));
    
    print('📊 Total de códigos en la base de datos: ${countResponse.length}');
    
  } catch (e) {
    print('❌ Error general: $e');
  }
}
