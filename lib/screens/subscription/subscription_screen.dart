import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../services/subscription_service.dart';
import 'package:intl/intl.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<ProductDetails> _products = [];
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _selectedProductId;
  bool _hasPremiumAccess = false;
  DateTime? _trialExpiryDate;
  DateTime? _subscriptionExpiryDate;
  int? _remainingDays;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _checkTrialStatus();
  }

  Future<void> _checkTrialStatus() async {
    // Asegurar que el servicio esté inicializado
    await _subscriptionService.initialize();
    
    // Verificar si el usuario tiene acceso premium (período de prueba o suscripción activa)
    _hasPremiumAccess = _subscriptionService.hasPremiumAccess;
    _subscriptionExpiryDate = _subscriptionService.subscriptionExpiryDate;
    
    // Obtener días restantes del trial
    _remainingDays = await _subscriptionService.getRemainingTrialDays();
    
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _subscriptionService.getProducts();
      // Filtrar productos gratuitos - solo mostrar los que tienen precio
      final paidProducts = products.where((product) {
        // Filtrar productos que no sean gratuitos
        final price = product.price.toLowerCase();
        return !price.contains('gratis') && 
               !price.contains('free') && 
               !price.contains(r'$0') &&
               product.price.isNotEmpty;
      }).toList();
      
      setState(() {
        _products = paidProducts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando productos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _purchaseSubscription(String productId) async {
    setState(() {
      _isPurchasing = true;
      _selectedProductId = productId;
    });

    try {
      final success = await _subscriptionService.purchaseSubscription(productId);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Compra iniciada. Completa el proceso en Google Play.'),
            backgroundColor: const Color(0xFFFFD700),
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al iniciar la compra. Intenta nuevamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
          _selectedProductId = null;
        });
      }
    }
  }

  String _getProductTitle(String productId) {
    if (productId == SubscriptionService.monthlyProductId) {
      return 'Mensual';
    } else if (productId == SubscriptionService.yearlyProductId) {
      return 'Anual';
    }
    return 'Premium';
  }

  String _getProductDescription(String productId) {
    if (productId == SubscriptionService.monthlyProductId) {
      return 'Acceso completo por 1 mes';
    } else if (productId == SubscriptionService.yearlyProductId) {
      return 'Acceso completo por 1 año\nAhorra más con el plan anual';
    }
    return 'Acceso completo';
  }

  String _getFormattedPrice(String productId, String defaultPrice) {
    // Formatear precios específicos según el producto
    if (productId == SubscriptionService.monthlyProductId) {
      // Precio mensual: $88.00
      return '\$88.00';
    } else if (productId == SubscriptionService.yearlyProductId) {
      // Precio anual: $888.00
      return '\$888.00';
    }
    // Si no es uno de los productos esperados, usar el precio por defecto
    return defaultPrice;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 360;
    final now = DateTime.now();
    final hasPaidSubscription = _hasPremiumAccess &&
        (_subscriptionExpiryDate != null &&
            _subscriptionExpiryDate!.isAfter(now) &&
            (_remainingDays == null || _remainingDays! <= 0));
    final expiryText = _subscriptionExpiryDate != null
        ? DateFormat('dd/MM/yyyy').format(_subscriptionExpiryDate!)
        : '-';

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Suscripciones',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFFD700),
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(isCompact ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Banner de estado según tipo de acceso
                    if (hasPaidSubscription)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C2541),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFFD700),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.25),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.verified,
                                  color: Color(0xFFFFD700),
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    'Usuario Plan Pro',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: isCompact ? 20 : 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.visible,
                                    softWrap: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tu suscripción está activa.',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Color(0xFFFFD700),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Válida hasta: $expiryText',
                                      style: GoogleFonts.inter(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFFFD700).withOpacity(0.2),
                              const Color(0xFFFFD700).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFFD700).withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFFFFD700),
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    _remainingDays != null && _remainingDays! > 0
                                        ? '${_remainingDays} ${_remainingDays == 1 ? 'Día' : 'Días'} Premium GRATIS'
                                        : '0 Días Premium GRATIS',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFFFD700),
                                      fontSize: isCompact ? 20 : 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.visible,
                                    softWrap: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _hasPremiumAccess 
                                ? 'Desde que te registraste, disfrutas de acceso completo a todas las funciones premium por 7 días.'
                                : 'Al registrarte, disfrutarás de acceso completo a todas las funciones premium por 7 días.',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Color(0xFFFFD700),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Después del período de prueba, elige uno de los planes para continuar disfrutando de los beneficios.',
                                      style: GoogleFonts.inter(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Solo mostrar planes si NO es usuario PRO pagado (mostrar durante trial o sin suscripción)
                    if (!hasPaidSubscription) ...[
                      const SizedBox(height: 32),

                      // Título de planes
                      Text(
                        'Elige tu plan',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selecciona una opción para continuar después de tu período de prueba',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Lista de productos
                      if (_products.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white54,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No se pudieron cargar los planes',
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadProducts,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD700),
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._products.map((product) {
                        final isMonthly = product.id == SubscriptionService.monthlyProductId;
                        final isYearly = product.id == SubscriptionService.yearlyProductId;
                        final isPopular = isYearly;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: isPopular
                                ? const Color(0xFF1C2541)
                                : const Color(0xFF1C2541).withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isPopular
                                  ? const Color(0xFFFFD700)
                                  : Colors.white.withOpacity(0.2),
                              width: isPopular ? 3 : 1,
                            ),
                            boxShadow: isPopular
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700).withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Stack(
                            children: [
                              if (isPopular)
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD700),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'MÁS POPULAR',
                                      style: GoogleFonts.inter(
                                        color: Colors.black,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _getProductTitle(product.id),
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _getProductDescription(product.id),
                                                style: GoogleFonts.inter(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  _getFormattedPrice(product.id, product.price),
                                                  style: GoogleFonts.inter(
                                                    color: const Color(0xFFFFD700),
                                                    fontSize: isCompact ? 22 : 28,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              if (isYearly)
                                                Text(
                                                  'Ahorra 33%',
                                                  style: GoogleFonts.inter(
                                                    color: Colors.green,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _isPurchasing
                                            ? null
                                            : () => _purchaseSubscription(
                                                  product.id,
                                                ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isPopular
                                              ? const Color(0xFFFFD700)
                                              : Colors.white.withOpacity(0.1),
                                          foregroundColor: isPopular
                                              ? Colors.black
                                              : Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: _isPurchasing &&
                                                _selectedProductId == product.id
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.black,
                                                ),
                                              )
                                            : Text(
                                                'Suscribirse',
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
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 24),

                      // Información adicional
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Color(0xFFFFD700),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'La suscripción se renovará automáticamente',
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.cancel_outlined,
                                  color: Color(0xFFFFD700),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Cancela cuando quieras desde Google Play',
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

