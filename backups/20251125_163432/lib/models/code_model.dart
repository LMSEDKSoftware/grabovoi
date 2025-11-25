class CodigoGrabovoi {
  final String categoria;
  final String nombre;
  final String codigo;
  final String descripcion;

  CodigoGrabovoi({
    required this.categoria,
    required this.nombre,
    required this.codigo,
    required this.descripcion,
  });

  factory CodigoGrabovoi.fromJson(Map<String, dynamic> json) {
    return CodigoGrabovoi(
      categoria: json['categoria'] as String,
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String,
      descripcion: json['descripcion'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoria': categoria,
      'nombre': nombre,
      'codigo': codigo,
      'descripcion': descripcion,
    };
  }
}

