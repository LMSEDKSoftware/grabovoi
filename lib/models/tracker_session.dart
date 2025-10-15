class TrackerSession {
  final String id;
  final String codeId;
  final String code;
  final int repetitions;
  final DateTime startTime;
  final DateTime? endTime;
  final int targetRepetitions;
  final bool isCompleted;
  final String? notes;

  TrackerSession({
    required this.id,
    required this.codeId,
    required this.code,
    this.repetitions = 0,
    required this.startTime,
    this.endTime,
    this.targetRepetitions = 108,
    this.isCompleted = false,
    this.notes,
  });

  factory TrackerSession.fromJson(Map<String, dynamic> json) {
    return TrackerSession(
      id: json['id'] as String,
      codeId: json['code_id'] as String,
      code: json['code'] as String,
      repetitions: json['repetitions'] as int? ?? 0,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null 
          ? DateTime.parse(json['end_time'] as String) 
          : null,
      targetRepetitions: json['target_repetitions'] as int? ?? 108,
      isCompleted: json['is_completed'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code_id': codeId,
      'code': code,
      'repetitions': repetitions,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'target_repetitions': targetRepetitions,
      'is_completed': isCompleted,
      'notes': notes,
    };
  }

  TrackerSession copyWith({
    String? id,
    String? codeId,
    String? code,
    int? repetitions,
    DateTime? startTime,
    DateTime? endTime,
    int? targetRepetitions,
    bool? isCompleted,
    String? notes,
  }) {
    return TrackerSession(
      id: id ?? this.id,
      codeId: codeId ?? this.codeId,
      code: code ?? this.code,
      repetitions: repetitions ?? this.repetitions,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      targetRepetitions: targetRepetitions ?? this.targetRepetitions,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
    );
  }

  double get progress {
    if (targetRepetitions == 0) return 0.0;
    return (repetitions / targetRepetitions).clamp(0.0, 1.0);
  }
}

