import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../models/challenge_model.dart';
import '../../services/challenge_service.dart';
import '../../services/challenge_progress_tracker.dart';
import '../../services/challenge_tracking_service.dart';
import 'challenge_congrats_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service_simple.dart';
import '../../config/env.dart';
import '../../config/supabase_config.dart';

class ChallengeProgressScreen extends StatefulWidget {
  final Challenge challenge;

  const ChallengeProgressScreen({super.key, required this.challenge});

  @override
  State<ChallengeProgressScreen> createState() => _ChallengeProgressScreenState();
}

class _ChallengeProgressScreenState extends State<ChallengeProgressScreen> {
  late Challenge _challenge;
  bool _isLoading = true;
  final ChallengeProgressTracker _progressTracker = ChallengeProgressTracker();

  @override
  void initState() {
    super.initState();
    _challenge = widget.challenge;
    _loadChallengeProgress();
    
    // Escuchar cambios en el tracker
    _progressTracker.addListener(_onTrackerChanged);
  }
  
  void _onTrackerChanged() {
    if (mounted) {
      setState(() {
        print('🔄 Tracker cambió - actualizando UI');
      });
    }
  }
  
  @override
  void dispose() {
    _progressTracker.removeListener(_onTrackerChanged);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refrescar el estado cuando el usuario regrese a esta pantalla
    setState(() {});
  }

  Future<void> _loadChallengeProgress() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _progressTracker.initialize();
      // Verificar y actualizar racha al cargar la pantalla
      final challengeService = ChallengeService();
      final trackingService = ChallengeTrackingService();
      
      // Sincronizar progreso desde Supabase para asegurar que el estado del día sea correcto
      await trackingService.syncProgressFromSupabase(_challenge.id);
      
      await trackingService.verificarYActualizarRacha(_challenge.id);
      // Recargar el desafío actualizado
      final updatedChallenge = challengeService.getChallenge(_challenge.id);
      if (updatedChallenge != null && mounted) {
        setState(() {
          _challenge = updatedChallenge;
        });
      }
      
      // Forzar actualización de la UI después de cargar progreso
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error inicializando el rastreador de progreso: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Título del desafío
                      Text(
                        _challenge.title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _challenge.description,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Progreso del desafío
                      _buildProgressCard(),
                      
                      const SizedBox(height: 30),
                      
                      // Acciones del día
                      _buildDailyActions(),
                      
                      const SizedBox(height: 30),
                      
                      // Botones de acción
                      _buildActionButtons(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final color = Color(int.parse(_challenge.color.replaceAll('#', '0xFF')));
    
    // Calcular progreso basado en días COMPLETADOS, no en el día actual
    int completedDays = 0;
    final trackingService = ChallengeTrackingService();
    final challengeProgress = trackingService.getChallengeProgress(_challenge.id);
    
    if (challengeProgress != null) {
      // Contar cuántos días están marcados como completados
      completedDays = challengeProgress.dayProgress.values
          .where((dayProg) => dayProg.isCompleted)
          .length;
    }
    
    final progress = _challenge.durationDays > 0 
        ? completedDays / _challenge.durationDays 
        : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _challenge.icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progreso del Desafío',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Día ${_challenge.currentDay} de ${_challenge.durationDays}',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acciones de Hoy',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._getRequiredActionsForToday().map((action) => _buildActionItem(action)).toList(),
        ],
      ),
    );
  }

  List<String> _getRequiredActionsForToday() {
    // Obtener las acciones requeridas basadas en la dificultad del desafío
    switch (_challenge.difficulty) {
      case ChallengeDifficulty.principiante:
        return [
          '🔄 Repetir al menos 1 código',
          '🖼️ Compartir 1 pilotaje',
          '⏱️ Usar la app 15 minutos'
        ];
      case ChallengeDifficulty.intermedio:
        return [
          '🔄 Repetir 2 códigos diferentes',
          '🚀 Pilotar 1 código',
          '🖼️ Compartir 1 pilotaje',
          '⏱️ Usar la app 20 minutos'
        ];
      case ChallengeDifficulty.avanzado:
        return [
          '🔄 Repetir 3 códigos diferentes',
          '🚀 Pilotar 2 códigos',
          '🖼️ Compartir 2 pilotajes',
          '⏱️ Usar la app 30 minutos'
        ];
      case ChallengeDifficulty.maestro:
        return [
          '🔄 Repetir 5 códigos diferentes',
          '🚀 Pilotar 3 códigos',
          '🖼️ Compartir 3 pilotajes',
          '⏱️ Usar la app 45 minutos'
        ];
    }
  }

  IconData _getActionIcon(String action) {
    if (action.contains('🔄')) return Icons.repeat;
    if (action.contains('🚀')) return Icons.rocket_launch;
    if (action.contains('🖼️')) return Icons.ios_share;
    if (action.contains('⏱️')) return Icons.timer;
    return Icons.check_circle_outline;
  }

  Widget _buildActionItem(String action) {
    final isCompleted = _progressTracker.isActionCompleted(action, 0);
    final currentProgress = _progressTracker.getActionProgress(action);
    final requiredAmount = _progressTracker.getActionRequirement(action);
    
    print('🔍 Acción: $action - Completada: $isCompleted - Progreso: $currentProgress/$requiredAmount');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(
            _getActionIcon(action),
            color: const Color(0xFFFFD700),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                if (requiredAmount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$currentProgress / $requiredAmount',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? Colors.green : Colors.white.withOpacity(0.5),
            size: 20,
          ),
        ],
      ),
    );
  }


  Widget _buildActionButtons() {
    final actions = _getRequiredActionsForToday();
    final allDone = actions.every((a) => _progressTracker.isActionCompleted(a, 0));
    final isLastDay = _challenge.currentDay >= _challenge.durationDays;

    final showFinalize = allDone && isLastDay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!showFinalize) ...[
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: 320,
              child: CustomButton(
                text: 'Continuar Desafío',
                onPressed: () async {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: Icons.play_arrow,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (showFinalize) ...[
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: 360,
              child: CustomButton(
                text: 'Finalizar Reto y Obtener Certificado',
                onPressed: () async {
                  // Verificar y otorgar recompensas si el desafío está completado
                  final challengeService = ChallengeService();
                  await challengeService.verificarYOtorgarRecompensasDesafio(_challenge.id);
                  
                  final supabaseBase = (Env.supabaseUrl.isNotEmpty ? Env.supabaseUrl : SupabaseConfig.url).replaceFirst(RegExp(r'/$'), '');
                  final publicUrl = '$supabaseBase/storage/v1/object/public/rewards/challenges/iniciacion_energetica/certificado.png';
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChallengeCongratsScreen(
                        title: 'Desafío de Iniciación Energética',
                        imageUrl: publicUrl,
                        description: 'Comienza tu viaje de manifestación con los códigos básicos. Has completado con éxito este desafío de iniciación usando los códigos cuánticos de Grigori Grabovoi.',
                      ),
                    ),
                  );
                },
                icon: Icons.emoji_events,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: 320,
            child: CustomButton(
              text: 'Ver Estadísticas',
              onPressed: _showStatistics,
              isOutlined: true,
              icon: Icons.analytics,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showStatistics() async {
    final supabase = Supabase.instance.client;
    final auth = AuthServiceSimple();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para ver estadísticas')),
      );
      return;
    }

    final start = (_challenge.startDate ?? DateTime.now().subtract(Duration(days: _challenge.durationDays))).toUtc();
    final end = (_challenge.endDate ?? DateTime.now()).toUtc();

    final response = await supabase
        .from('user_actions')
        .select('action_type, action_data, recorded_at')
        .eq('user_id', auth.currentUser!.id)
        .gte('recorded_at', start.toIso8601String())
        .lte('recorded_at', end.toIso8601String());

    final Map<String, Map<String, int>> perDay = {};
    int totalRepeated = 0, totalPiloted = 0, totalQuantum = 0, totalShared = 0;

    for (final row in response as List) {
      final date = DateTime.parse(row['recorded_at']).toLocal();
      final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final type = row['action_type'] as String? ?? '';
      final data = (row['action_data'] as Map?)?.cast<String, dynamic>();
      perDay.putIfAbsent(dayKey, () => {
            'repetidos': 0,
            'pilotajes': 0,
            'pilotajes_cuanticos': 0,
            'compartidos': 0,
            'uso_app_min': 0,
          });
      switch (type) {
        case 'codigoRepetido':
          perDay[dayKey]!['repetidos'] = (perDay[dayKey]!['repetidos'] ?? 0) + 1;
          totalRepeated++;
          break;
        case 'sesionPilotaje':
          perDay[dayKey]!['pilotajes'] = (perDay[dayKey]!['pilotajes'] ?? 0) + 1;
          totalPiloted++;
          break;
        case 'pilotajeCuantico':
          perDay[dayKey]!['pilotajes_cuanticos'] = (perDay[dayKey]!['pilotajes_cuanticos'] ?? 0) + 1;
          totalQuantum++;
          break;
        case 'pilotajeCompartido':
          perDay[dayKey]!['compartidos'] = (perDay[dayKey]!['compartidos'] ?? 0) + 1;
          totalShared++;
          break;
        case 'tiempoEnApp':
          final minutes = (data?['duration'] as num?)?.toInt() ?? 0;
          perDay[dayKey]!['uso_app_min'] =
              (perDay[dayKey]!['uso_app_min'] ?? 0) + minutes;
          break;
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B132B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final days = perDay.keys.toList()..sort();
        final accent = const Color(0xFFFFD700);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insights, color: Color(0xFFFFD700)),
                    const SizedBox(width: 8),
                    Text('Resumen del reto', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 14),
                // Tarjetas de totales
                Row(
                  children: [
                    _StatChip(icon: Icons.repeat, label: 'Repeticiones', value: '$totalRepeated', color: accent),
                    const SizedBox(width: 10),
                    _StatChip(icon: Icons.rocket_launch, label: 'Pilotajes', value: '$totalPiloted', color: accent),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StatChip(icon: Icons.auto_awesome, label: 'Pil. cuánticos', value: '$totalQuantum', color: accent),
                    const SizedBox(width: 10),
                    _StatChip(icon: Icons.ios_share, label: 'Pilotajes compartidos', value: '$totalShared', color: accent),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Detalle por día', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                ...days.map((d) {
                  final m = perDay[d]!;
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 10,
                                runSpacing: 6,
                                children: [
                                  _MiniStat(icon: Icons.repeat, text: '${m['repetidos']} rep'),
                                  _MiniStat(icon: Icons.rocket_launch, text: '${m['pilotajes']} pil'),
                                  _MiniStat(icon: Icons.auto_awesome, text: '${m['pilotajes_cuanticos']} pilQ'),
                                  _MiniStat(icon: Icons.ios_share, text: '${m['compartidos']} comp'),
                                  _MiniStat(icon: Icons.timer, text: '${m['uso_app_min']} min app'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.18), color.withOpacity(0.06)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
                  Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MiniStat({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFFFD700), size: 14),
          const SizedBox(width: 6),
          Text(text, style: GoogleFonts.inter(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}