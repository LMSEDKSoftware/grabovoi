class MuralMessage {
  final int id;
  final String title;
  final String message;
  final String? imageUrl;
  final String? actionUrl;
  final bool isActive;
  final String type;
  final DateTime createdAt;
  final DateTime? expiresAt;

  MuralMessage({
    required this.id,
    required this.title,
    required this.message,
    this.imageUrl,
    this.actionUrl,
    required this.isActive,
    required this.type,
    required this.createdAt,
    this.expiresAt,
  });

  factory MuralMessage.fromJson(Map<String, dynamic> json) {
    return MuralMessage(
      id: json['id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      imageUrl: json['image_url'] as String?,
      actionUrl: json['action_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      type: json['type'] as String? ?? 'info',
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'image_url': imageUrl,
      'action_url': actionUrl,
      'is_active': isActive,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
}
