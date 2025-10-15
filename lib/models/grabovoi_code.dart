class GrabovoiCode {
  final String id;
  final String code;
  final String title;
  final String description;
  final String category;
  final List<String> tags;
  final int popularityScore;
  final DateTime createdAt;

  GrabovoiCode({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.category,
    required this.tags,
    this.popularityScore = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory GrabovoiCode.fromJson(Map<String, dynamic> json) {
    return GrabovoiCode(
      id: json['id'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      popularityScore: json['popularity_score'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'description': description,
      'category': category,
      'tags': tags,
      'popularity_score': popularityScore,
      'created_at': createdAt.toIso8601String(),
    };
  }

  GrabovoiCode copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    String? category,
    List<String>? tags,
    int? popularityScore,
    DateTime? createdAt,
  }) {
    return GrabovoiCode(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      popularityScore: popularityScore ?? this.popularityScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum CodeCategory {
  salud,
  abundancia,
  relaciones,
  crecimientoPersonal,
  proteccion,
  armonia,
}

extension CodeCategoryExtension on CodeCategory {
  String get name {
    switch (this) {
      case CodeCategory.salud:
        return 'Salud';
      case CodeCategory.abundancia:
        return 'Abundancia';
      case CodeCategory.relaciones:
        return 'Relaciones';
      case CodeCategory.crecimientoPersonal:
        return 'Crecimiento Personal';
      case CodeCategory.proteccion:
        return 'Protección';
      case CodeCategory.armonia:
        return 'Armonía';
    }
  }

  String get key {
    switch (this) {
      case CodeCategory.salud:
        return 'salud';
      case CodeCategory.abundancia:
        return 'abundancia';
      case CodeCategory.relaciones:
        return 'relaciones';
      case CodeCategory.crecimientoPersonal:
        return 'crecimiento_personal';
      case CodeCategory.proteccion:
        return 'proteccion';
      case CodeCategory.armonia:
        return 'armonia';
    }
  }

  String get icon {
    switch (this) {
      case CodeCategory.salud:
        return '❤️';
      case CodeCategory.abundancia:
        return '💰';
      case CodeCategory.relaciones:
        return '🤝';
      case CodeCategory.crecimientoPersonal:
        return '🌱';
      case CodeCategory.proteccion:
        return '🛡️';
      case CodeCategory.armonia:
        return '☮️';
    }
  }
}

