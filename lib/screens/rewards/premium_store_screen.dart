import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/rewards_display.dart';
import '../../models/rewards_model.dart';
import '../../models/store_config_model.dart';
import '../../services/rewards_service.dart';
import '../../services/store_config_service.dart';
import 'premium_wallpaper_screen.dart';
import '../profile/voice_numbers_settings_screen.dart';

/// Pantalla de tienda premium con secuencias especiales y meditaciones
class PremiumStoreScreen extends StatefulWidget {
  const PremiumStoreScreen({super.key});

  @override
  State<PremiumStoreScreen> createState() => _PremiumStoreScreenState();
}

class _PremiumStoreScreenState extends State<PremiumStoreScreen> {
  final RewardsService _rewardsService = RewardsService();
  final StoreConfigService _storeConfig = StoreConfigService();
  final ScrollController _scrollController = ScrollController();
  UserRewards? _rewards;
  List<CodigoPremium> _codigosPremium = [];
  List<MeditacionEspecial> _meditacionesEspeciales = [];
  List<PaqueteCristales> _paquetesCristales = [];
  int _costoVozNumerica = RewardsService.cristalesParaVozNumerica;
  int _costoAnclaContinuidad = RewardsService.cristalesParaAnclaContinuidad;
  int _maxAnclas = RewardsService.maxAnclasContinuidad;
  bool _isLoading = true;
  bool _showStickyHeader = false;
  static const double _rewardsSectionHeight = 280; // Altura aprox. título + Recompensas Cuánticas

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final show = _scrollController.offset > _rewardsSectionHeight;
    if (show != _showStickyHeader && mounted) {
      setState(() => _showStickyHeader = show);
    }
  }

  Future<void> _loadData() async {
    try {
      final rewards = await _rewardsService.getUserRewards();
      final codigos = await _storeConfig.getCodigosPremium();
      final meditaciones = await _storeConfig.getMeditacionesEspeciales();
      final paquetes = await _storeConfig.getPaquetesCristales();
      final costoVoz = await _storeConfig.getCostoVozNumerica();
      final configAncla = await _storeConfig.getConfigAnclaContinuidad();

      if (mounted) {
        setState(() {
          _rewards = rewards;
          _codigosPremium = codigos;
          _meditacionesEspeciales = meditaciones;
          _paquetesCristales = paquetes;
          _costoVozNumerica = costoVoz;
          _costoAnclaContinuidad = configAncla.costo;
          _maxAnclas = configAncla.maxAnclas;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos de tienda: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

    if (_rewards!.cristalesEnergia < _costoAnclaContinuidad) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ No tienes suficientes cristales. Necesitas $_costoAnclaContinuidad, tienes ${_rewards!.cristalesEnergia}',
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
              '¿Deseas comprar una Ancla de Continuidad por $_costoAnclaContinuidad cristales?',
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
      final updatedRewards = await _rewardsService.comprarAnclaContinuidad(
        costo: _costoAnclaContinuidad,
        maxAnclas: _maxAnclas,
      );

      await _rewardsService.addToHistory(
        'compra',
        'Ancla de Continuidad comprada',
        cantidad: _costoAnclaContinuidad,
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

  Future<void> _comprarVozNumerica() async {
    if (_rewards == null) return;

    final yaDesbloqueado = _rewards!.logros['voice_numbers_unlocked'] == true ||
        _rewards!.voiceNumbersEnabled == true;

    if (yaDesbloqueado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ La voz numérica ya está desbloqueada'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    if (_rewards!.cristalesEnergia < _costoVozNumerica) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ No tienes suficientes cristales. Necesitas $_costoVozNumerica, tienes ${_rewards!.cristalesEnergia}',
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
          'Desbloquear Voz Numérica',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Deseas desbloquear la voz numérica por $_costoVozNumerica cristales?',
          style: GoogleFonts.inter(color: Colors.white70),
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
      final updatedRewards = await _rewardsService.comprarVozNumerica(costo: _costoVozNumerica);
      if (mounted) {
        setState(() {
          _rewards = updatedRewards;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Voz numérica desbloqueada'),
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

  Widget _buildVoiceNumbersCard() {
    final desbloqueado = _rewards?.logros['voice_numbers_unlocked'] == true ||
        _rewards?.voiceNumbersEnabled == true;
    final puedeComprar = (_rewards?.cristalesEnergia ?? 0) >= _costoVozNumerica;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50).withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.4),
          width: 1.5,
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
                  Icons.record_voice_over,
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
                      'Voz numérica en pilotajes',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reproduce la secuencia dígito a dígito durante el pilotaje (voz hombre o mujer).',
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
                  const Icon(Icons.diamond, color: Color(0xFFFFD700), size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '$_costoVozNumerica',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFD700),
                    ),
                  ),
                ],
              ),
              CustomButton(
                text: desbloqueado
                    ? 'Configurar'
                    : puedeComprar
                        ? 'Comprar'
                        : 'Insuficientes',
                onPressed: desbloqueado
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const VoiceNumbersSettingsScreen(),
                          ),
                        );
                      }
                    : (puedeComprar ? () => _comprarVozNumerica() : null),
                color: (desbloqueado || puedeComprar)
                    ? const Color(0xFFFFD700)
                    : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnclaContinuidadCard() {
    final puedeComprar = (_rewards?.cristalesEnergia ?? 0) >= _costoAnclaContinuidad;
    final anclasDisponibles = _rewards?.anclasContinuidad ?? 0;
    final puedeComprarMas = anclasDisponibles < _maxAnclas;

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
              color:               anclasDisponibles >= _maxAnclas
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: anclasDisponibles >= _maxAnclas
                    ? Colors.orange.withOpacity(0.3)
                    : Colors.green.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  anclasDisponibles >= _maxAnclas ? Icons.info_outline : Icons.check_circle,
                  color: anclasDisponibles >= _maxAnclas ? Colors.orange : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    anclasDisponibles >= _maxAnclas
                        ? 'Tienes el máximo de $_maxAnclas anclas. No puedes comprar más.'
                        : 'Tienes $anclasDisponibles/$_maxAnclas anclas disponible${anclasDisponibles == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(
                      color: anclasDisponibles >= _maxAnclas ? Colors.orange : Colors.green,
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
                    '$_costoAnclaContinuidad',
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

  Widget _buildStickyHeader() {
    if (_rewards == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2541).withOpacity(0.98),
        border: Border(bottom: BorderSide(color: const Color(0xFFFFD700).withOpacity(0.3))),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFFFFD700)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Text(
                'Tienda Cuántica',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700),
                ),
              ),
            ),
            // Cristales (estilo app: icono + cantidad)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2C3E50).withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.diamond, color: Color(0xFFFFD700), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${_rewards!.cristalesEnergia}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Luz cuántica (estilo app: icono + %)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2C3E50).withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${_rewards!.luzCuantica.toInt()}%',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
              : Stack(
                  children: [
                    // Todo el contenido en un solo scroll (sección Recompensas se mueve con el resto)
                    SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          const SizedBox(height: 12),
                          if (_rewards != null)
                            RewardsDisplay(compact: false, initialRewards: _rewards),
                          const SizedBox(height: 30),
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
                            Text(
                              'Mejoras de Pilotaje',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFD700),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildVoiceNumbersCard(),
                            const SizedBox(height: 30),
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
                            const SizedBox(height: 30),
                            Text(
                              'Cristales de energía',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFD700),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Recarga cristales para comprar secuencias, voz numérica y más.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_paquetesCristales.isEmpty) ...[
                              _buildCristalesPackCard(250, 89),
                              const SizedBox(height: 12),
                              _buildCristalesPackCard(700, 199),
                              const SizedBox(height: 12),
                              _buildCristalesPackCard(1600, 349),
                            ] else ...[
                              ..._paquetesCristales.asMap().entries.map((e) {
                                final p = e.value;
                                final isLast = e.key == _paquetesCristales.length - 1;
                                return Padding(
                                  padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                                  child: _buildCristalesPackCard(p.cantidadCristales, p.precioMxn),
                                );
                              }),
                            ],
                            const SizedBox(height: 30),
                            Text(
                              'Luz cuántica',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFD700),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Recarga tu luz cuántica sin esperar para acceder a meditaciones especiales.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildRecargaLuzCuanticaCard(),
                        ],
                      ),
                    ),
                    if (_showStickyHeader)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Material(
                          color: Colors.transparent,
                          child: _buildStickyHeader(),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Card de pack de cristales (compra in-app). Iconos de cristales según cantidad (más llenado = más cristales).
  Widget _buildCristalesPackCard(int cristales, int precioMxn) {
    // Nivel visual: 250 -> pocos, 700 -> medio, 1600 -> lleno (cantidad de iconos + “llenado”)
    final int nivel = cristales <= 250 ? 3 : (cristales <= 700 ? 5 : 7);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50).withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.35),
                width: 1,
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              runSpacing: 2,
              spacing: 2,
              children: List.generate(nivel, (i) {
                final size = 14.0 + (i % 3) * 2.0;
                final opacity = 0.6 + (i / nivel) * 0.4;
                return Icon(
                  Icons.diamond,
                  color: const Color(0xFFFFD700).withOpacity(opacity.clamp(0.0, 1.0)),
                  size: size,
                );
              }),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$cristales cristales',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$$precioMxn MXN',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700),
                ),
              ),
              const SizedBox(height: 8),
              CustomButton(
                text: 'Comprar',
                onPressed: () => _comprarCristalesPack(cristales, precioMxn),
                color: const Color(0xFFFFD700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Card de recarga de luz cuántica (placeholder hasta integrar IAP).
  Widget _buildRecargaLuzCuanticaCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50).withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recarga al 100%',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Luz cuántica al máximo para meditaciones especiales',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          CustomButton(
            text: 'Próximamente',
            onPressed: null,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Future<void> _comprarCristalesPack(int cristales, int precioMxn) async {
    if (!mounted) return;
    // Simular proceso de pago en tienda (luego aquí irá la integración real con StoreKit / in_app_purchase)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFFFD700)),
                SizedBox(height: 16),
                Text(
                  'Procesando compra...',
                  style: TextStyle(
                    color: Color(0xFF1C2541),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    try {
      final updatedRewards = await _rewardsService.agregarCristalesComprados(cristales);
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() {
        _rewards = updatedRewards;
      });
      if (!mounted) return;
      _mostrarConfirmacionCristalesComprados(cristales);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar la compra: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarConfirmacionCristalesComprados(int cristales) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFFD700), width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFFFFD700), size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '¡Gracias por tu compra!',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Has adquirido $cristales cristales de energía. Ya están en tu cuenta.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ahora puedes usarlos para comprar:',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFFD700),
              ),
            ),
            const SizedBox(height: 8),
            _bullet('Secuencias premium'),
            _bullet('Mejoras en el pilotaje (voz numérica)'),
            _bullet('Elementos salvadores (anclas de continuidad)'),
            const SizedBox(height: 8),
            Text(
              '¡Disfruta tu experiencia cuántica!',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Entendido',
              style: GoogleFonts.inter(
                color: const Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.inter(
              color: const Color(0xFFFFD700),
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ),
        ],
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
