import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../data/room_feature_models.dart';
import '../data/classic_gift_catalog.dart';
import 'room_chat_service.dart';
import '../data/room_backend_config.dart';
import 'room_quiz_service.dart';

class RoomFeatureService {
  RoomFeatureService({required this.roomId, this.collectionName = 'rooms'});

  final String roomId;
  final String collectionName;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  User? get _user => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>> get _room =>
      _db.collection(collectionName).doc(roomId);

  Stream<RoomFeatureState> watchState() {
    return _room.snapshots().map(
      (snapshot) => RoomFeatureState.fromData(
        snapshot.data() ?? const <String, dynamic>{},
      ),
    );
  }

  /// Host-created rooms already contain their level and XP. Never reset
  /// progress, privacy, live sharing or music when reopening a room.
  Future<void> initializeDefaults() async {
    final snapshot = await _room.get();
    if (!snapshot.exists) {
      throw StateError('Create or join the room before initializing tools.');
    }
    final data = snapshot.data() ?? const <String, dynamic>{};
    final isHost = data['hostId'] == _user?.uid;
    if (!isHost) return;

    final needsBackgroundV3 =
        (data['backgroundLayoutVersion'] as num?)?.toInt() != 4 ||
        !data.containsKey('themeId');
    if (needsBackgroundV3) {
      // Background changes are server-authorized so a stale client Firestore
      // rule cannot block the host from restoring the clean default canvas.
      await setPurchasedBackground(
        themeId: 'softGreenFlow',
        backgroundUrl: null,
      );
    }

    if (!data.containsKey('boardWriteEnabled')) {
      await _room.update({
        'boardWriteEnabled': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> setTheme(String themeId) => _room.set(
        {
          'themeId': themeId,
          'backgroundUrl': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

  Future<void> setPurchasedBackground({
    required String themeId,
    required String? backgroundUrl,
  }) async {
    // The server validates host ownership and paid background entitlements.
    // Do not trust a client-provided URL; it is retained in the signature only
    // for compatibility with existing callers.
    assert(backgroundUrl == null || backgroundUrl.isEmpty ||
        Uri.tryParse(backgroundUrl)?.hasScheme == true);

    final user = _user;
    if (user == null) throw StateError('SIGN_IN_REQUIRED');
    final uri = Uri.tryParse(
      _economyBackend.trim().replaceFirst(RegExp(r'/$'), ''),
    );
    if (uri == null || !uri.hasAuthority || uri.scheme != 'https') {
      throw StateError('Room backend unavailable.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Could not authorize background change.');
    }

    final response = await http.post(
      uri.replace(
        path: '${uri.path.replaceFirst(RegExp(r"/$"), "")}/room/background/apply',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'roomId': roomId,
        'themeId': themeId,
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String reason = 'Could not apply background.';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          reason = decoded['error']?.toString() ?? reason;
        }
      } catch (_) {
        // Keep the stable user-facing failure.
      }
      throw StateError(reason);
    }
  }

  /// Host-only shared presentation, watched by all room members.
  Future<void> setBoardPresentationActive(bool active) => _room.update({
    'boardPresentationActive': active,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> setBoardWriteEnabled(bool value) => _room.set(
        {
          'boardWriteEnabled': value,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

  Future<void> setAccess({
    required bool isPrivate,
    required bool vipOnly,
  }) =>
      _room.set(
        {
          'isPrivate': isPrivate,
          'vipOnly': vipOnly,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

  Future<void> setScreenSharing({required bool active, int? sharerUid}) async {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final room = await transaction.get(_room);
      if (active && room.data()?['boardMediaId'] != null) {
        throw StateError('Stop the current media presentation first.');
      }
      transaction.update(_room, {
        'screenShareActive': active,
        'screenSharerUid': active && sharerUid != null ? sharerUid : FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> setMusic({
    required String? title,
    required String? url,
    required bool playing,
  }) =>
      _room.set(
        {
          'musicTitle': title,
          'musicUrl': url,
          'musicPlaying': playing,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

  // Preserve existing callers; all quiz work is owned by RoomQuizService.
  RoomQuizService get _quiz => RoomQuizService(roomId: roomId);

  Future<void> startQuiz({
    required String question,
    required List<String> options,
    required int correctIndex,
  }) => _quiz.startQuiz(
        question: question, options: options, correctIndex: correctIndex,
      );

  Future<void> answerQuiz(int optionIndex) => _quiz.answerQuiz(optionIndex);
  Future<void> revealQuiz() => _quiz.revealQuiz();
  Future<void> finishQuiz() => _quiz.finishQuiz();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchQuizAnswers() =>
      _quiz.watchQuizAnswers();

  // Gift settlement must run against the same original-main service as
  // owner monthly grants, to preserve admin-paid coin provenance.
  static String get _economyBackend =>
      RoomBackendConfig.giftStoreBaseUrl.trim();

  /// Existing room caller: the backend alone calculates catalog price.
  Future<void> sendGift({
    required String recipientId,
    required String recipientName,
    required String giftId,
    required int points,
    int quantity = 1,
    String? requestKey,
  }) {
    // Keep legacy UI callers compatible while refusing client-controlled price.
    assert(points >= 0 && recipientName.isNotEmpty);
    return sendContextGift(
      context: 'room', contextId: roomId, recipientId: recipientId,
      giftId: giftId, quantity: quantity, requestKey: requestKey,
    );
  }

  /// Shared by room, real live sessions and real conversations only.
  /// Unsupported contexts receive a 501 from the backend until membership
  /// checks and message event streams exist (never simulate a paid success).
  static Future<void> sendContextGift({
    required String context,
    required String contextId,
    required String recipientId,
    required String giftId,
    int quantity = 1,
    String? requestKey,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('SIGN_IN_REQUIRED');
    if (recipientId == user.uid) throw StateError('CANNOT_GIFT_SELF');
    if (!const {'room', 'live', 'chat'}.contains(context) ||
        quantity <= 0 || giftId.trim().isEmpty || contextId.trim().isEmpty) {
      throw StateError('INVALID_GIFT');
    }
    final uri = Uri.tryParse(_economyBackend.trim().replaceFirst(RegExp(r'/$'), ''));
    if (uri == null || !uri.hasAuthority || uri.scheme != 'https') {
      throw StateError('Economy backend unavailable. Gifts are disabled.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Could not authorize gift request.');
    }
    final secureRandom = Random.secure();
    final key = requestKey ?? List<int>.generate(
      24, (_) => secureRandom.nextInt(256),
    ).map((v) => v.toRadixString(16).padLeft(2, '0')).join();

    // Keep the caller's idempotency key when retrying after a timeout;
    // never claim delivery when the backend has not acknowledged settlement.
    final response = await http.post(
      uri.replace(path: '${uri.path.replaceFirst(RegExp(r"/$"), "")}/gift/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Idempotency-Key': key,
      },
      body: jsonEncode({
        'context': context, 'contextId': contextId,
        'recipientId': recipientId, 'giftId': giftId, 'quantity': quantity,
      }),
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String reason = 'Gift could not be sent.';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          reason = decoded['error']?.toString() ?? reason;
        }
      } catch (_) { /* Keep stable error. */ }
      throw StateError(reason);
    }
  }

  /// Real owner-only beta gift delivered to an existing private chat.
  /// The authenticated server enforces all financial and identity checks.
  /// Only the server can approve verified-owner non-redeemable test gifts.
  static Future<({bool available, String reason})>
      ownerBetaGiftReadiness() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return (available: false, reason: 'SIGN_IN_REQUIRED');
    }
    final uri = Uri.tryParse(
      RoomBackendConfig.giftStoreBaseUrl.trim()
          .replaceFirst(RegExp(r'/$'), ''),
    );
    if (uri == null || uri.scheme != 'https' ||
        !uri.hasAuthority || uri.userInfo.isNotEmpty) {
      return (available: false, reason: 'GIFT_BACKEND_NOT_CONFIGURED');
    }
    try {
      final token = await user.getIdToken(true)
          .timeout(const Duration(seconds: 12));
      if (token == null || token.isEmpty) {
        return (available: false, reason: 'SIGN_IN_REQUIRED');
      }
      final basePath = uri.path.replaceFirst(RegExp(r'/$'), '');
      final response = await http.get(
        uri.replace(path: '$basePath/gift/owner-beta/status'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 20));
      Map<String, dynamic> data = const <String, dynamic>{};
      try {
        final parsed = jsonDecode(response.body);
        if (parsed is Map<String, dynamic>) data = parsed;
      } catch (_) {}
      if (response.statusCode == 401) {
        return (available: false, reason: 'SIGN_IN_REQUIRED');
      }
      if (response.statusCode != 200 || data['ok'] != true) {
        return (available: false, reason: 'GIFT_BACKEND_UNAVAILABLE');
      }
      return (
        available: data['available'] == true,
        reason: (data['reason'] ?? 'GIFT_BACKEND_UNAVAILABLE').toString(),
      );
    } catch (_) {
      return (available: false, reason: 'NETWORK_ERROR');
    }
  }

  static Future<bool> ownerBetaGiftAvailable() async =>
      (await ownerBetaGiftReadiness()).available;

  static Future<void> sendOwnerBetaChatGift({
    required String chatId,
    required String recipientId,
    required String giftId,
    required String requestKey,
  }) async {
    // Verified owner and administrative-only debits are enforced by server.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid == recipientId ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(chatId)) {
      throw StateError('Invalid owner test gift chat.');
    }
    final backend = Uri.tryParse(
      RoomBackendConfig.giftStoreBaseUrl.trim().replaceFirst(RegExp(r'/$'), ''),
    );
    if (backend == null || backend.scheme != 'https' ||
        !backend.hasAuthority || backend.userInfo.isNotEmpty) {
      throw StateError('Gift testing backend not configured.');
    }
    // A signed-in user's valid cached token avoids forcing a new Firebase
    // network round trip for every gift. The server still verifies it.
    String? token;
    try {
      token = await user.getIdToken();
    } on FirebaseAuthException catch (error) {
      if (error.code == 'unknown' ||
          (error.message?.toLowerCase().contains('connection reset') ?? false)) {
        throw StateError('FIREBASE_CONNECTION_INTERRUPTED');
      }
      rethrow;
    }
    if (token == null || token.isEmpty) {
      throw StateError('Firebase authorization failed.');
    }
    final basePath = backend.path.endsWith('/')
        ? backend.path.substring(0, backend.path.length - 1)
        : backend.path;
    final response = await http.post(
      backend.replace(path: '$basePath/gift/owner-beta-chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Idempotency-Key': requestKey,
      },
      body: jsonEncode({
        'contextId': chatId,
        'recipientId': recipientId,
        'giftId': giftId,
        'quantity': 1,
      }),
    ).timeout(const Duration(seconds: 20));
    Map<String, dynamic> payload = <String, dynamic>{};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) payload = decoded;
    } catch (_) {
      // Keep a safe error if the backend response was not JSON.
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        payload['error']?.toString() ?? 'Owner test gift not delivered.',
      );
    }
    if (payload['ok'] != true || payload['ownerBetaGift'] != true ||
        payload['pendingDiamonds'] != 0 ||
        payload['paidCoinsSpent'] != 0) {
      throw StateError('Owner gift receipt was not verified.');
    }
  }

  /// A server-verified owner test gift to a real room or Live participant.
  /// Only administrative coins are used; no diamonds can be minted.
  static Future<void> sendOwnerBetaContextGift({
    required String context,
    required String contextId,
    required String recipientId,
    required String giftId,
    required String requestKey,
  }) async {
    if (!const {'room', 'live'}.contains(context)) {
      throw StateError('Invalid gift test context.');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid == recipientId ||
        contextId.isEmpty || contextId.contains('/')) {
      throw StateError('Invalid gift session or recipient.');
    }
    final endpoint = Uri.tryParse(
      RoomBackendConfig.giftStoreBaseUrl.trim().replaceFirst(RegExp(r'/$'), ''),
    );
    if (endpoint == null || endpoint.scheme != 'https' ||
        !endpoint.hasAuthority || endpoint.userInfo.isNotEmpty) {
      throw StateError('Gift testing backend not configured.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Firebase authorization failed.');
    }
    final path = endpoint.path.endsWith('/')
        ? endpoint.path.substring(0, endpoint.path.length - 1)
        : endpoint.path;
    final response = await http.post(
      endpoint.replace(path: '$path/gift/owner-beta-context'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Idempotency-Key': requestKey,
      },
      body: jsonEncode({
        'context': context, 'contextId': contextId,
        'recipientId': recipientId, 'giftId': giftId, 'quantity': 1,
      }),
    ).timeout(const Duration(seconds: 20));
    Map<String, dynamic> receipt = <String, dynamic>{};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) receipt = decoded;
    } catch (_) {}
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(receipt['error']?.toString() ??
          'Owner test gift could not be sent.');
    }
    if (receipt['ok'] != true || receipt['ownerBetaGift'] != true ||
        receipt['pendingDiamonds'] != 0 ||
        receipt['paidCoinsSpent'] != 0) {
      throw StateError('Owner gift receipt could not be verified.');
    }
  }

  /// These notices are separate from /gifts, balances and paid chat messages.
  static const bool friendPreviewEnabled = bool.fromEnvironment(
      'WORLDVOICE_FRIEND_GIFT_PREVIEW', defaultValue: false);

  static CollectionReference<Map<String, dynamic>> _previewCollection({
    required String context,
    required String contextId,
  }) {
    if (!const {'room', 'live', 'chat'}.contains(context) ||
        contextId.isEmpty || contextId.contains('/')) {
      throw ArgumentError('Invalid test preview destination');
    }
    final parentName = switch (context) {
      'chat' => 'chats',
      'live' => 'live_sessions',
      _ => 'rooms',
    };
    final parent = FirebaseFirestore.instance
        .collection(parentName)
        .doc(contextId);
    return parent.collection('gift_previews');
  }

  /// Read only explicitly free demonstration notices. The Firebase rules
  /// verify both parties' room/chat membership and throttle each sender.
  static Stream<List<RoomGiftPreview>> watchFriendGiftPreviews({
    required String context,
    required String contextId,
  }) {
    if (!friendPreviewEnabled) {
      return const Stream<List<RoomGiftPreview>>.empty();
    }
    return _previewCollection(context: context, contextId: contextId)
        .orderBy('sentAt', descending: true).limit(20).snapshots()
        .map((snap) =>
            snap.docs.map(RoomGiftPreview.fromDoc).toList(growable: false));
  }

  /// A TEST ANIMATION sent across two devices. It never touches an economy
  /// endpoint, paid gift events, room XP or private-wallet balances.
  static Future<void> sendFriendGiftPreview({
    required String context,
    required String contextId,
    required String recipientId,
    required String recipientName,
    required String giftId,
  }) async {
    if (!friendPreviewEnabled) throw StateError('TEST_PREVIEWS_DISABLED');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('SIGN_IN_REQUIRED');
    if (recipientId.isEmpty || recipientId == user.uid ||
        recipientId == 'teacher_ai') {
      throw StateError('SELECT_A_REAL_FRIEND');
    }
    final approved = await ClassicGiftCatalog.load();
    final approvedForDemo = approved.any((g) => g.id == giftId);
    if (!approvedForDemo) {
      throw StateError('INVALID_TEST_GIFT');
    }
    // Always resolve names from existing authorized membership documents.
    // Never trust arbitrary sender/receiver labels from the device.
    final db = FirebaseFirestore.instance;
    late final String sender;
    late final String receiver;
    if (context == 'chat') {
      final chat = await db.collection('chats').doc(contextId).get();
      final members = chat.data()?['memberIds'];
      final names = chat.data()?['memberNames'];
      if (chat.data()?['active'] != true || members is! List ||
          !members.contains(user.uid) || !members.contains(recipientId) ||
          names is! Map) {
        throw StateError('TEST_CHAT_MEMBERSHIP_REQUIRED');
      }
      sender = (names[user.uid] ?? '').toString();
      receiver = (names[recipientId] ?? '').toString();
    } else {
      final participants = db.collection('rooms').doc(contextId)
          .collection('participants');
      final docs = await Future.wait([
        participants.doc(user.uid).get(),
        participants.doc(recipientId).get(),
      ]);
      if (docs.any((doc) => !doc.exists)) {
        throw StateError('TEST_ROOM_MEMBERSHIP_REQUIRED');
      }
      sender = (docs[0].data()?['displayName'] ?? '').toString();
      receiver = (docs[1].data()?['displayName'] ?? '').toString();
    }
    // The argument is used only to select the recipient id; Firestore is the
    // authority for the display name on the cross-device preview.
    assert(recipientName.isNotEmpty);
    if (sender.trim().isEmpty || sender.length > 100 ||
        receiver.trim().isEmpty || receiver.length > 100) {
      throw StateError('INVALID_TEST_RECIPIENT');
    }
    final random = Random.secure();
    final nonce = List<int>.generate(12, (_) => random.nextInt(256))
        .map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    try {
      await _previewCollection(context: context, contextId: contextId)
          .doc(user.uid).set({
        'nonce': nonce,
        'senderId': user.uid,
        'senderName': sender,
        'recipientId': recipientId,
        'recipientName': receiver,
        'giftId': giftId,
        'sentAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      // Users can test with friends before deploying the NEW isolated
      // preview rules if their existing voice-room chat is operational.
      // This fallback is only a marked free chat text; the server-owned
      // monetary /gifts and wallet records remain untouched.
      if (error.code != 'permission-denied' || context == 'chat') rethrow;
      final marker = RoomGiftPreviewChatCodec.encode(
        giftId: giftId, recipientId: recipientId, nonce: nonce);
      await RoomChatService(roomId: contextId).send(marker);
    }
  }

  Stream<List<RoomGiftCatalogItem>> watchGiftCatalog() {
    return _db
        .collection('store_items')
        .where('type', isEqualTo: 'gift')
        .snapshots()
        .asyncMap((snapshot) async {
      final previews = await ClassicGiftCatalog.load();
      final published = snapshot.docs
          .map(RoomGiftCatalogItem.fromDoc)
          .toList(growable: false);
      final items = ClassicGiftCatalog.merge(
        previews: previews,
        published: published,
      ).where((item) => item.active).toList(growable: false)
        ..sort((a, b) => a.priceCoins.compareTo(b.priceCoins));
      return items;
    });
  }

  Stream<List<RoomGiftEvent>> watchGifts() {
    return _room
        .collection('gifts')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(RoomGiftEvent.fromDoc).toList(growable: false),
        );
  }

  static Stream<List<RoomGiftEvent>> watchContextGifts({
    required String context,
    required String contextId,
  }) {
    if (!const {'room', 'live', 'chat'}.contains(context) ||
        contextId.trim().isEmpty ||
        contextId.contains('/')) {
      throw ArgumentError('Invalid gift event context');
    }
    final parent = switch (context) {
      'live' => 'live_sessions',
      'chat' => 'chats',
      _ => 'rooms',
    };
    return FirebaseFirestore.instance
        .collection(parent)
        .doc(contextId)
        .collection('gifts')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(RoomGiftEvent.fromDoc).toList(growable: false),
        );
  }

  // Mission credit is now backend-only. Never compute or set XP from a
  // client-side button; server verifies joinedAt, live guests and gift events.
  Uri _missionEndpoint(String path) {
    final configured = _economyBackend.trim();
    if (configured.isNotEmpty) {
      final uri = Uri.tryParse(configured);
      if (uri == null || !uri.hasAuthority || uri.scheme != 'https') {
        throw StateError('The verified room mission backend URL is invalid.');
      }
      final prefix = uri.path.replaceFirst(RegExp(r'/$'), '');
      return uri.replace(path: '$prefix$path');
    }
    final endpoint = RoomBackendConfig.endpoint(path);
    if (endpoint.isEmpty) {
      throw StateError('Room mission backend is not configured.');
    }
    return Uri.parse(endpoint);
  }

  Future<Map<String, dynamic>> _missionRequest(
    String path, {Map<String, dynamic>? payload}
  ) async {
    final user = _user;
    if (user == null) throw StateError('Sign in to view room missions.');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Could not authorize room missions.');
    }
    final uri = _missionEndpoint(path);
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    late final http.Response response;
    try {
      response = payload == null
          ? await http.get(uri.replace(queryParameters: {'roomId': roomId}),
              headers: headers).timeout(const Duration(seconds: 15))
          : await http.post(uri, headers: headers, body: jsonEncode(payload))
              .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw StateError('ROOM_TASK_BACKEND_TIMEOUT');
    }
    Map<String, dynamic>? decoded;
    try {
      final parsed = jsonDecode(response.body);
      if (parsed is Map) decoded = Map<String, dynamic>.from(parsed);
    } catch (_) {
      // The deployed free Worker may not include the optional mission routes.
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(decoded?['error']?.toString() ??
          'Verified room missions need the full backend, not the token-only Worker.');
    }
    if (decoded?['ok'] != true) {
      throw StateError('The mission server returned an invalid result.');
    }
    return decoded!;
  }

  Future<Map<String, dynamic>> recordTaskPresence() =>
      _missionRequest('/room/tasks/heartbeat', payload: {'roomId': roomId});

  Future<Map<String, dynamic>> taskStatus() =>
      _missionRequest('/room/tasks/status');

  Future<Map<String, dynamic>> claimVerifiedTask(String taskKey) {
    if (!const {
      'ten_minutes', 'host_five', 'stage_five', 'three_gifts', 'stay_hours',
        'room_checkin', 'visit_5', 'visit_6', 'visit_30', 'visit_60',
    }.contains(taskKey)) {
      throw ArgumentError.value(taskKey, 'taskKey', 'Unknown room mission');
    }
    return _missionRequest('/room/tasks/claim',
        payload: {'roomId': roomId, 'taskKey': taskKey});
  }

  Future<void> recordSpeakerActivity({
    int seconds = 30,
  }) async {
    final user = _user;
    if (user == null || seconds <= 0 || seconds > 60) return;

    final profile = await _db.collection('users').doc(user.uid).get();
    final data = profile.data() ?? const <String, dynamic>{};
    final name =
        (data['displayName'] ?? user.displayName ?? 'WorldVoice user')
            .toString();

    await _room.collection('speaker_stats').doc(user.uid).set(
      {
        'userId': user.uid,
        'displayName': name,
        'seconds': FieldValue.increment(seconds),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSpeakerStats() {
    return _room
        .collection('speaker_stats')
        .orderBy('seconds', descending: true)
        .limit(50)
        .snapshots();
  }

  Future<void> recordHistoryEnter(String roomName) async {
    final user = _user;
    if (user == null) return;
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('room_history')
        .doc(roomId)
        .set(
      {
        'roomId': roomId,
        'roomName': roomName,
        'lastEnteredAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> submitRating({
    required String targetUserId,
    required int stars,
  }) async {
    final user = _user;
    if (user == null || stars < 1 || stars > 5) return;
    await _room.collection('ratings').doc('${user.uid}_$targetUserId').set({
      'fromUserId': user.uid,
      'targetUserId': targetUserId,
      'stars': stars,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
