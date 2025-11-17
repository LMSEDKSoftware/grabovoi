import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/challenge_model.dart';
import 'challenge_tracking_service.dart';
import 'auth_service_simple.dart';
import 'rewards_service.dart';

class ChallengeService extends ChangeNotifier {
  static final ChallengeService _instance = ChallengeService._internal();
  factory ChallengeService() => _instance;
  ChallengeService._internal();

  final ChallengeTrackingService _trackingService = ChallengeTrackingService();
  final AuthServiceSimple _authService = AuthServiceSimple();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  final List<Challenge> _availableChallenges = [];
  final Map<String, Challenge> _userChallenges = {};

  // Getters
  List<Challenge> get availableChallenges => List.unmodifiable(_availableChallenges);
  Map<String, Challenge> get userChallenges => Map.unmodifiable(_userChallenges);
  
  // Obtener desafíos disponibles
  List<Challenge> getAvailableChallenges() {
    return _availableChallenges.where((challenge) => 
      !_userChallenges.containsKey(challenge.id)
    ).toList();
  }

  // Obtener desafíos del usuario
  List<Challenge> getUserChallenges() {
    return _userChallenges.values.toList();
  }

  // Obtener desafío específico
  Challenge? getChallenge(String id) {
    return _userChallenges[id] ?? _availableChallenges.firstWhere(
      (challenge) => challenge.id == id,
      orElse: () => throw Exception('Challenge not found'),
    );
  }

  // Actualizar desafío (usado internamente por ChallengeTrackingService)
  void actualizarDesafio(String challengeId, Challenge updatedChallenge) {
    _userChallenges[challengeId] = updatedChallenge;
    notifyListeners();
  }

  // Inicializar desafíos disponibles
  Future<void> initializeChallenges() async {
    if (!_authService.isLoggedIn) {
      _availableChallenges.clear();
      _availableChallenges.addAll(_createDefaultChallenges());
      notifyListeners();
      return;
    }

    try {
      await _loadUserChallengesFromSupabase();
      _availableChallenges.clear();
      _availableChallenges.addAll(_createDefaultChallenges());
      notifyListeners();
    } catch (e) {
      print('Error cargando desafíos desde Supabase: $e');
      // Fallback a desafíos locales
      _availableChallenges.clear();
      _availableChallenges.addAll(_createDefaultChallenges());
      notifyListeners();
    }
  }

  // Cargar desafíos del usuario desde Supabase
  Future<void> _loadUserChallengesFromSupabase() async {
    if (!_authService.isLoggedIn) return;

    try {
      final response = await _supabase
          .from('user_challenges')
          .select()
          .eq('user_id', _authService.currentUser!.id);

      _userChallenges.clear();
      for (final challengeData in response) {
        final challenge = _createChallengeFromSupabaseData(challengeData);
        _userChallenges[challenge.id] = challenge;
        
        // Si el desafío está en progreso, inicializar progreso y verificar racha
        if (challenge.status == ChallengeStatus.enProgreso) {
          // Inicializar progreso desde el desafío
          await _inicializarProgresoDesdeChallenge(challenge);
          // Verificar y actualizar racha al cargar
          await _trackingService.verificarYActualizarRacha(challenge.id);
        }
      }
    } catch (e) {
      print('Error cargando desafíos del usuario: $e');
      rethrow;
    }
  }

  // Crear desafío desde datos de Supabase
  Challenge _createChallengeFromSupabaseData(Map<String, dynamic> data) {
    // Buscar el desafío base en los desafíos disponibles
    final baseChallenge = _availableChallenges.firstWhere(
      (c) => c.id == data['challenge_id'],
      orElse: () => _createDefaultChallenges().firstWhere(
        (c) => c.id == data['challenge_id'],
      ),
    );

    return baseChallenge.copyWith(
      status: ChallengeStatus.values.firstWhere(
        (s) => s.toString().split('.').last == data['status'],
        orElse: () => ChallengeStatus.noIniciado,
      ),
      startDate: data['start_date'] != null ? DateTime.parse(data['start_date']) : null,
      endDate: data['end_date'] != null ? DateTime.parse(data['end_date']) : null,
      currentDay: data['current_day'] ?? 0,
      totalProgress: data['total_progress'] ?? 0,
      dayProgress: (data['day_progress'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(int.parse(k), DayProgress.fromJson(v as Map<String, dynamic>)),
      ) ?? {},
    );
  }

  // Inicializar progreso del desafío desde Challenge
  Future<void> _inicializarProgresoDesdeChallenge(Challenge challenge) async {
    // Convertir dayProgress del Challenge a ChallengeProgress
    final dayProgressMap = <int, DayProgress>{};
    for (final entry in challenge.dayProgress.entries) {
      dayProgressMap[entry.key] = entry.value;
    }

    final progress = ChallengeProgress(
      challengeId: challenge.id,
      currentDay: challenge.currentDay,
      dayProgress: dayProgressMap,
      totalActionsCompleted: 0, // Calcular desde dayProgress si es necesario
      totalTimeSpent: Duration.zero, // Calcular desde dayProgress si es necesario
      recentActions: [],
      lastActivity: DateTime.now(),
    );

    // Registrar el progreso en el tracking service
    _trackingService.registrarProgreso(progress);
  }

  // Crear desafíos por defecto
  List<Challenge> _createDefaultChallenges() {
    return [
      Challenge(
        id: 'iniciacion_energetica',
        title: 'Desafío de Iniciación Energética',
        description: 'Comienza tu viaje de manifestación con los códigos básicos.',
        durationDays: 7,
        difficulty: ChallengeDifficulty.principiante,
        dailyActions: [
          ChallengeAction(
            type: ActionType.codigoRepetido,
            description: 'Repetir al menos 1 código al día',
            requiredCount: 1,
          ),
          ChallengeAction(
            type: ActionType.pilotajeCompartido,
            description: 'Compartir al menos 1 pilotaje o certificado al día',
            requiredCount: 1,
          ),
          ChallengeAction(
            type: ActionType.tiempoEnApp,
            description: 'Pasar al menos 15 minutos en la app al día',
            requiredCount: 1,
            requiredDuration: const Duration(minutes: 15),
          ),
        ],
        icon: '🌟',
        color: '#4CAF50',
        rewards: ['Badge de Iniciación', 'Acceso a códigos avanzados'],
      ),
      Challenge(
        id: 'armonizacion_intermedia',
        title: 'Desafío de Armonización Intermedia',
        description: 'Profundiza en tu conexión interior y expande tu campo energético.',
        durationDays: 14,
        difficulty: ChallengeDifficulty.intermedio,
        dailyActions: [
          ChallengeAction(
            type: ActionType.codigoRepetido,
            description: 'Repetir al menos 2 códigos al día',
            requiredCount: 2,
          ),
          ChallengeAction(
            type: ActionType.sesionPilotaje,
            description: 'Completar al menos 1 sesión de pilotaje al día',
            requiredCount: 1,
          ),
          ChallengeAction(
            type: ActionType.pilotajeCompartido,
            description: 'Compartir al menos 1 pilotaje al día',
            requiredCount: 1,
          ),
          ChallengeAction(
            type: ActionType.tiempoEnApp,
            description: 'Pasar al menos 20 minutos en la app al día',
            requiredCount: 1,
            requiredDuration: const Duration(minutes: 20),
          ),
        ],
        icon: '⭐',
        color: '#2196F3',
        rewards: ['Badge de Armonización', 'Códigos exclusivos', 'Meditación guiada'],
      ),
      Challenge(
        id: 'luz_dorada_avanzada',
        title: 'Desafío Avanzado de Luz Dorada',
        description: 'Expande tu campo vibracional al máximo nivel de manifestación.',
        durationDays: 21,
        difficulty: ChallengeDifficulty.avanzado,
        dailyActions: [
          ChallengeAction(
            type: ActionType.codigoRepetido,
            description: 'Repetir al menos 3 códigos al día',
            requiredCount: 3,
          ),
          ChallengeAction(
            type: ActionType.sesionPilotaje,
            description: 'Completar al menos 2 sesiones de pilotaje al día',
            requiredCount: 2,
          ),
          ChallengeAction(
            type: ActionType.pilotajeCompartido,
            description: 'Compartir al menos 2 pilotajes al día',
            requiredCount: 2,
          ),
          ChallengeAction(
            type: ActionType.tiempoEnApp,
            description: 'Pasar al menos 30 minutos en la app al día',
            requiredCount: 1,
            requiredDuration: Duration(minutes: 30),
          ),
        ],
        icon: '✨',
        color: '#FFD700',
        rewards: ['Badge de Luz Dorada', 'Códigos maestros', 'Acceso VIP', 'Consultoría personalizada'],
      ),
      Challenge(
        id: 'maestro_abundancia',
        title: 'Desafío Maestro de Abundancia',
        description: 'Transforma tu realidad hacia la abundancia infinita.',
        durationDays: 30,
        difficulty: ChallengeDifficulty.maestro,
        dailyActions: [
          ChallengeAction(
            type: ActionType.codigoRepetido,
            description: 'Repetir al menos 5 códigos al día',
            requiredCount: 5,
          ),
          ChallengeAction(
            type: ActionType.sesionPilotaje,
            description: 'Completar al menos 3 sesiones de pilotaje al día',
            requiredCount: 3,
          ),
          ChallengeAction(
            type: ActionType.pilotajeCompartido,
            description: 'Compartir al menos 3 pilotajes al día',
            requiredCount: 3,
          ),
          ChallengeAction(
            type: ActionType.tiempoEnApp,
            description: 'Pasar al menos 45 minutos en la app al día',
            requiredCount: 1,
            requiredDuration: Duration(minutes: 45),
          ),
          ChallengeAction(
            type: ActionType.codigoEspecifico,
            description: 'Usar códigos específicos de abundancia',
            requiredCount: 1,
            specificCode: 'abundancia',
          ),
        ],
        icon: '💎',
        color: '#9C27B0',
        rewards: ['Badge Maestro', 'Códigos únicos', 'Mentoría personal', 'Acceso a comunidad VIP'],
      ),
    ];
  }

  // Iniciar un desafío
  Future<void> startChallenge(String challengeId) async {
    // TEMPORAL: Permitir desafíos sin autenticación para testing
    // if (!_authService.isLoggedIn) {
    //   throw Exception('Debes iniciar sesión para participar en desafíos.');
    // }

    // Verificar si ya hay un desafío activo
    final activeChallenge = _getActiveChallenge();
    if (activeChallenge != null) {
      throw Exception('Ya tienes un desafío activo: "${activeChallenge.title}". Debes completarlo antes de iniciar uno nuevo.');
    }

    final challenge = _availableChallenges.firstWhere(
      (c) => c.id == challengeId,
      orElse: () => throw Exception('Challenge not found'),
    );

    final startedChallenge = challenge.copyWith(
      status: ChallengeStatus.enProgreso,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: challenge.durationDays)),
      currentDay: 1,
      dayProgress: {1: DayProgress(day: 1, date: DateTime.now(), actionCounts: {}, actionDurations: {}, isCompleted: false, completedActions: [])},
    );

    try {
      // Guardar en Supabase
      await _supabase.from('user_challenges').insert({
        'user_id': _authService.currentUser!.id,
        'challenge_id': challengeId,
        'status': startedChallenge.status.toString().split('.').last,
        'start_date': startedChallenge.startDate!.toIso8601String(),
        'end_date': startedChallenge.endDate!.toIso8601String(),
        'current_day': startedChallenge.currentDay,
        'total_progress': startedChallenge.totalProgress,
        'day_progress': startedChallenge.dayProgress.map((k, v) => MapEntry(k.toString(), v.toJson())),
      });

      _userChallenges[challengeId] = startedChallenge;
      await _trackingService.startChallenge(startedChallenge);
      notifyListeners();
      print('🚀 Desafío "${startedChallenge.title}" iniciado.');
    } catch (e) {
      print('Error guardando desafío en Supabase: $e');
      rethrow;
    }
  }

  // Obtener el desafío activo (método privado)
  Challenge? _getActiveChallenge() {
    try {
      return _userChallenges.values.firstWhere(
        (challenge) => challenge.status == ChallengeStatus.enProgreso,
      );
    } catch (e) {
      return null; // No hay desafío activo
    }
  }

  // Obtener progreso de un desafío
  ChallengeProgress? getChallengeProgress(String challengeId) {
    return _trackingService.getChallengeProgress(challengeId);
  }

  // Obtener stream de progreso de un desafío
  Stream<ChallengeProgress>? getChallengeProgressStream(String challengeId) {
    return _trackingService.getChallengeProgressStream(challengeId);
  }

  // Verificar si un desafío está completado
  bool isChallengeCompleted(String challengeId) {
    final progress = getChallengeProgress(challengeId);
    if (progress == null) return false;

    // Un desafío está completado si todos los días están completados
    final challenge = getChallenge(challengeId);
    if (challenge == null) return false;

    for (int day = 1; day <= challenge.durationDays; day++) {
      final dayProgress = progress.dayProgress[day];
      if (dayProgress == null || !dayProgress.isCompleted) {
        return false;
      }
    }

    return true;
  }

  // Verificar y otorgar recompensas si un desafío está completado
  Future<void> verificarYOtorgarRecompensasDesafio(String challengeId) async {
    if (!isChallengeCompleted(challengeId)) return;
    
    final challenge = getChallenge(challengeId);
    if (challenge == null) return;
    
    // Verificar si ya se otorgaron recompensas para este desafío
    final progress = getChallengeProgress(challengeId);
    if (progress == null) return;
    
    // Verificar si ya se otorgaron recompensas para este desafío
    final rewardsService = RewardsService();
    final rewards = await rewardsService.getUserRewards();
    final logros = rewards.logros;
    final desafioKey = 'desafio_${challengeId}_recompensado';
    
    if (logros[desafioKey] == true) {
      // Ya se otorgaron recompensas
      return;
    }
    
    // Otorgar recompensas
    try {
      await rewardsService.recompensarPorDesafioCompletado(challenge.durationDays);
      
      // Marcar como recompensado
      final nuevosLogros = Map<String, dynamic>.from(logros);
      nuevosLogros[desafioKey] = true;
      await rewardsService.saveUserRewards(rewards.copyWith(logros: nuevosLogros));
      
      print('✅ Recompensas otorgadas por completar desafío de ${challenge.durationDays} días');
    } catch (e) {
      print('⚠️ Error otorgando recompensas por desafío: $e');
    }
  }

  // Obtener estadísticas de un desafío
  Map<String, dynamic> getChallengeStats(String challengeId) {
    final progress = getChallengeProgress(challengeId);
    if (progress == null) return {};

    final challenge = getChallenge(challengeId);
    if (challenge == null) return {};

    int completedDays = 0;
    int totalActions = 0;
    Duration totalTime = Duration.zero;

    for (int day = 1; day <= challenge.durationDays; day++) {
      final dayProgress = progress.dayProgress[day];
      if (dayProgress != null) {
        if (dayProgress.isCompleted) completedDays++;
        
        for (final count in dayProgress.actionCounts.values) {
          totalActions += count;
        }
        
        for (final duration in dayProgress.actionDurations.values) {
          totalTime += duration;
        }
      }
    }

    return {
      'completedDays': completedDays,
      'totalDays': challenge.durationDays,
      'completionPercentage': (completedDays / challenge.durationDays) * 100,
      'totalActions': totalActions,
      'totalTime': totalTime,
      'currentStreak': _calculateCurrentStreak(progress),
      'longestStreak': _calculateLongestStreak(progress),
    };
  }

  // Calcular racha actual
  int _calculateCurrentStreak(ChallengeProgress progress) {
    int streak = 0;
    final today = DateTime.now();
    
    for (int day = progress.currentDay; day >= 1; day--) {
      final dayProgress = progress.dayProgress[day];
      if (dayProgress != null && dayProgress.isCompleted) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }

  // Calcular racha más larga
  int _calculateLongestStreak(ChallengeProgress progress) {
    int longestStreak = 0;
    int currentStreak = 0;
    
    for (int day = 1; day <= progress.currentDay; day++) {
      final dayProgress = progress.dayProgress[day];
      if (dayProgress != null && dayProgress.isCompleted) {
        currentStreak++;
        longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
      } else {
        currentStreak = 0;
      }
    }
    
    return longestStreak;
  }

  // Obtener desafíos recomendados basándose en el progreso del usuario
  List<Challenge> getRecommendedChallenges() {
    final userProgress = _trackingService.challengesProgress;
    
    // Si no tiene desafíos activos, recomendar el de iniciación
    if (userProgress.isEmpty) {
      return _availableChallenges.where((c) => c.difficulty == ChallengeDifficulty.principiante).toList();
    }
    
    // Si completó el de iniciación, recomendar el intermedio
    final hasCompletedBeginner = userProgress.values.any((progress) {
      final challenge = getChallenge(progress.challengeId);
      return challenge?.difficulty == ChallengeDifficulty.principiante && 
             isChallengeCompleted(progress.challengeId);
    });
    
    if (hasCompletedBeginner) {
      return _availableChallenges.where((c) => c.difficulty == ChallengeDifficulty.intermedio).toList();
    }
    
    return _availableChallenges.where((c) => c.difficulty == ChallengeDifficulty.principiante).toList();
  }

  // Obtener logros del usuario
  List<Map<String, dynamic>> getUserAchievements() {
    final achievements = <Map<String, dynamic>>[];
    final userProgress = _trackingService.challengesProgress;
    
    // Logro: Primer código repetido
    final hasRepeatedCode = _trackingService.userActions.any((action) => 
      action.type == ActionType.codigoRepetido);
    if (hasRepeatedCode) {
      achievements.add({
        'id': 'first_code',
        'title': 'Primer Paso',
        'description': 'Repetiste tu primer código',
        'icon': '🎯',
        'unlockedAt': _trackingService.userActions
            .where((action) => action.type == ActionType.codigoRepetido)
            .first.timestamp,
      });
    }
    
    // Logro: Primera meditación
    final hasSharedPilotage = _trackingService.userActions.any((action) =>
      action.type == ActionType.pilotajeCompartido);
    if (hasSharedPilotage) {
      achievements.add({
        'id': 'first_share',
        'title': 'Expansión Energética',
        'description': 'Compartiste tu primer pilotaje o certificado',
        'icon': '🖼️',
        'unlockedAt': _trackingService.userActions
            .where((action) => action.type == ActionType.pilotajeCompartido)
            .first.timestamp,
      });
    }
    
    // Logro: Desafío completado
    for (final progress in userProgress.values) {
      if (isChallengeCompleted(progress.challengeId)) {
        final challenge = getChallenge(progress.challengeId);
        achievements.add({
          'id': 'challenge_${progress.challengeId}',
          'title': '${challenge?.title} Completado',
          'description': 'Completaste el desafío ${challenge?.title}',
          'icon': '🏆',
          'unlockedAt': progress.lastActivity,
        });
      }
    }
    
    return achievements;
  }

  @override
  void dispose() {
    _trackingService.dispose();
    super.dispose();
  }
}