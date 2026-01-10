class Resource {
  final String id;
  final String title;
  final String description;
  final String content; // Contenido principal (texto, HTML, etc.)
  final String type; // 'text', 'image', 'video', 'mixed'
  final String? imageUrl;
  final String? videoUrl;
  final String category; // Categoría del recurso
  final int order; // Orden de visualización
  final bool isActive; // Si está activo y visible
  final DateTime createdAt;
  final DateTime? updatedAt;

  Resource({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.type,
    this.imageUrl,
    this.videoUrl,
    required this.category,
    required this.order,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      content: json['content'] as String,
      type: json['type'] as String,
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?,
      category: json['category'] as String,
      order: json['order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'type': type,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'category': category,
      'order': order,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

