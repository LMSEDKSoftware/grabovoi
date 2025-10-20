import 'lib/services/supabase_service.dart';

void main() async {
  print('🔍 Agregando códigos de cuidado del cabello...');
  
  // Códigos reales de cuidado del cabello de Grabovoi
  final codigosCabello = [
    {
      'codigo': '81441871',
      'nombre': 'Crecimiento y fortalecimiento del cabello',
      'descripcion': 'Código para estimular el crecimiento del cabello y fortalecerlo desde la raíz.',
      'categoria': 'Salud',
    },
    {
      'codigo': '548714218',
      'nombre': 'Cabello saludable y brillante',
      'descripcion': 'Para mantener el cabello saludable, brillante y con vitalidad natural.',
      'categoria': 'Salud',
    },
    {
      'codigo': '319818918',
      'nombre': 'Regeneración capilar',
      'descripcion': 'Código para regenerar el cabello y combatir la caída capilar.',
      'categoria': 'Salud',
    },
    {
      'codigo': '528491',
      'nombre': 'Equilibrio del cuero cabelludo',
      'descripcion': 'Para mantener el equilibrio y salud del cuero cabelludo.',
      'categoria': 'Salud',
    },
  ];

  try {
    for (final codigoData in codigosCabello) {
      final codigo = codigoData['codigo'] as String;
      
      // Verificar si el código ya existe
      final existe = await SupabaseService.codigoExiste(codigo);
      
      if (!existe) {
        print('➕ Agregando código: $codigo - ${codigoData['nombre']}');
        
        await SupabaseService.agregarCodigoEspecifico(
          codigo,
          codigoData['nombre'] as String,
          codigoData['descripcion'] as String,
          codigoData['categoria'] as String,
        );
        
        print('✅ Código agregado exitosamente: $codigo');
      } else {
        print('⚠️ Código ya existe: $codigo');
      }
    }
    
    print('🎉 Proceso completado');
  } catch (e) {
    print('❌ Error: $e');
  }
}
