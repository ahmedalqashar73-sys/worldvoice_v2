import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/coin_product_config.dart';

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
  String? _pendingExchangeKey;
  int? _pendingExchangeDiamonds;


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
    const base = String.fromEnvironment('WORLDVOICE_ECONOMY_ENDPOINT');
    final uri = Uri.tryParse(base);
    final endpoint = uri == null || uri.scheme != 'https' || !uri.hasAuthority
        ? ''
        : '${base.endsWith('/') ? base.substring(0, base.length - 1) : base}/iap/verify';

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

  // The backend alone applies diamond conversions and quotes.
  // Failed requests retain the idempotency key so a retry cannot debit twice.
  Uri get _walletBase {
    const raw = String.fromEnvironment('WORLDVOICE_ECONOMY_ENDPOINT');
    final parsed = Uri.tryParse(raw.trim());
    if (parsed == null || parsed.scheme != 'https' || !parsed.hasAuthority ||
        parsed.userInfo.isNotEmpty || parsed.query.isNotEmpty ||
        parsed.fragment.isNotEmpty) {
      throw StateError('Economy server is not configured for the wallet.');
    }
    final path = parsed.path.endsWith('/')
        ? parsed.path.substring(0, parsed.path.length - 1)
        : parsed.path;
    return parsed.replace(path: path);
  }

  Future<Map<String, dynamic>> _walletPost(
    String path,
    Map<String, dynamic> body, {
    String? idempotencyKey,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to use the wallet.');
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw StateError('Your login could not be verified.');
    }
    final base = _walletBase;
    final response = await http.post(
      base.replace(path: '${base.path}$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        ...(idempotencyKey == null ? <String, String>{} :
          <String, String>{'Idempotency-Key': idempotencyKey}),
      },
      body: jsonEncode(body),
    );
    Map<String, dynamic> decoded;
    try {
      final raw = jsonDecode(response.body);
      decoded = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    } catch (_) {
      throw StateError('The wallet server returned an invalid response.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300 ||
        decoded['ok'] != true) {
      throw StateError(decoded['error']?.toString() ??
          'The wallet request was not completed.');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> exchangeDiamonds(int amount) async {
    if (amount <= 0) throw StateError('Enter a positive diamond amount.');
    if (_pendingExchangeDiamonds != amount || _pendingExchangeKey == null) {
      final random = Random.secure();
      _pendingExchangeKey = List<int>.generate(
        24, (_) => random.nextInt(256),
      ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
      _pendingExchangeDiamonds = amount;
    }
    final result = await _walletPost(
      '/wallet/exchange', {'diamonds': amount},
      idempotencyKey: _pendingExchangeKey,
    );
    _pendingExchangeKey = null;
    _pendingExchangeDiamonds = null;
    return result;
  }

  /// Card checkout is WEB-ONLY. Native Android/iOS must use their respective
  /// in-app billing systems unless independently approved by store policy.
  Future<void> startWebCheckout(CoinProductConfig item) async {
    if (!kIsWeb || !item.hasApprovedWebPrice) {
      throw StateError('Web checkout is not available for this product.');
    }
    final result = await _walletPost('/web/checkout', {'catalogId': item.id});
    final url = Uri.tryParse((result['checkoutUrl'] ?? '').toString());
    if (url == null || url.scheme != 'https' || !url.hasAuthority) {
      throw StateError('The card checkout URL was invalid.');
    }
    if (!await launchUrl(url, mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_self')) {
      throw StateError('Could not open the secure card checkout.');
    }
  }

  Future<Map<String, dynamic>> getWithdrawalQuote(int amount) async {
    if (amount <= 0) throw StateError('Enter a positive diamond amount.');
    return _walletPost('/wallet/withdraw/quote', {'diamonds': amount});
  }

  Future<int> releaseMaturedDiamonds() async {
    final result = await _walletPost('/wallet/settle', <String, dynamic>{});
    return (result['diamondsReleased'] as num?)?.toInt() ?? 0;
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }
}
