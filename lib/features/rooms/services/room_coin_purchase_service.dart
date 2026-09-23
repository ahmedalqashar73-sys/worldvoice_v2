import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';

import '../data/coin_product_config.dart';
import '../data/room_backend_config.dart';

class CoinStoreProduct {
  const CoinStoreProduct({
    required this.config,
    required this.product,
  });

  final CoinProductConfig config;
  final ProductDetails product;
}

class RoomCoinPurchaseService extends ChangeNotifier {
  RoomCoinPurchaseService._();

  static final RoomCoinPurchaseService instance =
      RoomCoinPurchaseService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  bool _initialized = false;
  bool _loading = false;
  bool _storeAvailable = false;
  String? _message;
  List<CoinStoreProduct> _products = const <CoinStoreProduct>[];

  bool get loading => _loading;
  bool get storeAvailable => _storeAvailable;
  String? get message => _message;
  List<CoinStoreProduct> get products => _products;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _purchaseSub = _iap.purchaseStream.listen(
      _handlePurchases,
      onError: (Object error) {
        _message = error.toString();
        notifyListeners();
      },
    );

    await refreshProducts();
  }

  Future<void> refreshProducts() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      _storeAvailable = false;
      _products = const <CoinStoreProduct>[];
      notifyListeners();
      return;
    }

    _loading = true;
    _message = null;
    notifyListeners();

    try {
      _storeAvailable = await _iap.isAvailable();
      if (!_storeAvailable) {
        _products = const <CoinStoreProduct>[];
        _message = 'Store is not available on this device.';
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('coin_products')
          .where('active', isEqualTo: true)
          .get();

      final configs = snapshot.docs
          .map(CoinProductConfig.fromDoc)
          .where((item) => item.active && item.coins > 0)
          .toList(growable: false);

      final byProductId = <String, CoinProductConfig>{};
      for (final item in configs) {
        final productId =
            Platform.isAndroid ? item.androidProductId : item.iosProductId;
        if (productId?.trim().isNotEmpty == true) {
          byProductId[productId!.trim()] = item;
        }
      }

      if (byProductId.isEmpty) {
        _products = const <CoinStoreProduct>[];
        _message = 'No coin products are configured for this store.';
        return;
      }

      final response =
          await _iap.queryProductDetails(byProductId.keys.toSet());

      _products = response.productDetails
          .where((product) => byProductId.containsKey(product.id))
          .map(
            (product) => CoinStoreProduct(
              config: byProductId[product.id]!,
              product: product,
            ),
          )
          .toList(growable: false)
        ..sort((a, b) => a.config.coins.compareTo(b.config.coins));

      if (response.error != null) {
        _message = response.error!.message;
      } else if (response.notFoundIDs.isNotEmpty) {
        _message =
            'Some store products are not active yet: ${response.notFoundIDs.join(', ')}';
      }
    } catch (error) {
      _message = error.toString();
      _products = const <CoinStoreProduct>[];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> buy(CoinStoreProduct item) async {
    _message = null;
    notifyListeners();

    final parameter = PurchaseParam(
      productDetails: item.product,
    );

    final started = await _iap.buyConsumable(
      purchaseParam: parameter,
    );

    if (!started) {
      _message = 'The store did not start the purchase.';
      notifyListeners();
    }
  }

  Future<void> _handlePurchases(
    List<PurchaseDetails> purchases,
  ) async {
    for (final purchase in purchases) {
      try {
        switch (purchase.status) {
          case PurchaseStatus.pending:
            _message = 'Purchase pending…';
            notifyListeners();
            continue;
          case PurchaseStatus.error:
            _message = purchase.error?.message ?? 'Purchase failed.';
            notifyListeners();
            continue;
          case PurchaseStatus.canceled:
            _message = 'Purchase canceled.';
            notifyListeners();
            continue;
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            final verified = await _verifyWithBackend(purchase);
            if (!verified) {
              _message = 'Purchase verification failed.';
              notifyListeners();
              continue;
            }

            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }

            _message = 'Coins added successfully.';
            notifyListeners();
            break;
        }
      } catch (error) {
        _message = error.toString();
        notifyListeners();
      }
    }
  }

  Future<bool> _verifyWithBackend(
    PurchaseDetails purchase,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    final endpoint = RoomBackendConfig.endpoint('/iap/verify');

    if (user == null || endpoint.isEmpty) {
      throw StateError(
        'WorldVoice purchase verification backend is not configured.',
      );
    }

    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Could not authorize purchase verification.');
    }

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'productId': purchase.productID,
        'purchaseId': purchase.purchaseID,
        'verificationData':
            purchase.verificationData.serverVerificationData,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Purchase verification failed.';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          message = decoded['error']?.toString() ?? message;
        }
      } catch (_) {
        // Keep the generic message.
      }
      throw StateError(message);
    }

    final body = jsonDecode(response.body);
    return body is Map<String, dynamic> && body['ok'] == true;
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }
}
