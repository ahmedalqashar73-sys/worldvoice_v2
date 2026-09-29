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
  RoomFeatureService({required this.roomId});

  final String roomId;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  User? get _user => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>> get _room =>
      _db.collection('rooms').doc(roomId);

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
    final missing = <String, dynamic>{
      if (!data.containsKey('themeId')) 'themeId': 'emerald',
      if (!data.containsKey('boardWriteEnabled'))
        'boardWriteEnabled': true,
    };
    if (missing.isNotEmpty) {
      await _room.update({
        ...missing,
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
  }) =>
      _room.set(
        {
          'themeId': themeId,
          'backgroundUrl': backgroundUrl?.trim().isNotEmpty == true
              ? backgroundUrl!.trim()
              : FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

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

  static const String _economyBackend =
      String.fromEnvironment('WORLDVOICE_ECONOMY_ENDPOINT');

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

  /// Opt-in TEST APK mode only. Never enabled in the production default.
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
    final parent = FirebaseFirestore.instance
        .collection(context == 'chat' ? 'chats' : 'rooms')
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
    if (!approved.any((g) => g.id == giftId)) {
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
        .map((snapshot) {
      final items = snapshot.docs
          .map(RoomGiftCatalogItem.fromDoc)
          .where((item) => item.active && item.priceCoins > 0)
          .toList(growable: false)
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
    final response = payload == null
        ? await http.get(uri.replace(queryParameters: {'roomId': roomId}),
            headers: headers).timeout(const Duration(seconds: 15))
        : await http.post(uri, headers: headers, body: jsonEncode(payload))
            .timeout(const Duration(seconds: 15));
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

  Future<Map<String, dynamic>> taskStatus() =>
      _missionRequest('/room/tasks/status');

  Future<Map<String, dynamic>> claimVerifiedTask(String taskKey) {
    if (!const {
      'ten_minutes', 'host_five', 'three_gifts', 'stay_hours',
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
