import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/rewards_model.dart';
import '../config/supabase_config.dart';
import 'auth_service_simple.dart';
import 'user_progress_service.dart';

/// Servicio para gestionar el sistema de recompensas
class RewardsService {
  static const String _prefsKey = 'user_rewards';
  static const String _rewardsHistoryKey = 'rewards_history';
  
  // Constantes del sistema de recompensas
  static const int cristalesPorRepeticion = 3; // Cristales por completar repetición
  static const int cristalesPorPilotajeRetoDiario = 3; // Cristales por completar pilotaje del reto diario
  static const int cristalesPorPilotajeCuantico = 5; // Cristales por completar pilotaje cuántico
  static const int cristalesPorDesafio7Dias = 30; // Cristales por completar desafío de 7 días
  static const int cristalesPorDesafio14Dias = 50; // Cristales por completar desafío de 14 días
  static const int cristalesPorDesafio21Dias = 70; // Cristales por completar desafío de 21 días
  static const double luzCuanticaPorDiaRacha = 5.0; // Luz cuántica por día de racha (5%)
  static const double luzCuanticaMaxima = 100.0; // Máximo de luz cuántica (100%)
  
  // Constantes de compra
  static const int cristalesParaCodigoPremium = 100; // Cristales necesarios para código premium
  static const int cristalesParaAnclaContinuidad = 200; // Cristales necesarios para comprar una ancla de continuidad
  static const int cristalesParaVozNumerica = 50; // Cristales para desbloquear voz numérica en pilotajes
  static const int maxAnclasContinuidad = 2; // Máximo de anclas que se pueden tener (solo 2 días seguidos)
  static const int diasParaRestaurador = 7; // Días para obtener un restaurador
  static const int diasParaMantra = 21; // Días consecutivos para desbloquear mantra

  final AuthServiceSimple _authService = AuthServiceSimple();

  /// Notificador para que las vistas (Tienda, Portal) refresquen cuando se actualizan recompensas (ej. compra de cristales).
  static final ValueNotifier<int> rewardsUpdated = ValueNotifier<int>(0);
  
  AuthServiceSimple get authService => _authService;

  /// Obtener recompensas del usuario
  Future<UserRewards> getUserRewards({bool forceRefresh = false}) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) {
      print('❌ ERROR: Usuario no autenticado en getUserRewards');
      throw Exception('Usuario no autenticado');
    }

    print('🔍 [DIAGNÓSTICO] getUserRewards llamado para usuario: $userId, forceRefresh: $forceRefresh');

    try {
      // Intentar obtener de Supabase primero
      // Si forceRefresh es true, ordenar por updated_at para obtener la versión más reciente
      dynamic queryBuilder = SupabaseConfig.client
          .from('user_rewards')
          .select()
          .eq('user_id', userId);
      
      // Forzar lectura fresca si es necesario
      if (forceRefresh) {
        queryBuilder = queryBuilder.order('updated_at', ascending: false);
      }
      
      print('🔍 [DIAGNÓSTICO] Ejecutando query a Supabase...');
      final response = await queryBuilder.maybeSingle();
      print('🔍 [DIAGNÓSTICO] Respuesta de Supabase: ${response != null ? "ENCONTRADA" : "NO ENCONTRADA"}');

      if (response != null && response.isNotEmpty) {
        print('🔍 [DIAGNÓSTICO] Datos RAW de Supabase: cristales_energia=${response['cristales_energia']}, luz_cuantica=${response['luz_cuantica']}');
        
        final rewards = UserRewards(
          userId: userId,
          cristalesEnergia: response['cristales_energia'] ?? 0,
          restauradoresArmonia: response['restauradores_armonia'] ?? 0,
          anclasContinuidad: response['anclas_continuidad'] ?? 0,
          luzCuantica: (response['luz_cuantica'] ?? 0.0).toDouble(),
          mantrasDesbloqueados: List<String>.from(response['mantras_desbloqueados'] ?? []),
          codigosPremiumDesbloqueados: List<String>.from(response['codigos_premium_desbloqueados'] ?? []),
          ultimaActualizacion: DateTime.parse(response['ultima_actualizacion']),
          ultimaMeditacionEspecial: response['ultima_meditacion_especial'] != null
              ? DateTime.parse(response['ultima_meditacion_especial'])
              : null,
          logros: Map<String, dynamic>.from(response['logros'] ?? {}),
          voiceNumbersEnabled: response['voice_numbers_enabled'] == true,
          voiceGender: (response['voice_gender'] as String?) ?? 'female',
        );
        
        print('✅ [DIAGNÓSTICO] Recompensas leídas de SUPABASE para usuario $userId: ${rewards.cristalesEnergia} cristales, ${rewards.luzCuantica}% luz cuántica');
        return rewards;
      } else {
        print('⚠️ [DIAGNÓSTICO] No se encontró registro en Supabase para usuario $userId');
      }

      // Si no existe en Supabase, crear uno nuevo Y GUARDARLO
      final newRewards = UserRewards(
        userId: userId,
        cristalesEnergia: 0,
        restauradoresArmonia: 0,
        anclasContinuidad: 0,
        luzCuantica: 0.0,
        mantrasDesbloqueados: [],
        codigosPremiumDesbloqueados: [],
        ultimaActualizacion: DateTime.now(),
        logros: {},
        voiceNumbersEnabled: false,
        voiceGender: 'female',
      );
      
      // Guardar el nuevo registro en Supabase para que quede persistido
      try {
        await saveUserRewards(newRewards);
        print('✅ Registro inicial de recompensas creado para usuario: $userId');
      } catch (e) {
        print('⚠️ Error creando registro inicial de recompensas: $e');
        // Si falla al guardar, continuar con el objeto local
      }
      
      print('⚠️ [DIAGNÓSTICO] No se encontró registro en Supabase, creando nuevo registro con valores en 0');
      return newRewards;
    } catch (e, stackTrace) {
      print('❌ [DIAGNÓSTICO] ERROR obteniendo recompensas de Supabase: $e');
      print('❌ [DIAGNÓSTICO] Stack trace: $stackTrace');
      print('⚠️ [DIAGNÓSTICO] Haciendo FALLBACK a SharedPreferences...');
      // Fallback a SharedPreferences
      final prefsRewards = await _getRewardsFromPrefs(userId);
      print('⚠️ [DIAGNÓSTICO] Recompensas leídas de SHAREDPREFERENCES (fallback): ${prefsRewards.cristalesEnergia} cristales, ${prefsRewards.luzCuantica}% luz cuántica');
      return prefsRewards;
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
        anclasContinuidad: map['anclasContinuidad'] ?? 0,
        luzCuantica: (map['luzCuantica'] ?? 0.0).toDouble(),
        mantrasDesbloqueados: List<String>.from(map['mantrasDesbloqueados'] ?? []),
        codigosPremiumDesbloqueados: List<String>.from(map['codigosPremiumDesbloqueados'] ?? []),
        ultimaActualizacion: DateTime.parse(map['ultimaActualizacion']),
        logros: Map<String, dynamic>.from(map['logros'] ?? {}),
        voiceNumbersEnabled: map['voiceNumbersEnabled'] == true,
        voiceGender: (map['voiceGender'] as String?) ?? 'female',
      );
    }

    return UserRewards(
      userId: userId,
      cristalesEnergia: 0,
      restauradoresArmonia: 0,
      anclasContinuidad: 0,
      luzCuantica: 0.0,
      mantrasDesbloqueados: [],
      codigosPremiumDesbloqueados: [],
      ultimaActualizacion: DateTime.now(),
      logros: {},
      voiceNumbersEnabled: false,
      voiceGender: 'female',
    );
  }

  /// Guardar solo configuración de voz numérica (reutilizable desde UI).
  Future<void> saveVoiceNumbersSettings({required bool enabled, required String gender}) async {
    final rewards = await getUserRewards();
    await saveUserRewards(rewards.copyWith(
      voiceNumbersEnabled: enabled,
      voiceGender: gender == 'male' ? 'male' : 'female',
    ));
  }

  /// Guardar recompensas
  Future<void> saveUserRewards(UserRewards rewards) async {
    print('💾 [DIAGNÓSTICO] saveUserRewards llamado para usuario ${rewards.userId}');
    print('💾 [DIAGNÓSTICO] Datos a guardar: ${rewards.cristalesEnergia} cristales, ${rewards.luzCuantica}% luz cuántica');
    
    // Verificar autenticación antes de guardar
    final currentUser = SupabaseConfig.client.auth.currentUser;
    if (currentUser == null) {
      print('❌ ERROR: Usuario no autenticado en Supabase. No se puede guardar recompensas.');
      throw Exception('Usuario no autenticado en Supabase');
    }
    
    // Verificar que el userId coincida con el usuario autenticado
    if (currentUser.id != rewards.userId) {
      print('❌ ERROR: userId no coincide con usuario autenticado. userId: ${rewards.userId}, auth.uid: ${currentUser.id}');
      throw Exception('userId no coincide con usuario autenticado');
    }
    
    print('✅ [DIAGNÓSTICO] Usuario autenticado verificado: ${currentUser.id}');
    
    try {
      final dataToSave = {
        'user_id': rewards.userId,
        'cristales_energia': rewards.cristalesEnergia,
        'restauradores_armonia': rewards.restauradoresArmonia,
        'anclas_continuidad': rewards.anclasContinuidad,
        'luz_cuantica': rewards.luzCuantica,
        'mantras_desbloqueados': rewards.mantrasDesbloqueados,
        'codigos_premium_desbloqueados': rewards.codigosPremiumDesbloqueados,
        'ultima_actualizacion': rewards.ultimaActualizacion.toIso8601String(),
        'ultima_meditacion_especial': rewards.ultimaMeditacionEspecial?.toIso8601String(),
        'logros': rewards.logros,
        'voice_numbers_enabled': rewards.voiceNumbersEnabled,
        'voice_gender': rewards.voiceGender,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      print('💾 [DIAGNÓSTICO] Ejecutando upsert en Supabase con datos: $dataToSave');
      
      final response = await SupabaseConfig.client.from('user_rewards').upsert(
        dataToSave,
        onConflict: 'user_id'
      ).select().single();
      
      print('✅ [DIAGNÓSTICO] Recompensas GUARDADAS en Supabase para usuario ${rewards.userId}');
      print('✅ [DIAGNÓSTICO] Confirmación de Supabase: ${response['cristales_energia']} cristales, ${response['luz_cuantica']}% luz cuántica');
    } catch (e, stackTrace) {
      print('❌ [DIAGNÓSTICO] ERROR guardando recompensas en Supabase: $e');
      print('❌ [DIAGNÓSTICO] Stack trace: $stackTrace');
      rethrow; // Re-lanzar el error para que se pueda manejar arriba
    }

    // También guardar en SharedPreferences como backup
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefsKey${rewards.userId}',
      jsonEncode({
        'userId': rewards.userId,
        'cristalesEnergia': rewards.cristalesEnergia,
        'restauradoresArmonia': rewards.restauradoresArmonia,
        'anclasContinuidad': rewards.anclasContinuidad,
        'luzCuantica': rewards.luzCuantica,
        'mantrasDesbloqueados': rewards.mantrasDesbloqueados,
        'codigosPremiumDesbloqueados': rewards.codigosPremiumDesbloqueados,
        'ultimaActualizacion': rewards.ultimaActualizacion.toIso8601String(),
        'ultimaMeditacionEspecial': rewards.ultimaMeditacionEspecial?.toIso8601String(),
        'logros': rewards.logros,
        'voiceNumbersEnabled': rewards.voiceNumbersEnabled,
        'voiceGender': rewards.voiceGender,
      }),
    );
  }

  /// Verificar si ya se otorgaron recompensas por un código en el día actual
  Future<bool> yaSeOtorgaronRecompensas({
    required String codigoId,
    required String tipoAccion, // 'repeticion' o 'pilotaje'
  }) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return false;

      final hoy = DateTime.now();
      final fechaDia = DateTime(hoy.year, hoy.month, hoy.day);
      final fechaDiaStr = fechaDia.toIso8601String().split('T')[0]; // Formato YYYY-MM-DD

      // Verificar en Supabase si ya existe un registro
      final response = await SupabaseConfig.client
          .from('user_rewarded_actions')
          .select()
          .eq('user_id', userId)
          .eq('codigo_id', codigoId)
          .eq('tipo_accion', tipoAccion)
          .eq('fecha_dia', fechaDiaStr)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('⚠️ Error verificando recompensas otorgadas: $e');
      // Si hay error, permitir otorgar recompensas (fallback)
      return false;
    }
  }

  /// Registrar que se otorgaron recompensas por un código
  Future<void> registrarRecompensaOtorgada({
    required String codigoId,
    required String tipoAccion, // 'repeticion' o 'pilotaje'
    required int cristalesOtorgados,
  }) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      final hoy = DateTime.now();

      // Insertar registro en Supabase
      final fechaDia = DateTime(hoy.year, hoy.month, hoy.day);
      await SupabaseConfig.client.from('user_rewarded_actions').insert({
        'user_id': userId,
        'codigo_id': codigoId,
        'tipo_accion': tipoAccion,
        'cristales_otorgados': cristalesOtorgados,
        'fecha': hoy.toIso8601String(),
        'fecha_dia': fechaDia.toIso8601String().split('T')[0], // Formato YYYY-MM-DD
        'created_at': hoy.toIso8601String(),
      });

      print('✅ Recompensa registrada: $tipoAccion para código $codigoId');
    } catch (e) {
      print('⚠️ Error registrando recompensa otorgada: $e');
      // No lanzar error, solo registrar
    }
  }

  /// Recompensar por completar una repetición
  /// Retorna un mapa con información sobre las recompensas otorgadas
  Future<Map<String, dynamic>> recompensarPorRepeticion({
    String? codigoId,
  }) async {
    // Si se proporciona código ID, verificar si ya se otorgaron recompensas
    bool yaOtorgadas = false;
    if (codigoId != null) {
      yaOtorgadas = await yaSeOtorgaronRecompensas(
        codigoId: codigoId,
        tipoAccion: 'repeticion',
      );
    }

    // Si ya se otorgaron, retornar información sin otorgar más
    if (yaOtorgadas) {
      final rewards = await getUserRewards(forceRefresh: true);
      return {
        'rewards': rewards,
        'cristalesGanados': 0,
        'luzCuanticaAnterior': rewards.luzCuantica,
        'luzCuanticaActual': rewards.luzCuantica,
        'yaOtorgadas': true,
        'mensaje': 'Ya recibiste cristales por este código hoy. Puedes seguir usándolo, pero no recibirás más recompensas.',
      };
    }

    // Forzar lectura fresca antes de otorgar recompensas
    final rewards = await getUserRewards(forceRefresh: true);
    final luzCuanticaAnterior = rewards.luzCuantica;
    
    print('💎 Otorgando ${cristalesPorRepeticion} cristales por repetición. Cristales actuales: ${rewards.cristalesEnergia}');
    
    final updatedRewards = rewards.copyWith(
      cristalesEnergia: rewards.cristalesEnergia + cristalesPorRepeticion,
      ultimaActualizacion: DateTime.now(),
    );

    print('💎 Guardando ${updatedRewards.cristalesEnergia} cristales totales después de la repetición');
    await saveUserRewards(updatedRewards);
    await addToHistory(
      'cristales',
      'Cristales ganados por completar repetición',
      cantidad: cristalesPorRepeticion,
    );

    // Registrar que se otorgaron recompensas
    if (codigoId != null) {
      await registrarRecompensaOtorgada(
        codigoId: codigoId,
        tipoAccion: 'repeticion',
        cristalesOtorgados: cristalesPorRepeticion,
      );
    }
    
    // Actualizar luz cuántica basada en racha
    final progressService = UserProgressService();
    final progress = await progressService.getUserProgress();
    double? luzCuanticaActual;
    if (progress != null) {
      final diasConsecutivos = progress['dias_consecutivos'] ?? 0;
      final updatedRewardsConLuz = await actualizarLuzCuanticaPorRacha(diasConsecutivos);
      luzCuanticaActual = updatedRewardsConLuz.luzCuantica;
    }
    
    return {
      'rewards': updatedRewards,
      'cristalesGanados': cristalesPorRepeticion,
      'luzCuanticaAnterior': luzCuanticaAnterior,
      'luzCuanticaActual': luzCuanticaActual ?? luzCuanticaAnterior,
      'yaOtorgadas': false,
    };
  }

  /// Recompensar por completar pilotaje del reto diario
  /// Retorna un mapa con información sobre las recompensas otorgadas
  Future<Map<String, dynamic>> recompensarPorPilotajeRetoDiario() async {
    final rewards = await getUserRewards();
    final luzCuanticaAnterior = rewards.luzCuantica;
    
    final updatedRewards = rewards.copyWith(
      cristalesEnergia: rewards.cristalesEnergia + cristalesPorPilotajeRetoDiario,
      ultimaActualizacion: DateTime.now(),
    );

    await saveUserRewards(updatedRewards);
    await addToHistory(
      'cristales',
      'Cristales ganados por completar pilotaje del reto diario',
      cantidad: cristalesPorPilotajeRetoDiario,
    );
    
    // Actualizar luz cuántica basada en racha
    final progressService = UserProgressService();
    final progress = await progressService.getUserProgress();
    double? luzCuanticaActual;
    if (progress != null) {
      final diasConsecutivos = progress['dias_consecutivos'] ?? 0;
      final updatedRewardsConLuz = await actualizarLuzCuanticaPorRacha(diasConsecutivos);
      luzCuanticaActual = updatedRewardsConLuz.luzCuantica;
    }
    
    return {
      'rewards': updatedRewards,
      'cristalesGanados': cristalesPorPilotajeRetoDiario,
      'luzCuanticaAnterior': luzCuanticaAnterior,
      'luzCuanticaActual': luzCuanticaActual ?? luzCuanticaAnterior,
    };
  }

  /// Recompensar por completar pilotaje cuántico
  /// Retorna un mapa con información sobre las recompensas otorgadas
  Future<Map<String, dynamic>> recompensarPorPilotajeCuantico({
    String? codigoId,
  }) async {
    // Si se proporciona código ID, verificar si ya se otorgaron recompensas
    bool yaOtorgadas = false;
    if (codigoId != null) {
      yaOtorgadas = await yaSeOtorgaronRecompensas(
        codigoId: codigoId,
        tipoAccion: 'pilotaje',
      );
    }

    // Si ya se otorgaron, retornar información sin otorgar más
    if (yaOtorgadas) {
      final rewards = await getUserRewards(forceRefresh: true);
      return {
        'rewards': rewards,
        'cristalesGanados': 0,
        'luzCuanticaAnterior': rewards.luzCuantica,
        'luzCuanticaActual': rewards.luzCuantica,
        'yaOtorgadas': true,
        'mensaje': 'Ya recibiste cristales por este código hoy. Puedes seguir usándolo, pero no recibirás más recompensas.',
      };
    }

    // Forzar lectura fresca antes de otorgar recompensas
    final rewards = await getUserRewards(forceRefresh: true);
    final luzCuanticaAnterior = rewards.luzCuantica;
    
    print('💎 Otorgando ${cristalesPorPilotajeCuantico} cristales por pilotaje cuántico. Cristales actuales: ${rewards.cristalesEnergia}');
    
    final updatedRewards = rewards.copyWith(
      cristalesEnergia: rewards.cristalesEnergia + cristalesPorPilotajeCuantico,
      ultimaActualizacion: DateTime.now(),
    );

    print('💎 Guardando ${updatedRewards.cristalesEnergia} cristales totales después del pilotaje');
    await saveUserRewards(updatedRewards);
    await addToHistory(
      'cristales',
      'Cristales ganados por completar pilotaje cuántico',
      cantidad: cristalesPorPilotajeCuantico,
    );

    // Registrar que se otorgaron recompensas
    if (codigoId != null) {
      await registrarRecompensaOtorgada(
        codigoId: codigoId,
        tipoAccion: 'pilotaje',
        cristalesOtorgados: cristalesPorPilotajeCuantico,
      );
    }
    
    // Actualizar luz cuántica basada en racha
    final progressService = UserProgressService();
    final progress = await progressService.getUserProgress();
    double? luzCuanticaActual;
    if (progress != null) {
      final diasConsecutivos = progress['dias_consecutivos'] ?? 0;
      final updatedRewardsConLuz = await actualizarLuzCuanticaPorRacha(diasConsecutivos);
      luzCuanticaActual = updatedRewardsConLuz.luzCuantica;
    }
    
    return {
      'rewards': updatedRewards,
      'cristalesGanados': cristalesPorPilotajeCuantico,
      'luzCuanticaAnterior': luzCuanticaAnterior,
      'luzCuanticaActual': luzCuanticaActual ?? luzCuanticaAnterior,
      'yaOtorgadas': false,
    };
  }

  /// Recompensar por completar un desafío completo
  Future<UserRewards> recompensarPorDesafioCompletado(int duracionDias) async {
    final rewards = await getUserRewards();
    
    int cristalesGanados = 0;
    if (duracionDias == 7) {
      cristalesGanados = cristalesPorDesafio7Dias;
    } else if (duracionDias == 14) {
      cristalesGanados = cristalesPorDesafio14Dias;
    } else if (duracionDias == 21) {
      cristalesGanados = cristalesPorDesafio21Dias;
    } else {
      throw Exception('Duración de desafío no válida: $duracionDias días');
    }
    
    final updatedRewards = rewards.copyWith(
      cristalesEnergia: rewards.cristalesEnergia + cristalesGanados,
      ultimaActualizacion: DateTime.now(),
    );

    await saveUserRewards(updatedRewards);
    await addToHistory(
      'cristales',
      'Cristales ganados por completar desafío de $duracionDias días',
      cantidad: cristalesGanados,
    );
    return updatedRewards;
  }

  /// Calcular y actualizar luz cuántica basada en la racha de días
  Future<UserRewards> actualizarLuzCuanticaPorRacha(int diasConsecutivos) async {
    final rewards = await getUserRewards();
    
    // Calcular luz cuántica: 5% por cada día de racha (máximo 100%)
    double nuevaLuzCuantica = (diasConsecutivos * luzCuanticaPorDiaRacha).clamp(0.0, luzCuanticaMaxima);
    
    final updatedRewards = rewards.copyWith(
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

  /// Comprar Ancla de Continuidad con cristales.
  /// [costo] y [maxAnclas] vienen de StoreConfigService; si no se pasan, se usan los valores por defecto.
  Future<UserRewards> comprarAnclaContinuidad({int? costo, int? maxAnclas}) async {
    final costoReal = costo ?? cristalesParaAnclaContinuidad;
    final maxReal = maxAnclas ?? maxAnclasContinuidad;
    final rewards = await getUserRewards();

    if (rewards.cristalesEnergia < costoReal) {
      throw Exception('No tienes suficientes cristales de energía. Necesitas $costoReal cristales.');
    }

    if (rewards.anclasContinuidad >= maxReal) {
      throw Exception('Ya tienes el máximo de $maxReal anclas de continuidad.');
    }

    final updatedRewards = rewards.copyWith(
      cristalesEnergia: rewards.cristalesEnergia - costoReal,
      anclasContinuidad: rewards.anclasContinuidad + 1,
      ultimaActualizacion: DateTime.now(),
    );

    await saveUserRewards(updatedRewards);
    await addToHistory(
      'ancla_continuidad',
      'Ancla de Continuidad comprada',
      cantidad: 1,
    );
    return updatedRewards;
  }

  /// Comprar voz numérica con cristales (habilita voiceNumbersEnabled).
  /// [costo] viene de StoreConfigService; si no se pasa, se usa cristalesParaVozNumerica.
  Future<UserRewards> comprarVozNumerica({int? costo}) async {
    final costoReal = costo ?? cristalesParaVozNumerica;
    final rewards = await getUserRewards();

    if (rewards.cristalesEnergia < costoReal) {
      throw Exception('No tienes suficientes cristales. Necesitas $costoReal cristales.');
    }

    if (rewards.voiceNumbersEnabled) {
      throw Exception('La voz numérica ya está desbloqueada');
    }

    final newLogros = Map<String, dynamic>.from(rewards.logros)
      ..['voice_numbers_unlocked'] = true;
    final updatedRewards = rewards.copyWith(
      cristalesEnergia: rewards.cristalesEnergia - costoReal,
      voiceNumbersEnabled: true,
      logros: newLogros,
      ultimaActualizacion: DateTime.now(),
    );

    await saveUserRewards(updatedRewards);
    await addToHistory(
      'voice_numbers',
      'Voz numérica desbloqueada',
    );
    return updatedRewards;
  }

  /// Añadir cristales por compra (IAP simulada o real). Cuando la tienda valide el pago,
  /// se llama este método con la cantidad del paquete comprado.
  Future<UserRewards> agregarCristalesComprados(int cantidad) async {
    final rewards = await getUserRewards(forceRefresh: true);
    final updatedRewards = rewards.copyWith(
      cristalesEnergia: rewards.cristalesEnergia + cantidad,
      ultimaActualizacion: DateTime.now(),
    );
    await saveUserRewards(updatedRewards);
    await addToHistory(
      'cristales',
      'Cristales comprados (paquete)',
      cantidad: cantidad,
    );
    rewardsUpdated.value++;
    return updatedRewards;
  }

  /// Usar Ancla de Continuidad para salvar la racha
  Future<UserRewards> usarAnclaContinuidad() async {
    final rewards = await getUserRewards();
    
    if (rewards.anclasContinuidad <= 0) {
      throw Exception('No tienes Anclas de Continuidad disponibles');
    }

    final updatedRewards = rewards.copyWith(
      anclasContinuidad: rewards.anclasContinuidad - 1,
      ultimaActualizacion: DateTime.now(),
    );

    await saveUserRewards(updatedRewards);
    await addToHistory(
      'ancla_continuidad',
      'Ancla de Continuidad usada para salvar racha',
      cantidad: -1,
    );
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

