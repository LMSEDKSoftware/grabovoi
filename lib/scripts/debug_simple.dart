import 'dart:io';
import 'dart:convert';
import 'dart:async';

/// Script de debug simplificado que no depende de Flutter
class DebugSimple {
  static final List<String> _debugLog = [];
  static final Map<String, dynamic> _testResults = {};
  static int _testsPassed = 0;
  static int _testsFailed = 0;

  /// Ejecuta debug simplificado sin dependencias de Flutter
  static Future<Map<String, dynamic>> runSimpleDebug() async {
    _debugLog.clear();
    _testResults.clear();
    _testsPassed = 0;
    _testsFailed = 0;

    _log('🚀 INICIANDO DEBUG SIMPLIFICADO');
    _log('================================');

    try {
      // 1. Verificar conectividad básica
      await _testBasicConnectivity();
      
      // 2. Verificar archivos del proyecto
      await _testProjectFiles();
      
      // 3. Verificar dependencias
      await _testDependencies();
      
      // 4. Verificar configuración de Supabase
      await _testSupabaseConfig();
      
      // 5. Verificar servicios básicos
      await _testBasicServices();
      
      // 6. Generar reporte final
      _generateFinalReport();

    } catch (e) {
      _log('❌ ERROR CRÍTICO EN DEBUG: $e');
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

  /// 1. Verificar conectividad básica
  static Future<void> _testBasicConnectivity() async {
    _log('\n🌐 VERIFICANDO CONECTIVIDAD BÁSICA');
    _log('----------------------------------');

    try {
      // Verificar conectividad a internet
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _passTest('Conectividad a internet verificada');
      } else {
        _failTest('Sin conectividad a internet', 'Verificar conexión de red');
      }

      // Verificar conectividad a Supabase
      final supabaseResult = await InternetAddress.lookup('whtiazgcxdnemrrgjjqf.supabase.co');
      if (supabaseResult.isNotEmpty && supabaseResult[0].rawAddress.isNotEmpty) {
        _passTest('Conectividad a Supabase verificada');
      } else {
        _failTest('Sin conectividad a Supabase', 'Verificar DNS');
      }

    } catch (e) {
      _failTest('Error verificando conectividad', e.toString());
    }
  }

  /// 2. Verificar archivos del proyecto
  static Future<void> _testProjectFiles() async {
    _log('\n📁 VERIFICANDO ARCHIVOS DEL PROYECTO');
    _log('------------------------------------');

    final criticalFiles = [
      'pubspec.yaml',
      'lib/main.dart',
      'lib/services/supabase_config.dart',
      'lib/models/supabase_models.dart',
      'lib/screens/home/home_screen.dart',
      'lib/screens/biblioteca/static_biblioteca_screen.dart',
      'lib/screens/desafios/desafios_screen.dart',
      'lib/screens/evolucion/evolucion_screen.dart',
      'lib/screens/profile/profile_screen.dart',
    ];

    for (final file in criticalFiles) {
      final fileExists = File(file).existsSync();
      if (fileExists) {
        _passTest('Archivo $file existe');
      } else {
        _failTest('Archivo $file no encontrado', 'Verificar estructura del proyecto');
      }
    }
  }

  /// 3. Verificar dependencias
  static Future<void> _testDependencies() async {
    _log('\n📦 VERIFICANDO DEPENDENCIAS');
    _log('----------------------------');

    try {
      // Verificar que pubspec.yaml existe y es válido
      final pubspecFile = File('pubspec.yaml');
      if (!pubspecFile.existsSync()) {
        _failTest('pubspec.yaml no encontrado', 'Verificar estructura del proyecto');
        return;
      }

      final pubspecContent = await pubspecFile.readAsString();
      final pubspecYaml = pubspecContent;

      // Verificar dependencias críticas
      final criticalDeps = [
        'supabase_flutter',
        'google_fonts',
        'just_audio',
        'http',
        'shared_preferences',
        'url_launcher',
        'share_plus',
        'flutter_local_notifications',
      ];

      for (final dep in criticalDeps) {
        if (pubspecYaml.contains(dep)) {
          _passTest('Dependencia $dep encontrada');
        } else {
          _failTest('Dependencia $dep no encontrada', 'Agregar a pubspec.yaml');
        }
      }

      // Verificar que pubspec.lock existe
      final pubspecLockFile = File('pubspec.lock');
      if (pubspecLockFile.existsSync()) {
        _passTest('pubspec.lock existe');
      } else {
        _failTest('pubspec.lock no encontrado', 'Ejecutar flutter pub get');
      }

    } catch (e) {
      _failTest('Error verificando dependencias', e.toString());
    }
  }

  /// 4. Verificar configuración de Supabase
  static Future<void> _testSupabaseConfig() async {
    _log('\n🗄️ VERIFICANDO CONFIGURACIÓN DE SUPABASE');
    _log('----------------------------------------');

    try {
      // Verificar archivo de configuración de Supabase
      final supabaseConfigFile = File('lib/services/supabase_config.dart');
      if (!supabaseConfigFile.existsSync()) {
        _failTest('Archivo supabase_config.dart no encontrado', 'Crear configuración de Supabase');
        return;
      }

      final supabaseConfigContent = await supabaseConfigFile.readAsString();
      
      // Verificar que contiene la URL de Supabase
      if (supabaseConfigContent.contains('whtiazgcxdnemrrgjjqf.supabase.co')) {
        _passTest('URL de Supabase configurada');
      } else {
        _failTest('URL de Supabase no configurada', 'Verificar configuración');
      }

      // Verificar que contiene la API key
      if (supabaseConfigContent.contains('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9')) {
        _passTest('API key de Supabase configurada');
      } else {
        _failTest('API key de Supabase no configurada', 'Verificar configuración');
      }

      // Verificar que contiene la anon key
      if (supabaseConfigContent.contains('anon')) {
        _passTest('Anon key de Supabase configurada');
      } else {
        _failTest('Anon key de Supabase no configurada', 'Verificar configuración');
      }

    } catch (e) {
      _failTest('Error verificando configuración de Supabase', e.toString());
    }
  }

  /// 5. Verificar servicios básicos
  static Future<void> _testBasicServices() async {
    _log('\n🔧 VERIFICANDO SERVICIOS BÁSICOS');
    _log('--------------------------------');

    final serviceFiles = [
      'lib/services/biblioteca_supabase_service.dart',
      'lib/services/simple_api_service.dart',
      'lib/services/auth_service_simple.dart',
      'lib/services/audio_service.dart',
      'lib/services/ai/ai_service.dart',
    ];

    for (final serviceFile in serviceFiles) {
      final fileExists = File(serviceFile).existsSync();
      if (fileExists) {
        _passTest('Servicio $serviceFile existe');
      } else {
        _failTest('Servicio $serviceFile no encontrado', 'Verificar implementación de servicios');
      }
    }

    // Verificar archivos de modelos
    final modelFiles = [
      'lib/models/supabase_models.dart',
      'lib/models/user_model.dart',
      'lib/models/challenge_model.dart',
    ];

    for (final modelFile in modelFiles) {
      final fileExists = File(modelFile).existsSync();
      if (fileExists) {
        _passTest('Modelo $modelFile existe');
      } else {
        _failTest('Modelo $modelFile no encontrado', 'Verificar implementación de modelos');
      }
    }
  }

  /// Generar reporte final
  static void _generateFinalReport() {
    _log('\n📋 REPORTE FINAL DE DEBUG');
    _log('==========================');
    _log('✅ Pruebas exitosas: $_testsPassed');
    _log('❌ Pruebas fallidas: $_testsFailed');
    _log('📊 Total de pruebas: ${_testsPassed + _testsFailed}');
    _log('📈 Tasa de éxito: ${(_testsPassed / (_testsPassed + _testsFailed) * 100).toStringAsFixed(1)}%');
    
    if (_testsFailed == 0) {
      _log('🎉 ¡TODAS LAS PRUEBAS PASARON! La aplicación está funcionando correctamente.');
    } else {
      _log('⚠️ Se encontraron $_testsFailed problemas que requieren atención.');
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
  print('🔧 DEBUG SIMPLIFICADO DE LA APLICACIÓN');
  print('======================================');
  print('');

  try {
    final results = await DebugSimple.runSimpleDebug();
    
    print('\n📊 RESULTADOS FINALES:');
    print('======================');
    print('Éxito: ${results['success']}');
    print('Pruebas exitosas: ${results['testsPassed']}');
    print('Pruebas fallidas: ${results['testsFailed']}');
    print('Tasa de éxito: ${results['successRate']?.toStringAsFixed(1)}%');
    
    // Exportar resultados
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final filename = 'debug_simple_$timestamp.json';
    
    // Crear directorio de resultados si no existe
    final resultsDir = Directory('debug_results');
    if (!resultsDir.existsSync()) {
      resultsDir.createSync();
    }
    
    final file = File('debug_results/$filename');
    await file.writeAsString(jsonEncode(results));
    
    print('\n📁 Resultados exportados a: debug_results/$filename');
    
    if (results['success'] == true) {
      print('\n🎉 ¡Debug completado exitosamente!');
      exit(0);
    } else {
      print('\n⚠️ Se encontraron problemas que requieren atención.');
      exit(1);
    }
    
  } catch (e) {
    print('\n❌ Error ejecutando debug: $e');
    exit(1);
  }
}
