class User {
  final String id;
  final String email;
  final String name;
  final String? avatar;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isEmailVerified;
  final Map<String, dynamic> preferences;
  final int level;
  final int experience;
  final List<String> achievements;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
    required this.createdAt,
    this.lastLoginAt,
    this.isEmailVerified = false,
    this.preferences = const {},
    this.level = 1,
    this.experience = 0,
    this.achievements = const [],
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? avatar,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
    Map<String, dynamic>? preferences,
    int? level,
    int? experience,
    List<String>? achievements,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      preferences: preferences ?? this.preferences,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      achievements: achievements ?? this.achievements,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar': avatar,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'is_email_verified': isEmailVerified,
      'preferences': preferences,
      'level': level,
      'experience': experience,
      'achievements': achievements,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      avatar: json['avatar'],
      createdAt: DateTime.parse(json['created_at']),
      lastLoginAt: json['last_login_at'] != null 
          ? DateTime.parse(json['last_login_at']) 
          : null,
      isEmailVerified: json['is_email_verified'] ?? false,
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      level: json['level'] ?? 1,
      experience: json['experience'] ?? 0,
      achievements: List<String>.from(json['achievements'] ?? []),
    );
  }

  // Métodos de utilidad
  int get experienceToNextLevel {
    return (level * 100) - experience;
  }

  double get levelProgress {
    final currentLevelExp = (level - 1) * 100;
    final nextLevelExp = level * 100;
    final progress = (experience - currentLevelExp) / (nextLevelExp - currentLevelExp);
    return progress.clamp(0.0, 1.0);
  }

  bool get canLevelUp {
    return experience >= (level * 100);
  }

  User levelUp() {
    if (!canLevelUp) return this;
    return copyWith(
      level: level + 1,
      experience: experience - (level * 100),
    );
  }

  User addExperience(int exp) {
    final newExperience = experience + exp;
    return copyWith(experience: newExperience);
  }

  User addAchievement(String achievement) {
    if (achievements.contains(achievement)) return this;
    return copyWith(
      achievements: [...achievements, achievement],
    );
  }
}
