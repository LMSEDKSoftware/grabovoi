import 'dart:async';
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

  // Verificar si el usuario es gratuito (sin suscripción activa después del período de prueba)
  bool get isFreeUser {
    // Si no tiene suscripción premium activa, es usuario gratuito
    return !_isPremium;
  }

  // Verificar si el usuario tiene acceso premium (suscripción activa o en período de prueba)
  bool get hasPremiumAccess => _isPremium;

  // Obtener fecha de expiración de la suscripción
  DateTime? get subscriptionExpiryDate => _subscriptionExpiryDate;

  // Obtener fecha de inicio de la suscripción (si está disponible)
  Future<DateTime?> getSubscriptionStartDate() async {
    if (!_authService.isLoggedIn) return null;
    
    try {
      final userId = _authService.currentUser!.id;
      // Obtener siempre la suscripción activa más reciente (por fecha de expiración)
      final subscriptionData = await _supabase
          .from('user_subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('expires_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (subscriptionData != null) {
        return DateTime.parse(subscriptionData['transaction_date'] ?? subscriptionData['created_at']);
      }
      
      // Si no hay suscripción activa, usar fecha de creación de la cuenta
      final userData = await _supabase
          .from('users')
          .select('created_at')
          .eq('id', userId)
          .maybeSingle();
      
      if (userData != null && userData['created_at'] != null) {
        return DateTime.parse(userData['created_at']);
      }
      
      return null;
    } catch (e) {
      print('❌ Error obteniendo fecha de inicio: $e');
      return null;
    }
  }

  // Inicializar el servicio
  Future<void> initialize() async {
    _isAvailable = await _inAppPurchase.isAvailable();
    
    if (!_isAvailable) {
      print('⚠️ In-App Purchase no está disponible');
      // IMPORTANTE: Aún así verificar estado de suscripción (puede haber suscripción en Supabase)
      await checkSubscriptionStatus();
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
    print('🔍 Iniciando verificación de estado de suscripción...');
    print('🔍 Usuario autenticado: ${_authService.isLoggedIn}');
    
    try {
      // Obtener información del usuario desde Supabase
      if (_authService.isLoggedIn && _authService.currentUser != null) {
        final userId = _authService.currentUser!.id;
        print('🔍 User ID: $userId');

        // Verificar en Supabase si hay suscripción activa (SIEMPRE verificar, incluso si IAP no está disponible)
        // Tomar SIEMPRE la suscripción activa más reciente (por expires_at)
        final subscriptionData = await _supabase
            .from('user_subscriptions')
            .select()
            .eq('user_id', userId)
            .eq('is_active', true)
            .order('expires_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (subscriptionData != null) {
          final expiryDate = DateTime.parse(subscriptionData['expires_at']);
          final now = DateTime.now();

          print('🔍 Suscripción encontrada en Supabase. Expira: $expiryDate');

          if (expiryDate.isAfter(now)) {
            // Suscripción vigente -> usuario PRO
            _isPremium = true;
            _subscriptionExpiryDate = expiryDate;
            _activeProductId = subscriptionData['product_id'];
            _subscriptionStatusController.add(true);
            print('✅ Usuario tiene suscripción activa hasta: $expiryDate');
            return;
          } else {
            // Suscripción expirada, actualizar estado y marcar como no PRO
            print('⚠️ Suscripción expirada, actualizando estado...');
            await _supabase
                .from('user_subscriptions')
                .update({'is_active': false})
                .eq('user_id', userId)
                .eq('id', subscriptionData['id']);

            _isPremium = false;
            _subscriptionExpiryDate = null;
            _activeProductId = null;
            _subscriptionStatusController.add(false);
          }
        } else {
          // No hay suscripciones activas -> usuario NO PRO (salvo que el trial lo reactive)
          print('🔍 No se encontró suscripción activa en Supabase');
          _isPremium = false;
          _subscriptionExpiryDate = null;
          _activeProductId = null;
          _subscriptionStatusController.add(false);
        }
      } else {
        print('⚠️ Usuario no autenticado o currentUser es null');
        _isPremium = false;
        _subscriptionExpiryDate = null;
        _activeProductId = null;
        _subscriptionStatusController.add(false);
      }

      // Solo verificar Google Play si está disponible
      if (_isAvailable) {
        print('🔍 Verificando compras en Google Play...');
        // Restaurar compras anteriores desde Google Play
        await restorePurchases();
      } else {
        print('⚠️ Google Play IAP no está disponible, saltando verificación');
      }

      // Verificar si está en período de prueba (solo si no hay suscripción activa)
      // Solo verificar período de prueba si no se encontró suscripción activa en Supabase
      if (!_isPremium) {
        print('🔍 No hay suscripción premium activa, verificando período de prueba...');
        await _checkFreeTrialStatus();
      } else {
        print('✅ Usuario ya tiene acceso premium, no se verifica período de prueba');
      }

    } catch (e) {
      print('❌ Error verificando estado de suscripción: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      // En caso de error, verificar período de prueba como fallback
      await _checkFreeTrialStatus();
    }
  }

  // Obtener días restantes del período de prueba
  // Usa la fecha de creación de la cuenta desde Supabase, no SharedPreferences
  Future<int?> getRemainingTrialDays() async {
    if (!_authService.isLoggedIn) {
      return null;
    }

    try {
      final userId = _authService.currentUser!.id;
      
      // Obtener fecha de creación de la cuenta desde Supabase
      final userData = await _supabase
          .from('users')
          .select('created_at')
          .eq('id', userId)
          .maybeSingle();
      
      if (userData == null || userData['created_at'] == null) {
        print('⚠️ No se encontró fecha de creación del usuario');
        return null;
      }
      
      final accountCreatedAt = DateTime.parse(userData['created_at']);
      // Normalizar fechas a medianoche para comparación correcta
      final accountCreatedAtMidnight = DateTime(accountCreatedAt.year, accountCreatedAt.month, accountCreatedAt.day);
      final now = DateTime.now();
      final nowMidnight = DateTime(now.year, now.month, now.day);
      
      // Calcular días transcurridos desde la creación (0 = mismo día, 1 = día siguiente, etc.)
      final daysSinceCreation = nowMidnight.difference(accountCreatedAtMidnight).inDays;
      
      // El período de prueba es de 7 días completos
      // Si es el mismo día (días transcurridos = 0), debe mostrar 7 días
      // Si pasó 1 día completo, muestra 6 días, etc.
      final remaining = freeTrialDays - daysSinceCreation;
      
      print('🔍 Fecha de creación de cuenta: $accountCreatedAtMidnight');
      print('🔍 Fecha actual: $nowMidnight');
      print('🔍 Días transcurridos desde creación: $daysSinceCreation');
      print('🔍 Días restantes de prueba: $remaining');

      if (remaining > 0) {
        print('✅ Días restantes de prueba: $remaining');
        return remaining;
      } else {
        // Período de prueba expirado
        print('⚠️ Período de prueba expirado');
        return 0;
      }
    } catch (e) {
      print('❌ Error obteniendo días restantes: $e');
      return null;
    }
  }

  // Verificar si el usuario está en período de prueba gratis
  // Usa la fecha de creación de la cuenta desde Supabase, no SharedPreferences
  Future<void> _checkFreeTrialStatus() async {
    print('🔍 Verificando estado de período de prueba...');
    print('🔍 Usuario autenticado: ${_authService.isLoggedIn}');
    
    if (!_authService.isLoggedIn) {
      // Usuario no autenticado = usuario gratuito
      _isPremium = false;
      _subscriptionExpiryDate = null;
      _subscriptionStatusController.add(false);
      print('⚠️ Usuario no autenticado - no se puede verificar período de prueba');
      return;
    }

    try {
      final userId = _authService.currentUser!.id;
      print('🔍 User ID: $userId');
      
      // Obtener fecha de creación de la cuenta desde Supabase
      final userData = await _supabase
          .from('users')
          .select('created_at')
          .eq('id', userId)
          .maybeSingle();
      
      if (userData == null || userData['created_at'] == null) {
        print('⚠️ No se encontró fecha de creación del usuario - usuario gratuito');
        _isPremium = false;
        _subscriptionExpiryDate = null;
        _subscriptionStatusController.add(false);
        return;
      }
      
      final accountCreatedAt = DateTime.parse(userData['created_at']);
      final trialEnd = accountCreatedAt.add(const Duration(days: freeTrialDays));
      final now = DateTime.now();

      print('🔍 Fecha de creación de cuenta: $accountCreatedAt');
      print('🔍 Período de prueba expira: $trialEnd');
      print('🔍 Fecha actual: $now');

      if (now.isBefore(trialEnd)) {
        // Usuario en período de prueba activo
        _isPremium = true;
        _subscriptionExpiryDate = trialEnd;
        _subscriptionStatusController.add(true);
        print('✅ Usuario en período de prueba. Expira: $trialEnd');
      } else {
        // Período de prueba expirado - usuario gratuito
        _isPremium = false;
        _subscriptionExpiryDate = null;
        _subscriptionStatusController.add(false);
        print('⚠️ Período de prueba expirado - usuario gratuito');
      }
    } catch (e) {
      print('❌ Error verificando período de prueba: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      // En caso de error, considerar como usuario gratuito
      _isPremium = false;
      _subscriptionExpiryDate = null;
      _subscriptionStatusController.add(false);
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

  // Evitar procesar la misma compra varias veces (stream puede disparar múltiples veces)
  static final Map<String, DateTime> _recentlyProcessedPurchaseIds = {};
  static bool _handlingPurchaseLock = false;
  static const _dedupeWindow = Duration(seconds: 90);

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

  // Manejar compra exitosa (una sola inserción/actualización por compra)
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    final userId = _authService.currentUser!.id;
    final productId = purchase.productID;
    final purchaseId = purchase.purchaseID ?? '';

    // Dedupe: si ya procesamos este purchase_id hace poco, no hacer nada
    if (purchaseId.isNotEmpty) {
      final now = DateTime.now();
      final last = _recentlyProcessedPurchaseIds[purchaseId];
      if (last != null && now.difference(last) < _dedupeWindow) {
        print('⏭️ Compra ya procesada recientemente (purchase_id=$purchaseId), omitiendo');
        return;
      }
    }

    // Bloqueo: solo una compra a la vez para evitar condiciones de carrera
    while (_handlingPurchaseLock) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    _handlingPurchaseLock = true;
    try {
      await _handleSuccessfulPurchaseImpl(purchase, userId, productId, purchaseId);
      if (purchaseId.isNotEmpty) {
        _recentlyProcessedPurchaseIds[purchaseId] = DateTime.now();
        // Limpiar entradas antiguas
        final toRemove = <String>[];
        for (final e in _recentlyProcessedPurchaseIds.entries) {
          if (DateTime.now().difference(e.value) > _dedupeWindow) toRemove.add(e.key);
        }
        for (final k in toRemove) {
          _recentlyProcessedPurchaseIds.remove(k);
        }
      }
    } finally {
      _handlingPurchaseLock = false;
    }
  }

  Future<void> _handleSuccessfulPurchaseImpl(
    PurchaseDetails purchase,
    String userId,
    String productId,
    String purchaseId,
  ) async {
    try {
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

      // 1) Verificar si ya existe una fila para este user_id + purchase_id
      Map<String, dynamic>? existing;
      if (purchaseId.isNotEmpty) {
        try {
          existing = await _supabase
              .from('user_subscriptions')
              .select('id, is_active, expires_at')
              .eq('user_id', userId)
              .eq('purchase_id', purchaseId)
              .maybeSingle();
        } catch (e) {
          print('⚠️ Error buscando suscripción existente para purchase_id=$purchaseId: $e');
        }
      }

      // Si purchase_id vacío (Android a veces): buscar suscripción reciente mismo user+product
      if (existing == null && purchaseId.isEmpty) {
        final cutoff = DateTime.now().subtract(const Duration(minutes: 2));
        try {
          final recent = await _supabase
              .from('user_subscriptions')
              .select('id, is_active')
              .eq('user_id', userId)
              .eq('product_id', productId)
              .gte('created_at', cutoff.toIso8601String())
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
          if (recent != null) {
            existing = recent;
          }
        } catch (e) {
          print('⚠️ Error buscando suscripción reciente (purchase_id vacío): $e');
        }
      }

      if (existing != null) {
        // 2a) Ya existe un registro para este purchase_id: actualizarlo y dejar solo uno activo
        final existingId = existing['id'] as String;
        await _supabase
            .from('user_subscriptions')
            .update({
              'product_id': productId,
              'purchase_id': purchaseId.isEmpty ? null : purchaseId,
              'transaction_date': DateTime.now().toIso8601String(),
              'expires_at': expiryDate.toIso8601String(),
              'is_active': true,
            })
            .eq('id', existingId);

        await _supabase
            .from('user_subscriptions')
            .update({'is_active': false})
            .eq('user_id', userId)
            .eq('is_active', true)
            .neq('id', existingId);

        _applySubscriptionState(productId, expiryDate, userId);
        print('✅ Suscripción actualizada (id=$existingId): $productId hasta $expiryDate');
        return;
      }

      // 2b) No existe este purchase_id: validar que no haya ya una suscripción vigente
      // Si ya hay una vigente (expires_at > now), no insertar ni sobrescribir con otra
      final now = DateTime.now();
      Map<String, dynamic>? validSubscription;
      try {
        validSubscription = await _supabase
            .from('user_subscriptions')
            .select('id, product_id, expires_at')
            .eq('user_id', userId)
            .gt('expires_at', now.toIso8601String())
            .order('expires_at', ascending: false)
            .limit(1)
            .maybeSingle();
      } catch (e) {
        print('⚠️ Error buscando suscripción vigente: $e');
      }

      if (validSubscription != null) {
        final vigenteProduct = validSubscription['product_id'] as String?;
        final vigenteExpira = validSubscription['expires_at'] as String?;
        print('⏭️ Usuario ya tiene suscripción vigente ($vigenteProduct hasta $vigenteExpira). No se inserta ni se sobrescribe con $productId.');
        _applySubscriptionState(vigenteProduct ?? monthlyProductId, vigenteExpira != null ? DateTime.parse(vigenteExpira) : expiryDate, userId);
        return;
      }

      // 2c) No hay suscripción vigente: reutilizar registro existente (expirado) o insertar uno nuevo
      Map<String, dynamic>? anyExisting;
      try {
        anyExisting = await _supabase
            .from('user_subscriptions')
            .select('id')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
      } catch (e) {
        print('⚠️ Error buscando suscripción previa para reutilizar: $e');
      }

      if (anyExisting != null) {
        final existingId = anyExisting['id'] as String;

        // Desactivar todas las demás y dejar SOLO este registro como activo
        await _supabase
            .from('user_subscriptions')
            .update({'is_active': false})
            .eq('user_id', userId)
            .neq('id', existingId);

        await _supabase
            .from('user_subscriptions')
            .update({
              'product_id': productId,
              'purchase_id': purchaseId.isEmpty ? null : purchaseId,
              'transaction_date': DateTime.now().toIso8601String(),
              'expires_at': expiryDate.toIso8601String(),
              'is_active': true,
            })
            .eq('id', existingId);

        _applySubscriptionState(productId, expiryDate, userId);
        print('✅ Suscripción actualizada reutilizando registro existente (id=$existingId): $productId hasta $expiryDate');
      } else {
        // No hay ningún registro previo: crear uno nuevo
        await _supabase
            .from('user_subscriptions')
            .update({'is_active': false})
            .eq('user_id', userId)
            .eq('is_active', true);

        await _supabase.from('user_subscriptions').insert({
          'user_id': userId,
          'product_id': productId,
          'purchase_id': purchaseId.isEmpty ? null : purchaseId,
          'transaction_date': DateTime.now().toIso8601String(),
          'expires_at': expiryDate.toIso8601String(),
          'is_active': true,
        });

        _applySubscriptionState(productId, expiryDate, userId);
        print('✅ Suscripción insertada (única, sin registros previos): $productId hasta $expiryDate');
      }
    } catch (e) {
      print('❌ Error procesando compra exitosa: $e');
    }
  }

  void _applySubscriptionState(String productId, DateTime expiryDate, String userId) {
    _isPremium = true;
    _subscriptionExpiryDate = expiryDate;
    _activeProductId = productId;
    _subscriptionStatusController.add(true);
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('free_trial_start_$userId');
    });
  }

  // Limpiar recursos
  void dispose() {
    _subscription?.cancel();
    _subscriptionStatusController.close();
  }
}

