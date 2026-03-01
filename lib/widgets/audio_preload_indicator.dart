import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_preload_service.dart';

class AudioPreloadIndicator extends StatefulWidget {
  const AudioPreloadIndicator({super.key});

  @override
  State<AudioPreloadIndicator> createState() => _AudioPreloadIndicatorState();
}

class _AudioPreloadIndicatorState extends State<AudioPreloadIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fillController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fillAnimation;
  
  final AudioPreloadService _preloadService = AudioPreloadService();
  StreamSubscription<double>? _progressSubscription;
  StreamSubscription<bool>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    
    // Animación de pulso
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Animación de llenado
    _fillController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fillAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fillController, curve: Curves.easeInOut),
    );
    
    // Escuchar cambios en el progreso
    _progressSubscription = _preloadService.progressStream.listen((progress) {
      _fillController.animateTo(progress);
    });
    
    // Escuchar cambios en el estado
    _statusSubscription = _preloadService.statusStream.listen((isPreloading) {
      if (isPreloading) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fillController.dispose();
    _progressSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _preloadService.statusStream,
      initialData: false,
      builder: (context, statusSnapshot) {
        final isPreloading = statusSnapshot.data ?? false;
        
        if (!isPreloading) return const SizedBox.shrink();
        
        return StreamBuilder<double>(
          stream: _preloadService.progressStream,
          initialData: 0.0,
          builder: (context, progressSnapshot) {
            final progress = progressSnapshot.data ?? 0.0;
            
            return Positioned(
              top: 20,
              right: 20,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.8),
                        border: Border.all(
                          color: const Color(0xFFFFD700),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Icono de audio
                          const Icon(
                            Icons.audiotrack,
                            color: Color(0xFFFFD700),
                            size: 32,
                          ),
                          
                          // Indicador de progreso circular
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: AnimatedBuilder(
                              animation: _fillAnimation,
                              builder: (context, child) {
                                return CircularProgressIndicator(
                                  value: _fillAnimation.value,
                                  strokeWidth: 4,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    const Color(0xFFFFD700).withOpacity(0.3),
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          // Porcentaje de progreso
                          Positioned(
                            bottom: 8,
                            child: Text(
                              '${(progress * 100).toInt()}%',
                              style: GoogleFonts.spaceMono(
                                color: const Color(0xFFFFD700),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
