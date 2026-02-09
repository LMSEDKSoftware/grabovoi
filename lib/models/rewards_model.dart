import 'package:json_annotation/json_annotation.dart';

part 'rewards_model.g.dart';

/// Modelo de recompensas del usuario
@JsonSerializable()
class UserRewards {
  final String userId;
  final int cristalesEnergia; // Monedas virtuales acumuladas
  final int restauradoresArmonia; // Restauradores disponibles
  final int anclasContinuidad; // Anclas de continuidad para salvar rachas
  final double luzCuantica; // 0.0 a 100.0, barra de progreso (calculada por racha)
  final List<String> mantrasDesbloqueados; // IDs de mantras desbloqueados
  final List<String> codigosPremiumDesbloqueados; // IDs de códigos premium
  final DateTime ultimaActualizacion;
  final DateTime? ultimaMeditacionEspecial; // Cuándo se usó la última meditación especial
  final Map<String, dynamic> logros; // Logros adicionales
  /// Voz numérica en pilotajes (Premium): activar lectura dígito a dígito.
  final bool voiceNumbersEnabled;
  /// Género de voz: 'male' | 'female'.
  final String voiceGender;

  UserRewards({
    required this.userId,
    this.cristalesEnergia = 0,
    this.restauradoresArmonia = 0,
    this.anclasContinuidad = 0,
    this.luzCuantica = 0.0,
    this.mantrasDesbloqueados = const [],
    this.codigosPremiumDesbloqueados = const [],
    required this.ultimaActualizacion,
    this.ultimaMeditacionEspecial,
    this.logros = const {},
    this.voiceNumbersEnabled = false,
    this.voiceGender = 'female',
  });

  factory UserRewards.fromJson(Map<String, dynamic> json) => _$UserRewardsFromJson(json);
  Map<String, dynamic> toJson() => _$UserRewardsToJson(this);

  UserRewards copyWith({
    String? userId,
    int? cristalesEnergia,
    int? restauradoresArmonia,
    int? anclasContinuidad,
    double? luzCuantica,
    List<String>? mantrasDesbloqueados,
    List<String>? codigosPremiumDesbloqueados,
    DateTime? ultimaActualizacion,
    DateTime? ultimaMeditacionEspecial,
    Map<String, dynamic>? logros,
    bool? voiceNumbersEnabled,
    String? voiceGender,
  }) {
    return UserRewards(
      userId: userId ?? this.userId,
      cristalesEnergia: cristalesEnergia ?? this.cristalesEnergia,
      restauradoresArmonia: restauradoresArmonia ?? this.restauradoresArmonia,
      anclasContinuidad: anclasContinuidad ?? this.anclasContinuidad,
      luzCuantica: luzCuantica ?? this.luzCuantica,
      mantrasDesbloqueados: mantrasDesbloqueados ?? this.mantrasDesbloqueados,
      codigosPremiumDesbloqueados: codigosPremiumDesbloqueados ?? this.codigosPremiumDesbloqueados,
      ultimaActualizacion: ultimaActualizacion ?? this.ultimaActualizacion,
      ultimaMeditacionEspecial: ultimaMeditacionEspecial ?? this.ultimaMeditacionEspecial,
      logros: logros ?? this.logros,
      voiceNumbersEnabled: voiceNumbersEnabled ?? this.voiceNumbersEnabled,
      voiceGender: voiceGender ?? this.voiceGender,
    );
  }
}

/// Modelo de mantra desbloqueable
@JsonSerializable()
class Mantra {
  final String id;
  final String nombre;
  final String descripcion;
  final String texto;
  final int diasRequeridos; // Días de racha necesarios para desbloquear
  final String categoria;
  final bool esPremium;

  Mantra({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.texto,
    required this.diasRequeridos,
    this.categoria = 'Espiritualidad',
    this.esPremium = false,
  });

  factory Mantra.fromJson(Map<String, dynamic> json) => _$MantraFromJson(json);
  Map<String, dynamic> toJson() => _$MantraToJson(this);
}

/// Modelo de código premium
@JsonSerializable()
class CodigoPremium {
  final String id;
  final String codigo;
  final String nombre;
  final String descripcion;
  final int costoCristales; // Cristales necesarios para desbloquear
  final String categoria;
  final bool esRaro; // Códigos especiales/raros
  /// URL (opcional) del wallpaper asociado a este código premium.
  /// 
  /// - En Supabase se recomienda almacenar este valor en la columna `wallpaper_url`.
  /// - En JSON local (por ejemplo configuraciones estáticas) se usa la clave `wallpaperUrl`.
  final String? wallpaperUrl;

  CodigoPremium({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.costoCristales,
    this.categoria = 'Premium',
    this.esRaro = false,
    this.wallpaperUrl,
  });

  factory CodigoPremium.fromJson(Map<String, dynamic> json) => _$CodigoPremiumFromJson(json);
  Map<String, dynamic> toJson() => _$CodigoPremiumToJson(this);
}

/// Modelo de meditación especial
@JsonSerializable()
class MeditacionEspecial {
  final String id;
  final String nombre;
  final String descripcion;
  final String audioUrl; // URL del audio
  final double luzCuanticaRequerida; // Luz cuántica necesaria (100.0 = barra completa)
  final int duracionMinutos;

  MeditacionEspecial({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.audioUrl,
    this.luzCuanticaRequerida = 100.0,
    this.duracionMinutos = 15,
  });

  factory MeditacionEspecial.fromJson(Map<String, dynamic> json) => _$MeditacionEspecialFromJson(json);
  Map<String, dynamic> toJson() => _$MeditacionEspecialToJson(this);
}

