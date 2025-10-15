import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';

class PilotajeTiposScreen extends StatefulWidget {
  const PilotajeTiposScreen({super.key});

  @override
  State<PilotajeTiposScreen> createState() => _PilotajeTiposScreenState();
}

class _PilotajeTiposScreenState extends State<PilotajeTiposScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  final List<Map<String, dynamic>> _tiposPilotaje = [
    {
      'titulo': 'Prosperidad',
      'descripcion': 'Activa la abundancia con visualización dorada',
      'secuencia': '318 798',
      'color': const Color(0xFFF59E0B),
      'icono': Icons.trending_up,
      'visualizacion': 'Esfera dorada brillante con luz dorada expandiéndose',
      'instrucciones': 'Visualiza una esfera dorada brillante. Dentro de ella, imagina tu deseo de abundancia como luz dorada que se expande por todo el universo.',
    },
    {
      'titulo': 'Salud Total',
      'descripcion': 'Norma absoluta de la salud',
      'secuencia': '1884321, 88888588888',
      'color': const Color(0xFF10B981),
      'icono': Icons.favorite,
      'visualizacion': 'Esfera verde esmeralda con energía sanadora',
      'instrucciones': 'Visualiza una esfera verde esmeralda. Dentro de ella, imagina tu cuerpo perfectamente sano, lleno de energía vital y armonía.',
    },
    {
      'titulo': 'Liberar Bloqueos',
      'descripcion': 'Elimina resistencias y creencias limitantes',
      'secuencia': '591061718489, 9788891719',
      'color': const Color(0xFF8B5CF6),
      'icono': Icons.lock_open,
      'visualizacion': 'Esfera violeta disolviendo obstáculos',
      'instrucciones': 'Visualiza una esfera violeta. Dentro de ella, imagina todos tus bloqueos y limitaciones disolviéndose como humo, liberando tu verdadero potencial.',
    },
    {
      'titulo': 'Dolor Físico',
      'descripcion': 'Reduce dolor con anestesia energética',
      'secuencia': '498712891319',
      'color': const Color(0xFFEF4444),
      'icono': Icons.healing,
      'visualizacion': 'Esfera roja sanadora neutralizando el dolor',
      'instrucciones': 'Visualiza una esfera roja sanadora. Dentro de ella, imagina el área del dolor siendo envuelta en luz roja curativa que neutraliza completamente el malestar.',
    },
    {
      'titulo': 'Protección Energética',
      'descripcion': 'Genera campo de luz contra negatividad',
      'secuencia': '71931, 741',
      'color': const Color(0xFF06B6D4),
      'icono': Icons.shield,
      'visualizacion': 'Esfera azul creando escudo protector',
      'instrucciones': 'Visualiza una esfera azul brillante. Dentro de ella, imagina un escudo de luz azul que te protege de toda energía negativa y te mantiene en armonía.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Tipos de Pilotaje',
          style: TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF94A3B8)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildTiposList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.1 + _glowAnimation.value * 0.1),
                  const Color(0xFF06B6D4).withOpacity(0.1 + _glowAnimation.value * 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withOpacity(0.3 + _glowAnimation.value * 0.2),
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
                        color: const Color(0xFF8B5CF6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.category,
                        color: Color(0xFF8B5CF6),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Pilotajes Especializados',
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
                  'Cada tipo de pilotaje tiene secuencias específicas y técnicas de visualización diseñadas para manifestar diferentes aspectos de tu realidad.',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTiposList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona un Tipo de Pilotaje',
          style: TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(_tiposPilotaje.length, (index) {
          final tipo = _tiposPilotaje[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildTipoCard(tipo, index),
          );
        }),
      ],
    );
  }

  Widget _buildTipoCard(Map<String, dynamic> tipo, int index) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (tipo['color'] as Color).withOpacity(0.1 + _glowAnimation.value * 0.1),
                (tipo['color'] as Color).withOpacity(0.05 + _glowAnimation.value * 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (tipo['color'] as Color).withOpacity(0.3 + _glowAnimation.value * 0.2),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showTipoDetail(tipo),
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
                            color: (tipo['color'] as Color).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            tipo['icono'] as IconData,
                            color: tipo['color'] as Color,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tipo['titulo'] as String,
                                style: const TextStyle(
                                  color: Color(0xFFE2E8F0),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tipo['descripcion'] as String,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Consumer2<FavoritesProvider, AuthProvider>(
                          builder: (context, favProvider, authProvider, _) {
                            final isFavorite = favProvider.isFavorite('pilotaje_${index}');
                            final userId = authProvider.getUserId();

                            return GestureDetector(
                              onTap: userId != null
                                  ? () => favProvider.toggleFavorite(userId, 'pilotaje_${index}')
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isFavorite
                                      ? Colors.red.withOpacity(0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorite
                                      ? Colors.red
                                      : const Color(0xFF94A3B8),
                                  size: 20,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F23),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (tipo['color'] as Color).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Secuencia Sagrada',
                            style: TextStyle(
                              color: tipo['color'] as Color,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tipo['secuencia'] as String,
                            style: TextStyle(
                              color: tipo['color'] as Color,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showTipoDetail(tipo),
                            icon: const Icon(Icons.visibility, color: Colors.white, size: 18),
                            label: const Text(
                              'Ver Detalles',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tipo['color'] as Color,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _startPilotaje(tipo),
                            icon: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                            label: const Text(
                              'Iniciar',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTipoDetail(Map<String, dynamic> tipo) {
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
                color: (tipo['color'] as Color).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                tipo['icono'] as IconData,
                color: tipo['color'] as Color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tipo['titulo'] as String,
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (tipo['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (tipo['color'] as Color).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Secuencia Sagrada',
                      style: TextStyle(
                        color: tipo['color'] as Color,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tipo['secuencia'] as String,
                      style: TextStyle(
                        color: tipo['color'] as Color,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Visualización:',
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tipo['visualizacion'] as String,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Instrucciones:',
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tipo['instrucciones'] as String,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
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
                'Cerrar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startPilotaje(tipo);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: tipo['color'] as Color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Iniciar Pilotaje',
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

  void _startPilotaje(Map<String, dynamic> tipo) {
    HapticFeedback.lightImpact();
    
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
                color: (tipo['color'] as Color).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.play_arrow,
                color: tipo['color'] as Color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Iniciando Pilotaje',
              style: TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 18,
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
                    (tipo['color'] as Color).withOpacity(0.2),
                    (tipo['color'] as Color).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    tipo['titulo'] as String,
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tipo['secuencia'] as String,
                    style: TextStyle(
                      color: tipo['color'] as Color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '¿Estás listo para comenzar tu pilotaje?',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showPilotajeInProgress(tipo);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: tipo['color'] as Color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Comenzar',
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

  void _showPilotajeInProgress(Map<String, dynamic> tipo) {
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
                color: (tipo['color'] as Color).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.auto_awesome,
                color: tipo['color'] as Color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Pilotaje en Progreso',
              style: TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 18,
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
                color: (tipo['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (tipo['color'] as Color).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.visibility,
                    color: Color(0xFF8B5CF6),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tipo['instrucciones'] as String,
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 16,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Repite la secuencia:',
                    style: TextStyle(
                      color: tipo['color'] as Color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tipo['secuencia'] as String,
                    style: TextStyle(
                      color: tipo['color'] as Color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Completar',
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
}
