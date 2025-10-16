// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supabase_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CodigoGrabovoi _$CodigoGrabovoiFromJson(Map<String, dynamic> json) =>
    CodigoGrabovoi(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      categoria: json['categoria'] as String,
      color: json['color'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$CodigoGrabovoiToJson(CodigoGrabovoi instance) =>
    <String, dynamic>{
      'id': instance.id,
      'codigo': instance.codigo,
      'nombre': instance.nombre,
      'descripcion': instance.descripcion,
      'categoria': instance.categoria,
      'color': instance.color,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

UsuarioFavorito _$UsuarioFavoritoFromJson(Map<String, dynamic> json) =>
    UsuarioFavorito(
      id: json['id'] as String,
      userId: json['userId'] as String,
      codigoId: json['codigoId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$UsuarioFavoritoToJson(UsuarioFavorito instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'codigoId': instance.codigoId,
      'createdAt': instance.createdAt.toIso8601String(),
    };

CodigoPopularidad _$CodigoPopularidadFromJson(Map<String, dynamic> json) =>
    CodigoPopularidad(
      id: json['id'] as String,
      codigoId: json['codigoId'] as String,
      contador: (json['contador'] as num).toInt(),
      ultimoUso: json['ultimoUso'] == null
          ? null
          : DateTime.parse(json['ultimoUso'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$CodigoPopularidadToJson(CodigoPopularidad instance) =>
    <String, dynamic>{
      'id': instance.id,
      'codigoId': instance.codigoId,
      'contador': instance.contador,
      'ultimoUso': instance.ultimoUso?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

AudioFile _$AudioFileFromJson(Map<String, dynamic> json) => AudioFile(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      archivo: json['archivo'] as String,
      descripcion: json['descripcion'] as String,
      categoria: json['categoria'] as String,
      duracion: (json['duracion'] as num).toInt(),
      url: json['url'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$AudioFileToJson(AudioFile instance) => <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'archivo': instance.archivo,
      'descripcion': instance.descripcion,
      'categoria': instance.categoria,
      'duracion': instance.duracion,
      'url': instance.url,
      'createdAt': instance.createdAt.toIso8601String(),
    };

UsuarioProgreso _$UsuarioProgresoFromJson(Map<String, dynamic> json) =>
    UsuarioProgreso(
      id: json['id'] as String,
      userId: json['userId'] as String,
      diasConsecutivos: (json['diasConsecutivos'] as num).toInt(),
      totalPilotajes: (json['totalPilotajes'] as num).toInt(),
      nivelEnergetico: (json['nivelEnergetico'] as num).toInt(),
      ultimoPilotaje: DateTime.parse(json['ultimoPilotaje'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UsuarioProgresoToJson(UsuarioProgreso instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'diasConsecutivos': instance.diasConsecutivos,
      'totalPilotajes': instance.totalPilotajes,
      'nivelEnergetico': instance.nivelEnergetico,
      'ultimoPilotaje': instance.ultimoPilotaje.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
