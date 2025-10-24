import 'package:flutter/foundation.dart';

enum ChallengeDifficulty {
  principiante,
  intermedio,
  avanzado,
  maestro,
}

enum ChallengeStatus {
  noIniciado,
  enProgreso,
  completado,
  pausado,
}

enum ActionType {
  codigoRepetido,
  meditacionCompletada,
  sesionPilotaje,
  tiempoEnApp,
  codigoEspecifico,
}

class ChallengeAction {
  final ActionType type;
  final String description;
  final int requiredCount;
  final Duration? requiredDuration;
  final String? specificCode;

  const ChallengeAction({
    required this.type,
    required this.description,
    required this.requiredCount,
    this.requiredDuration,
    this.specificCode,
  });
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final int durationDays;
  final ChallengeDifficulty difficulty;
  final List<ChallengeAction> dailyActions;
  final String icon;
  final String color;
  final List<String> rewards;
  final DateTime? startDate;
  final DateTime? endDate;
  final ChallengeStatus status;
  final int currentDay;
  final Map<int, DayProgress> dayProgress;
  final int totalProgress;
  final List<String> requiredActions;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.durationDays,
    required this.difficulty,
    required this.dailyActions,
    required this.icon,
    required this.color,
    required this.rewards,
    this.startDate,
    this.endDate,
    this.status = ChallengeStatus.noIniciado,
    this.currentDay = 0,
    this.dayProgress = const {},
    this.totalProgress = 0,
    this.requiredActions = const [],
  });

  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    int? durationDays,
    ChallengeDifficulty? difficulty,
    List<ChallengeAction>? dailyActions,
    String? icon,
    String? color,
    List<String>? rewards,
    DateTime? startDate,
    DateTime? endDate,
    ChallengeStatus? status,
    int? currentDay,
    Map<int, DayProgress>? dayProgress,
    int? totalProgress,
    List<String>? requiredActions,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      durationDays: durationDays ?? this.durationDays,
      difficulty: difficulty ?? this.difficulty,
      dailyActions: dailyActions ?? this.dailyActions,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      rewards: rewards ?? this.rewards,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      currentDay: currentDay ?? this.currentDay,
      dayProgress: dayProgress ?? this.dayProgress,
      totalProgress: totalProgress ?? this.totalProgress,
      requiredActions: requiredActions ?? this.requiredActions,
    );
  }

  bool get isCompleted => status == ChallengeStatus.completado;
  bool get isInProgress => status == ChallengeStatus.enProgreso;
  double get progressPercentage => totalProgress / (durationDays * 100);
  
  bool isDayCompleted(int day) {
    return dayProgress[day]?.isCompleted ?? false;
  }

  DayProgress? getDayProgress(int day) {
    return dayProgress[day];
  }
}

class DayProgress {
  final int day;
  final DateTime date;
  final Map<ActionType, int> actionCounts;
  final Map<ActionType, Duration> actionDurations;
  final bool isCompleted;
  final DateTime? completedAt;
  final List<String> completedActions;

  const DayProgress({
    required this.day,
    required this.date,
    required this.actionCounts,
    required this.actionDurations,
    required this.isCompleted,
    this.completedAt,
    required this.completedActions,
  });

  DayProgress copyWith({
    int? day,
    DateTime? date,
    Map<ActionType, int>? actionCounts,
    Map<ActionType, Duration>? actionDurations,
    bool? isCompleted,
    DateTime? completedAt,
    List<String>? completedActions,
  }) {
    return DayProgress(
      day: day ?? this.day,
      date: date ?? this.date,
      actionCounts: actionCounts ?? this.actionCounts,
      actionDurations: actionDurations ?? this.actionDurations,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      completedActions: completedActions ?? this.completedActions,
    );
  }

  int getActionCount(ActionType type) {
    return actionCounts[type] ?? 0;
  }

  Duration getActionDuration(ActionType type) {
    return actionDurations[type] ?? Duration.zero;
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'date': date.toIso8601String(),
      'actionCounts': actionCounts.map((k, v) => MapEntry(k.toString().split('.').last, v)),
      'actionDurations': actionDurations.map((k, v) => MapEntry(k.toString().split('.').last, v.inMinutes)),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'completedActions': completedActions,
    };
  }

  factory DayProgress.fromJson(Map<String, dynamic> json) {
    return DayProgress(
      day: json['day'],
      date: DateTime.parse(json['date']),
      actionCounts: (json['actionCounts'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(ActionType.values.firstWhere((e) => e.toString().split('.').last == k), v as int),
      ),
      actionDurations: (json['actionDurations'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(ActionType.values.firstWhere((e) => e.toString().split('.').last == k), Duration(minutes: v as int)),
      ),
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      completedActions: List<String>.from(json['completedActions'] ?? []),
    );
  }
}

class UserAction {
  final String id;
  final ActionType type;
  final DateTime timestamp;
  final String? codeId;
  final String? codeName;
  final Duration? duration;
  final Map<String, dynamic> metadata;

  const UserAction({
    required this.id,
    required this.type,
    required this.timestamp,
    this.codeId,
    this.codeName,
    this.duration,
    this.metadata = const {},
  });
}

class ChallengeProgress {
  final String challengeId;
  final int currentDay;
  final Map<int, DayProgress> dayProgress;
  final int totalActionsCompleted;
  final Duration totalTimeSpent;
  final List<UserAction> recentActions;
  final DateTime lastActivity;

  const ChallengeProgress({
    required this.challengeId,
    required this.currentDay,
    required this.dayProgress,
    required this.totalActionsCompleted,
    required this.totalTimeSpent,
    required this.recentActions,
    required this.lastActivity,
  });

  ChallengeProgress copyWith({
    String? challengeId,
    int? currentDay,
    Map<int, DayProgress>? dayProgress,
    int? totalActionsCompleted,
    Duration? totalTimeSpent,
    List<UserAction>? recentActions,
    DateTime? lastActivity,
  }) {
    return ChallengeProgress(
      challengeId: challengeId ?? this.challengeId,
      currentDay: currentDay ?? this.currentDay,
      dayProgress: dayProgress ?? this.dayProgress,
      totalActionsCompleted: totalActionsCompleted ?? this.totalActionsCompleted,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      recentActions: recentActions ?? this.recentActions,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }
}