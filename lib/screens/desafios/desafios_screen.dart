import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import 'challenge_progress_screen.dart';
import '../../services/challenge_service.dart';

class DesafiosScreen extends StatefulWidget {
  const DesafiosScreen({super.key});

  @override
  State<DesafiosScreen> createState() => _DesafiosScreenState();
}

class _DesafiosScreenState extends State<DesafiosScreen> {
  Map<String, dynamic>? activeChallenge;

  final List<Map<String, dynamic>> _desafios = [
    {
      'id': '1',
      'titulo': 'Desafío de Iniciación Energética',
      'duracionDias': 7,
      'descripcion': 'Comienza tu viaje de manifestación con los códigos básicos.',
      'dificultad': 'Principiante',
      'color': const Color(0xFF4CAF50),
      'icon': Icons.star_border,
    },
    {
      'id': '2',
      'titulo': 'Desafío de Armonización Intermedia',
      'duracionDias': 14,
      'descripcion': 'Profundiza en tu conexión interior y expande tu campo energético.',
      'dificultad': 'Intermedio',
      'color': const Color(0xFF2196F3),
      'icon': Icons.star_half,
    },
    {
      'id': '3',
      'titulo': 'Desafío Avanzado de Luz Dorada',
      'duracionDias': 21,
      'descripcion': 'Expande tu campo vibracional al máximo nivel de manifestación.',
      'dificultad': 'Avanzado',
      'color': const Color(0xFFFFD700),
      'icon': Icons.star,
    },
    {
      'id': '4',
      'titulo': 'Desafío Maestro de Abundancia',
      'duracionDias': 30,
      'descripcion': 'Transforma tu realidad hacia la abundancia infinita.',
      'dificultad': 'Maestro',
      'color': const Color(0xFF9C27B0),
      'icon': Icons.diamond,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadActiveChallenge();
  }

  Future<void> _loadActiveChallenge() async {
    final challenge = await ChallengeService.getActiveChallenge();
    setState(() {
      activeChallenge = challenge;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: SingleChildScrollView(
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
                
                // Título
                Text(
                  'Desafíos Vibracionales',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rutas de transformación personal',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                       const SizedBox(height: 30),

                       // Desafío Activo (si existe)
                       if (activeChallenge != null) ...[
                         _buildActiveChallengeCard(),
                         const SizedBox(height: 20),
                       ],
                       
                       // Lista de Desafíos
                       ..._desafios.map((desafio) => _buildDesafioCard(desafio)).toList(),
                
                const SizedBox(height: 30),
                
                // Botón de Desafío Aleatorio
                CustomButton(
                  text: 'Desafío Aleatorio',
                  onPressed: () {
                    final randomDesafio = _desafios[
                      (DateTime.now().millisecondsSinceEpoch % _desafios.length)
                    ];
                    _showDesafioDialog(randomDesafio);
                  },
                  isOutlined: true,
                  icon: Icons.shuffle,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesafioCard(Map<String, dynamic> desafio) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: desafio['color'].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDesafioDialog(desafio),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: desafio['color'].withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        desafio['icon'],
                        color: desafio['color'],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            desafio['titulo'],
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${desafio['duracionDias']} días',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: desafio['color'].withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  desafio['dificultad'],
                                  style: GoogleFonts.inter(
                                    color: desafio['color'],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white54,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  desafio['descripcion'],
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDesafioDialog(Map<String, dynamic> desafio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: desafio['color'].withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                desafio['icon'],
                color: desafio['color'],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                desafio['titulo'],
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFFFD700),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
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
              desafio['descripcion'],
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Duración: ${desafio['duracionDias']} días',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Nivel: ${desafio['dificultad']}',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cerrar',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startDesafio(desafio);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: desafio['color'],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Comenzar',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChallengeCard() {
    if (activeChallenge == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withOpacity(0.2),
            const Color(0xFFFFD700).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_circle_fill,
                  color: Color(0xFFFFD700),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Desafío Activo: ${activeChallenge!['title']}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Día ${activeChallenge!['currentDay']} en progreso',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Continuar Desafío',
            onPressed: () {
              // Buscar el desafío completo para pasar a la pantalla de progreso
              final challengeData = _desafios.firstWhere(
                (d) => d['id'] == activeChallenge!['id'],
                orElse: () => _desafios.first,
              );
              
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChallengeProgressScreen(challenge: challengeData),
                ),
              );
            },
            icon: Icons.play_arrow,
          ),
        ],
      ),
    );
  }

  Future<void> _startDesafio(Map<String, dynamic> desafio) async {
    // Iniciar el desafío
    await ChallengeService.startChallenge(desafio['id'], desafio['titulo']);
    
    // Recargar el desafío activo
    await _loadActiveChallenge();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Has comenzado el ${desafio['titulo']}!'),
        backgroundColor: desafio['color'],
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Ver Progreso',
          textColor: Colors.white,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChallengeProgressScreen(challenge: desafio),
              ),
            );
          },
        ),
      ),
    );
  }
}

