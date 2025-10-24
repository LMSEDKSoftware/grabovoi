import 'dart:io';
import 'dart:convert';
import 'dart:async';

/// Script de debug funcional que prueba la funcionalidad real de la aplicación
class DebugFunctional {
  static final List<String> _debugLog = [];
  static final Map<String, dynamic> _testResults = {};
  static int _testsPassed = 0;
  static int _testsFailed = 0;

  /// Ejecuta debug funcional de la aplicación
  static Future<Map<String, dynamic>> runFunctionalDebug() async {
    _debugLog.clear();
    _testResults.clear();
    _testsPassed = 0;
    _testsFailed = 0;

    _log('🚀 INICIANDO DEBUG FUNCIONAL');
    _log('============================');

    try {
      // 1. Verificar compilación de la aplicación
      await _testAppCompilation();
      
      // 2. Verificar servicios de Supabase
      await _testSupabaseServices();
      
      // 3. Verificar APIs externas
      await _testExternalAPIs();
      
      // 4. Verificar modelos de datos
      await _testDataModels();
      
      // 5. Verificar configuración de assets
      await _testAssets();
      
      // 6. Verificar archivos de configuración
      await _testConfigurationFiles();
      
      // 7. Generar reporte final
      _generateFinalReport();

    } catch (e) {
      _log('❌ ERROR CRÍTICO EN DEBUG FUNCIONAL: $e');
      _testsFailed++;
    }

    return {
      'success': _testsFailed == 0,
      'testsPassed': _testsPassed,
      'testsFailed': _testsFailed,
      'totalTests': _testsPassed + _testsFailed,
      'successRate': _testsPassed / (_testsPassed + _testsFailed) * 100,
      'log': _debugLog,
      'results': _testResults,
    };
  }

  /// 1. Verificar compilación de la aplicación
  static Future<void> _testAppCompilation() async {
    _log('\n🔨 VERIFICANDO COMPILACIÓN DE LA APLICACIÓN');
    _log('--------------------------------------------');

    try {
      // Verificar que Flutter puede analizar el código
      final result = await Process.run('flutter', ['analyze'], runInShell: true);
      
      if (result.exitCode == 0) {
        _passTest('Análisis de Flutter exitoso');
        _log('Análisis de Flutter: ${result.stdout}');
      } else {
        _failTest('Análisis de Flutter falló', result.stderr);
        _log('Errores de análisis: ${result.stderr}');
      }

      // Verificar que no hay errores de compilación
      final buildResult = await Process.run('flutter', ['build', 'apk', '--debug', '--no-pub'], runInShell: true);
      
      if (buildResult.exitCode == 0) {
        _passTest('Compilación de debug exitosa');
      } else {
        _failTest('Compilación de debug falló', buildResult.stderr);
        _log('Errores de compilación: ${buildResult.stderr}');
      }

    } catch (e) {
      _failTest('Error verificando compilación', e.toString());
    }
  }

  /// 2. Verificar servicios de Supabase
  static Future<void> _testSupabaseServices() async {
    _log('\n🗄️ VERIFICANDO SERVICIOS DE SUPABASE');
    _log('------------------------------------');

    try {
      // Verificar conectividad a Supabase
      final supabaseUrl = 'https://whtiazgcxdnemrrgjjqf.supabase.co';
      final response = await HttpClient().getUrl(Uri.parse('$supabaseUrl/rest/v1/'));
      final httpResponse = await response.close();
      
      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 401) {
        _passTest('Supabase REST API accesible');
      } else {
        _failTest('Supabase REST API no accesible', 'Status: ${httpResponse.statusCode}');
      }

      // Verificar Edge Functions
      final functionsUrl = '$supabaseUrl/functions/v1/';
      final functionsResponse = await HttpClient().getUrl(Uri.parse(functionsUrl));
      final functionsHttpResponse = await functionsResponse.close();
      
      if (functionsHttpResponse.statusCode == 200 || functionsHttpResponse.statusCode == 401) {
        _passTest('Supabase Edge Functions accesibles');
      } else {
        _failTest('Supabase Edge Functions no accesibles', 'Status: ${functionsHttpResponse.statusCode}');
      }

    } catch (e) {
      _failTest('Error verificando servicios de Supabase', e.toString());
    }
  }

  /// 3. Verificar APIs externas
  static Future<void> _testExternalAPIs() async {
    _log('\n🌐 VERIFICANDO APIs EXTERNAS');
    _log('-----------------------------');

    try {
      // Verificar Google Fonts
      final googleFontsUrl = 'https://fonts.googleapis.com';
      final googleResponse = await HttpClient().getUrl(Uri.parse(googleFontsUrl));
      final googleHttpResponse = await googleResponse.close();
      
      if (googleHttpResponse.statusCode == 200) {
        _passTest('Google Fonts accesible');
      } else {
        _failTest('Google Fonts no accesible', 'Status: ${googleHttpResponse.statusCode}');
      }

      // Verificar conectividad general
      final internetResponse = await HttpClient().getUrl(Uri.parse('https://httpbin.org/get'));
      final internetHttpResponse = await internetResponse.close();
      
      if (internetHttpResponse.statusCode == 200) {
        _passTest('Conectividad a internet verificada');
      } else {
        _failTest('Sin conectividad a internet', 'Status: ${internetHttpResponse.statusCode}');
      }

    } catch (e) {
      _failTest('Error verificando APIs externas', e.toString());
    }
  }

  /// 4. Verificar modelos de datos
  static Future<void> _testDataModels() async {
    _log('\n📊 VERIFICANDO MODELOS DE DATOS');
    _log('-------------------------------');

    try {
      // Verificar que los archivos de modelos existen y son válidos
      final modelFiles = [
        'lib/models/supabase_models.dart',
        'lib/models/user_model.dart',
        'lib/models/challenge_model.dart',
      ];

      for (final modelFile in modelFiles) {
        final file = File(modelFile);
        if (file.existsSync()) {
          final content = await file.readAsString();
          
          // Verificar que contiene clases
          if (content.contains('class ')) {
            _passTest('Modelo $modelFile válido');
          } else {
            _failTest('Modelo $modelFile no contiene clases', 'Verificar estructura');
          }
          
          // Verificar que contiene métodos toJson/fromJson
          if (content.contains('toJson') && content.contains('fromJson')) {
            _passTest('Modelo $modelFile tiene serialización JSON');
          } else {
            _failTest('Modelo $modelFile sin serialización JSON', 'Agregar métodos toJson/fromJson');
          }
        } else {
          _failTest('Modelo $modelFile no encontrado', 'Verificar archivo');
        }
      }

    } catch (e) {
      _failTest('Error verificando modelos de datos', e.toString());
    }
  }

  /// 5. Verificar configuración de assets
  static Future<void> _testAssets() async {
    _log('\n🎨 VERIFICANDO ASSETS');
    _log('----------------------');

    try {
      // Verificar directorio de assets
      final assetsDir = Directory('assets');
      if (assetsDir.existsSync()) {
        _passTest('Directorio assets existe');
        
        // Verificar subdirectorios
        final subdirs = ['images', 'audios', 'lottie', 'icons'];
        for (final subdir in subdirs) {
          final subdirPath = Directory('assets/$subdir');
          if (subdirPath.existsSync()) {
            _passTest('Directorio assets/$subdir existe');
          } else {
            _failTest('Directorio assets/$subdir no encontrado', 'Crear directorio');
          }
        }
      } else {
        _failTest('Directorio assets no encontrado', 'Crear directorio assets');
      }

      // Verificar archivos de audio
      final audioFiles = [
        'assets/audios/432hz_harmony.mp3',
        'assets/audios/528hz_love.mp3',
        'assets/audios/binaural_manifestation.mp3',
        'assets/audios/crystal_bowls.mp3',
        'assets/audios/forest_meditation.mp3',
      ];

      for (final audioFile in audioFiles) {
        final file = File(audioFile);
        if (file.existsSync()) {
          _passTest('Archivo de audio $audioFile existe');
        } else {
          _failTest('Archivo de audio $audioFile no encontrado', 'Agregar archivo de audio');
        }
      }

    } catch (e) {
      _failTest('Error verificando assets', e.toString());
    }
  }

  /// 6. Verificar archivos de configuración
  static Future<void> _testConfigurationFiles() async {
    _log('\n⚙️ VERIFICANDO ARCHIVOS DE CONFIGURACIÓN');
    _log('----------------------------------------');

    try {
      // Verificar pubspec.yaml
      final pubspecFile = File('pubspec.yaml');
      if (pubspecFile.existsSync()) {
        final content = await pubspecFile.readAsString();
        
        // Verificar campos obligatorios
        if (content.contains('name:') && content.contains('version:')) {
          _passTest('pubspec.yaml tiene campos obligatorios');
        } else {
          _failTest('pubspec.yaml sin campos obligatorios', 'Verificar estructura');
        }
        
        // Verificar dependencias críticas
        final criticalDeps = ['supabase_flutter', 'google_fonts', 'just_audio', 'http'];
        for (final dep in criticalDeps) {
          if (content.contains(dep)) {
            _passTest('Dependencia $dep en pubspec.yaml');
          } else {
            _failTest('Dependencia $dep faltante en pubspec.yaml', 'Agregar dependencia');
          }
        }
      } else {
        _failTest('pubspec.yaml no encontrado', 'Verificar archivo');
      }

      // Verificar análisis_options.yaml
      final analysisFile = File('analysis_options.yaml');
      if (analysisFile.existsSync()) {
        _passTest('analysis_options.yaml existe');
      } else {
        _failTest('analysis_options.yaml no encontrado', 'Crear archivo de configuración');
      }

    } catch (e) {
      _failTest('Error verificando archivos de configuración', e.toString());
    }
  }

  /// Generar reporte final
  static void _generateFinalReport() {
    _log('\n📋 REPORTE FINAL DE DEBUG FUNCIONAL');
    _log('====================================');
    _log('✅ Pruebas exitosas: $_testsPassed');
    _log('❌ Pruebas fallidas: $_testsFailed');
    _log('📊 Total de pruebas: ${_testsPassed + _testsFailed}');
    _log('📈 Tasa de éxito: ${(_testsPassed / (_testsPassed + _testsFailed) * 100).toStringAsFixed(1)}%');
    
    if (_testsFailed == 0) {
      _log('🎉 ¡TODAS LAS PRUEBAS FUNCIONALES PASARON! La aplicación está lista para usar.');
    } else {
      _log('⚠️ Se encontraron $_testsFailed problemas funcionales que requieren atención.');
    }

    _testResults['resumen'] = {
      'testsPassed': _testsPassed,
      'testsFailed': _testsFailed,
      'totalTests': _testsPassed + _testsFailed,
      'successRate': _testsPassed / (_testsPassed + _testsFailed) * 100,
    };
  }

  /// Registrar log de debug
  static void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    _debugLog.add('[$timestamp] $message');
    print('[$timestamp] $message');
  }

  /// Marcar prueba como exitosa
  static void _passTest(String testName) {
    _testsPassed++;
    _log('✅ $testName');
  }

  /// Marcar prueba como fallida
  static void _failTest(String testName, String error) {
    _testsFailed++;
    _log('❌ $testName: $error');
  }

  /// Obtener log de debug
  static List<String> get debugLog => _debugLog;

  /// Obtener resultados de pruebas
  static Map<String, dynamic> get testResults => _testResults;
}

/// Función principal para ejecutar desde línea de comandos
void main() async {
  print('🔧 DEBUG FUNCIONAL DE LA APLICACIÓN');
  print('====================================');
  print('');

  try {
    final results = await DebugFunctional.runFunctionalDebug();
    
    print('\n📊 RESULTADOS FINALES:');
    print('======================');
    print('Éxito: ${results['success']}');
    print('Pruebas exitosas: ${results['testsPassed']}');
    print('Pruebas fallidas: ${results['testsFailed']}');
    print('Tasa de éxito: ${results['successRate']?.toStringAsFixed(1)}%');
    
    // Exportar resultados
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final filename = 'debug_functional_$timestamp.json';
    
    // Crear directorio de resultados si no existe
    final resultsDir = Directory('debug_results');
    if (!resultsDir.existsSync()) {
      resultsDir.createSync();
    }
    
    final file = File('debug_results/$filename');
    await file.writeAsString(jsonEncode(results));
    
    print('\n📁 Resultados exportados a: debug_results/$filename');
    
    if (results['success'] == true) {
      print('\n🎉 ¡Debug funcional completado exitosamente!');
      exit(0);
    } else {
      print('\n⚠️ Se encontraron problemas funcionales que requieren atención.');
      exit(1);
    }
    
  } catch (e) {
    print('\n❌ Error ejecutando debug funcional: $e');
    exit(1);
  }
}

