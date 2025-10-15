import 'package:flutter/material.dart';
import 'dart:async';

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() => _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _timer;
  int _currentPhase = 0; // 0: inhale, 1: hold, 2: exhale, 3: hold
  int _cycles = 0;
  bool _isActive = false;
  String _selectedPattern = '4-7-8';

  final Map<String, List<int>> _patterns = {
    '4-7-8': [4, 7, 8, 0], // Relajante
    '4-4-4-4': [4, 4, 4, 4], // Box breathing
    '5-5-5-5': [5, 5, 5, 5], // Profunda
    '3-0-3-0': [3, 0, 3, 0], // Rápida energizante
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _patterns[_selectedPattern]![0]),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startExercise() {
    setState(() {
      _isActive = true;
      _currentPhase = 0;
      _cycles = 0;
    });
    _runPhase();
  }

  void _stopExercise() {
    setState(() {
      _isActive = false;
    });
    _timer?.cancel();
    _controller.stop();
    _controller.reset();
  }

  void _runPhase() {
    final pattern = _patterns[_selectedPattern]!;
    final duration = pattern[_currentPhase];

    if (duration > 0) {
      _controller.duration = Duration(seconds: duration);
      _controller.forward(from: 0);

      _timer = Timer(Duration(seconds: duration), () {
        if (_isActive) {
          setState(() {
            _currentPhase = (_currentPhase + 1) % 4;
            if (_currentPhase == 0) {
              _cycles++;
            }
          });
          _runPhase();
        }
      });
    } else {
      setState(() {
        _currentPhase = (_currentPhase + 1) % 4;
      });
      _runPhase();
    }
  }

  String _getPhaseText() {
    switch (_currentPhase) {
      case 0:
        return 'Inhala';
      case 1:
        return 'Sostén';
      case 2:
        return 'Exhala';
      case 3:
        return 'Sostén';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejercicio de Respiración'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildPatternSelector(),
            const SizedBox(height: 32),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildVisualization(),
                  const SizedBox(height: 32),
                  Text(
                    _isActive ? _getPhaseText() : 'Toca para comenzar',
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  if (_isActive) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Ciclo: $_cycles',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ],
              ),
            ),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patrón de respiración',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _patterns.keys.map((pattern) {
                return ChoiceChip(
                  label: Text(pattern),
                  selected: _selectedPattern == pattern,
                  onSelected: _isActive
                      ? null
                      : (selected) {
                          if (selected) {
                            setState(() {
                              _selectedPattern = pattern;
                            });
                          }
                        },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              _getPatternDescription(_selectedPattern),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPatternDescription(String pattern) {
    switch (pattern) {
      case '4-7-8':
        return 'Inhala 4s, sostén 7s, exhala 8s - Relajación profunda';
      case '4-4-4-4':
        return 'Box Breathing - Balance y enfoque';
      case '5-5-5-5':
        return 'Respiración profunda - Calma y centrado';
      case '3-0-3-0':
        return 'Respiración energizante - Vitalidad';
      default:
        return '';
    }
  }

  Widget _buildVisualization() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final size = 100 + (_controller.value * 100);
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_isActive)
          ElevatedButton.icon(
            onPressed: _startExercise,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Comenzar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: _stopExercise,
            icon: const Icon(Icons.stop),
            label: const Text('Detener'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
      ],
    );
  }
}

