import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service_simple.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final AuthServiceSimple _authService = AuthServiceSimple();
  final SupabaseClient _supabase = Supabase.instance.client;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final StreamController<bool> _subscriptionStatusController = StreamController<bool>.broadcast();

  // IDs de productos (deben coincidir con los configurados en Google Play Console)
  static const String monthlyProductId = 'subscription_monthly';
  static const String yearlyProductId = 'subscription_yearly';
  
  // Período de prueba gratis: 7 días
  static const int freeTrialDays = 7;

  bool _isAvailable = false;
  bool _isPremium = false;
  DateTime? _subscriptionExpiryDate;
  String? _activeProductId;

  // Getters
  bool get isAvailable => _isAvailable;
  bool get isPremium => _isPremium;
  DateTime? get subscriptionExpiryDate => _subscriptionExpiryDate;
  String? get activeProductId => _activeProductId;
  Stream<bool> get subscriptionStatusStream => _subscriptionStatusController.stream;

  // Inicializar el servicio
  Future<void> initialize() async {
    _isAvailable = await _inAppPurchase.isAvailable();
    
    if (!_isAvailable) {
      print('⚠️ In-App Purchase no está disponible');
      return;
    }

    // Escuchar actualizaciones de compras
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => print('❌ Error en stream de compras: $error'),
    );

    // Restaurar compras anteriores
    await restorePurchases();
    
    // Verificar estado de suscripción
    await checkSubscriptionStatus();
  }

  // Verificar estado de suscripción
  Future<void> checkSubscriptionStatus() async {
    if (!_isAvailable) return;

    try {
      // Obtener información del usuario desde Supabase
      if (_authService.isLoggedIn && _authService.currentUser != null) {
        final userId = _authService.currentUser!.id;
        
        // Verificar en Supabase si hay suscripción activa
        final subscriptionData = await _supabase
            .from('user_subscriptions')
            .select()
            .eq('user_id', userId)
            .eq('is_active', true)
            .maybeSingle();

        if (subscriptionData != null) {
          final expiryDate = DateTime.parse(subscriptionData['expires_at']);
          final now = DateTime.now();
          
          if (expiryDate.isAfter(now)) {
            _isPremium = true;
            _subscriptionExpiryDate = expiryDate;
            _activeProductId = subscriptionData['product_id'];
            _subscriptionStatusController.add(true);
            print('✅ Usuario tiene suscripción activa hasta: $expiryDate');
            return;
          } else {
            // Suscripción expirada, actualizar estado
            await _supabase
                .from('user_subscriptions')
                .update({'is_active': false})
                .eq('user_id', userId)
                .eq('id', subscriptionData['id']);
          }
        }
      }

      // Restaurar compras anteriores desde Google Play
      await restorePurchases();

      // Verificar si está en período de prueba
      await _checkFreeTrialStatus();

    } catch (e) {
      print('❌ Error verificando estado de suscripción: $e');
    }
  }

  // Verificar si el usuario está en período de prueba gratis
  Future<void> _checkFreeTrialStatus() async {
    if (!_authService.isLoggedIn) return;

    try {
      final userId = _authService.currentUser!.id;
      final prefs = await SharedPreferences.getInstance();
      final trialStartKey = 'free_trial_start_$userId';
      final trialStartStr = prefs.getString(trialStartKey);

      if (trialStartStr == null) {
        // Iniciar período de prueba
        final now = DateTime.now();
        await prefs.setString(trialStartKey, now.toIso8601String());
        _isPremium = true;
        _subscriptionExpiryDate = now.add(Duration(days: freeTrialDays));
        _subscriptionStatusController.add(true);
        print('✅ Período de prueba iniciado. Expira: ${_subscriptionExpiryDate}');
        return;
      }

      final trialStart = DateTime.parse(trialStartStr);
      final trialEnd = trialStart.add(Duration(days: freeTrialDays));
      final now = DateTime.now();

      if (now.isBefore(trialEnd)) {
        _isPremium = true;
        _subscriptionExpiryDate = trialEnd;
        _subscriptionStatusController.add(true);
        print('✅ Usuario en período de prueba. Expira: $trialEnd');
      } else {
        _isPremium = false;
        _subscriptionExpiryDate = null;
        _subscriptionStatusController.add(false);
        print('⚠️ Período de prueba expirado');
      }
    } catch (e) {
      print('❌ Error verificando período de prueba: $e');
    }
  }

  // Obtener productos disponibles
  Future<List<ProductDetails>> getProducts() async {
    if (!_isAvailable) return [];

    try {
      final productIds = {monthlyProductId, yearlyProductId};
      final response = await _inAppPurchase.queryProductDetails(productIds);

      if (response.error != null) {
        print('❌ Error obteniendo productos: ${response.error}');
        return [];
      }

      return response.productDetails;
    } catch (e) {
      print('❌ Error obteniendo productos: $e');
      return [];
    }
  }

  // Comprar suscripción
  Future<bool> purchaseSubscription(String productId) async {
    if (!_isAvailable) {
      print('❌ In-App Purchase no disponible');
      return false;
    }

    try {
      final products = await getProducts();
      final product = products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Producto no encontrado: $productId'),
      );

      // Para suscripciones, usar buyNonConsumable
      final purchaseParam = PurchaseParam(productDetails: product);
      final success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      if (!success) {
        print('❌ No se pudo iniciar la compra');
        return false;
      }

      return true;
    } catch (e) {
      print('❌ Error comprando suscripción: $e');
      return false;
    }
  }

  // Restaurar compras
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;

    try {
      // restorePurchases() dispara las compras restauradas a través del stream
      // que ya estamos escuchando en _onPurchaseUpdate
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      print('❌ Error restaurando compras: $e');
    }
  }

  // Procesar actualizaciones de compras
  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    _processPurchases(purchases);
  }

  // Procesar compras
  Future<void> _processPurchases(List<PurchaseDetails> purchases) async {
    if (!_authService.isLoggedIn) {
      print('⚠️ Usuario no autenticado, no se pueden procesar compras');
      return;
    }

    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _handleSuccessfulPurchase(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        print('❌ Error en compra: ${purchase.error}');
      }

      // Completar la compra
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  // Manejar compra exitosa
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    try {
      final userId = _authService.currentUser!.id;
      final productId = purchase.productID;
      
      // Calcular fecha de expiración según el producto
      DateTime expiryDate;
      if (productId == monthlyProductId) {
        expiryDate = DateTime.now().add(const Duration(days: 30));
      } else if (productId == yearlyProductId) {
        expiryDate = DateTime.now().add(const Duration(days: 365));
      } else {
        print('⚠️ Producto desconocido: $productId');
        return;
      }

      // Guardar en Supabase
      await _supabase.from('user_subscriptions').insert({
        'user_id': userId,
        'product_id': productId,
        'purchase_id': purchase.purchaseID ?? '',
        'transaction_date': DateTime.now().toIso8601String(),
        'expires_at': expiryDate.toIso8601String(),
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Actualizar estado local
      _isPremium = true;
      _subscriptionExpiryDate = expiryDate;
      _activeProductId = productId;
      _subscriptionStatusController.add(true);

      // Limpiar período de prueba si existe
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('free_trial_start_$userId');

      print('✅ Suscripción activada: $productId hasta $expiryDate');
    } catch (e) {
      print('❌ Error procesando compra exitosa: $e');
    }
  }

  // Limpiar recursos
  void dispose() {
    _subscription?.cancel();
    _subscriptionStatusController.close();
  }
}

