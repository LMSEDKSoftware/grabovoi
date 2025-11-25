class BusquedaProfunda {
  final int? id;
  final String codigoBuscado;
  final String? usuarioId;
  final String promptSystem;
  final String promptUser;
  final String? respuestaIa;
  final bool codigoEncontrado;
  final bool codigoGuardado;
  final String? errorMessage;
  final DateTime fechaBusqueda;
  final int? duracionMs;
  final String modeloIa;
  final int? tokensUsados;
  final double? costoEstimado;

  BusquedaProfunda({
    this.id,
    required this.codigoBuscado,
    this.usuarioId,
    required this.promptSystem,
    required this.promptUser,
    this.respuestaIa,
    this.codigoEncontrado = false,
    this.codigoGuardado = false,
    this.errorMessage,
    required this.fechaBusqueda,
    this.duracionMs,
    this.modeloIa = 'gpt-3.5-turbo',
    this.tokensUsados,
    this.costoEstimado,
  });

  factory BusquedaProfunda.fromJson(Map<String, dynamic> json) {
    return BusquedaProfunda(
      id: json['id'],
      codigoBuscado: json['codigo_buscado'],
      usuarioId: json['usuario_id'],
      promptSystem: json['prompt_system'],
      promptUser: json['prompt_user'],
      respuestaIa: json['respuesta_ia'],
      codigoEncontrado: json['codigo_encontrado'] ?? false,
      codigoGuardado: json['codigo_guardado'] ?? false,
      errorMessage: json['error_message'],
      fechaBusqueda: DateTime.parse(json['fecha_busqueda']),
      duracionMs: json['duracion_ms'],
      modeloIa: json['modelo_ia'] ?? 'gpt-3.5-turbo',
      tokensUsados: json['tokens_usados'],
      costoEstimado: json['costo_estimado']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'codigo_buscado': codigoBuscado,
      'usuario_id': usuarioId,
      'prompt_system': promptSystem,
      'prompt_user': promptUser,
      'respuesta_ia': respuestaIa,
      'codigo_encontrado': codigoEncontrado,
      'codigo_guardado': codigoGuardado,
      'error_message': errorMessage,
      'fecha_busqueda': fechaBusqueda.toIso8601String(),
      'duracion_ms': duracionMs,
      'modelo_ia': modeloIa,
      'tokens_usados': tokensUsados,
      'costo_estimado': costoEstimado,
    };
    
    // Solo incluir id si no es null (para updates)
    if (id != null) {
      json['id'] = id;
    }
    
    return json;
  }

  BusquedaProfunda copyWith({
    int? id,
    String? codigoBuscado,
    String? usuarioId,
    String? promptSystem,
    String? promptUser,
    String? respuestaIa,
    bool? codigoEncontrado,
    bool? codigoGuardado,
    String? errorMessage,
    DateTime? fechaBusqueda,
    int? duracionMs,
    String? modeloIa,
    int? tokensUsados,
    double? costoEstimado,
  }) {
    return BusquedaProfunda(
      id: id ?? this.id,
      codigoBuscado: codigoBuscado ?? this.codigoBuscado,
      usuarioId: usuarioId ?? this.usuarioId,
      promptSystem: promptSystem ?? this.promptSystem,
      promptUser: promptUser ?? this.promptUser,
      respuestaIa: respuestaIa ?? this.respuestaIa,
      codigoEncontrado: codigoEncontrado ?? this.codigoEncontrado,
      codigoGuardado: codigoGuardado ?? this.codigoGuardado,
      errorMessage: errorMessage ?? this.errorMessage,
      fechaBusqueda: fechaBusqueda ?? this.fechaBusqueda,
      duracionMs: duracionMs ?? this.duracionMs,
      modeloIa: modeloIa ?? this.modeloIa,
      tokensUsados: tokensUsados ?? this.tokensUsados,
      costoEstimado: costoEstimado ?? this.costoEstimado,
    );
  }

  @override
  String toString() {
    return 'BusquedaProfunda(id: $id, codigoBuscado: $codigoBuscado, usuarioId: $usuarioId, codigoEncontrado: $codigoEncontrado, codigoGuardado: $codigoGuardado, fechaBusqueda: $fechaBusqueda)';
  }
}
