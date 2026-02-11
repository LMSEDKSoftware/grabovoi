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

class _EnergyStatsTabState extends State<EnergyStatsTab> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final RewardsService _rewardsService = RewardsService();
  bool _expanded = false;
  UserRewards? _rewards;
  bool _isLoading = true;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    RewardsService.rewardsUpdated.addListener(_onRewardsUpdated);
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refrescar cuando la app vuelve a estar activa (solo entonces, no periódicamente)
    if (state == AppLifecycleState.resumed && mounted) {
      _loadRewards(forceRefresh: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refrescar cuando el widget se vuelve visible (pero no en cada cambio)
    // Solo refrescar si no está cargando y no hay recompensas cargadas
    if (!_isLoading && _rewards == null) {
      _loadRewards();
    }
  }

  void _onRewardsUpdated() {
    if (mounted) _loadRewards(forceRefresh: true);
  }

  @override
  void dispose() {
    RewardsService.rewardsUpdated.removeListener(_onRewardsUpdated);
    WidgetsBinding.instance.removeObserver(this);
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadRewards({bool forceRefresh = false}) async {
    try {
      // Solo forzar lectura fresca cuando sea necesario (cuando se actualizan recompensas)
      final rewards = await _rewardsService.getUserRewards(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _rewards = rewards;
          _isLoading = false;
        });
        print('📊 EnergyStatsTab actualizado: ${rewards.cristalesEnergia} cristales, ${rewards.luzCuantica}% luz cuántica');
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
  
  // Método público para refrescar desde fuera (cuando se actualizan recompensas)
  void refresh() {
    _loadRewards(forceRefresh: true);
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
    // Crear recompensas por defecto si no existen para mostrar siempre el widget
    final rewards = _rewards ?? UserRewards(
      userId: 'default',
      cristalesEnergia: 0,
      restauradoresArmonia: 0,
      luzCuantica: 0.0,
      mantrasDesbloqueados: [],
      codigosPremiumDesbloqueados: [],
      ultimaActualizacion: DateTime.now(),
      logros: {},
    );
    
    // Mostrar siempre el widget, incluso si está cargando o hay error
    if (_isLoading && _rewards == null) {
      // Mostrar versión mínima mientras carga
      return Container(
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
        );
    }

    // Ancho del panel: 45px colapsado, 200px expandido (reducido para evitar overflow)
    const double collapsedWidth = 45;
    const double expandedWidth = 200;

    return Stack(
        clipBehavior: Clip.none,
        children: [
          // Se retira el backdrop para que no oscurezca la pantalla al expandir
          
          // Panel con ancho animado (anclado al borde derecho)
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              // Calcular el ancho actual según la animación
              final currentWidth = collapsedWidth + (_slideAnimation.value * (expandedWidth - collapsedWidth));
              // Mantener anclado al borde derecho; solo cambia el ancho
              return GestureDetector(
                  onTap: () {
                    // Tocar alterna entre expandido/colapsado
                    _toggleExpanded();
                  },
                  onHorizontalDragUpdate: (details) {
                    // Deslizar hacia la derecha oculta la solapa
                    if (_expanded && details.primaryDelta != null && details.primaryDelta! > 8) {
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
                    child: _expanded ? _buildExpandedContent(rewards) : _buildCollapsedContent(),
                  ),
                );
            },
          ),
        ],
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
          const Icon(
            Icons.diamond,
            color: Color(0xFFFFD700),
            size: 20,
          ),
          const SizedBox(height: 8),
          // Ícono de luz cuántica (✨)
          const Icon(
            Icons.auto_awesome,
            color: Color(0xFFFFD700),
            size: 20,
          ),
        ],
      ),
    );
  }

  /// Estado expandido: muestra detalles completos
  Widget _buildExpandedContent(UserRewards rewards) {
    final porcentaje = (rewards.luzCuantica / RewardsService.luzCuanticaMaxima * 100).toInt();
    final isLuzCompleta = rewards.luzCuantica >= RewardsService.luzCuanticaMaxima;

    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sin título de cabecera; mantenemos el alto con un espacio (
          // aprovechado para aumentar los tamaños de los títulos)
          const SizedBox(height: 6),
          
          // Cristales de energía
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(
                  Icons.diamond,
                  color: Color(0xFFFFD700),
                  size: 14,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cristales de energía',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${rewards.cristalesEnergia}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
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
          const SizedBox(height: 10),
          
          // Luz cuántica
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    isLuzCompleta ? Icons.check_circle : Icons.auto_awesome,
                    color: isLuzCompleta ? Colors.green : const Color(0xFFFFD700),
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Luz cuántica',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$porcentaje%',
                    style: GoogleFonts.inter(
                      fontSize: 9,
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
                    widthFactor: rewards.luzCuantica / RewardsService.luzCuanticaMaxima,
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
          if (rewards.cristalesEnergia >= RewardsService.cristalesParaCodigoPremium) ...[
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
