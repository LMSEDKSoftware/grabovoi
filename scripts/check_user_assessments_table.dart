#!/usr/bin/env dart
// Script para verificar si la tabla user_assessments existe en Supabase
// Ejecutar: dart scripts/check_user_assessments_table.dart

import 'dart:io';
import 'dart:convert';

Future<void> main() async {
  print('🔍 Verificando si la tabla user_assessments existe en Supabase...\n');

  // Leer variables de entorno desde .env
  final envFile = File('.env');
  if (!await envFile.exists()) {
    print('❌ Error: No se encontró el archivo .env');
    exit(1);
  }

  final envLines = await envFile.readAsLines();
  final env = <String, String>{};
  
  for (final line in envLines) {
    if (line.trim().isEmpty || line.startsWith('#')) continue;
    final parts = line.split('=');
    if (parts.length >= 2) {
      final key = parts[0].trim();
      var value = parts.sublist(1).join('=').trim();
      // Remover comillas si existen
      if (value.startsWith('"') && value.endsWith('"')) {
        value = value.substring(1, value.length - 1);
      } else if (value.startsWith("'") && value.endsWith("'")) {
        value = value.substring(1, value.length - 1);
      }
      env[key] = value;
    }
  }

  final supabaseUrl = env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    print('❌ Error: SUPABASE_URL o SUPABASE_ANON_KEY no están configurados en .env');
    exit(1);
  }

  print('✅ Leyendo configuración de Supabase...');
  print('   URL: ${supabaseUrl.substring(0, supabaseUrl.length > 40 ? 40 : supabaseUrl.length)}...\n');

  // Verificar si la tabla existe usando la API REST de Supabase
  // Intentamos hacer un SELECT que fallará si la tabla no existe
  try {
    final client = HttpClient();
    
    // Intentar acceder a la tabla user_assessments
    final uri = Uri.parse('$supabaseUrl/rest/v1/user_assessments?select=id&limit=1');
    final request = await client.getUrl(uri);
    request.headers.set('apikey', supabaseAnonKey);
    request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Prefer', 'return=representation');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200 || response.statusCode == 206) {
      print('✅ La tabla user_assessments EXISTE');
      print('   - Se puede acceder a la tabla');
      
      // Intentar contar registros
      try {
        final countUri = Uri.parse('$supabaseUrl/rest/v1/user_assessments?select=id');
        final countRequest = await client.getUrl(countUri);
        countRequest.headers.set('apikey', supabaseAnonKey);
        countRequest.headers.set('Authorization', 'Bearer $supabaseAnonKey');
        countRequest.headers.set('Content-Type', 'application/json');
        countRequest.headers.set('Prefer', 'count=exact');
        
        final countResponse = await countRequest.close();
        final countHeader = countResponse.headers.value('content-range');
        
        if (countHeader != null) {
          final match = RegExp(r'(\d+)$').firstMatch(countHeader);
          if (match != null) {
            print('   - Total de registros: ${match.group(1)}');
          }
        }
      } catch (e) {
        print('   - No se pudo contar registros: $e');
      }
      
      // Verificar estructura básica
      try {
        final structUri = Uri.parse('$supabaseUrl/rest/v1/user_assessments?select=id,user_id,assessment_data,created_at&limit=1');
        final structRequest = await client.getUrl(structUri);
        structRequest.headers.set('apikey', supabaseAnonKey);
        structRequest.headers.set('Authorization', 'Bearer $supabaseAnonKey');
        structRequest.headers.set('Content-Type', 'application/json');
        
        final structResponse = await structRequest.close();
        if (structResponse.statusCode == 200) {
          print('   - Estructura verificada: id, user_id, assessment_data, created_at');
        }
      } catch (e) {
        print('   - Error verificando estructura: $e');
      }
      
    } else if (response.statusCode == 404 || response.statusCode == 406) {
      print('❌ La tabla user_assessments NO EXISTE');
      print('\n📋 Para crear la tabla, ejecuta en Supabase SQL Editor:');
      print('   database/user_assessment_schema.sql\n');
    } else {
      final errorBody = responseBody.isNotEmpty ? jsonDecode(responseBody) : {};
      print('⚠️  Respuesta inesperada: ${response.statusCode}');
      if (errorBody.containsKey('message')) {
        print('   Mensaje: ${errorBody['message']}');
      }
      print('   Respuesta: $responseBody\n');
    }
    
    client.close();
    
  } catch (e) {
    if (e.toString().contains('404') || e.toString().contains('does not exist')) {
      print('❌ La tabla user_assessments NO EXISTE');
      print('\n📋 Para crear la tabla, ejecuta en Supabase SQL Editor:');
      print('   database/user_assessment_schema.sql\n');
    } else {
      print('⚠️  Error al verificar la tabla: $e');
      print('\n💡 Esto podría indicar:');
      print('   - La tabla no existe');
      print('   - Problemas de permisos RLS');
      print('   - Error de conexión\n');
    }
  }

  // Verificar también en user_progress (más importante)
  try {
    final client = HttpClient();
    final uri = Uri.parse('$supabaseUrl/rest/v1/user_progress?select=preferences&limit=1');
    final request = await client.getUrl(uri);
    request.headers.set('apikey', supabaseAnonKey);
    request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
    request.headers.set('Content-Type', 'application/json');
    
    final response = await request.close();
    
    if (response.statusCode == 200 || response.statusCode == 206) {
      print('✅ La tabla user_progress EXISTE');
      print('   - Esta es la tabla principal donde se guarda la evaluación');
      print('   - Campo: preferences->assessment_completed\n');
    } else {
      print('⚠️  No se pudo verificar user_progress: ${response.statusCode}\n');
    }
    
    client.close();
  } catch (e) {
    print('⚠️  Error verificando user_progress: $e\n');
  }
}
