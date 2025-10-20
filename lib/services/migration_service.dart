import 'dart:convert';
import 'package:flutter/services.dart';
import 'supabase_service.dart';
import 'supabase_config.dart';

class MigrationService {
  static Future<void> migrarDatosIniciales() async {
    try {
      print('🚀 Iniciando migración de datos a Supabase...');
      
      // Migrar códigos
      await _migrarCodigos();
      
      // Migrar audios
      await _migrarAudios();
      
      print('✅ Migración completada exitosamente');
    } catch (e) {
      print('❌ Error en migración: $e');
      rethrow;
    }
  }

  static Future<void> _migrarCodigos() async {
    try {
      print('📚 Migrando códigos Grabovoi...');
      
      // Cargar datos desde JSON local
      final String jsonString = await rootBundle.loadString('lib/data/codigos_grabovoi.json');
      final List<dynamic> codigosData = json.decode(jsonString);

      // Migrar a Supabase
      await SupabaseService.migrarCodigosDesdeJson(codigosData.cast<Map<String, dynamic>>());
      
      print('✅ Códigos migrados exitosamente');
    } catch (e) {
      print('❌ Error al migrar códigos: $e');
      rethrow;
    }
  }

  static Future<void> _migrarAudios() async {
    try {
      print('🎵 Migrando archivos de audio...');
      
      final List<Map<String, dynamic>> audios = [
        {
          'id': 'audio_1',
          'nombre': 'Frecuencia 432Hz - Armonía Universal',
          'archivo': '432hz_harmony.mp3',
          'descripcion': 'Frecuencia de sanación natural, reduce estrés y promueve la armonía.',
          'categoria': 'Frecuencias Sanadoras',
          'duracion': 300,
          'url': 'https://whtiazgcxdnemrrgjjqf.supabase.co/storage/v1/object/public/audios/432hz_harmony.mp3',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'id': 'audio_2',
          'nombre': 'Códigos Solfeggio 528Hz - Amor',
          'archivo': '528hz_love.mp3',
          'descripcion': 'Transformación y reparación del ADN, amor incondicional y sanación.',
          'categoria': 'Frecuencias Sanadoras',
          'duracion': 300,
          'url': 'https://whtiazgcxdnemrrgjjqf.supabase.co/storage/v1/object/public/audios/528hz_love.mp3',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'id': 'audio_3',
          'nombre': 'Binaural Beats - Manifestación',
          'archivo': 'binaural_manifestation.mp3',
          'descripcion': 'Ondas cerebrales para estados de meditación profunda y manifestación.',
          'categoria': 'Binaural Beats',
          'duracion': 300,
          'url': 'https://whtiazgcxdnemrrgjjqf.supabase.co/storage/v1/object/public/audios/binaural_manifestation.mp3',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'id': 'audio_4',
          'nombre': 'Crystal Bowls - Chakra Healing',
          'archivo': 'crystal_bowls.mp3',
          'descripcion': 'Sonidos de cuencos de cristal para sanación de chakras y equilibrio energético.',
          'categoria': 'Instrumentos Sanadores',
          'duracion': 300,
          'url': 'https://whtiazgcxdnemrrgjjqf.supabase.co/storage/v1/object/public/audios/crystal_bowls.mp3',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'id': 'audio_5',
          'nombre': 'Nature Sounds - Forest Meditation',
          'archivo': 'forest_meditation.mp3',
          'descripcion': 'Sonidos de la naturaleza para meditación profunda y conexión con la tierra.',
          'categoria': 'Sonidos Naturales',
          'duracion': 300,
          'url': 'https://whtiazgcxdnemrrgjjqf.supabase.co/storage/v1/object/public/audios/forest_meditation.mp3',
          'created_at': DateTime.now().toIso8601String(),
        },
      ];

      // Insertar audios en Supabase
      for (final audio in audios) {
        await SupabaseConfig.serviceClient
            .from('audio_files')
            .upsert(audio);
      }
      
      print('✅ Audios migrados exitosamente');
    } catch (e) {
      print('❌ Error al migrar audios: $e');
      rethrow;
    }
  }

  static Future<void> crearEsquemaSupabase() async {
    try {
      print('🗄️ Creando esquema de base de datos...');
      
      // Crear tablas usando SQL directo
      final List<String> queries = [
        // Tabla de códigos Grabovoi
        '''
        CREATE TABLE IF NOT EXISTS codigos_grabovoi (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          codigo TEXT UNIQUE NOT NULL,
          nombre TEXT NOT NULL,
          descripcion TEXT NOT NULL,
          categoria TEXT NOT NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        ''',
        
        // Tabla de favoritos de usuario
        '''
        CREATE TABLE IF NOT EXISTS usuario_favoritos (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          user_id TEXT NOT NULL,
          codigo_id TEXT NOT NULL REFERENCES codigos_grabovoi(codigo),
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          UNIQUE(user_id, codigo_id)
        );
        ''',
        
        // Tabla de popularidad de códigos
        '''
        CREATE TABLE IF NOT EXISTS codigo_popularidad (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          codigo_id TEXT NOT NULL REFERENCES codigos_grabovoi(codigo),
          contador INTEGER DEFAULT 0,
          ultimo_uso TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          UNIQUE(codigo_id)
        );
        ''',
        
        // Tabla de archivos de audio
        '''
        CREATE TABLE IF NOT EXISTS audio_files (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          nombre TEXT NOT NULL,
          archivo TEXT NOT NULL,
          descripcion TEXT NOT NULL,
          categoria TEXT NOT NULL,
          duracion INTEGER NOT NULL,
          url TEXT NOT NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        ''',
        
        // Tabla de progreso de usuario
        '''
        CREATE TABLE IF NOT EXISTS usuario_progreso (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          user_id TEXT UNIQUE NOT NULL,
          dias_consecutivos INTEGER DEFAULT 0,
          total_pilotajes INTEGER DEFAULT 0,
          nivel_energetico INTEGER DEFAULT 1,
          ultimo_pilotaje TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        ''',
        
        // Índices para optimización
        '''
        CREATE INDEX IF NOT EXISTS idx_codigos_categoria ON codigos_grabovoi(categoria);
        CREATE INDEX IF NOT EXISTS idx_codigos_nombre ON codigos_grabovoi(nombre);
        CREATE INDEX IF NOT EXISTS idx_favoritos_user ON usuario_favoritos(user_id);
        CREATE INDEX IF NOT EXISTS idx_popularidad_contador ON codigo_popularidad(contador DESC);
        CREATE INDEX IF NOT EXISTS idx_audio_categoria ON audio_files(categoria);
        ''',
      ];

      // Ejecutar queries
      for (final query in queries) {
        await SupabaseConfig.serviceClient.rpc('exec_sql', params: {'sql': query});
      }
      
      print('✅ Esquema creado exitosamente');
    } catch (e) {
      print('❌ Error al crear esquema: $e');
      // Intentar crear esquema manualmente en el dashboard de Supabase
      print('💡 Crea manualmente el esquema en el dashboard de Supabase');
    }
  }
}
