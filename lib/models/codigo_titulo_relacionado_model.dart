class CodigoTituloRelacionado {
  final String id;
  final String codigoExistente;
  final String titulo;
  final String? descripcion;
  final String? categoria;
  final String fuente;
  final int? sugerenciaId;
  final String? usuarioId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CodigoTituloRelacionado({
    required this.id,
    required this.codigoExistente,
    required this.titulo,
    this.descripcion,
    this.categoria,
    this.fuente = 'sugerencia_aprobada',
    this.sugerenciaId,
    this.usuarioId,
    required this.createdAt,
    this.updatedAt,
  });

  factory CodigoTituloRelacionado.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return CodigoTituloRelacionado(
      id: (json['id'] ?? '').toString(),
      codigoExistente: (json['codigo_existente'] ?? '').toString(),
      titulo: (json['titulo'] ?? '').toString(),
      descripcion: json['descripcion']?.toString(),
      categoria: json['categoria']?.toString(),
      fuente: (json['fuente'] ?? 'sugerencia_aprobada').toString(),
      sugerenciaId: json['sugerencia_id'] != null ? int.tryParse(json['sugerencia_id'].toString()) : null,
      usuarioId: json['usuario_id']?.toString(),
      createdAt: parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo_existente': codigoExistente,
      'titulo': titulo,
      'descripcion': descripcion,
      'categoria': categoria,
      'fuente': fuente,
      'sugerencia_id': sugerenciaId,
      'usuario_id': usuarioId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

