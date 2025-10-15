class Meditation {
  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final String type; // 'guiada', 'respiracion', 'visualizacion', 'pilotaje'
  final String? audioUrl;
  final String? scriptText;
  final List<String> benefits;
  final String difficulty; // 'principiante', 'intermedio', 'avanzado'
  final String? graboyoiCode;
  
  Meditation({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.type,
    this.audioUrl,
    this.scriptText,
    this.benefits = const [],
    this.difficulty = 'principiante',
    this.graboyoiCode,
  });

  factory Meditation.fromJson(Map<String, dynamic> json) {
    return Meditation(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      durationMinutes: json['duration_minutes'] as int,
      type: json['type'] as String,
      audioUrl: json['audio_url'] as String?,
      scriptText: json['script_text'] as String?,
      benefits: List<String>.from(json['benefits'] ?? []),
      difficulty: json['difficulty'] as String? ?? 'principiante',
      graboyoiCode: json['grabovoyi_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'duration_minutes': durationMinutes,
      'type': type,
      'audio_url': audioUrl,
      'script_text': scriptText,
      'benefits': benefits,
      'difficulty': difficulty,
      'grabovoyi_code': graboyoiCode,
    };
  }
}

class MeditationSession {
  final String id;
  final String meditationId;
  final DateTime startTime;
  final DateTime? endTime;
  final int? completedMinutes;
  final String? notes;
  final int rating;

  MeditationSession({
    required this.id,
    required this.meditationId,
    required this.startTime,
    this.endTime,
    this.completedMinutes,
    this.notes,
    this.rating = 0,
  });

  factory MeditationSession.fromJson(Map<String, dynamic> json) {
    return MeditationSession(
      id: json['id'] as String,
      meditationId: json['meditation_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null 
          ? DateTime.parse(json['end_time'] as String) 
          : null,
      completedMinutes: json['completed_minutes'] as int?,
      notes: json['notes'] as String?,
      rating: json['rating'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meditation_id': meditationId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'completed_minutes': completedMinutes,
      'notes': notes,
      'rating': rating,
    };
  }
}

