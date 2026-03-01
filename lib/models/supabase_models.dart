import 'package:json_annotation/json_annotation.dart';

part 'supabase_models.g.dart';

@JsonSerializable()
class CodigoGrabovoi {
  final String id;
  final String codigo;
  final String nombre;
  final String descripcion;
  final String categoria;
  final String color;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CodigoGrabovoi({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.color,
    this.createdAt,
    this.updatedAt,
  });

  factory CodigoGrabovoi.fromJson(Map<String, dynamic> json) {
    // Algunos códigos pueden venir con guiones o underscores; NO castees a num.
    final String rawCodigo = (json['codigo'] ?? '').toString().trim();

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try { 
        return DateTime.parse(v.toString()); 
      } catch (_) { 
        return null; 
      }
    }

    return CodigoGrabovoi(
      id: (json['id'] ?? '').toString(),
      codigo: rawCodigo,
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      categoria: (json['categoria'] ?? 'General').toString(),
      color: (json['color'] ?? '#FFD700').toString(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }
  
  Map<String, dynamic> toJson() => _$CodigoGrabovoiToJson(this);
}

@JsonSerializable()
class UsuarioFavorito {
  final String id;
  final String userId;
  final String codigoId;
  final String etiqueta;
  final DateTime createdAt;

  UsuarioFavorito({
    required this.id,
    required this.userId,
    required this.codigoId,
    required this.etiqueta,
    required this.createdAt,
  });

  factory UsuarioFavorito.fromJson(Map<String, dynamic> json) => _$UsuarioFavoritoFromJson(json);
  Map<String, dynamic> toJson() => _$UsuarioFavoritoToJson(this);
}

@JsonSerializable()
class CodigoPopularidad {
  final String id;
  final String codigoId;
  final int contador;
  final DateTime? ultimoUso;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CodigoPopularidad({
    required this.id,
    required this.codigoId,
    required this.contador,
    this.ultimoUso,
    this.createdAt,
    this.updatedAt,
  });

  factory CodigoPopularidad.fromJson(Map<String, dynamic> json) {
    return CodigoPopularidad(
      id: json['id']?.toString() ?? '',
      codigoId: json['codigo_id']?.toString() ?? '',
      contador: json['contador']?.toInt() ?? 0,
      ultimoUso: json['ultimo_uso'] != null ? DateTime.parse(json['ultimo_uso']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
  
  Map<String, dynamic> toJson() => _$CodigoPopularidadToJson(this);
}

@JsonSerializable()
class AudioFile {
  final String id;
  final String nombre;
  final String archivo;
  final String descripcion;
  final String categoria;
  final int duracion; // en segundos
  final String url;
  final DateTime createdAt;

  AudioFile({
    required this.id,
    required this.nombre,
    required this.archivo,
    required this.descripcion,
    required this.categoria,
    required this.duracion,
    required this.url,
    required this.createdAt,
  });

  factory AudioFile.fromJson(Map<String, dynamic> json) => _$AudioFileFromJson(json);
  Map<String, dynamic> toJson() => _$AudioFileToJson(this);
}

@JsonSerializable()
class UsuarioProgreso {
  final String id;
  final String userId;
  final int diasConsecutivos;
  final int totalPilotajes;
  final int nivelEnergetico;
  final DateTime ultimoPilotaje;
  final DateTime createdAt;
  final DateTime updatedAt;

  UsuarioProgreso({
    required this.id,
    required this.userId,
    required this.diasConsecutivos,
    required this.totalPilotajes,
    required this.nivelEnergetico,
    required this.ultimoPilotaje,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UsuarioProgreso.fromJson(Map<String, dynamic> json) => _$UsuarioProgresoFromJson(json);
  Map<String, dynamic> toJson() => _$UsuarioProgresoToJson(this);
}
