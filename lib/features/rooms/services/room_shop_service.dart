import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../data/room_shop_models.dart';

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
