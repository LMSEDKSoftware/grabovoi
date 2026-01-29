import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/rewards_display.dart';
import '../../models/rewards_model.dart';
import '../../services/rewards_service.dart';
import '../../config/supabase_config.dart';
import 'premium_wallpaper_screen.dart';

/// Pantalla de tienda premium con secuencias especiales y meditaciones
class PremiumStoreScreen extends StatefulWidget {
  const PremiumStoreScreen({super.key});

  @override
  State<PremiumStoreScreen> createState() => _PremiumStoreScreenState();
}

class _PremiumStoreScreenState extends State<PremiumStoreScreen> {
  final RewardsService _rewardsService = RewardsService();
  UserRewards? _rewards;
  List<CodigoPremium> _codigosPremium = [];
  List<MeditacionEspecial> _meditacionesEspeciales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final rewards = await _rewardsService.getUserRewards();
      final codigos = await _loadCodigosPremium();
      final meditaciones = await _loadMeditacionesEspeciales();

      if (mounted) {
        setState(() {
          _rewards = rewards;
          _codigosPremium = codigos;
          _meditacionesEspeciales = meditaciones;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando datos de tienda: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<CodigoPremium>> _loadCodigosPremium() async {
    try {
      final response = await SupabaseConfig.client
          .from('codigos_premium')
          .select()
          .order('costo_cristales', ascending: true);

      return (response as List).map((json) {
        return CodigoPremium(
          id: json['id'],
          codigo: json['codigo'],
          nombre: json['nombre'],
          descripcion: json['descripcion'],
          costoCristales: json['costo_cristales'],
          categoria: json['categoria'] ?? 'Premium',
          esRaro: json['es_raro'] ?? false,
          // Campo opcional en Supabase: URL completa o relativa de la imagen
          wallpaperUrl: json['wallpaper_url'] as String?,
        );
      }).toList();
    } catch (e) {
      print('Error cargando secuencias premium: $e');
      return [];
    }
  }

  Future<List<MeditacionEspecial>> _loadMeditacionesEspeciales() async {
    try {
      final response = await SupabaseConfig.client
          .from('meditaciones_especiales')
          .select()
          .order('duracion_minutos', ascending: true);

      return (response as List).map((json) => MeditacionEspecial(
        id: json['id'],
        nombre: json['nombre'],
        descripcion: json['descripcion'],
        audioUrl: json['audio_url'] ?? '',
        luzCuanticaRequerida: (json['luz_cuantica_requerida'] ?? 100.0).toDouble(),
        duracionMinutos: json['duracion_minutos'] ?? 15,
      )).toList();
    } catch (e) {
      print('Error cargando meditaciones especiales: $e');
      return [];
    }
  }

  Future<void> _comprarCodigoPremium(CodigoPremium codigo) async {
    if (_rewards == null) return;

    if (_rewards!.codigosPremiumDesbloqueados.contains(codigo.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Esta secuencia ya está desbloqueada'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    if (_rewards!.cristalesEnergia < codigo.costoCristales) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ No tienes suficientes cristales. Necesitas ${codigo.costoCristales}, tienes ${_rewards!.cristalesEnergia}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar compra'),
        content: Text(
          '¿Deseas comprar "${codigo.nombre}" por ${codigo.costoCristales} cristales?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Comprar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final updatedRewards = await _rewardsService.comprarCodigoPremium(
        codigo.id,
        codigo.costoCristales,
      );

      await _rewardsService.addToHistory(
        'compra',
        'Secuencia premium desbloqueada: ${codigo.nombre}',
        cantidad: codigo.costoCristales,
      );

      if (mounted) {
        setState(() {
          _rewards = updatedRewards;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${codigo.nombre} desbloqueado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _comprarAnclaContinuidad() async {
    if (_rewards == null) return;

    const costo = RewardsService.cristalesParaAnclaContinuidad;

    if (_rewards!.cristalesEnergia < costo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ No tienes suficientes cristales. Necesitas $costo, tienes ${_rewards!.cristalesEnergia}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        title: Text(
          'Comprar Ancla de Continuidad',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Deseas comprar una Ancla de Continuidad por $costo cristales?',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFFFFD700), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '¿Qué hace?',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La Ancla de Continuidad salva automáticamente tu racha cuando no completes un día en un desafío. Si no completas un día, se usará automáticamente para mantener tu progreso. Solo puedes tener máximo 2 anclas (para salvar máximo 2 días seguidos).',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: const Color(0xFF0B132B),
            ),
            child: Text(
              'Comprar',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final updatedRewards = await _rewardsService.comprarAnclaContinuidad();

      await _rewardsService.addToHistory(
        'compra',
        'Ancla de Continuidad comprada',
        cantidad: costo,
      );

      if (mounted) {
        setState(() {
          _rewards = updatedRewards;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ancla de Continuidad comprada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAnclaContinuidadCard() {
    final puedeComprar = (_rewards?.cristalesEnergia ?? 0) >= RewardsService.cristalesParaAnclaContinuidad;
    final anclasDisponibles = _rewards?.anclasContinuidad ?? 0;
    final maxAnclas = RewardsService.maxAnclasContinuidad;
    final puedeComprarMas = anclasDisponibles < maxAnclas;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withOpacity(0.2),
            const Color(0xFFFFD700).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.anchor,
                  color: Color(0xFFFFD700),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ancla de Continuidad',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Salva tu racha automáticamente cuando no completes un día (máximo 2 anclas = 2 días seguidos)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: anclasDisponibles >= maxAnclas 
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: anclasDisponibles >= maxAnclas
                    ? Colors.orange.withOpacity(0.3)
                    : Colors.green.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  anclasDisponibles >= maxAnclas ? Icons.info_outline : Icons.check_circle,
                  color: anclasDisponibles >= maxAnclas ? Colors.orange : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    anclasDisponibles >= maxAnclas
                        ? 'Tienes el máximo de $maxAnclas anclas. No puedes comprar más.'
                        : 'Tienes $anclasDisponibles/${maxAnclas} anclas disponible${anclasDisponibles == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(
                      color: anclasDisponibles >= maxAnclas ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.diamond, color: Color(0xFFFFD700), size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${RewardsService.cristalesParaAnclaContinuidad}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFD700),
                    ),
                  ),
                ],
              ),
              CustomButton(
                text: !puedeComprarMas
                    ? 'Máximo alcanzado'
                    : puedeComprar
                        ? 'Comprar'
                        : 'Insuficientes',
                onPressed: (puedeComprarMas && puedeComprar) ? () => _comprarAnclaContinuidad() : null,
                color: (puedeComprarMas && puedeComprar) ? const Color(0xFFFFD700) : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _usarMeditacionEspecial(MeditacionEspecial meditacion) async {
    if (_rewards == null) return;

    if (_rewards!.luzCuantica < meditacion.luzCuanticaRequerida) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Necesitas ${meditacion.luzCuanticaRequerida.toInt()}% de luz cuántica. Tienes ${_rewards!.luzCuantica.toInt()}%',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final updatedRewards = await _rewardsService.usarMeditacionEspecial();

      await _rewardsService.addToHistory(
        'meditacion',
        'Meditación especial usada: ${meditacion.nombre}',
      );

      if (mounted) {
        setState(() {
          _rewards = updatedRewards;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ Disfruta tu meditación: ${meditacion.nombre}'),
            backgroundColor: const Color(0xFFFFD700),
          ),
        );
      }

      // Aquí podrías navegar a una pantalla de meditación
      // Navigator.push(context, MaterialPageRoute(...));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Color(0xFFFFD700)),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Text(
                              'Tienda Cuántica',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFD700),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Recompensas actuales
                      if (_rewards != null) RewardsDisplay(compact: false),
                      const SizedBox(height: 30),
                      // Secuencias Premium
                      Text(
                        'Secuencias Premium',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._codigosPremium.map((codigo) => _buildCodigoPremiumCard(codigo)),
                      const SizedBox(height: 30),
                      // Anclas de Continuidad
                      Text(
                        'Elementos Salvadores',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAnclaContinuidadCard(),
                      const SizedBox(height: 30),
                      // Meditaciones Especiales
                      Text(
                        'Meditaciones Especiales',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._meditacionesEspeciales.map((meditacion) => _buildMeditacionCard(meditacion)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCodigoPremiumCard(CodigoPremium codigo) {
    final estaDesbloqueado = _rewards?.codigosPremiumDesbloqueados.contains(codigo.id) ?? false;
    final puedeComprar = (_rewards?.cristalesEnergia ?? 0) >= codigo.costoCristales;
    final tieneWallpaper = (codigo.wallpaperUrl != null && codigo.wallpaperUrl!.isNotEmpty);

    void _abrirRecompensa() {
      if (!estaDesbloqueado) {
        return;
      }

      if (!tieneWallpaper) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La imagen de esta secuencia aún no está disponible'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PremiumWallpaperScreen(
            codigo: codigo,
            imageUrl: codigo.wallpaperUrl,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: estaDesbloqueado && tieneWallpaper ? _abrirRecompensa : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: estaDesbloqueado
                ? Colors.green.withOpacity(0.1)
                : const Color(0xFF2C3E50).withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: estaDesbloqueado
                  ? Colors.green
                  : codigo.esRaro
                      ? Colors.purple
                      : const Color(0xFFFFD700).withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          codigo.codigo,
                          style: GoogleFonts.spaceMono(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFD700),
                          ),
                        ),
                        if (codigo.esRaro) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'RARO',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      codigo.nombre,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      codigo.descripcion,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    if (estaDesbloqueado && tieneWallpaper) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.image, color: Colors.green, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Toca para ver tu fondo cuántico',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.diamond, color: Color(0xFFFFD700), size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${codigo.costoCristales}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFD700),
                    ),
                  ),
                ],
              ),
              if (estaDesbloqueado)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '✅ Desbloqueado',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!tieneWallpaper)
                      Text(
                        'Imagen próximamente',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white60,
                        ),
                      ),
                  ],
                )
              else
                CustomButton(
                  text: puedeComprar ? 'Comprar' : 'Insuficientes',
                  onPressed: puedeComprar ? () => _comprarCodigoPremium(codigo) : null,
                  color: puedeComprar ? const Color(0xFFFFD700) : Colors.grey,
                ),
            ],
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeditacionCard(MeditacionEspecial meditacion) {
    final puedeUsar = (_rewards?.luzCuantica ?? 0) >= meditacion.luzCuanticaRequerida;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50).withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: puedeUsar
              ? Colors.green.withOpacity(0.5)
              : const Color(0xFFFFD700).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.self_improvement,
                color: puedeUsar ? Colors.green : const Color(0xFFFFD700),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meditacion.nombre,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      meditacion.descripcion,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${meditacion.luzCuanticaRequerida.toInt()}% luz cuántica',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFFFFD700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.timer, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${meditacion.duracionMinutos} min',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: puedeUsar ? () => _usarMeditacionEspecial(meditacion) : null,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: puedeUsar 
                        ? const Color(0xFFFFD700).withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: puedeUsar 
                          ? const Color(0xFFFFD700).withOpacity(0.5)
                          : Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    puedeUsar ? Icons.lock_open : Icons.lock,
                    color: puedeUsar ? const Color(0xFFFFD700) : Colors.grey,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

