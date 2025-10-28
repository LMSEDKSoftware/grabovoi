class SugerenciaCodigo {
  final int? id;
  final int busquedaId;
  final String codigoExistente;
  final String? temaEnDb;
  final String temaSugerido;
  final String? descripcionSugerida;
  final String? usuarioId;
  final String fuente;
  final String estado;
  final DateTime fechaSugerencia;
  final DateTime? fechaResolucion;
  final String? comentarioAdmin;

  SugerenciaCodigo({
    this.id,
    required this.busquedaId,
    required this.codigoExistente,
    this.temaEnDb,
    required this.temaSugerido,
    this.descripcionSugerida,
    this.usuarioId,
    this.fuente = 'IA',
    this.estado = 'pendiente',
    required this.fechaSugerencia,
    this.fechaResolucion,
    this.comentarioAdmin,
  });

  // Convertir a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'busqueda_id': busquedaId,
      'codigo_existente': codigoExistente,
      'tema_en_db': temaEnDb,
      'tema_sugerido': temaSugerido,
      'descripcion_sugerida': descripcionSugerida,
      'usuario_id': usuarioId,
      'fuente': fuente,
      'estado': estado,
      'fecha_sugerencia': fechaSugerencia.toIso8601String(),
      'fecha_resolucion': fechaResolucion?.toIso8601String(),
      'comentario_admin': comentarioAdmin,
    };
  }

  // Crear desde JSON de Supabase
  factory SugerenciaCodigo.fromJson(Map<String, dynamic> json) {
    return SugerenciaCodigo(
      id: json['id'] as int?,
      busquedaId: json['busqueda_id'] as int,
      codigoExistente: json['codigo_existente'] as String,
      temaEnDb: json['tema_en_db'] as String?,
      temaSugerido: json['tema_sugerido'] as String,
      descripcionSugerida: json['descripcion_sugerida'] as String?,
      usuarioId: json['usuario_id'] as String?,
      fuente: json['fuente'] as String? ?? 'IA',
      estado: json['estado'] as String? ?? 'pendiente',
      fechaSugerencia: DateTime.parse(json['fecha_sugerencia'] as String),
      fechaResolucion: json['fecha_resolucion'] != null 
          ? DateTime.parse(json['fecha_resolucion'] as String) 
          : null,
      comentarioAdmin: json['comentario_admin'] as String?,
    );
  }

  // Crear copia con cambios
  SugerenciaCodigo copyWith({
    int? id,
    int? busquedaId,
    String? codigoExistente,
    String? temaEnDb,
    String? temaSugerido,
    String? descripcionSugerida,
    String? usuarioId,
    String? fuente,
    String? estado,
    DateTime? fechaSugerencia,
    DateTime? fechaResolucion,
    String? comentarioAdmin,
  }) {
    return SugerenciaCodigo(
      id: id ?? this.id,
      busquedaId: busquedaId ?? this.busquedaId,
      codigoExistente: codigoExistente ?? this.codigoExistente,
      temaEnDb: temaEnDb ?? this.temaEnDb,
      temaSugerido: temaSugerido ?? this.temaSugerido,
      descripcionSugerida: descripcionSugerida ?? this.descripcionSugerida,
      usuarioId: usuarioId ?? this.usuarioId,
      fuente: fuente ?? this.fuente,
      estado: estado ?? this.estado,
      fechaSugerencia: fechaSugerencia ?? this.fechaSugerencia,
      fechaResolucion: fechaResolucion ?? this.fechaResolucion,
      comentarioAdmin: comentarioAdmin ?? this.comentarioAdmin,
    );
  }

  @override
  String toString() {
    return 'SugerenciaCodigo(id: $id, codigo: $codigoExistente, temaDb: $temaEnDb, temaSugerido: $temaSugerido, estado: $estado)';
  }
}

