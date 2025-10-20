import '../services/supabase_service.dart';

/// Script para agregar códigos específicos conocidos a la base de datos
Future<void> main() async {
  print('🚀 Iniciando agregado de códigos específicos...');
  
  try {
    // Agregar el código 520_741_8
    await SupabaseService.agregarCodigoEspecifico(
      '520_741_8',
      'Manifestación Material',
      'Atracción de dinero inesperado o resolución económica rápida',
      'Manifestacion',
    );
    
    print('✅ Código 520_741_8 agregado exitosamente');
    
    // Agregar otros códigos conocidos si es necesario
    await SupabaseService.agregarCodigoEspecifico(
      '741',
      'Solución Inmediata',
      'Para resolver problemas de manera rápida y efectiva',
      'Manifestacion',
    );
    
    print('✅ Código 741 agregado exitosamente');
    
    print('🎉 Todos los códigos específicos agregados correctamente');
    
  } catch (e) {
    print('❌ Error al agregar códigos específicos: $e');
  }
}
