import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../data/room_shop_models.dart';
import '../../../core/widgets/worldvoice_avatar_frame.dart';

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
      String.fromEnvironment('WORLDVOICE_ECONOMY_ENDPOINT');

  String get endpoint {
    final explicit = _explicitEndpoint.trim();
    final url = explicit.endsWith('/')
        ? explicit.substring(0, explicit.length - 1) : explicit;
    final parsed = Uri.tryParse(url);
    if (parsed == null || parsed.scheme != 'https' || !parsed.hasAuthority) {
      return '';
    }
    return '$url/store';
  }

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

    final normalized = frameId.trim();
    if (WorldVoiceAvatarFrame.isFree(normalized)) {
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
    if (!const {'gift', 'background', 'frame', 'entrance', 'vip'}
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

  Future<void> purchaseBackground(String itemId) {
    return _post(
      action: 'purchase',
      body: {'itemId': itemId},
    );
  }

  Future<void> giftItem({
    required String itemId,
    required String recipientId,
  }) => _post(
    action: 'purchase',
    body: {'itemId': itemId, 'recipientId': recipientId},
  );

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
    final keyId = '$action:${body['itemId'] ?? ''}:${body['recipientId'] ?? ''}:${body['rewardId'] ?? ''}';
    final requestKey = _pendingKeys.putIfAbsent(keyId, _newRequestKey);
    final response = await http.post(
      Uri.parse('$base/$action'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
        'Idempotency-Key': requestKey,
      },
      body: jsonEncode(body),
    );

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