// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rewards_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserRewards _$UserRewardsFromJson(Map<String, dynamic> json) => UserRewards(
      userId: json['userId'] as String,
      cristalesEnergia: (json['cristalesEnergia'] as num?)?.toInt() ?? 0,
      restauradoresArmonia:
          (json['restauradoresArmonia'] as num?)?.toInt() ?? 0,
      anclasContinuidad: (json['anclasContinuidad'] as num?)?.toInt() ?? 0,
      luzCuantica: (json['luzCuantica'] as num?)?.toDouble() ?? 0.0,
      mantrasDesbloqueados: (json['mantrasDesbloqueados'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      codigosPremiumDesbloqueados:
          (json['codigosPremiumDesbloqueados'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              const [],
      ultimaActualizacion:
          DateTime.parse(json['ultimaActualizacion'] as String),
      ultimaMeditacionEspecial: json['ultimaMeditacionEspecial'] == null
          ? null
          : DateTime.parse(json['ultimaMeditacionEspecial'] as String),
      logros: json['logros'] as Map<String, dynamic>? ?? const {},
      voiceNumbersEnabled: json['voiceNumbersEnabled'] as bool? ?? false,
      voiceGender: json['voiceGender'] as String? ?? 'female',
    );

Map<String, dynamic> _$UserRewardsToJson(UserRewards instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'cristalesEnergia': instance.cristalesEnergia,
      'restauradoresArmonia': instance.restauradoresArmonia,
      'anclasContinuidad': instance.anclasContinuidad,
      'luzCuantica': instance.luzCuantica,
      'mantrasDesbloqueados': instance.mantrasDesbloqueados,
      'codigosPremiumDesbloqueados': instance.codigosPremiumDesbloqueados,
      'ultimaActualizacion': instance.ultimaActualizacion.toIso8601String(),
      'ultimaMeditacionEspecial':
          instance.ultimaMeditacionEspecial?.toIso8601String(),
      'logros': instance.logros,
      'voiceNumbersEnabled': instance.voiceNumbersEnabled,
      'voiceGender': instance.voiceGender,
    };

Mantra _$MantraFromJson(Map<String, dynamic> json) => Mantra(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      texto: json['texto'] as String,
      diasRequeridos: (json['diasRequeridos'] as num).toInt(),
      categoria: json['categoria'] as String? ?? 'Espiritualidad',
      esPremium: json['esPremium'] as bool? ?? false,
    );

Map<String, dynamic> _$MantraToJson(Mantra instance) => <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'descripcion': instance.descripcion,
      'texto': instance.texto,
      'diasRequeridos': instance.diasRequeridos,
      'categoria': instance.categoria,
      'esPremium': instance.esPremium,
    };

CodigoPremium _$CodigoPremiumFromJson(Map<String, dynamic> json) =>
    CodigoPremium(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      costoCristales: (json['costoCristales'] as num).toInt(),
      categoria: json['categoria'] as String? ?? 'Premium',
      esRaro: json['esRaro'] as bool? ?? false,
      wallpaperUrl: json['wallpaperUrl'] as String?,
    );

Map<String, dynamic> _$CodigoPremiumToJson(CodigoPremium instance) =>
    <String, dynamic>{
      'id': instance.id,
      'codigo': instance.codigo,
      'nombre': instance.nombre,
      'descripcion': instance.descripcion,
      'costoCristales': instance.costoCristales,
      'categoria': instance.categoria,
      'esRaro': instance.esRaro,
      'wallpaperUrl': instance.wallpaperUrl,
    };

MeditacionEspecial _$MeditacionEspecialFromJson(Map<String, dynamic> json) =>
    MeditacionEspecial(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      audioUrl: json['audioUrl'] as String,
      luzCuanticaRequerida:
          (json['luzCuanticaRequerida'] as num?)?.toDouble() ?? 100.0,
      duracionMinutos: (json['duracionMinutos'] as num?)?.toInt() ?? 15,
    );

Map<String, dynamic> _$MeditacionEspecialToJson(MeditacionEspecial instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'descripcion': instance.descripcion,
      'audioUrl': instance.audioUrl,
      'luzCuanticaRequerida': instance.luzCuanticaRequerida,
      'duracionMinutos': instance.duracionMinutos,
    };
