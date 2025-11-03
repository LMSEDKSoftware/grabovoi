import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../models/rewards_model.dart';
import '../../services/rewards_service.dart';
import '../../config/supabase_config.dart';

/// Pantalla para mostrar mantras desbloqueados
class MantrasScreen extends StatefulWidget {
  const MantrasScreen({super.key});

  @override
  State<MantrasScreen> createState() => _MantrasScreenState();
}

class _MantrasScreenState extends State<MantrasScreen> {
  final RewardsService _rewardsService = RewardsService();
  UserRewards? _rewards;
  List<Mantra> _mantras = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final rewards = await _rewardsService.getUserRewards();
      final mantras = await _loadMantras();
      final userProgress = await _getUserProgress();

      if (mounted) {
        setState(() {
          _rewards = rewards;
          _mantras = mantras;
          _isLoading = false;
        });
      }

      // Verificar si hay nuevos mantras para desbloquear
      if (userProgress != null) {
        final diasConsecutivos = userProgress['dias_consecutivos'] ?? 0;
        await _checkAndUnlockMantras(diasConsecutivos);
      }
    } catch (e) {
      print('Error cargando mantras: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _getUserProgress() async {
    try {
      final userId = _rewardsService.authService.currentUser?.id;
      if (userId == null) return null;

      final response = await SupabaseConfig.client
          .from('usuario_progreso')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error obteniendo progreso: $e');
      return null;
    }
  }

  Future<List<Mantra>> _loadMantras() async {
    try {
      final response = await SupabaseConfig.client
          .from('mantras')
          .select()
          .order('dias_requeridos', ascending: true);

      return (response as List).map((json) => Mantra(
        id: json['id'],
        nombre: json['nombre'],
        descripcion: json['descripcion'],
        texto: json['texto'],
        diasRequeridos: json['dias_requeridos'],
        categoria: json['categoria'] ?? 'Espiritualidad',
        esPremium: json['es_premium'] ?? false,
      )).toList();
    } catch (e) {
      print('Error cargando mantras: $e');
      return [];
    }
  }

  Future<void> _checkAndUnlockMantras(int diasConsecutivos) async {
    if (_rewards == null) return;

    try {
      for (var mantra in _mantras) {
        if (diasConsecutivos >= mantra.diasRequeridos &&
            !_rewards!.mantrasDesbloqueados.contains(mantra.id)) {
          // Desbloquear mantra
          final updatedRewards = await _rewardsService.desbloquearMantra(mantra.id);
          await _rewardsService.addToHistory(
            'mantra',
            'Mantra desbloqueado: ${mantra.nombre}',
          );

          if (mounted) {
            setState(() {
              _rewards = updatedRewards;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✨ ¡Has desbloqueado: ${mantra.nombre}!'),
                backgroundColor: const Color(0xFFFFD700),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error verificando mantras: $e');
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
                              'Mis Mantras',
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
                      // Lista de mantras
                      ..._mantras.map((mantra) => _buildMantraCard(mantra)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildMantraCard(Mantra mantra) {
    final estaDesbloqueado = _rewards?.mantrasDesbloqueados.contains(mantra.id) ?? false;
    final userProgress = _getUserProgress();
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: userProgress,
      builder: (context, snapshot) {
        final diasConsecutivos = snapshot.data?['dias_consecutivos'] ?? 0;
        final puedeDesbloquear = diasConsecutivos >= mantra.diasRequeridos && !estaDesbloqueado;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: estaDesbloqueado
                ? Colors.purple.withOpacity(0.1)
                : const Color(0xFF2C3E50).withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: estaDesbloqueado
                  ? Colors.purple
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
                    estaDesbloqueado ? Icons.auto_awesome : Icons.lock,
                    color: estaDesbloqueado ? Colors.purple : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mantra.nombre,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: estaDesbloqueado ? Colors.white : Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mantra.descripcion,
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
              if (estaDesbloqueado) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mantra:',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mantra.texto,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Requiere ${mantra.diasRequeridos} días consecutivos',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    if (puedeDesbloquear)
                      CustomButton(
                        text: 'Desbloquear',
                        onPressed: () async {
                          await _checkAndUnlockMantras(diasConsecutivos);
                          await _loadData();
                        },
                        color: Colors.purple,
                      )
                    else
                      Text(
                        '$diasConsecutivos/${mantra.diasRequeridos} días',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white54,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

