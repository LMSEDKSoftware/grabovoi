import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/challenge_model.dart';
import '../models/notification_type.dart';
import 'challenge_tracking_service.dart';
import 'auth_service_simple.dart';
import 'rewards_service.dart';
import 'notification_service.dart';

class ChallengeService extends ChangeNotifier {
  static final ChallengeService _instance = ChallengeService._internal();
  factory ChallengeService() => _instance;
  ChallengeService._internal();

  final ChallengeTrackingService _trackingService = ChallengeTrackingService();
  final AuthServiceSimple _authService = AuthServiceSimple();
  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();
  
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
        } else if (challenge.status == ChallengeStatus.completado) {
          // También cargar el progreso histórico de desafíos ya completados
          // (sin verificar racha, eso solo aplica a desafíos activos). Sin
          // esto, el tracking service quedaba vacío para un desafío
          // completado tras recargar la app, y pantallas como la tarjeta de
          // Desafíos o Evolución lo mostraban en 0% pese a estar terminado.
          await _inicializarProgresoDesdeChallenge(challenge);
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
      const Challenge(
        id: 'iniciacion_energetica',
        title: 'Desafío de Iniciación Energética',
        description: 'Comienza tu viaje de manifestación con las secuencias básicas.',
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
            requiredDuration: Duration(minutes: 15),
          ),
        ],
        icon: '🌟',
        color: '#4CAF50',
        rewards: ['Badge de Iniciación', 'Acceso a códigos avanzados'],
      ),
      const Challenge(
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
            requiredDuration: Duration(minutes: 20),
          ),
        ],
        icon: '⭐',
        color: '#2196F3',
        rewards: ['Badge de Armonización', 'Códigos exclusivos', 'Meditación guiada'],
      ),
      const Challenge(
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
      const Challenge(
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

  // Obtener el orden de los desafíos
  List<String> get _challengeOrder => [
    'iniciacion_energetica',      // 7 días - Primero
    'armonizacion_intermedia',     // 14 días - Segundo
    'luz_dorada_avanzada',         // 21 días - Tercero
    'maestro_abundancia',          // 30 días - Cuarto
  ];

  // Verificar si el desafío anterior está completado
  bool _isPreviousChallengeCompleted(String challengeId) {
    final challengeIndex = _challengeOrder.indexOf(challengeId);
    
    // Si es el primer desafío, siempre está disponible
    if (challengeIndex <= 0) {
      return true;
    }
    
    // Verificar que el desafío anterior esté completado
    final previousChallengeId = _challengeOrder[challengeIndex - 1];
    final previousChallenge = _userChallenges[previousChallengeId];
    
    if (previousChallenge == null) {
      // Si no existe el desafío anterior, no se puede iniciar este
      return false;
    }
    
    // Verificar que el desafío anterior esté completado. Basta con el status
    // persistido (no con isChallengeCompleted(), que depende del progreso en
    // memoria del tracking service y no está disponible para desafíos ya
    // completados que se recargan desde Supabase en una sesión nueva).
    return previousChallenge.status == ChallengeStatus.completado;
  }

  /// Indica si el usuario puede iniciar este desafío (el anterior en la
  /// secuencia ya está completado, o es el primero). Usado por la UI para
  /// decidir si mostrar el candado.
  bool puedeIniciarDesafio(String challengeId) => _isPreviousChallengeCompleted(challengeId);

  /// Mensaje explicando por qué un desafío está bloqueado, o null si no lo está.
  String? getLockReason(String challengeId) {
    if (_isPreviousChallengeCompleted(challengeId)) return null;
    final challengeIndex = _challengeOrder.indexOf(challengeId);
    if (challengeIndex <= 0) return null;
    final previousChallengeId = _challengeOrder[challengeIndex - 1];
    final defaults = _createDefaultChallenges();
    final previousChallenge = _availableChallenges.firstWhere(
      (c) => c.id == previousChallengeId,
      orElse: () => defaults.firstWhere((c) => c.id == previousChallengeId),
    );
    return 'Completa primero "${previousChallenge.title}" para desbloquear este desafío.';
  }

  /// Marca un desafío como completado de verdad: lo persiste en Supabase y
  /// actualiza el estado en memoria. Sin esto, el status se quedaba en
  /// "enProgreso" para siempre y bloqueaba el inicio de cualquier otro
  /// desafío (_getActiveChallenge() lo seguía viendo como activo).
  Future<void> finalizarDesafio(String challengeId) async {
    final challenge = _userChallenges[challengeId];
    if (challenge == null) return;
    if (challenge.status == ChallengeStatus.completado) return; // ya finalizado

    final completedChallenge = challenge.copyWith(status: ChallengeStatus.completado);
    try {
      if (_authService.isLoggedIn) {
        await _supabase
            .from('user_challenges')
            .update({'status': ChallengeStatus.completado.toString().split('.').last})
            .eq('user_id', _authService.currentUser!.id)
            .eq('challenge_id', challengeId);
      }
      _userChallenges[challengeId] = completedChallenge;
      notifyListeners();
      print('🏁 Desafío "${completedChallenge.title}" marcado como completado.');

      // Notificar: el método ya existía en NotificationService pero nadie lo
      // llamaba desde el flujo real, así que terminar un desafío no avisaba
      // nada más allá de la pantalla de felicitaciones (si el usuario seguía
      // ahí en ese momento).
      try {
        final awards = completedChallenge.rewards.isNotEmpty
            ? completedChallenge.rewards.join(', ')
            : 'tu certificado';
        await _notificationService.notifyChallengeCompleted(completedChallenge.title, awards);
      } catch (e) {
        print('⚠️ Error enviando notificación de desafío completado: $e');
      }

      // Encadenar automáticamente el siguiente desafío de la secuencia
      // (7 → 14 → 21 → 30 días = 72 días corridos en total). Sin esto, la
      // racha dependía de que el usuario volviera y tocara "Comenzar" a
      // tiempo, dejando un hueco entre desafíos.
      await _iniciarSiguienteDesafioEnCadena(challengeId);
    } catch (e) {
      print('⚠️ Error marcando desafío como completado: $e');
      rethrow;
    }
  }

  /// Inicia automáticamente el siguiente desafío de _challengeOrder justo al
  /// completar el actual, para que los 72 días totales corran seguidos sin
  /// depender de una acción manual del usuario.
  Future<void> _iniciarSiguienteDesafioEnCadena(String challengeId) async {
    final currentIndex = _challengeOrder.indexOf(challengeId);
    if (currentIndex < 0 || currentIndex >= _challengeOrder.length - 1) {
      return; // No es parte de la cadena, o es el último (maestro_abundancia)
    }
    final nextChallengeId = _challengeOrder[currentIndex + 1];
    if (_userChallenges.containsKey(nextChallengeId)) {
      return; // Ya iniciado o completado previamente
    }
    try {
      await startChallenge(nextChallengeId);
      print('➡️ Desafío "$nextChallengeId" iniciado automáticamente para mantener la racha de 72 días.');

      final nextChallenge = getChallenge(nextChallengeId);
      if (nextChallenge != null) {
        await _notificationService.showNotification(
          title: '🎯 Nuevo desafío disponible',
          body: 'Ya puedes comenzar el ${nextChallenge.title}.',
          type: NotificationType.challengeNewAvailable,
        );
      }
    } catch (e) {
      print('⚠️ No se pudo encadenar automáticamente el siguiente desafío: $e');
    }
  }

  // Iniciar un desafío
  Future<void> startChallenge(String challengeId) async {
    // TEMPORAL: Permitir desafíos sin autenticación para testing
    // if (!_authService.isLoggedIn) {
    //   throw Exception('Debes iniciar sesión para participar en desafíos.');
    // }

    // _getActiveChallenge() solo mira _userChallenges, un mapa en memoria
    // que puede estar desactualizado (p. ej. justo al encadenar
    // automáticamente el siguiente desafío en _iniciarSiguienteDesafioEnCadena,
    // o si esta instancia del servicio no recargó todavía). Confiar solo en
    // eso dejaba insertar una fila "enProgreso" duplicada en Supabase para
    // el mismo challenge_id -- sin restricción única en la tabla, nada lo
    // frenaba del lado del servidor, y el cron de recordatorios mandaba un
    // aviso por cada fila. Por eso aquí se vuelve a preguntar a Supabase
    // directo, la fuente de verdad, antes de insertar.
    if (_authService.isLoggedIn) {
      // .limit(1) + lista en vez de .maybeSingle(): si ya existieran dos
      // filas "enProgreso" duplicadas (el estado roto que este cambio
      // previene hacia adelante), .maybeSingle() reventaría con un error
      // de "multiple rows" en vez de simplemente frenar el nuevo insert.
      final activosEnServidor = await _supabase
          .from('user_challenges')
          .select('challenge_id')
          .eq('user_id', _authService.currentUser!.id)
          .eq('status', 'enProgreso')
          .limit(1);
      if ((activosEnServidor as List).isNotEmpty) {
        final activeId = activosEnServidor.first['challenge_id'] as String;
        if (activeId == challengeId) return; // ya está activo este mismo, no es un error
        final activeTitle = getChallenge(activeId)?.title ?? activeId;
        throw Exception('Ya tienes un desafío activo: "$activeTitle". Debes completarlo antes de iniciar uno nuevo.');
      }
    } else {
      final activeChallenge = _getActiveChallenge();
      if (activeChallenge != null) {
        throw Exception('Ya tienes un desafío activo: "${activeChallenge.title}". Debes completarlo antes de iniciar uno nuevo.');
      }
    }

    final challenge = _availableChallenges.firstWhere(
      (c) => c.id == challengeId,
      orElse: () => throw Exception('Challenge not found'),
    );

    // Verificar que el desafío anterior esté completado (validación secuencial)
    if (!_isPreviousChallengeCompleted(challengeId)) {
      final challengeIndex = _challengeOrder.indexOf(challengeId);
      if (challengeIndex > 0) {
        final previousChallengeId = _challengeOrder[challengeIndex - 1];
        final previousChallenge = _availableChallenges.firstWhere(
          (c) => c.id == previousChallengeId,
          orElse: () => throw Exception('Previous challenge not found'),
        );
        throw Exception('Debes completar primero el "${previousChallenge.title}" antes de iniciar este desafío.');
      }
    }

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