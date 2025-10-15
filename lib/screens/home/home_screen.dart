import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/codes_provider.dart';
import '../../providers/tracker_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/code_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _pulseController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _loadData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.getUserId();
    
    if (userId != null) {
      await Future.wait([
        context.read<CodesProvider>().loadCodes(),
        context.read<TrackerProvider>().loadRecentSessions(userId),
      ]);
    }
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
                color: const Color(0xFF8B5CF6).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xFF8B5CF6),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Códigos Grabovoi',
              style: TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF94A3B8)),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildMysticalHome() : _buildStatsTab(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          border: Border(
            top: BorderSide(
              color: const Color(0xFF8B5CF6).withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined, color: Color(0xFF94A3B8)),
              selectedIcon: Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6)),
              label: 'Códigos',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined, color: Color(0xFF94A3B8)),
              selectedIcon: Icon(Icons.analytics, color: Color(0xFF8B5CF6)),
              label: 'Progreso',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMysticalHome() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF8B5CF6),
      backgroundColor: const Color(0xFF1A1A2E),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMysticalWelcome(),
              const SizedBox(height: 32),
              _buildMysticalActions(),
              const SizedBox(height: 32),
              _buildRecommendedCodes(),
              const SizedBox(height: 32),
              _buildMysticalQuote(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMysticalWelcome() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF8B5CF6).withOpacity(0.1 + _pulseController.value * 0.1),
                const Color(0xFF06B6D4).withOpacity(0.1 + _pulseController.value * 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withOpacity(0.3 + _pulseController.value * 0.2),
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
                      color: const Color(0xFF8B5CF6).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF8B5CF6),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bienvenido al Portal',
                          style: TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manifesta tu realidad con códigos sagrados',
                          style: TextStyle(
                            color: const Color(0xFF94A3B8),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMysticalActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Portal de Manifestación',
          style: TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildMysticalActionCard(
              icon: Icons.format_list_numbered,
              title: 'Códigos Sagrados',
              subtitle: 'Explorar secuencias',
              color: const Color(0xFF8B5CF6),
              onTap: () => context.push('/codes'),
            ),
            _buildMysticalActionCard(
              icon: Icons.repeat,
              title: 'Ritual de Repetición',
              subtitle: 'Contador místico',
              color: const Color(0xFF06B6D4),
              onTap: () => context.push('/tracker'),
            ),
            _buildMysticalActionCard(
              icon: Icons.flight,
              title: 'Pilotaje Consciente',
              subtitle: 'Dirige tu realidad',
              color: const Color(0xFFF59E0B),
              onTap: () => context.push('/pilotaje'),
            ),
            _buildMysticalActionCard(
              icon: Icons.book,
              title: 'Diario Místico',
              subtitle: 'Registra tu viaje',
              color: const Color(0xFFEC4899),
              onTap: () => context.push('/journal'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMysticalActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.3 + _glowController.value * 0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendedCodes() {
    return Consumer<CodesProvider>(
      builder: (context, codesProvider, _) {
        if (codesProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF8B5CF6),
            ),
          );
        }

        final recommendedCodes = codesProvider.getRecommendedCodes(limit: 3);

        if (recommendedCodes.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Códigos del Día',
                  style: TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/codes'),
                  child: const Text(
                    'Ver todos',
                    style: TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recommendedCodes.map((code) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CodeCard(code: code),
            )),
          ],
        );
      },
    );
  }

  Widget _buildMysticalQuote() {
    final quotes = [
      'Los números son la música del universo',
      'Cada secuencia es una puerta dimensional',
      'La manifestación fluye a través de la frecuencia',
      'Tu intención activa el código sagrado',
      'El universo responde a tu vibración numérica',
    ];

    final random = DateTime.now().day % quotes.length;
    final quote = quotes[random];

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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF06B6D4).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.format_quote,
              color: Color(0xFF06B6D4),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              quote,
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 16,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return Consumer2<TrackerProvider, AuthProvider>(
      builder: (context, trackerProvider, authProvider, _) {
        final totalRepetitions = trackerProvider.getTotalRepetitions(days: 7);
        final completedSessions = trackerProvider.getCompletedSessionsCount(days: 7);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tu Progreso Místico',
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Últimos 7 días de manifestación',
                style: TextStyle(
                  color: const Color(0xFF94A3B8),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              _buildMysticalStatCard(
                'Repeticiones Sagradas',
                totalRepetitions.toString(),
                Icons.repeat,
                const Color(0xFF8B5CF6),
              ),
              const SizedBox(height: 16),
              _buildMysticalStatCard(
                'Sesiones Completadas',
                completedSessions.toString(),
                Icons.check_circle,
                const Color(0xFF10B981),
              ),
              const SizedBox(height: 32),
              const Text(
                'Acceso Rápido',
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildMysticalListTile(
                icon: Icons.auto_awesome,
                title: 'Códigos Sagrados',
                subtitle: 'Explorar secuencias numéricas',
                color: const Color(0xFF8B5CF6),
                onTap: () => context.push('/codes'),
              ),
              _buildMysticalListTile(
                icon: Icons.repeat,
                title: 'Ritual de Repetición',
                subtitle: 'Contador de manifestación',
                color: const Color(0xFF06B6D4),
                onTap: () => context.push('/tracker'),
              ),
              _buildMysticalListTile(
                icon: Icons.self_improvement,
                title: 'Meditación Guiada',
                subtitle: 'Pilotaje profundo',
                color: const Color(0xFFF59E0B),
                onTap: () => context.push('/meditations'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMysticalStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMysticalListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1A1A2E),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFF94A3B8),
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}