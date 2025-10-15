import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/settings_provider.dart';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({super.key});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  bool _isActive = false;
  int _remainingMinutes = 20;
  int _selectedDuration = 20;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startFocusMode() {
    setState(() {
      _isActive = true;
      _remainingMinutes = _selectedDuration;
    });

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        _remainingMinutes--;
        if (_remainingMinutes <= 0) {
          _completeFocusMode();
        }
      });
    });

    context.read<SettingsProvider>().setFocusModeEnabled(true);
  }

  void _stopFocusMode() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
    });
    context.read<SettingsProvider>().setFocusModeEnabled(false);
  }

  void _completeFocusMode() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
    });
    context.read<SettingsProvider>().setFocusModeEnabled(false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¡Sesión completada!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Felicitaciones! Completaste tu sesión de enfoque.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Enfoque'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.do_not_disturb_on,
                    size: 80,
                    color: _isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _isActive ? 'Modo Enfoque Activo' : 'Modo Enfoque',
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (!_isActive) ...[
                    Text(
                      'Crea un espacio sin distracciones para tus prácticas',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    _buildDurationSelector(),
                  ] else ...[
                    Text(
                      '$_remainingMinutes',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'minutos restantes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 32),
                    _buildActiveFeatures(),
                  ],
                ],
              ),
            ),
            if (!_isActive)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startFocusMode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(20),
                  ),
                  child: const Text('Iniciar Modo Enfoque'),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _stopFocusMode,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                  ),
                  child: const Text('Detener'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Duración',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDurationChip(10),
                _buildDurationChip(20),
                _buildDurationChip(30),
                _buildDurationChip(60),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationChip(int minutes) {
    final isSelected = _selectedDuration == minutes;
    
    return ChoiceChip(
      label: Text('$minutes min'),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedDuration = minutes;
        });
      },
    );
  }

  Widget _buildActiveFeatures() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Durante el modo enfoque:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              Icons.notifications_off,
              'Notificaciones silenciadas',
            ),
            _buildFeatureItem(
              Icons.phone_disabled,
              'Llamadas bloqueadas',
            ),
            _buildFeatureItem(
              Icons.access_time,
              'Temporizador activo',
            ),
            _buildFeatureItem(
              Icons.spa,
              'Ambiente de calma',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}

