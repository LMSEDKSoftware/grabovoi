import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/rewards_model.dart';
import '../config/supabase_config.dart';
import 'auth_service_simple.dart';

/// Servicio para gestionar el sistema de recompensas
class RewardsService {
  static const String _prefsKey = 'user_rewards';
  static const String _rewardsHistoryKey = 'rewards_history';
  
  // Constantes del sistema
  static const int cristalesPorDia = 10; // Cristales por día de pilotaje
  static const int cristalesParaCodigoPremium = 100; // Cristales necesarios para código premium
  static const int diasParaRestaurador = 7; // Días para obtener un restaurador
  static const double luzCuanticaPorPilotaje = 5.0; // Luz cuántica ganada por pilotaje
  static const int diasParaMantra = 21; // Días consecutivos para desbloquear mantra
  static const double luzCuanticaMaxima = 100.0; // Máximo de luz cuántica

  final AuthServiceSimple _authService = AuthServiceSimple();
  
  AuthServiceSimple get authService => _authService;

  /// Obtener recompensas del usuario
  Future<UserRewards> getUserRewards() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      // Intentar obtener de Supabase primero
      final response = await SupabaseConfig.client
          .from('user_rewards')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && response.isNotEmpty) {
        return UserRewards(
          userId: userId,
          cristalesEnergia: response['cristales_energia'] ?? 0,
          restauradoresArmonia: response['restauradores_armonia'] ?? 0,
          luzCuantica: (response['luz_cuantica'] ?? 0.0).toDouble(),
          mantrasDesbloqueados: List<String>.from(response['mantras_desbloqueados'] ?? []),
          codigosPremiumDesbloqueados: List<String>.from(response['codigos_premium_desbloqueados'] ?? []),
          ultimaActualizacion: DateTime.parse(response['ultima_actualizacion']),
          ultimaMeditacionEspecial: response['ultima_meditacion_especial'] != null
              ? DateTime.parse(response['ultima_meditacion_especial'])
              : null,
          logros: Map<String, dynamic>.from(response['logros'] ?? {}),
        );
      }

      // Si no existe en Supabase, crear uno nuevo
      return UserRewards(
        userId: userId,
        cristalesEnergia: 0,
        restauradoresArmonia: 0,
        luzCuantica: 0.0,
        mantrasDesbloqueados: [],
        codigosPremiumDesbloqueados: [],
        ultimaActualizacion: DateTime.now(),
        logros: {},
      );
    } catch (e) {
      print('⚠️ Error obteniendo recompensas de Supabase: $e');
      // Fallback a SharedPreferences
      return await _getRewardsFromPrefs(userId);
    }
  }

  /// Obtener recompensas desde SharedPreferences (fallback)
  Future<UserRewards> _getRewardsFromPrefs(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final rewardsJson = prefs.getString('$_prefsKey$userId');
    
    if (rewardsJson != null) {
      final map = jsonDecode(rewardsJson) as Map<String, dynamic>;
      return UserRewards(
        userId: userId,
        cristalesEnergia: map['cristalesEnergia'] ?? 0,
        restauradoresArmonia: map['restauradoresArmonia'] ?? 0,
        luzCuantica: (map['luzCuantica'] ?? 0.0).toDouble(),
        mantrasDesbloqueados: List<String>.from(map['mantrasDesbloqueados'] ?? []),
        codigosPremiumDesbloqueados: List<String>.from(map['codigosPremiumDesbloqueados'] ?? []),
        ultimaActualizacion: DateTime.parse(map['ultimaActualizacion']),
        logros: Map<String, dynamic>.from(map['logros'] ?? {}),
      );
    }

    return UserRewards(
      userId: userId,
      cristalesEnergia: 0,
      restauradoresArmonia: 0,
      luzCuantica: 0.0,
      mantrasDesbloqueados: [],
      codigosPremiumDesbloqueados: [],
      ultimaActualizacion: DateTime.now(),
      logros: {},
    );
  }

  /// Guardar recompensas
  Future<void> saveUserRewards(UserRewards rewards) async {
    try {
      // Guardar en Supabase
      await SupabaseConfig.client.from('user_rewards').upsert({
        'user_id': rewards.userId,
        'cristales_energia': rewards.cristalesEnergia,
        'restauradores_armonia': rewards.restauradoresArmonia,
        'luz_cuantica': rewards.luzCuantica,
        'mantras_desbloqueados': rewards.mantrasDesbloqueados,
        'codigos_premium_desbloqueados': rewards.codigosPremiumDesbloqueados,
        'ultima_actualizacion': rewards.ultimaActualizacion.toIso8601String(),
        'ultima_meditacion_especial': rewards.ultimaMeditacionEspecial?.toIso8601String(),
        'logros': rewards.logros,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('⚠️ Error guardando recompensas en Supabase: $e');
    }

    // También guardar en SharedPreferences como backup
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefsKey${rewards.userId}',
      jsonEncode({
        'userId': rewards.userId,
        'cristalesEnergia': rewards.cristalesEnergia,
        'restauradoresArmonia': rewards.restauradoresArmonia,
        'luzCuantica': rewards.luzCuantica,
        'mantrasDesbloqueados': rewards.mantrasDesbloqueados,
        'codigosPremiumDesbloqueados': rewards.codigosPremiumDesbloqueados,
        'ultimaActualizacion': rewards.ultimaActualizacion.toIso8601String(),
        'ultimaMeditacionEspecial': rewards.ultimaMeditacionEspecial?.toIso8601String(),
        'logros': rewards.logros,
      }),
    );
  }

  /// Recompensar por completar un pilotaje
  Future<UserRewards> recompensarPorPilotaje() async {
    final rewards = await getUserRewards();
    
    // Agregar cristales
    final nuevosCristales = rewards.cristalesEnergia + cristalesPorDia;
    
    // Agregar luz cuántica
    double nuevaLuzCuantica = rewards.luzCuantica + luzCuanticaPorPilotaje;
    if (nuevaLuzCuantica > luzCuanticaMaxima) {
      nuevaLuzCuantica = luzCuanticaMaxima;
    }

    final updatedRewards = rewards.copyWith(
      cristalesEnergia: nuevosCristales,
      luzCuantica: nuevaLuzCuantica,
      ultimaActualizacion: DateTime.now(),
    );

    await saveUserRewards(updatedRewards);
    return updatedRewards;
  }

  /// Recompensar por completar una semana (7 días consecutivos)
  Future<UserRewards> recompensarPorSemana() async {
    final rewards = await getUserRewards();
    
    final updatedRewards = rewards.copyWith(
      restauradoresArmonia: rewards.restauradoresArmonia + 1,
      ultimaActualizacion: DateTime.now(),
    );

    await saveUserRewards(updatedRewards);
    return updatedRewards;
  }

  /// Desbloquear mantra por racha de 21 días
  Future<UserRewards> desbloquearMantra(String mantraId) async {
    final rewards = await getUserRewards();
    
    if (rewards.mantrasDesbloqueados.contains(mantraId)) {
      return rewards; // Ya está desbloqueado
    }

    final updatedMantras = [...rewards.mantrasDesbloqueados, mantraId];
    
    final updatedRewards = rewards.copyWith(
      mantrasDesbloqueados: updatedMantras,
      ultimaActualizacion: DateTime.now(),
    );

    await saveUserRewards(updatedRewards);
    return updatedRewards;
  }

  /// Usar restaurador de armonía para mantener racha
  Future<UserRewards> usarRestauradorArmonia() async {
    final rewards = await getUserRewards();
    
    if (rewards.restauradoresArmonia <= 0) {
      throw Exception('No tienes restauradores de armonía disponibles');
    }

    final updatedRewards = rewards.copyWith(
      restauradoresArmonia: rewards.restauradoresArmonia - 1,
      ultimaActualizacion: DateTime.now(),
    );

    await saveUserRewards(updatedRewards);
    return updatedRewards;
  }

  /// Comprar código premium con cristales
  Future<UserRewards> comprarCodigoPremium(String codigoId, int costo) async {
    final rewards = await getUserRewards();
    
    if (rewards.cristalesEnergia < costo) {
      throw Exception('No tienes suficientes cristales de energía');
    }

    if (rewards.codigosPremiumDesbloqueados.contains(codigoId)) {
      throw Exception('Este código ya está desbloqueado');
    }

    final updatedCodigos = [...rewards.codigosPremiumDesbloqueados, codigoId];
    
    final updatedRewards = rewards.copyWith(
      cristalesEnergia: rewards.cristalesEnergia - costo,
      codigosPremiumDesbloqueados: updatedCodigos,
      ultimaActualizacion: DateTime.now(),
    );

    await saveUserRewards(updatedRewards);
    return updatedRewards;
  }

  /// Usar meditación especial (consume luz cuántica)
  Future<UserRewards> usarMeditacionEspecial() async {
    final rewards = await getUserRewards();
    
    if (rewards.luzCuantica < luzCuanticaMaxima) {
      throw Exception('No tienes suficiente luz cuántica para esta meditación');
    }

    // Resetear luz cuántica después de usar
    final updatedRewards = rewards.copyWith(
      luzCuantica: 0.0,
      ultimaMeditacionEspecial: DateTime.now(),
      ultimaActualizacion: DateTime.now(),
    );

    await saveUserRewards(updatedRewards);
    return updatedRewards;
  }

  /// Verificar y otorgar recompensas basadas en racha
  Future<UserRewards> verificarRecompensasPorRacha(int diasConsecutivos) async {
    final rewards = await getUserRewards();
    
    // Recompensa por semana (7 días)
    if (diasConsecutivos >= diasParaRestaurador && 
        diasConsecutivos % diasParaRestaurador == 0) {
      // Verificar si ya se otorgó este restaurador
      final ultimaSemanaRecompensada = rewards.logros['ultima_semana_recompensada'] as int? ?? 0;
      if (ultimaSemanaRecompensada < diasConsecutivos) {
        final updatedRewards = await recompensarPorSemana();
        final nuevosLogros = Map<String, dynamic>.from(updatedRewards.logros);
        nuevosLogros['ultima_semana_recompensada'] = diasConsecutivos;
        return updatedRewards.copyWith(logros: nuevosLogros);
      }
    }

    // Desbloquear mantra por 21 días (solo una vez)
    if (diasConsecutivos >= diasParaMantra) {
      final mantra21Id = 'mantra_21_dias';
      if (!rewards.mantrasDesbloqueados.contains(mantra21Id)) {
        return await desbloquearMantra(mantra21Id);
      }
    }

    return rewards;
  }

  /// Obtener historial de recompensas
  Future<List<Map<String, dynamic>>> getRewardsHistory() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return [];

    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('$_rewardsHistoryKey$userId');
    
    if (historyJson != null) {
      final List<dynamic> list = jsonDecode(historyJson);
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    return [];
  }

  /// Agregar entrada al historial
  Future<void> addToHistory(String tipo, String descripcion, {int? cantidad}) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    final history = await getRewardsHistory();
    history.insert(0, {
      'tipo': tipo,
      'descripcion': descripcion,
      'cantidad': cantidad,
      'fecha': DateTime.now().toIso8601String(),
    });

    // Mantener solo las últimas 50 entradas
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_rewardsHistoryKey$userId', jsonEncode(history));
  }
}

