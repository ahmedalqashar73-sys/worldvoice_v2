import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../data/room_shop_models.dart';
import '../data/room_backend_config.dart';

class ShopGiftRecipient {
  const ShopGiftRecipient({required this.uid, required this.displayName,
    this.username = '', this.customId = ''});

  final String uid;
  final String displayName;
  final String username;
  final String customId;

  factory ShopGiftRecipient.fromJson(Map<String, dynamic> data) =>
      ShopGiftRecipient(
        uid: (data['uid'] ?? '').toString(),
        displayName: (data['displayName'] ?? '').toString(),
        username: (data['username'] ?? '').toString(),
        customId: (data['customId'] ?? '').toString(),
      );
}

class RoomShopService {
  final Map<String,String> _pendingKeys = <String,String>{};

  String _newRequestKey() {
    final random = Random.secure();
    return List<int>.generate(24, (_) => random.nextInt(256))
        .map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  }

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  User? get _user => FirebaseAuth.instance.currentUser;

  static const String _explicitEndpoint =
      RoomBackendConfig.giftStoreBaseUrl;

  String get endpoint {
    final explicit = _explicitEndpoint.trim();
    final url = explicit.endsWith('/')
        ? explicit.substring(0, explicit.length - 1) : explicit;
    final parsed = Uri.tryParse(url);
    if (parsed == null || parsed.scheme != 'https' || !parsed.hasAuthority ||
        parsed.userInfo.isNotEmpty || parsed.hasQuery || parsed.hasFragment) {
      return '';
    }
    return '$url/store';
  }

  // A store administrator is not necessarily the verified account owner.
  // One server response supplies both permissions without duplicate requests.
  late final Future<Map<String, dynamic>> _access = _loadAccess();
  late final Future<bool> adminAccess =
      _access.then((value) => value['canManageStore'] == true);
  late final Future<bool> ownerAccess =
      _access.then((value) => value['isOwner'] == true);

  Future<Map<String, dynamic>> _loadAccess() async {
    try {
      final token = await _user?.getIdToken();
      if (token == null || !isConfigured) return const {};
      final response = await http.get(Uri.parse('$endpoint/access'), headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return const {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  /// Confirm the verified owner's current-month grant with a server response.
  /// This never directly writes wallet balances from a device.
  Future<Map<String, dynamic>> refreshOwnerMonthlyCoins() async {
    final user = _user;
    if (user == null || !isConfigured) {
      throw StateError('Sign in and store connection required.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Could not authorize owner coin check.');
    }
    final base = endpoint.substring(0, endpoint.length - '/store'.length);
    final response = await http.post(
      Uri.parse('$base/account/sync-entitlements'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: '{}',
    ).timeout(const Duration(seconds: 30));
    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw StateError('Invalid server response for monthly coin check.');
    }
    if (response.statusCode != 200 || data['privileged'] != true) {
      throw StateError((data['error'] ??
              'Owner verification or monthly coin sync failed.').toString());
    }
    return data;
  }

  Future<void> grantItem(String itemId) => _post(
    action: 'admin-grant', body: {'itemId': itemId},
  );

  bool get isConfigured => endpoint.trim().isNotEmpty;

  Stream<List<RoomShopBackground>> watchBackgrounds() {
    return _db
        .collection('store_items')
        .where('type', isEqualTo: 'background')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(RoomShopBackground.fromDoc)
              .where((item) => item.active)
              .toList(growable: false),
        );
  }

  Stream<List<RoomBackgroundEntitlement>> watchOwnedBackgrounds() {
    final user = _user;
    if (user == null) {
      return Stream.value(const <RoomBackgroundEntitlement>[]);
    }

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('inventory')
        .where('type', isEqualTo: 'background')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(RoomBackgroundEntitlement.fromDoc)
              .where((item) => item.isActive)
              .toList(growable: false),
        );
  }

  Stream<Set<String>> watchOwnedItemIds(String type) {
    final user = _user;
    if (user == null) return Stream.value(<String>{});
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('inventory')
        .where('type', isEqualTo: type)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs.where((doc) {
        final raw = doc.data()['expiresAt'];
        return raw is! Timestamp || raw.toDate().isAfter(now);
      }).map((doc) => doc.id).toSet();
    });
  }

  Stream<String?> watchSelectedProfileFrame() {
    final user = _user;
    if (user == null) return Stream.value(null);
    return _db.collection('users').doc(user.uid).snapshots().map(
          (snapshot) =>
              (snapshot.data()?['profileFrameId'] as String?)?.trim(),
        );
  }

  Future<void> setProfileFrame(String frameId) async {
    final user = _user;
    if (user == null) throw StateError('Sign in is required.');

    const freeFrames = <String>{
      // Legacy frames remain equipable on accounts that already use them.
      'free_clean_white',
      'free_soft_green',
      'free_sky_blue',
      'free_silver',
      'free_minimal_glow',
    };
    final normalized = frameId.trim();
    if (freeFrames.contains(normalized)) {
      await _db.collection('users').doc(user.uid).update({
        'profileFrameId': normalized,
      });
      return;
    }
    if (!normalized.startsWith('frame__')) {
      throw StateError('Invalid profile frame.');
    }

    final owned = await _db
        .collection('users')
        .doc(user.uid)
        .collection('inventory')
        .doc(normalized)
        .get();
    final data = owned.data() ?? const <String, dynamic>{};
    final rawExpires = data['expiresAt'];
    final active = rawExpires is! Timestamp ||
        rawExpires.toDate().isAfter(DateTime.now());
    if (!owned.exists || data['type'] != 'frame' || !active) {
      throw StateError('This frame is not in your inventory.');
    }

    await _db.collection('users').doc(user.uid).update({
      'profileFrameId': normalized,
    });
  }

  Stream<List<RoomBackgroundReward>> watchBackgroundRewards() {
    final user = _user;
    if (user == null) {
      return Stream.value(const <RoomBackgroundReward>[]);
    }

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('room_rewards')
        .where('type', isEqualTo: 'background_month')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(RoomBackgroundReward.fromDoc)
              .where((reward) => reward.isAvailable)
              .toList(growable: false),
        );
  }

  Stream<List<RoomStoreItem>> watchStoreItems(String type) {
    if (!const {'gift', 'background', 'frame', 'entrance', 'vip', 'bubble'}
        .contains(type)) {
      return Stream.value(const <RoomStoreItem>[]);
    }
    return _db.collection('store_items')
        .where('type', isEqualTo: type).snapshots().map((snapshot) =>
            snapshot.docs.map(RoomStoreItem.fromDoc)
                .where((item) => item.active && item.priceCoins > 0)
                .toList(growable: false)
              ..sort((a, b) => a.priceCoins.compareTo(b.priceCoins)));
  }

  Future<void> purchaseItem(String itemId) =>
      _post(action: 'purchase', body: {'itemId': itemId});

  /// Send one EXISTING published WorldVoice visual gift to any member.
  /// The server verifies owner identity, coin balance and canonical price.
  Future<void> sendOwnerDirectGift({
    required String giftId,
    required String recipientId,
  }) => _post(
    action: 'gift/owner-direct',
    rootPath: true,
    body: {'giftId': giftId, 'recipientId': recipientId, 'quantity': 1},
  );

  Future<void> setChatBubble(String bubbleId) =>
      _post(action: 'bubble/equip', body: {'bubbleId': bubbleId});

  Future<void> purchaseBackground(String itemId) {
    return _post(
      action: 'purchase',
      body: {'itemId': itemId},
    );
  }

  /// Always charge the catalog price; only the backend chooses the coin source.
  /// null duration means permanent ownership for backgrounds and frames.
  Future<void> giftItem({
    required String itemId,
    required String recipientId,
    int? durationDays,
  }) => _post(
    action: 'purchase',
    body: {
      'itemId': itemId,
      'recipientId': recipientId,
      ...(durationDays == null
          ? const <String, dynamic>{}
          : <String, dynamic>{'durationDays': durationDays}),
    },
  );

  Future<List<ShopGiftRecipient>> searchGiftRecipients(String term) async {
    final user = _user;
    if (user == null || !isConfigured) {
      throw StateError('Sign in and store connection required.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Missing authentication token.');
    }
    final query = term.trim();
    final uri = Uri.parse('$endpoint/recipient-search')
        .replace(queryParameters: {'q': query});
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    }).timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw StateError('Cannot search gift recipients.');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (payload['users'] as List<dynamic>? ?? const []);
    return results.whereType<Map<String, dynamic>>()
        .map(ShopGiftRecipient.fromJson)
        .where((value) => value.uid.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> claimReward({
    required String rewardId,
    required String itemId,
  }) {
    return _post(
      action: 'claim-reward',
      body: {
        'rewardId': rewardId,
        'itemId': itemId,
      },
    );
  }

  Future<void> _post({
    required String action,
    required Map<String, dynamic> body,
    bool rootPath = false,
  }) async {
    final user = _user;
    if (user == null) {
      throw StateError('Sign in is required.');
    }
    if (!isConfigured) {
      throw StateError('WorldVoice store backend is not configured.');
    }

    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Could not authorize the store request.');
    }

    final base = endpoint.endsWith('/')
        ? endpoint.substring(0, endpoint.length - 1)
        : endpoint;
    final keyId = '${body['adminGrant'] == true}:$action:${body['itemId'] ?? ''}:${body['giftId'] ?? ''}:${body['recipientId'] ?? ''}:${body['rewardId'] ?? ''}:${body['durationDays'] ?? 'permanent'}';
    final requestKey = _pendingKeys.putIfAbsent(keyId, _newRequestKey);
    final response = await http.post(
      Uri.parse('${rootPath ? base.substring(0, base.length - '/store'.length) : base}/$action'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
        'Idempotency-Key': requestKey,
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 110));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Store request failed.';
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
    _pendingKeys.remove(keyId);
  }
}