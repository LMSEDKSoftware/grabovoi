import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

void main() async {
  // Configurar Supabase
  await Supabase.initialize(
    url: 'https://your-project.supabase.co', // Reemplazar con tu URL
    anonKey: 'your-anon-key', // Reemplazar con tu clave
  );

  final client = Supabase.instance.client;

  // Códigos reales de cuidado del cabello de Grabovoi
  final codigosCabello = [
    {
      'codigo': '81441871',
      'nombre': 'Crecimiento y fortalecimiento del cabello',
      'descripcion': 'Código para estimular el crecimiento del cabello y fortalecerlo desde la raíz.',
      'categoria': 'Salud',
      'color': '#32CD32',
    },
    {
      'codigo': '548714218',
      'nombre': 'Cabello saludable y brillante',
      'descripcion': 'Para mantener el cabello saludable, brillante y con vitalidad natural.',
      'categoria': 'Salud',
      'color': '#32CD32',
    },
    {
      'codigo': '319818918',
      'nombre': 'Regeneración capilar',
      'descripcion': 'Código para regenerar el cabello y combatir la caída capilar.',
      'categoria': 'Salud',
      'color': '#32CD32',
    },
    {
      'codigo': '528491',
      'nombre': 'Equilibrio del cuero cabelludo',
      'descripcion': 'Para mantener el equilibrio y salud del cuero cabelludo.',
      'categoria': 'Salud',
      'color': '#32CD32',
    },
  ];

  try {
    print('🔍 Verificando códigos existentes...');
    
    for (final codigoData in codigosCabello) {
      final codigo = codigoData['codigo'] as String;
      
      // Verificar si el código ya existe
      final response = await client
          .from('codigos_grabovoi')
          .select('codigo')
          .eq('codigo', codigo)
          .limit(1);
      
      if (response.isEmpty) {
        print('➕ Agregando código: $codigo - ${codigoData['nombre']}');
        
        await client.from('codigos_grabovoi').insert({
          'codigo': codigo,
          'nombre': codigoData['nombre'],
          'descripcion': codigoData['descripcion'],
          'categoria': codigoData['categoria'],
          'color': codigoData['color'],
        });
        
        print('✅ Código agregado exitosamente: $codigo');
      } else {
        print('⚠️ Código ya existe: $codigo');
      }
    }
    
    print('🎉 Proceso completado');
  } catch (e) {
    print('❌ Error: $e');
  }
  
  exit(0);
}
