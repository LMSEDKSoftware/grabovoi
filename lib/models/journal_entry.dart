class JournalEntry {
  final String id;
  final DateTime date;
  final String? intention;
  final String? reflection;
  final List<String> gratitudes;
  final Map<String, int> moodRatings; // 'animo', 'energia', 'sueno'
  final List<String> accomplishments;
  final String? notes;
  final List<String> usedCodes;

  JournalEntry({
    required this.id,
    required this.date,
    this.intention,
    this.reflection,
    this.gratitudes = const [],
    this.moodRatings = const {},
    this.accomplishments = const [],
    this.notes,
    this.usedCodes = const [],
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      intention: json['intention'] as String?,
      reflection: json['reflection'] as String?,
      gratitudes: List<String>.from(json['gratitudes'] ?? []),
      moodRatings: Map<String, int>.from(json['mood_ratings'] ?? {}),
      accomplishments: List<String>.from(json['accomplishments'] ?? []),
      notes: json['notes'] as String?,
      usedCodes: List<String>.from(json['used_codes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'intention': intention,
      'reflection': reflection,
      'gratitudes': gratitudes,
      'mood_ratings': moodRatings,
      'accomplishments': accomplishments,
      'notes': notes,
      'used_codes': usedCodes,
    };
  }

  JournalEntry copyWith({
    String? id,
    DateTime? date,
    String? intention,
    String? reflection,
    List<String>? gratitudes,
    Map<String, int>? moodRatings,
    List<String>? accomplishments,
    String? notes,
    List<String>? usedCodes,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      intention: intention ?? this.intention,
      reflection: reflection ?? this.reflection,
      gratitudes: gratitudes ?? this.gratitudes,
      moodRatings: moodRatings ?? this.moodRatings,
      accomplishments: accomplishments ?? this.accomplishments,
      notes: notes ?? this.notes,
      usedCodes: usedCodes ?? this.usedCodes,
    );
  }
}

