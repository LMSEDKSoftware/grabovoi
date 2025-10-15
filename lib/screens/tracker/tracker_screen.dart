import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/tracker_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/audio_service.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> with TickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _audioService.initialize();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _codeController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _showMysticalCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xFF10B981),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Ritual Completado',
              style: TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withOpacity(0.2),
                    const Color(0xFF8B5CF6).withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
              Icons.check_circle,
                color: Color(0xFF10B981),
              size: 64,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¡La energía se ha manifestado!',
              style: TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tu ritual de repetición ha sido completado exitosamente. La frecuencia numérica ha sido activada.',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF06B6D4).withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.repeat,
                color: Color(0xFF06B6D4),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Ritual de Repetición',
              style: TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<TrackerProvider>(
        builder: (context, trackerProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
                  child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                _buildMysticalHeader(),
                const SizedBox(height: 32),
                _buildCodeSection(),
                const SizedBox(height: 32),
                _buildRitualCounter(),
                const SizedBox(height: 32),
                _buildRitualNotes(),
                const SizedBox(height: 32),
                _buildRitualControls(trackerProvider),
                      const SizedBox(height: 32),
                _buildRecentRituals(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMysticalHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF06B6D4).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF06B6D4).withOpacity(0.3),
          width: 1,
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
                  color: const Color(0xFF06B6D4).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF06B6D4),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Portal de Manifestación',
                  style: TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Repite tu código sagrado con intención y observa cómo la energía se manifiesta en tu realidad.',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeSection() {
    return Consumer<TrackerProvider>(builder: (context, trackerProvider, _) {
      final activeCode = trackerProvider.currentSession?.code;
      final isActive = trackerProvider.isActive;

      return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1A1A2E),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Código Sagrado',
            style: TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (isActive && activeCode != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F23),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.6), width: 1.5),
              ),
              child: Text(
                activeCode,
                style: const TextStyle(
                  color: Color(0xFF8B5CF6),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 3,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            TextField(
            controller: _codeController,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 18,
              fontFamily: 'monospace',
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              hintText: 'Ingresa tu código numérico...',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontFamily: 'monospace',
              ),
              filled: true,
              fillColor: const Color(0xFF0F0F23),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF8B5CF6),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
    });
  }

  Widget _buildRitualCounter() {
    return Consumer<TrackerProvider>(
      builder: (context, trackerProvider, _) {
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: trackerProvider.isActive ? _pulseAnimation.value : 1.0,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF8B5CF6).withOpacity(0.2),
                      const Color(0xFF06B6D4).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.repeat,
                            color: Color(0xFF8B5CF6),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 20),
            Column(
              children: [
                Text(
                              '${trackerProvider.currentCount}',
                              style: const TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontSize: 48,
                    fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const Text(
                              'Repeticiones',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 16,
                              ),
                ),
              ],
            ),
          ],
        ),
                    const SizedBox(height: 20),
                    if (_codeController.text.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0F23),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF8B5CF6).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _codeController.text,
                          style: const TextStyle(
                            color: Color(0xFF8B5CF6),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            letterSpacing: 3,
                          ),
                          textAlign: TextAlign.center,
          ),
        ),
      ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRitualNotes() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1A1A2E),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notas del Ritual',
            style: TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 4,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'Registra tus sensaciones, intenciones o experiencias...',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: const Color(0xFF0F0F23),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF8B5CF6),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRitualControls(TrackerProvider trackerProvider) {
    return Row(
        children: [
          Expanded(
          child: ElevatedButton.icon(
            onPressed: trackerProvider.isActive
                ? () {
                    trackerProvider.stopSession();
                    _pulseController.stop();
                    _glowController.stop();
                  }
                : () {
                    final preset = trackerProvider.currentSession?.code;
                    final code = preset ?? _codeController.text;
                    if (code.isNotEmpty) {
                      trackerProvider.startSession(code);
                      _pulseController.repeat(reverse: true);
                      _glowController.repeat(reverse: true);
                    }
                  },
            icon: Icon(
              trackerProvider.isActive ? Icons.stop : Icons.play_arrow,
              color: Colors.white,
            ),
            label: Text(
              trackerProvider.isActive ? 'Detener Ritual' : 'Iniciar Ritual',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: trackerProvider.isActive
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF8B5CF6),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
          child: ElevatedButton.icon(
            onPressed: trackerProvider.isActive
                ? () {
                    trackerProvider.incrementCount();
                    HapticFeedback.lightImpact();
                  }
                : null,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Repetir',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
              style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06B6D4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            ),
          ),
        ],
    );
  }

  Widget _buildRecentRituals() {
    return Consumer2<TrackerProvider, AuthProvider>(
      builder: (context, trackerProvider, authProvider, _) {
        final recentSessions = trackerProvider.recentSessions.take(3).toList();

        if (recentSessions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rituales Recientes',
              style: TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...recentSessions.map((session) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF1A1A2E),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.repeat,
                      color: Color(0xFF8B5CF6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                          session.code,
                          style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${session.repetitions} repeticiones • ${_formatDate(session.startTime)}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                        ),
                ),
              ],
            ),
            )),
          ],
          );
        },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m atrás';
    } else {
      return 'Ahora';
    }
  }
}