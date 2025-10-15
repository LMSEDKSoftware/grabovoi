class Desafio {
  final String nombre;
  final int duracion;
  final String descripcion;
  final List<String> codigos;
  final List<String> practicas;

  Desafio({
    required this.nombre,
    required this.duracion,
    required this.descripcion,
    required this.codigos,
    required this.practicas,
  });

  factory Desafio.fromJson(Map<String, dynamic> json) {
    return Desafio(
      nombre: json['nombre'] as String,
      duracion: json['duracion'] as int,
      descripcion: json['descripcion'] as String,
      codigos: List<String>.from(json['codigos']),
      practicas: List<String>.from(json['practicas']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'duracion': duracion,
      'descripcion': descripcion,
      'codigos': codigos,
      'practicas': practicas,
    };
  }
}

