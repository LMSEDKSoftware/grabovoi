import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manifestacion_numerica_grabovoi/config/supabase_config.dart';
import 'package:manifestacion_numerica_grabovoi/services/auth_service_simple.dart';
import 'package:manifestacion_numerica_grabovoi/services/rewards_service.dart';
import 'package:dotenv/dotenv.dart';

/// Script para verificar el estado de las recompensas en la base de datos
/// Uso: dart run scripts/verificar_recompensas.dart [email]
Future<void> main(List<String> args) async {
  print('🔍 Script de Verificación de Recompensas\n');
  
  // Cargar variables de entorno
  final env = DotEnv(includePlatformEnvironment: true)..load(['.env']);
  
  // Inicializar Supabase
  await Supabase.initialize(
    url: env['SUPABASE_URL'] ?? '',
    anonKey: env['SUPABASE_ANON_KEY'] ?? '',
  );
  
  final email = args.isNotEmpty ? args[0] : '2005.ivan@gmail.com';
  print('📧 Verificando recompensas para: $email\n');
  
  try {
    // 1. Buscar el usuario por email
    print('1️⃣ Buscando usuario en auth.users...');
    final authResponse = await SupabaseConfig.client.auth.admin.listUsers();
    final user = authResponse.users.firstWhere(
      (u) => u.email == email,
      orElse: () => throw Exception('Usuario no encontrado'),
    );
    
    print('✅ Usuario encontrado:');
    print('   - ID: ${user.id}');
    print('   - Email: ${user.email}');
    print('   - Creado: ${user.createdAt}');
    print('');
    
    // 2. Verificar datos en user_rewards
    print('2️⃣ Verificando datos en tabla user_rewards...');
    final rewardsResponse = await SupabaseConfig.client
        .from('user_rewards')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    
    if (rewardsResponse != null) {
      print('✅ Registro encontrado en user_rewards:');
      print('   - Cristales de energía: ${rewardsResponse['cristales_energia']}');
      print('   - Luz cuántica: ${rewardsResponse['luz_cuantica']}%');
      print('   - Restauradores: ${rewardsResponse['restauradores_armonia']}');
      print('   - Anclas continuidad: ${rewardsResponse['anclas_continuidad']}');
      print('   - Última actualización: ${rewardsResponse['ultima_actualizacion']}');
      print('   - Updated at: ${rewardsResponse['updated_at']}');
      print('   - Created at: ${rewardsResponse['created_at']}');
      print('');
    } else {
      print('❌ NO se encontró registro en user_rewards para este usuario');
      print('');
    }
    
    // 3. Verificar usando RewardsService
    print('3️⃣ Verificando usando RewardsService...');
    final authService = AuthServiceSimple();
    await authService.initialize();
    
    // Simular login del usuario
    try {
      final signInResponse = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: 'dummy', // Esto fallará, pero necesitamos el usuario
      );
    } catch (e) {
      // Ignorar error de password, solo necesitamos verificar el servicio
    }
    
    final rewardsService = RewardsService();
    final rewards = await rewardsService.getUserRewards(forceRefresh: true);
    
    print('✅ Datos obtenidos por RewardsService:');
    print('   - Cristales de energía: ${rewards.cristalesEnergia}');
    print('   - Luz cuántica: ${rewards.luzCuantica}%');
    print('   - Restauradores: ${rewards.restauradoresArmonia}');
    print('   - Anclas continuidad: ${rewards.anclasContinuidad}');
    print('   - Última actualización: ${rewards.ultimaActualizacion}');
    print('');
    
    // 4. Comparar datos
    print('4️⃣ Comparación:');
    if (rewardsResponse != null) {
      final dbCristales = rewardsResponse['cristales_energia'] as int;
      final serviceCristales = rewards.cristalesEnergia;
      final dbLuz = (rewardsResponse['luz_cuantica'] as num).toDouble();
      final serviceLuz = rewards.luzCuantica;
      
      if (dbCristales == serviceCristales && dbLuz == serviceLuz) {
        print('✅ Los datos coinciden entre base de datos y servicio');
      } else {
        print('⚠️ DISCREPANCIA ENCONTRADA:');
        print('   - Base de datos: $dbCristales cristales, $dbLuz% luz');
        print('   - Servicio: $serviceCristales cristales, $serviceLuz% luz');
      }
    }
    print('');
    
    // 5. Verificar historial de recompensas
    print('5️⃣ Verificando historial de recompensas...');
    final historyResponse = await SupabaseConfig.client
        .from('rewards_history')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(10);
    
    if (historyResponse.isNotEmpty) {
      print('✅ Últimas 10 recompensas:');
      for (var entry in historyResponse) {
        print('   - ${entry['tipo']}: ${entry['cantidad']} (${entry['created_at']})');
      }
    } else {
      print('⚠️ No se encontró historial de recompensas');
    }
    print('');
    
    // 6. Verificar usuario_progreso (para luz cuántica)
    print('6️⃣ Verificando usuario_progreso (para calcular luz cuántica)...');
    final progressResponse = await SupabaseConfig.client
        .from('usuario_progreso')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    
    if (progressResponse != null) {
      print('✅ Progreso encontrado:');
      print('   - Días consecutivos: ${progressResponse['dias_consecutivos']}');
      print('   - Total pilotajes: ${progressResponse['total_pilotajes']}');
      print('   - Último pilotaje: ${progressResponse['ultimo_pilotaje']}');
      print('   - Nivel energía: ${progressResponse['energy_level']}');
    } else {
      print('⚠️ No se encontró registro en usuario_progreso');
    }
    
  } catch (e, stackTrace) {
    print('❌ ERROR: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
  
  print('\n✅ Verificación completada');
  exit(0);
}

