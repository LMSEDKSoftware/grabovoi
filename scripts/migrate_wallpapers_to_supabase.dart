/// Script de ayuda para migrar imágenes de wallpapers a Supabase Storage
/// 
/// Este script descarga imágenes desde URLs externas y las sube a Supabase Storage
/// para resolver problemas de CORS en Flutter Web.
/// 
/// USO:
/// 1. Asegúrate de tener las variables de entorno configuradas (.env)
/// 2. Ejecuta: dart run scripts/migrate_wallpapers_to_supabase.dart
/// 
/// IMPORTANTE: Este script requiere que el bucket 'wallpapers' exista y sea público en Supabase
library;

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

// Mapeo de URLs antiguas a nombres de archivo en Supabase Storage
final Map<String, String> imageMappings = {
  'https://manigrab.app/imagenes_app/app6.png': 'app6.png',
  // Agrega más mapeos aquí según sea necesario
  // 'https://manigrab.app/imagenes_app/app7.png': 'app7.png',
};

Future<void> main() async {
  print('🚀 Iniciando migración de wallpapers a Supabase Storage...\n');

  // Cargar variables de entorno desde .env
  final envFile = File('.env');
  if (!await envFile.exists()) {
    print('❌ Error: No se encontró el archivo .env');
    print('   Crea un archivo .env con SUPABASE_URL y SUPABASE_ANON_KEY');
    exit(1);
  }

  final envVars = <String, String>{};
  final lines = await envFile.readAsLines();
  for (final line in lines) {
    if (line.trim().isEmpty || line.startsWith('#')) continue;
    final parts = line.split('=');
    if (parts.length == 2) {
      envVars[parts[0].trim()] = parts[1].trim();
    }
  }

  final supabaseUrl = envVars['SUPABASE_URL'];
  final supabaseAnonKey = envVars['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    print('❌ Error: SUPABASE_URL o SUPABASE_ANON_KEY no están configurados en .env');
    exit(1);
  }

  // Inicializar Supabase
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    print('✅ Supabase inicializado correctamente\n');
  } catch (e) {
    print('❌ Error inicializando Supabase: $e');
    exit(1);
  }

  final client = Supabase.instance.client;

  // Verificar que el bucket 'wallpapers' existe
  try {
    final buckets = await client.storage.listBuckets();
    final wallpapersBucket = buckets.firstWhere(
      (bucket) => bucket.name == 'wallpapers',
      orElse: () => throw Exception('Bucket no encontrado'),
    );
    
    if (!wallpapersBucket.public) {
      print('⚠️ ADVERTENCIA: El bucket "wallpapers" no es público.');
      print('   Las imágenes pueden no ser accesibles sin autenticación.');
      print('   Ve al Dashboard de Supabase y marca el bucket como público.\n');
    } else {
      print('✅ Bucket "wallpapers" encontrado y es público\n');
    }
  } catch (e) {
    print('❌ Error: El bucket "wallpapers" no existe.');
    print('   Crea el bucket "wallpapers" en Supabase Storage y márcalo como público.\n');
    exit(1);
  }

  // Migrar cada imagen
  int successCount = 0;
  int errorCount = 0;

  for (final entry in imageMappings.entries) {
    final sourceUrl = entry.key;
    final fileName = entry.value;
    
    print('📥 Descargando: $sourceUrl');
    
    try {
      // Descargar la imagen
      final response = await http.get(Uri.parse(sourceUrl));
      if (response.statusCode != 200) {
        throw Exception('Error HTTP ${response.statusCode}');
      }

      print('   ✅ Descargada (${response.bodyBytes.length} bytes)');

      // Subir a Supabase Storage
      print('   📤 Subiendo a Supabase Storage como: $fileName');
      
      await client.storage
          .from('wallpapers')
          .upload(fileName, response.bodyBytes, fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/png',
          ));

      // Obtener URL pública
      final publicUrl = client.storage
          .from('wallpapers')
          .getPublicUrl(fileName);

      print('   ✅ Subida exitosamente');
      print('   🔗 URL pública: $publicUrl\n');
      
      successCount++;
    } catch (e) {
      print('   ❌ Error: $e\n');
      errorCount++;
    }
  }

  // Resumen
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📊 Resumen de migración:');
  print('   ✅ Exitosas: $successCount');
  print('   ❌ Errores: $errorCount');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  if (successCount > 0) {
    print('💡 PRÓXIMOS PASOS:');
    print('   1. Actualiza la columna wallpaper_url en la tabla codigos_premium');
    print('   2. Usa el formato: "wallpapers/[nombre_archivo].png"');
    print('   3. Ejemplo SQL:');
    print('      UPDATE codigos_premium');
    print('      SET wallpaper_url = \'wallpapers/app6.png\'');
    print('      WHERE wallpaper_url = \'https://manigrab.app/imagenes_app/app6.png\';\n');
  }

  await Supabase.instance.dispose();
}
