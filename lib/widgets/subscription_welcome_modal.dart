import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/subscription/subscription_screen.dart';
import '../services/auth_service_simple.dart';
import '../services/subscription_service.dart';

class SubscriptionWelcomeModal extends StatefulWidget {
  const SubscriptionWelcomeModal({super.key});

  /// Verificar si el modal debe mostrarse
  /// Se muestra siempre que el usuario esté en estado FREE (sin suscripción activa)
  /// O si está en período de prueba (aunque tenga acceso premium temporal)
  static Future<bool> shouldShowModal() async {
    try {
      final authService = AuthServiceSimple();
      if (!authService.isLoggedIn || authService.currentUser == null) {
        return false;
      }

      // Verificar si el usuario está en estado FREE (sin suscripción activa)
      final subscriptionService = SubscriptionService();
      await subscriptionService.checkSubscriptionStatus();
      
      // Verificar si está en período de prueba
      final remainingDays = await subscriptionService.getRemainingTrialDays();
      
      // Mostrar si:
      // 1. Es usuario FREE (sin suscripción activa después del período de prueba)
      // 2. O está en período de prueba (remainingDays != null y > 0)
      if (remainingDays != null && remainingDays > 0) {
        print('✅ Modal debe mostrarse: Usuario en período de prueba ($remainingDays días restantes)');
        return true;
      }
      
      final isFreeUser = subscriptionService.isFreeUser;
      print('✅ Modal debe mostrarse: isFreeUser = $isFreeUser');
      return isFreeUser;
    } catch (e) {
      print('Error verificando si debe mostrar modal: $e');
      return false;
    }
  }

  @override
  State<SubscriptionWelcomeModal> createState() => _SubscriptionWelcomeModalState();
}

class _SubscriptionWelcomeModalState extends State<SubscriptionWelcomeModal> {
  int? _remainingDays;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRemainingDays();
  }

  Future<void> _loadRemainingDays() async {
    final subscriptionService = SubscriptionService();
    final remaining = await subscriptionService.getRemainingTrialDays();
    setState(() {
      _remainingDays = remaining;
      _isLoading = false;
    });
  }

  void _navigateToSubscription() {
    Navigator.of(context, rootNavigator: true).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SubscriptionScreen(),
      ),
    );
  }

  void _closeModal() {
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1C2541),
              const Color(0xFF0B132B),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icono estrella
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),

                // Título
                Text(
                  '¡Bienvenido a Premium!',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Mensaje principal
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.celebration,
                            color: Color(0xFFFFD700),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _isLoading
                                  ? 'Tienes 7 días GRATIS con acceso completo a todas las funciones premium'
                                  : _remainingDays != null && _remainingDays! > 0
                                      ? 'Tienes $_remainingDays ${_remainingDays == 1 ? 'día' : 'días'} GRATIS con acceso completo a todas las funciones premium'
                                      : 'Tienes 7 días GRATIS con acceso completo a todas las funciones premium',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Información de precios
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Después de tu período de prueba, elige tu plan:',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      
                      // Plan Mensual
                      GestureDetector(
                        onTap: _navigateToSubscription,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mensual',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Acceso completo por 1 mes',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _remainingDays != null && _remainingDays! > 0
                                    ? 'Gratis durante prueba'
                                    : '\$88.00',
                                style: GoogleFonts.inter(
                                  fontSize: _remainingDays != null && _remainingDays! > 0 ? 14 : 22,
                                  fontWeight: FontWeight.bold,
                                  color: _remainingDays != null && _remainingDays! > 0
                                      ? Colors.green
                                      : const Color(0xFFFFD700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Plan Anual
                      GestureDetector(
                        onTap: _navigateToSubscription,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFFD700).withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Anual',
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFD700),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'AHORRA',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Acceso completo por 1 año',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Ahorra 33%',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\$888.00',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFFD700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Botón Continuar y Aprovechar mi Prueba Gratis
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _closeModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                    ),
                    child: Text(
                      'Continuar y Aprovechar mi Prueba Gratis',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

