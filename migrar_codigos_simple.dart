import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  print('🚀 Migrando códigos correctamente a Supabase...');
  
  try {
    // Inicializar Supabase
    await Supabase.initialize(
      url: 'https://your-project.supabase.co',
      anonKey: 'your-anon-key',
    );
    
    final serviceClient = Supabase.instance.client;
    
    // Leer archivo JSON directamente
    print('📚 Leyendo archivo JSON...');
    final file = File('lib/data/codigos_grabovoi.json');
    final String jsonString = await file.readAsString();
    final List<dynamic> codigosData = json.decode(jsonString);
    
    print('📊 Total de códigos en JSON: ${codigosData.length}');
    
    // Migrar códigos uno por uno
    int successCount = 0;
    int errorCount = 0;
    
    for (final codigoData in codigosData) {
      try {
        await serviceClient.from('codigos_grabovoi').upsert({
          'codigo': codigoData['codigo'],
          'nombre': codigoData['nombre'],
          'descripcion': codigoData['descripcion'],
          'categoria': codigoData['categoria'] ?? 'General',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        
        successCount++;
        print('✅ Migrado: ${codigoData['codigo']} - ${codigoData['nombre']}');
      } catch (e) {
        errorCount++;
        print('❌ Error migrando ${codigoData['codigo']}: $e');
      }
    }
    
    print('\n📊 Resumen de migración:');
    print('✅ Códigos migrados exitosamente: $successCount');
    print('❌ Códigos con error: $errorCount');
    
    // Verificar que el código específico existe
    print('\n🔍 Verificando código específico "812_719_819_14"...');
    final verificacion = await serviceClient
        .from('codigos_grabovoi')
        .select('codigo, nombre, categoria')
        .eq('codigo', '812_719_819_14')
        .maybeSingle();
    
    if (verificacion != null) {
      print('✅ Código verificado:');
      print('   - Código: ${verificacion['codigo']}');
      print('   - Nombre: ${verificacion['nombre']}');
      print('   - Categoría: ${verificacion['categoria']}');
    } else {
      print('❌ Código no encontrado después de la migración');
    }
    
  } catch (e) {
    print('❌ Error general: $e');
  }
}
