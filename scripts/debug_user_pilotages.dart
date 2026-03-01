
import 'dart:io';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  // Cargar variables de entorno
  final env = Platform.environment;
  final supabaseUrl = env['SUPABASE_URL'];
  final supabaseServiceRoleKey = env['SB_SERVICE_ROLE_KEY'];

  if (supabaseUrl == null || supabaseServiceRoleKey == null) {
    print('❌ Error: Falta SUPABASE_URL o SB_SERVICE_ROLE_KEY en variables de entorno.');
    exit(1);
  }

  print('🔌 Conectando a Supabase...');
  final client = SupabaseClient(supabaseUrl, supabaseServiceRoleKey);

  const email = 'ifernandez@lmsedk.com';
  print('🔍 Buscando usuario: $email');

  try {
    // 1. Obtener ID de usuario (admin)
    final usersResponse = await client.auth.admin.listUsers();
    final user = usersResponse.find((u) => u.email == email);

    if (user == null) {
      print('❌ Usuario no encontrado con email: $email');
      exit(1);
    }

    print('✅ Usuario encontrado. ID: ${user.id}');

    // 2. Buscar acciones de pilotaje
    print('📂 Buscando acciones en public.user_actions...');
    final response = await client
        .from('user_actions')
        .select()
        .eq('user_id', user.id)
        .in_('action_type', ['sesionPilotaje', 'codigoRepetido', 'pilotajeCompartido'])
        .order('recorded_at', ascending: false);

    final actions = response as List<dynamic>;
    print('📊 Total acciones encontradas: ${actions.length}');

    print('\n--- DETALLE DE CÓDIGOS PILOTADOS ---');
    for (final action in actions) {
      final data = action['action_data'] as Map<String, dynamic>;
      final codeId = data['codeId'];
      final codeName = data['codeName'];
      final timestamp = action['recorded_at'];
      
      print('📅 $timestamp | Tipo: ${action['action_type']}');
      print('   CodeID Raw: "$codeId" (Len: ${codeId?.toString().length})');
      if (codeId != null) {
        print('   CodeID Trimmed: "${codeId.toString().trim()}"');
      }
      print('   Nombre: $codeName');
      print('-------------------------------------------');
    }

  } catch (e) {
    print('❌ Error: $e');
  }
}

extension ListExtension<T> on List<T> {
  T? find(bool Function(T) test) {
    try {
      return firstWhere(test);
    } catch (_) {
      return null;
    }
  }
}
