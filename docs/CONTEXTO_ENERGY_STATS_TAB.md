# Contexto Completo: Widget EnergyStatsTab

## 📋 Archivos que Interactúan con EnergyStatsTab

Este documento contiene todos los archivos necesarios para entender y modificar el widget `EnergyStatsTab`.

---

## 1️⃣ Widget Principal: `lib/widgets/energy_stats_tab.dart`

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/rewards_model.dart';
import '../services/rewards_service.dart';

/// Widget flotante para mostrar estadísticas de energía (cristales y luz cuántica)
/// Ubicado en la esquina superior derecha, expandible/colapsable con deslizamiento horizontal
class EnergyStatsTab extends StatefulWidget {
  const EnergyStatsTab({super.key});

  @override
  State<EnergyStatsTab> createState() => _EnergyStatsTabState();
}

class _EnergyStatsTabState extends State<EnergyStatsTab> with SingleTickerProviderStateMixin {
  final RewardsService _rewardsService = RewardsService();
  bool _expanded = false;
  UserRewards? _rewards;
  bool _isLoading = true;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Animación de deslizamiento: 0 = colapsado (pegado al borde), 1 = expandido (deslizado hacia la izquierda)
    _slideAnimation = Tween<double>(
      begin: 0.0, // Colapsado: pegado al borde derecho
      end: 1.0,   // Expandido: completamente visible
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _loadRewards();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadRewards() async {
    try {
      final rewards = await _rewardsService.getUserRewards();
      if (mounted) {
        setState(() {
          _rewards = rewards;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando recompensas: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
    
    if (_expanded) {
      _slideController.forward();
    } else {
      _slideController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar siempre el widget, incluso si está cargando
    if (_rewards == null) {
      if (_isLoading) {
        // Mostrar versión mínima mientras carga
        return Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: 45,
            height: 90,
            margin: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              right: 0,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1C2541).withOpacity(0.95),
                  const Color(0xFF2C3E50).withOpacity(0.9),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.5),
                width: 2,
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Color(0xFFFFD700),
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    // Ancho del panel: 45px colapsado, 200px expandido (reducido para evitar overflow)
    const double collapsedWidth = 45;
    const double expandedWidth = 200;

    return Positioned(
      top: 0,
      right: 0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Backdrop semi-transparente cuando está expandido
          if (_expanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleExpanded, // Cerrar al tocar fuera
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),
          
          // Panel deslizable
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              // Calcular el ancho actual según la animación
              final currentWidth = collapsedWidth + (_slideAnimation.value * (expandedWidth - collapsedWidth));
              
              // Calcular el offset horizontal: cuando está colapsado (slide = 0), está pegado al borde
              // Cuando se expande (slide = 1), se desplaza completamente hacia la izquierda
              final offsetX = _slideAnimation.value * (expandedWidth - collapsedWidth);
              
              return Transform.translate(
                offset: Offset(-offsetX, 0),
                child: GestureDetector(
                  onTap: () {
                    if (!_expanded) {
                      _toggleExpanded();
                    }
                  },
                  child: Container(
                    width: currentWidth,
                    margin: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 8,
                      right: 0,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1C2541).withOpacity(0.95),
                          const Color(0xFF2C3E50).withOpacity(0.9),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 1,
                          offset: const Offset(-2, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(-2, 2),
                        ),
                      ],
                    ),
                    child: _expanded ? _buildExpandedContent() : _buildCollapsedContent(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Estado colapsado: solo muestra los dos íconos verticales
  Widget _buildCollapsedContent() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícono de cristal (💎)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.diamond,
              color: Color(0xFFFFD700),
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          // Ícono de luz cuántica (✨)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFFFFD700),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// Estado expandido: muestra detalles completos
  Widget _buildExpandedContent() {
    final porcentaje = (_rewards!.luzCuantica / RewardsService.luzCuanticaMaxima * 100).toInt();
    final isLuzCompleta = _rewards!.luzCuantica >= RewardsService.luzCuanticaMaxima;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con botón cerrar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFFFD700),
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Estado',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _toggleExpanded,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Cristales de Energía
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.diamond,
                  color: Color(0xFFFFD700),
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cristales',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: Colors.white70,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${_rewards!.cristalesEnergia}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFD700),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Luz Cuántica
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLuzCompleta ? Icons.check_circle : Icons.auto_awesome,
                    color: isLuzCompleta ? Colors.green : const Color(0xFFFFD700),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Luz',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: Colors.white70,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$porcentaje%',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isLuzCompleta ? Colors.green : const Color(0xFFFFD700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Stack(
                children: [
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: _rewards!.luzCuantica / RewardsService.luzCuanticaMaxima,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: LinearGradient(
                          colors: isLuzCompleta
                              ? [Colors.green, Colors.greenAccent]
                              : [const Color(0xFFFFD700), const Color(0xFFFFFF00)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isLuzCompleta ? Colors.green : const Color(0xFFFFD700))
                                .withOpacity(0.6),
                            blurRadius: 4,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Badge si hay suficientes cristales para comprar códigos premium
          if (_rewards!.cristalesEnergia >= RewardsService.cristalesParaCodigoPremium) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: Colors.green.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_cart,
                    color: Colors.green,
                    size: 10,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '¡Disponible!',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

---

## 2️⃣ Implementación en Home Screen: `lib/screens/home/home_screen.dart` (Sección relevante)

    return Scaffold(
      body: GlowBackground(
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portal Energético',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFD700),
                        shadows: [
                          Shadow(
                            color: const Color(0xFFFFD700).withOpacity(0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _datosHome['fraseMotivacional'],
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 30),
                // Esfera con nombre del usuario sobre ella
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      GoldenSphere(
                    size: 180,
                    color: const Color(0xFFFFD700), // Color dorado fijo
                    glowIntensity: 0.7,
                    isAnimated: true,
                      ),
                      // Nombre del usuario sobre la esfera con estilo de código
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Bienvenid@',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.8),
                                  blurRadius: 6.0,
                                  offset: const Offset(2.0, 2.0),
                                ),
                                Shadow(
                                  color: Colors.black.withOpacity(0.6),
                                  blurRadius: 3.0,
                                  offset: const Offset(-1.0, -1.0),
                                ),
                                Shadow(
                                  color: const Color(0xFFFFD700).withOpacity(1.0),
                                  blurRadius: 30,
                                  offset: const Offset(0, 0),
                                ),
                                Shadow(
                                  color: Colors.white.withOpacity(0.8),
                                  blurRadius: 20,
                                  offset: const Offset(0, 0),
                                ),
                                Shadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.6),
                                  blurRadius: 40,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_userName.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              _userName,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.8),
                                    blurRadius: 6.0,
                                    offset: const Offset(2.0, 2.0),
                                  ),
                                  Shadow(
                                    color: Colors.black.withOpacity(0.6),
                                    blurRadius: 3.0,
                                    offset: const Offset(-1.0, -1.0),
                                  ),
                                  Shadow(
                                    color: const Color(0xFFFFD700).withOpacity(1.0),
                                    blurRadius: 30,
                                    offset: const Offset(0, 0),
                                  ),
                                  Shadow(
                                    color: Colors.white.withOpacity(0.8),
                                    blurRadius: 20,
                                    offset: const Offset(0, 0),
                                  ),
                                  Shadow(
                                    color: const Color(0xFFFFD700).withOpacity(0.6),
                                    blurRadius: 40,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildEnergyCard('Tu Nivel Energético hoy', '${_datosHome['nivel']}/10', Icons.bolt),
                const SizedBox(height: 20),
                _buildCodeOfDay(context, _datosHome['codigoRecomendado']),
                const SizedBox(height: 20),
                _buildNextStep(_datosHome['proximoPaso']),
                  ],
                ),
              ),
            ),
            // Solapa flotante de estadísticas de energía (esquina superior derecha)
            const EnergyStatsTab(),
          ],
        ),
      ),
    );
  }

---

## 3️⃣ Modelo de Datos: `lib/models/rewards_model.dart`

import 'package:json_annotation/json_annotation.dart';

part 'rewards_model.g.dart';

/// Modelo de recompensas del usuario
@JsonSerializable()
class UserRewards {
  final String userId;
  final int cristalesEnergia; // Monedas virtuales acumuladas
  final int restauradoresArmonia; // Restauradores disponibles
  final double luzCuantica; // 0.0 a 100.0, barra de progreso
  final List<String> mantrasDesbloqueados; // IDs de mantras desbloqueados
  final List<String> codigosPremiumDesbloqueados; // IDs de códigos premium
  final DateTime ultimaActualizacion;
  final DateTime? ultimaMeditacionEspecial; // Cuándo se usó la última meditación especial
  final Map<String, dynamic> logros; // Logros adicionales

  UserRewards({
    required this.userId,
    this.cristalesEnergia = 0,
    this.restauradoresArmonia = 0,
    this.luzCuantica = 0.0,
    this.mantrasDesbloqueados = const [],
    this.codigosPremiumDesbloqueados = const [],
    required this.ultimaActualizacion,
    this.ultimaMeditacionEspecial,
    this.logros = const {},
  });

  factory UserRewards.fromJson(Map<String, dynamic> json) => _$UserRewardsFromJson(json);
  Map<String, dynamic> toJson() => _$UserRewardsToJson(this);

  UserRewards copyWith({
    String? userId,
    int? cristalesEnergia,
    int? restauradoresArmonia,
    double? luzCuantica,
    List<String>? mantrasDesbloqueados,
    List<String>? codigosPremiumDesbloqueados,
    DateTime? ultimaActualizacion,
    DateTime? ultimaMeditacionEspecial,
    Map<String, dynamic>? logros,
  }) {
    return UserRewards(
      userId: userId ?? this.userId,
      cristalesEnergia: cristalesEnergia ?? this.cristalesEnergia,
      restauradoresArmonia: restauradoresArmonia ?? this.restauradoresArmonia,
      luzCuantica: luzCuantica ?? this.luzCuantica,
      mantrasDesbloqueados: mantrasDesbloqueados ?? this.mantrasDesbloqueados,
      codigosPremiumDesbloqueados: codigosPremiumDesbloqueados ?? this.codigosPremiumDesbloqueados,
      ultimaActualizacion: ultimaActualizacion ?? this.ultimaActualizacion,
      ultimaMeditacionEspecial: ultimaMeditacionEspecial ?? this.ultimaMeditacionEspecial,
      logros: logros ?? this.logros,
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

  CodigoPremium({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.costoCristales,
    this.categoria = 'Premium',
    this.esRaro = false,
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


---

## 4️⃣ Servicio de Recompensas: `lib/services/rewards_service.dart`

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/rewards_model.dart';
import '../config/supabase_config.dart';
import 'auth_service_simple.dart';

/// Servicio para gestionar el sistema de recompensas
class RewardsService {
  static const String _prefsKey = 'user_rewards';
  static const String _rewardsHistoryKey = 'rewards_history';
  
  // Constantes del sistema
  static const int cristalesPorDia = 10; // Cristales por día de pilotaje
  static const int cristalesParaCodigoPremium = 100; // Cristales necesarios para código premium
  static const int diasParaRestaurador = 7; // Días para obtener un restaurador
  static const double luzCuanticaPorPilotaje = 5.0; // Luz cuántica ganada por pilotaje
  static const int diasParaMantra = 21; // Días consecutivos para desbloquear mantra
  static const double luzCuanticaMaxima = 100.0; // Máximo de luz cuántica

  final AuthServiceSimple _authService = AuthServiceSimple();
  
  AuthServiceSimple get authService => _authService;

  /// Obtener recompensas del usuario
  Future<UserRewards> getUserRewards() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      // Intentar obtener de Supabase primero
      final response = await SupabaseConfig.client
          .from('user_rewards')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && response.isNotEmpty) {
        return UserRewards(
          userId: userId,
          cristalesEnergia: response['cristales_energia'] ?? 0,
          restauradoresArmonia: response['restauradores_armonia'] ?? 0,
          luzCuantica: (response['luz_cuantica'] ?? 0.0).toDouble(),
          mantrasDesbloqueados: List<String>.from(response['mantras_desbloqueados'] ?? []),
          codigosPremiumDesbloqueados: List<String>.from(response['codigos_premium_desbloqueados'] ?? []),
          ultimaActualizacion: DateTime.parse(response['ultima_actualizacion']),
          ultimaMeditacionEspecial: response['ultima_meditacion_especial'] != null
              ? DateTime.parse(response['ultima_meditacion_especial'])
              : null,
          logros: Map<String, dynamic>.from(response['logros'] ?? {}),
        );
      }

      // Si no existe en Supabase, crear uno nuevo
      return UserRewards(
        userId: userId,
        cristalesEnergia: 0,
        restauradoresArmonia: 0,
        luzCuantica: 0.0,
        mantrasDesbloqueados: [],
        codigosPremiumDesbloqueados: [],
        ultimaActualizacion: DateTime.now(),
        logros: {},
      );
    } catch (e) {
      print('⚠️ Error obteniendo recompensas de Supabase: $e');
      // Fallback a SharedPreferences
      return await _getRewardsFromPrefs(userId);
    }
  }

  /// Obtener recompensas desde SharedPreferences (fallback)
  Future<UserRewards> _getRewardsFromPrefs(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final rewardsJson = prefs.getString('$_prefsKey$userId');
    
    if (rewardsJson != null) {
      final map = jsonDecode(rewardsJson) as Map<String, dynamic>;
      return UserRewards(
        userId: userId,
        cristalesEnergia: map['cristalesEnergia'] ?? 0,
        restauradoresArmonia: map['restauradoresArmonia'] ?? 0,
        luzCuantica: (map['luzCuantica'] ?? 0.0).toDouble(),
        mantrasDesbloqueados: List<String>.from(map['mantrasDesbloqueados'] ?? []),
        codigosPremiumDesbloqueados: List<String>.from(map['codigosPremiumDesbloqueados'] ?? []),
        ultimaActualizacion: DateTime.parse(map['ultimaActualizacion']),
        logros: Map<String, dynamic>.from(map['logros'] ?? {}),
      );
    }

    return UserRewards(
      userId: userId,
      cristalesEnergia: 0,
      restauradoresArmonia: 0,
      luzCuantica: 0.0,
      mantrasDesbloqueados: [],
      codigosPremiumDesbloqueados: [],
      ultimaActualizacion: DateTime.now(),
      logros: {},
    );
  }

  /// Guardar recompensas
  Future<void> saveUserRewards(UserRewards rewards) async {
    try {
      // Guardar en Supabase
      await SupabaseConfig.client.from('user_rewards').upsert({
        'user_id': rewards.userId,
        'cristales_energia': rewards.cristalesEnergia,
        'restauradores_armonia': rewards.restauradoresArmonia,
        'luz_cuantica': rewards.luzCuantica,
        'mantras_desbloqueados': rewards.mantrasDesbloqueados,
        'codigos_premium_desbloqueados': rewards.codigosPremiumDesbloqueados,
        'ultima_actualizacion': rewards.ultimaActualizacion.toIso8601String(),
        'ultima_meditacion_especial': rewards.ultimaMeditacionEspecial?.toIso8601String(),
        'logros': rewards.logros,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('⚠️ Error guardando recompensas en Supabase: $e');
    }

    // También guardar en SharedPreferences como backup
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefsKey${rewards.userId}',
      jsonEncode({
        'userId': rewards.userId,
        'cristalesEnergia': rewards.cristalesEnergia,
        'restauradoresArmonia': rewards.restauradoresArmonia,
        'luzCuantica': rewards.luzCuantica,
        'mantrasDesbloqueados': rewards.mantrasDesbloqueados,
        'codigosPremiumDesbloqueados': rewards.codigosPremiumDesbloqueados,
        'ultimaActualizacion': rewards.ultimaActualizacion.toIso8601String(),
        'ultimaMeditacionEspecial': rewards.ultimaMeditacionEspecial?.toIso8601String(),
        'logros': rewards.logros,
      }),
    );
  }

  /// Recompensar por completar un pilotaje
  Future<UserRewards> recompensarPorPilotaje() async {
    final rewards = await getUserRewards();
    
    // Agregar cristales
    final nuevosCristales = rewards.cristalesEnergia + cristalesPorDia;
    
    // Agregar luz cuántica
    double nuevaLuzCuantica = rewards.luzCuantica + luzCuanticaPorPilotaje;
    if (nuevaLuzCuantica > luzCuanticaMaxima) {
      nuevaLuzCuantica = luzCuanticaMaxima;
    }

    final updatedRewards = rewards.copyWith(
      cristalesEnergia: nuevosCristales,
      luzCuantica: nuevaLuzCuantica,
      ultimaActualizacion: DateTime.now(),
    );

    await saveUserRewards(updatedRewards);
    return updatedRewards;
  }

  /// Recompensar por completar una semana (7 días consecutivos)
  Future<UserRewards> recompensarPorSemana() async {
    final rewards = await getUserRewards();
    
    final updatedRewards = rewards.copyWith(
      restauradoresArmonia: rewards.restauradoresArmonia + 1,
      ultimaActualizacion: DateTime.now(),
    );

    await saveUserRewards(updatedRewards);
    return updatedRewards;
  }

  /// Desbloquear mantra por racha de 21 días
  Future<UserRewards> desbloquearMantra(String mantraId) async {
    final rewards = await getUserRewards();
    
    if (rewards.mantrasDesbloqueados.contains(mantraId)) {
      return rewards; // Ya está desbloqueado
    }

    final updatedMantras = [...rewards.mantrasDesbloqueados, mantraId];
    
    final updatedRewards = rewards.copyWith(
      mantrasDesbloqueados: updatedMantras,
      ultimaActualizacion: DateTime.now(),
    );

    await saveUserRewards(updatedRewards);
    return updatedRewards;
  }

  /// Usar restaurador de armonía para mantener racha
  Future<UserRewards> usarRestauradorArmonia() async {
    final rewards = await getUserRewards();
    
    if (rewards.restauradoresArmonia <= 0) {
      throw Exception('No tienes restauradores de armonía disponibles');
    }

    final updatedRewards = rewards.copyWith(
      restauradoresArmonia: rewards.restauradoresArmonia - 1,
      ultimaActualizacion: DateTime.now(),
    );

    await saveUserRewards(updatedRewards);
    return updatedRewards;
  }

  /// Comprar código premium con cristales
  Future<UserRewards> comprarCodigoPremium(String codigoId, int costo) async {
    final rewards = await getUserRewards();
    
    if (rewards.cristalesEnergia < costo) {
      throw Exception('No tienes suficientes cristales de energía');
    }

    if (rewards.codigosPremiumDesbloqueados.contains(codigoId)) {
      throw Exception('Este código ya está desbloqueado');
    }

    final updatedCodigos = [...rewards.codigosPremiumDesbloqueados, codigoId];
    
    final updatedRewards = rewards.copyWith(
      cristalesEnergia: rewards.cristalesEnergia - costo,
      codigosPremiumDesbloqueados: updatedCodigos,
      ultimaActualizacion: DateTime.now(),
    );

    await saveUserRewards(updatedRewards);
    return updatedRewards;
  }

  /// Usar meditación especial (consume luz cuántica)
  Future<UserRewards> usarMeditacionEspecial() async {
    final rewards = await getUserRewards();
    
    if (rewards.luzCuantica < luzCuanticaMaxima) {
      throw Exception('No tienes suficiente luz cuántica para esta meditación');
    }

    // Resetear luz cuántica después de usar
    final updatedRewards = rewards.copyWith(
      luzCuantica: 0.0,
      ultimaMeditacionEspecial: DateTime.now(),
      ultimaActualizacion: DateTime.now(),
    );

    await saveUserRewards(updatedRewards);
    return updatedRewards;
  }

  /// Verificar y otorgar recompensas basadas en racha
  Future<UserRewards> verificarRecompensasPorRacha(int diasConsecutivos) async {
    final rewards = await getUserRewards();
    
    // Recompensa por semana (7 días)
    if (diasConsecutivos >= diasParaRestaurador && 
        diasConsecutivos % diasParaRestaurador == 0) {
      // Verificar si ya se otorgó este restaurador
      final ultimaSemanaRecompensada = rewards.logros['ultima_semana_recompensada'] as int? ?? 0;
      if (ultimaSemanaRecompensada < diasConsecutivos) {
        final updatedRewards = await recompensarPorSemana();
        final nuevosLogros = Map<String, dynamic>.from(updatedRewards.logros);
        nuevosLogros['ultima_semana_recompensada'] = diasConsecutivos;
        return updatedRewards.copyWith(logros: nuevosLogros);
      }
    }

    // Desbloquear mantra por 21 días (solo una vez)
    if (diasConsecutivos >= diasParaMantra) {
      final mantra21Id = 'mantra_21_dias';
      if (!rewards.mantrasDesbloqueados.contains(mantra21Id)) {
        return await desbloquearMantra(mantra21Id);
      }
    }

    return rewards;
  }

  /// Obtener historial de recompensas
  Future<List<Map<String, dynamic>>> getRewardsHistory() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return [];

    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('$_rewardsHistoryKey$userId');
    
    if (historyJson != null) {
      final List<dynamic> list = jsonDecode(historyJson);
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    return [];
  }

  /// Agregar entrada al historial
  Future<void> addToHistory(String tipo, String descripcion, {int? cantidad}) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    final history = await getRewardsHistory();
    history.insert(0, {
      'tipo': tipo,
      'descripcion': descripcion,
      'cantidad': cantidad,
      'fecha': DateTime.now().toIso8601String(),
    });

    // Mantener solo las últimas 50 entradas
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_rewardsHistoryKey$userId', jsonEncode(history));
  }
}


---

## 5️⃣ Widget de Fondo: `lib/widgets/glow_background.dart`

import 'package:flutter/material.dart';

class GlowBackground extends StatelessWidget {
  final Widget child;
  
  const GlowBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B132B), // Azul profundo
            Color(0xFF1C2541), // Azul medio
            Color(0xFF2C3E50), // Azul grisáceo
          ],
        ),
      ),
      child: Stack(
        children: [
          // Efectos de brillo de fondo
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFD700).withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFD700).withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Contenido principal
          child,
        ],
      ),
    );
  }
}


---

## 📝 Especificaciones del Widget

### Estado Colapsado (por defecto):
- Ancho: 45px
- Muestra 2 íconos verticales: 💎 (cristal) y ✨ (luz cuántica)
- Ubicado en esquina superior derecha
- Bordes redondeados solo en el lado izquierdo

### Estado Expandido (al tocar):
- Ancho: 200px
- Se desliza desde la derecha hacia la izquierda
- Muestra: header con 'Estado', cristales, luz cuántica con barra de progreso, badge si hay suficientes cristales
- Botón ❌ para cerrar

### Posicionamiento:
- `Positioned(top: 0, right: 0)` dentro de un `Stack`
- Debe estar encima del título 'Portal Energético'
- No debe interferir visualmente con el contenido
