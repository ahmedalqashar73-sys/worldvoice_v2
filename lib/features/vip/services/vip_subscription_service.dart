import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../rooms/data/room_backend_config.dart';

class VipSubscriptionOffer {
  const VipSubscriptionOffer({
    required this.product,
    required this.catalogId,
  });

  final ProductDetails product;
  final String catalogId;
}

/// Native recurring VIP memberships, isolated from consumable coin purchases.
/// The backend alone grants/revokes verified subscription entitlements.
class VipSubscriptionService extends ChangeNotifier {
  VipSubscriptionService._();

  static final VipSubscriptionService instance = VipSubscriptionService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _initialized = false;
  bool _loading = false;
  bool _billingApproved = false;
  String? _message;
  List<VipSubscriptionOffer> _offers = const [];

  bool get loading => _loading;
  bool get billingApproved => _billingApproved;
  String? get message => _message;
  List<VipSubscriptionOffer> get offers => _offers;

  static const _endpointOverride =
      String.fromEnvironment('WORLDVOICE_ECONOMY_ENDPOINT');

  String get _backendUrl {
    final raw = _endpointOverride.trim().isNotEmpty
        ? _endpointOverride.trim()
        : RoomBackendConfig.economyBaseUrl.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'https' || !uri.hasAuthority ||
        uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) return '';
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    // Subscribe before checking StoreKit/Play to avoid losing new transactions.
    _sub = _iap.purchaseStream.listen(_handlePurchases,
        onError: (Object error) {
          _message = 'Could not receive store purchase updates.';
          notifyListeners();
        });
    await refreshProducts();
  }

  Future<void> refreshProducts() async {
    _loading = true;
    _message = null;
    _billingApproved = false;
    _offers = const [];
    notifyListeners();
    try {
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
      if (FirebaseAuth.instance.currentUser == null) {
        _message = 'Sign in to view VIP memberships.';
        return;
      }
      final config = (await FirebaseFirestore.instance
          .doc('vip_config/current').get()).data();
      if (config?['enabled'] != true ||
          config?['storeIntegrationVerified'] != true) {
        _message = 'Subscriptions are not available yet.';
        return;
      }
      if (_backendUrl.isEmpty || !await _iap.isAvailable()) {
        _message = 'The platform store is not available.';
        return;
      }
      final catalog = await FirebaseFirestore.instance
          .collection('vip_products')
          .where('active', isEqualTo: true)
          .get();
      final skus = <String, String>{};
      for (final doc in catalog.docs) {
        final data = doc.data();
        if (data['tier'] != 'gold') continue;
        final sku = (Platform.isAndroid
            ? data['androidProductId'] : data['iosProductId'])?.toString();
        if (sku != null && sku.startsWith('wv_vip_')) {
          skus[sku] = doc.id;
        }
      }
      if (skus.isEmpty) {
        _message = 'No VIP subscriptions have been approved.';
        return;
      }
      final result = await _iap.queryProductDetails(skus.keys.toSet());
      if (result.error != null) {
        _message = result.error!.message;
        return;
      }
      _offers = result.productDetails
          .where((details) => skus.containsKey(details.id))
          .map((details) => VipSubscriptionOffer(
              product: details, catalogId: skus[details.id]!))
          .toList(growable: false);
      _billingApproved = _offers.isNotEmpty;
      if (!_billingApproved) _message = 'Approved store products are unavailable.';
    } catch (_) {
      _message = 'Could not load VIP subscriptions.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> purchase(VipSubscriptionOffer offer) async {
    if (!_billingApproved) throw StateError('VIP subscriptions are not enabled.');
    if (!_offers.any((item) => item.product.id == offer.product.id)) {
      throw StateError('This VIP offer is no longer available.');
    }
    final config = (await FirebaseFirestore.instance
        .doc('vip_config/current').get()).data();
    if (config?['enabled'] != true ||
        config?['storeIntegrationVerified'] != true) {
      throw StateError('VIP purchase has not been approved.');
    }
    // Subscriptions are non-consumable at the platform billing API level:
    // never call buyConsumable, which is reserved for the coin store.
    final started = await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: offer.product),
    );
    if (!started) {
      throw StateError('The platform store did not start the purchase.');
    }
  }

  Future<void> restore() async {
    if (!_billingApproved) {
      throw StateError('VIP purchases are not configured for this store.');
    }
    await _iap.restorePurchases();
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      // Keep subscriptions isolated from other WorldVoice IAP product types.
      if (!purchase.productID.startsWith('wv_vip_')) continue;
      try {
        switch (purchase.status) {
          case PurchaseStatus.pending:
            _message = 'VIP purchase is pending store confirmation.';
            break;
          case PurchaseStatus.error:
            _message = purchase.error?.message ?? 'VIP purchase failed.';
            break;
          case PurchaseStatus.canceled:
            _message = 'VIP purchase cancelled.';
            break;
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            await _verifyWithBackend(purchase);
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
            _message = 'VIP membership verified.';
            break;
        }
      } catch (_) {
        _message = 'VIP verification is pending. Restore after store setup.';
      }
      notifyListeners();
    }
  }

  Future<void> _verifyWithBackend(PurchaseDetails purchase) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _backendUrl.isEmpty) {
      throw StateError('VIP verification requires sign-in and a secure backend.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) throw StateError('Not signed in.');
    if (Platform.isIOS && (purchase.purchaseID ?? '').isEmpty) {
      throw StateError('Apple transaction ID not available.');
    }
    final response = await http.post(
      Uri.parse('$_backendUrl/vip/iap/verify'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'productId': purchase.productID,
        'purchaseId': purchase.purchaseID,
        'verificationData': purchase.verificationData.serverVerificationData,
      }),
    ).timeout(const Duration(seconds: 40));
    if (response.statusCode != 200) {
      throw StateError('The VIP purchase was not verified by WorldVoice.');
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic> || body['ok'] != true) {
      throw StateError('The VIP receipt was not approved.');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
