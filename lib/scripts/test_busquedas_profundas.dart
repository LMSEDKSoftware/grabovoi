import '../services/busquedas_profundas_service.dart';
import '../models/busqueda_profunda_model.dart';

/// Script para probar la conexión y funcionalidad de búsquedas profundas
Future<void> main() async {
  print('🚀 Iniciando prueba de búsquedas profundas...');
  
  try {
    // Crear una búsqueda de ejemplo
    final busquedaEjemplo = BusquedaProfunda(
      codigoBuscado: '52183',
      usuarioId: 'test-user-123',
      promptSystem: 'Eres un experto en códigos numéricos de Grigori Grabovoi...',
      promptUser: 'Analiza el código numérico de Grabovoi: 52183...',
      respuestaIa: '{"nombre": "Transformación Personal", "descripcion": "Código para transformación personal profunda", "categoria": "Reprogramacion"}',
      codigoEncontrado: true,
      codigoGuardado: true,
      fechaBusqueda: DateTime.now(),
      duracionMs: 2500,
      modeloIa: 'gpt-3.5-turbo',
      tokensUsados: 150,
      costoEstimado: 0.000225,
    );
    
    print('📝 Creando búsqueda de ejemplo...');
    print('   Código: ${busquedaEjemplo.codigoBuscado}');
    print('   Usuario: ${busquedaEjemplo.usuarioId}');
    print('   Fecha: ${busquedaEjemplo.fechaBusqueda}');
    
    // Guardar la búsqueda
    final id = await BusquedasProfundasService.guardarBusquedaProfunda(busquedaEjemplo);
    print('✅ Búsqueda guardada con ID: $id');
    
    // Obtener estadísticas
    print('\n📊 Obteniendo estadísticas...');
    final estadisticas = await BusquedasProfundasService.getEstadisticas();
    print('   Total búsquedas: ${estadisticas['total_busquedas']}');
    print('   Códigos encontrados: ${estadisticas['codigos_encontrados']}');
    print('   Códigos guardados: ${estadisticas['codigos_guardados']}');
    print('   Tasa de éxito: ${estadisticas['tasa_exito']?.toStringAsFixed(2)}%');
    print('   Duración promedio: ${estadisticas['duracion_promedio_ms']?.toStringAsFixed(2)} ms');
    print('   Tokens totales: ${estadisticas['tokens_totales']}');
    print('   Costo total: \$${estadisticas['costo_total']?.toStringAsFixed(6)}');
    
    // Obtener códigos más buscados
    print('\n🔍 Obteniendo códigos más buscados...');
    final masBuscados = await BusquedasProfundasService.getCodigosMasBuscados(limit: 5);
    for (var codigo in masBuscados) {
      print('   ${codigo['codigo']}: ${codigo['frecuencia']} búsquedas');
    }
    
    // Obtener búsquedas del usuario de prueba
    print('\n👤 Obteniendo búsquedas del usuario de prueba...');
    final busquedasUsuario = await BusquedasProfundasService.getBusquedasPorUsuario('test-user-123');
    print('   Búsquedas encontradas: ${busquedasUsuario.length}');
    for (var busqueda in busquedasUsuario) {
      print('   - ${busqueda.codigoBuscado} (${busqueda.fechaBusqueda}) - ${busqueda.codigoEncontrado ? "✅" : "❌"}');
    }
    
    print('\n🎉 ¡Prueba completada exitosamente!');
    
  } catch (e) {
    print('❌ Error en la prueba: $e');
    print('🔍 Verifica que:');
    print('   1. La tabla busquedas_profundas existe en Supabase');
    print('   2. Las credenciales de Supabase son correctas');
    print('   3. El usuario tiene permisos para insertar datos');
  }
}
